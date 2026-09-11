/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_input_processor_dynamic_rate_limit

#include <drivers/input_processor.h>
#include <stdlib.h>
#include <zephyr/device.h>
#include <zephyr/kernel.h>
#include <zephyr/sys/util.h>

#include <zephyr/logging/log.h>
#include <zmk/endpoints.h>
#include <zmk/endpoints_types.h>
#include <zmk/events/endpoint_changed.h>

#if IS_ENABLED(CONFIG_ZMK_BLE) && IS_ENABLED(CONFIG_ZMK_POINTING)
#include <zephyr/bluetooth/conn.h>
#include <zmk/ble.h>
#include <zmk/hid.h>
#include <zmk/hog.h>
#endif

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

#include <zmk/keymap.h>

#define MAX_CODES 2

#ifndef CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_USB_US
#define CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_USB_US 1000
#endif

#ifndef CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_BLE_US
#define CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_BLE_US 7000
#endif

#ifndef CONFIG_BT_PERIPHERAL_PREF_MIN_INT
#define CONFIG_BT_PERIPHERAL_PREF_MIN_INT 6
#endif

#ifndef CONFIG_BT_PERIPHERAL_PREF_MAX_INT
#define CONFIG_BT_PERIPHERAL_PREF_MAX_INT 6
#endif

#ifndef CONFIG_BT_PERIPHERAL_PREF_LATENCY
#define CONFIG_BT_PERIPHERAL_PREF_LATENCY 0
#endif

#ifndef CONFIG_BT_PERIPHERAL_PREF_TIMEOUT
#define CONFIG_BT_PERIPHERAL_PREF_TIMEOUT 400
#endif

#if IS_ENABLED(CONFIG_ZMK_BLE) && IS_ENABLED(CONFIG_ZMK_POINTING)
static int64_t last_param_update_req_us = 0;

/* アイドル放置等でホスト (macOS) が接続インターバルを緩和 (15ms/60Hz等) した場合に、
 * トラックボール操作再開時に即座に 7.5ms (133.3Hz) への復帰を要求する */
static void check_and_restore_ble_interval(void) {
  int64_t now_us = k_ticks_to_us_floor64(k_uptime_ticks());
  /* ガードタイマー: 直前要求から 2 秒以内は再送しない (過剰リクエストによるホスト拒否を防止) */
  if (now_us - last_param_update_req_us < 2000000) {
    return;
  }

  struct bt_conn *conn = zmk_ble_active_profile_conn();
  if (!conn) {
    return;
  }

  struct bt_conn_info info;
  int err = bt_conn_get_info(conn, &info);
  if (err == 0 && info.type == BT_CONN_TYPE_LE) {
    /* interval は 1.25ms 単位。6 = 7.5ms (133.3Hz)。
     * もし 6 を超えている場合（放置による 12=15ms / 66Hz 落ち込み等）、7.5ms へ再要求！ */
    if (info.le.interval > CONFIG_BT_PERIPHERAL_PREF_MAX_INT) {
      static const struct bt_le_conn_param fast_param =
          BT_LE_CONN_PARAM_INIT(CONFIG_BT_PERIPHERAL_PREF_MIN_INT,
                                CONFIG_BT_PERIPHERAL_PREF_MAX_INT,
                                CONFIG_BT_PERIPHERAL_PREF_LATENCY,
                                CONFIG_BT_PERIPHERAL_PREF_TIMEOUT);

      int ret = bt_conn_le_param_update(conn, &fast_param);
      if (ret == 0) {
        LOG_INF("Restoring BLE connection interval to fast 7.5ms (current %u > max %u)",
                info.le.interval, CONFIG_BT_PERIPHERAL_PREF_MAX_INT);
        last_param_update_req_us = now_us;
      } else {
        LOG_DBG("Failed to request fast connection interval (err %d)", ret);
      }
    }
  }

  bt_conn_unref(conn);
}
#endif

struct dynamic_rrl_config {
  uint8_t type;
  size_t codes_len;
  uint16_t codes[];
};

struct dynamic_rrl_data {
  int16_t rmds[MAX_CODES];
  bool syncs[MAX_CODES];
  int64_t last_rpt_us; /* 2軸統合フレームタイマー (マイクロ秒) */
  bool frame_active;   /* 現在のセンサフレーム処理中フラグ */
  bool report_ready;   /* 現在のセンサフレームを送出するかどうかのフラグ */
  enum zmk_transport transport;
};

static void reset_pipeline_data(struct dynamic_rrl_data *data) {
  int64_t now_us = k_ticks_to_us_floor64(k_uptime_ticks());
  for (int i = 0; i < MAX_CODES; i++) {
    data->rmds[i] = 0;
    data->syncs[i] = false;
  }
  data->last_rpt_us = now_us;
  data->frame_active = false;
  data->report_ready = false;
}

#if !IS_ENABLED(CONFIG_ZMK_SPLIT) || IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
#define HAS_ENDPOINTS 1
#endif

#define GET_DEV(node_id) DEVICE_DT_GET(node_id),

static const struct device *dynamic_rrl_devs[] = {
    DT_FOREACH_STATUS_OKAY(DT_DRV_COMPAT, GET_DEV)};

#if HAS_ENDPOINTS
static int dynamic_rrl_endpoint_listener(const zmk_event_t *eh) {
  struct zmk_endpoint_changed *ep_changed = as_zmk_endpoint_changed(eh);
  if (ep_changed) {
    struct zmk_endpoint_instance ep = zmk_endpoint_get_selected();
    for (size_t i = 0; i < ARRAY_SIZE(dynamic_rrl_devs); i++) {
      struct dynamic_rrl_data *data =
          (struct dynamic_rrl_data *)dynamic_rrl_devs[i]->data;
      if (data->transport != ep.transport) {
        data->transport = ep.transport;
        reset_pipeline_data(data);
      }
    }
  }
  return 0;
}

ZMK_LISTENER(dynamic_rrl_endpoint_listener, dynamic_rrl_endpoint_listener);
ZMK_SUBSCRIPTION(dynamic_rrl_endpoint_listener, zmk_endpoint_changed);
#endif

#if IS_ENABLED(CONFIG_ZMK_BLE) && IS_ENABLED(CONFIG_ZMK_POINTING)
static struct k_work_delayable ble_flush_work;

static void ble_flush_work_handler(struct k_work *work) {
  ARG_UNUSED(work);
  zmk_hog_trigger_mouse_send();
}

/* ========================================================================= */
/* 【BLE 送信前処理コールバック】送信直前に最新移動量を締めてセット (Fetch &
 * Clear) */
/* ========================================================================= */
static bool dynamic_rrl_before_send(struct zmk_hid_mouse_report_body *report,
                                    void *user_data) {
  struct dynamic_rrl_data *data = (struct dynamic_rrl_data *)user_data;
  if (!data) {
    return false;
  }

  /* アキュムレートされている移動量を締めてセット (Fetch & Clear) */
  report->d_x = data->rmds[0];
  report->d_y = data->rmds[1];
  data->rmds[0] = 0;
  data->rmds[1] = 0;
  data->syncs[0] = false;
  data->syncs[1] = false;

  bool has_motion = (report->d_x != 0 || report->d_y != 0);
  if (has_motion) {
    data->last_rpt_us = k_ticks_to_us_floor64(k_uptime_ticks());
  }

  return has_motion;
}
#endif

/* ========================================================================= */
/* 【レートリミット処理】USB 1000Hz Frame Gating / BLE 送信前処理ハンドシェイク
 */
/* ========================================================================= */
static int process_rate_limit(struct dynamic_rrl_data *data,
                              struct input_event *event, int code_idx,
                              uint32_t usb_delay_ms, uint32_t ble_delay_ms) {
  ARG_UNUSED(usb_delay_ms);
  ARG_UNUSED(ble_delay_ms);

  bool orig_sync = event->sync;

#if IS_ENABLED(CONFIG_ZMK_BLE) && IS_ENABLED(CONFIG_ZMK_POINTING)
  /* =========================================================================
   */
  /* 1. BLE 接続時: 送信前処理コールバック連携 (7.5msスロット同期
   * 1送出1レポート) */
  /* =========================================================================
   */
  if (data->transport == ZMK_TRANSPORT_BLE) {
    /* アイドル放置後の 60Hz 落ち込みを防止し、操作再開時に即座に 7.5ms (133Hz) へ復帰要求 */
    check_and_restore_ble_interval();

    /* 移動量をアキュムレータに加算 (1カウントも失わない) */
    data->rmds[code_idx] =
        CLAMP(data->rmds[code_idx] + event->value, INT16_MIN, INT16_MAX);
    data->syncs[code_idx] |= orig_sync;
    event->value = 0;
    event->sync = false;

    /* フレーム末尾 (sync) で送信判定:
     * 7.5ms スロット内のバースト送信 (285Hz)
     * を防ぎ、1スロット1レポートに同期させる */
    if (orig_sync) {
      int64_t now_us = k_ticks_to_us_floor64(k_uptime_ticks());
      int64_t elapsed_us = now_us - data->last_rpt_us;
      int64_t guard_us = (int64_t)CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_BLE_US;

      if (elapsed_us >= guard_us || data->last_rpt_us == 0) {
        /* 前回の送信から 7.0ms 以上経過 (次スロットの送出タイミング):
         * 即時キック */
        k_work_cancel_delayable(&ble_flush_work);
        zmk_hog_trigger_mouse_send();
      } else {
        /* 同じスロット内 (6.0ms 未満):
         * バーストを防ぐため即時送信せずアキュムレート。
         * スロット枠満了時にフラッシュ送信ワークを予約し、停止時の取りこぼしを完全防止
         */
        int64_t remain_us = guard_us - elapsed_us;
        k_work_schedule(&ble_flush_work, K_USEC(remain_us));
      }
    }

    /* 上位キューへの push をバイパスして STOP */
    return ZMK_INPUT_PROC_STOP;
  }
#endif

  /* =========================================================================
   */
  /* 2. USB 接続時: 1000Hz (1000us) Frame Gating & マイクロ秒完全一致 (既存保護)
   */
  /* =========================================================================
   */
  int64_t now_us = k_ticks_to_us_floor64(k_uptime_ticks());
  int64_t delay_us = (int64_t)CONFIG_ZMK_TRACKBALL_REPORT_INTERVAL_USB_US;

  /* センサフレーム開始判定 (X軸):
   * 直前のフレームが完了しているか、または時刻逆転時は新フレーム開始 */
  if (!data->frame_active || (now_us < data->last_rpt_us)) {
    data->frame_active = true;
    /* フレーム先頭で今回のフレーム（X, Y共通）を送出するかどうかを一括判定 */
    data->report_ready = (now_us - data->last_rpt_us >= delay_us) ||
                         (now_us < data->last_rpt_us);
  }

  /* 送出インターバル未達の場合: XもYも無条件に蓄積してSTOP (泣き別れ防止) */
  if (!data->report_ready) {
    data->rmds[code_idx] =
        CLAMP(data->rmds[code_idx] + event->value, INT16_MIN, INT16_MAX);
    data->syncs[code_idx] |= orig_sync;
    event->value = 0;
    event->sync = false;

    if (orig_sync) {
      data->frame_active = false;
    }
    return ZMK_INPUT_PROC_STOP;
  }

  /* 送出インターバル到達の場合: XもYも蓄積を合算して送出 (完全2軸同期送出) */
  event->value =
      CLAMP(event->value + data->rmds[code_idx], INT16_MIN, INT16_MAX);
  event->sync |= data->syncs[code_idx];
  data->rmds[code_idx] = 0;
  data->syncs[code_idx] = false;

  /* フレーム末尾 (sync) でグリッドロック基準時刻を更新 */
  if (orig_sync || event->sync) {
    if (now_us - data->last_rpt_us > delay_us * 2 ||
        now_us < data->last_rpt_us) {
      data->last_rpt_us = now_us;
    } else {
      data->last_rpt_us += delay_us;
    }
    data->frame_active = false;
  }

  return ZMK_INPUT_PROC_CONTINUE;
}

/* ========================================================================= */
/* 【ディスパッチャ】トランスポートに応じてインターバルを選択して処理        */
/* ========================================================================= */
static int dynamic_rrl_handle_event(const struct device *dev,
                                    struct input_event *event,
                                    uint32_t usb_delay_ms,
                                    uint32_t ble_delay_ms,
                                    struct zmk_input_processor_state *state) {
  const struct dynamic_rrl_config *cfg =
      (const struct dynamic_rrl_config *)dev->config;
  struct dynamic_rrl_data *data = (struct dynamic_rrl_data *)dev->data;

  if (event->type != cfg->type) {
    return ZMK_INPUT_PROC_CONTINUE;
  }

  for (int i = 0; i < cfg->codes_len; i++) {
    if (cfg->codes[i] == event->code) {
      return process_rate_limit(data, event, i, usb_delay_ms, ble_delay_ms);
    }
  }

  return ZMK_INPUT_PROC_CONTINUE;
}

static struct zmk_input_processor_driver_api dynamic_rrl_driver_api = {
    .handle_event = dynamic_rrl_handle_event,
};

static int dynamic_rrl_init(const struct device *dev) {
  struct dynamic_rrl_data *data = (struct dynamic_rrl_data *)dev->data;
#if HAS_ENDPOINTS
  struct zmk_endpoint_instance ep = zmk_endpoint_get_selected();
  data->transport = ep.transport;
#else
  data->transport = ZMK_TRANSPORT_BLE;
#endif
  reset_pipeline_data(data);

#if HAS_ENDPOINTS && IS_ENABLED(CONFIG_ZMK_BLE) &&                             \
    IS_ENABLED(CONFIG_ZMK_POINTING)
  static bool ble_flush_init_done = false;
  if (!ble_flush_init_done) {
    k_work_init_delayable(&ble_flush_work, ble_flush_work_handler);
    ble_flush_init_done = true;
  }
  zmk_hog_set_mouse_before_send_callback(dynamic_rrl_before_send, data);
#endif

  return 0;
}

#define DYNAMIC_RRL_INST(n)                                                    \
  BUILD_ASSERT(DT_INST_PROP_LEN(n, codes) <= MAX_CODES,                        \
               "Codes length > MAX_CODES");                                    \
  static struct dynamic_rrl_data dynamic_rrl_data_##n = {};                    \
  static struct dynamic_rrl_config dynamic_rrl_config_##n = {                  \
      .type = DT_INST_PROP_OR(n, type, INPUT_EV_REL),                          \
      .codes_len = DT_INST_PROP_LEN(n, codes),                                 \
      .codes = DT_INST_PROP(n, codes),                                         \
  };                                                                           \
  DEVICE_DT_INST_DEFINE(n, &dynamic_rrl_init, NULL, &dynamic_rrl_data_##n,     \
                        &dynamic_rrl_config_##n, POST_KERNEL,                  \
                        CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                   \
                        &dynamic_rrl_driver_api);

DT_INST_FOREACH_STATUS_OKAY(DYNAMIC_RRL_INST)
