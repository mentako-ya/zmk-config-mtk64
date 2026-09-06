/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_behavior_paw32xx_cpi

#include <zephyr/device.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/input/input_paw32xx.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/settings/settings.h>
#include <zephyr/sys/util.h>

#include <drivers/behavior.h>
#include <zmk/behavior.h>
#if IS_ENABLED(CONFIG_ZMK_SPLIT) && IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
#include <zmk/split/central.h>
#include <zmk/events/position_state_changed.h>
#endif
#include <zmk/split/transport/central.h>
#include <zmk/split/transport/types.h>

#include "paw32xx_cpi_changed.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

ZMK_EVENT_IMPL(zmk_paw32xx_cpi_changed);

#define CPI_LEVEL_COUNT 16
static const uint16_t cpi_levels[CPI_LEVEL_COUNT] = {
    608,  800,  1000, 1200, 1400, 1600, 1800, 2000,
    2300, 2600, 3000, 3400, 3800, 4200, 4500, 4826};
static uint8_t current_cpi_idx = 5; // Default: 1600 CPI

uint16_t zmk_paw32xx_cpi_get_current(void) {
    return cpi_levels[current_cpi_idx];
}

enum cpi_cmd {
  CPI_CMD_INC = 0,
  CPI_CMD_DEC = 1,
  CPI_CMD_SET = 2,
};

struct behavior_cpi_config {
  enum cpi_cmd cmd;
  uint16_t val;
};

static void apply_and_save_cpi(void) {
  uint16_t cpi = cpi_levels[current_cpi_idx];
  LOG_INF("PAW32xx CPI target updated to %u (idx: %d)", cpi, current_cpi_idx);

  // 1. Local trackball device check (if running directly on right half)
  const struct device *dev = DEVICE_DT_GET_OR_NULL(DT_NODELABEL(trackball));
  if (dev && device_is_ready(dev)) {
    int ret = paw32xx_set_resolution(dev, cpi);
    if (ret == 0) {
      LOG_INF("Local PAW32xx CPI set to %u", cpi);
    } else {
      LOG_ERR("Failed to set local PAW32xx CPI: %d", ret);
    }
  }

  // 2. Save to NVS
#if IS_ENABLED(CONFIG_SETTINGS)
  settings_save_one("paw32xx/cpi", &current_cpi_idx, sizeof(current_cpi_idx));
#endif

  // 4. Notify OLED display widget
  raise_zmk_paw32xx_cpi_changed((struct zmk_paw32xx_cpi_changed){.cpi = cpi});
}

static int on_keymap_binding_pressed(struct zmk_behavior_binding *binding,
                                     struct zmk_behavior_binding_event event) {
  const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
  if (!dev) {
    return ZMK_BEHAVIOR_OPAQUE;
  }
  const struct behavior_cpi_config *cfg = dev->config;

  switch (cfg->cmd) {
  case CPI_CMD_INC:
    if (current_cpi_idx < CPI_LEVEL_COUNT - 1) {
      current_cpi_idx++;
    }
    break;
  case CPI_CMD_DEC:
    if (current_cpi_idx > 0) {
      current_cpi_idx--;
    }
    break;
  case CPI_CMD_SET:
    for (int i = 0; i < CPI_LEVEL_COUNT; i++) {
      if (cpi_levels[i] == cfg->val) {
        current_cpi_idx = i;
        break;
      }
    }
    break;
  }

  // 1. 自分自身の処理（親機ならOLED表示更新＋フラッシュ保存、子機なら実機感度変更＋フラッシュ保存）
  apply_and_save_cpi();

  // 2. 親機側で実行された場合、キーを押した子機（右手 ID: 2）にだけピンポイントで転送
#if IS_ENABLED(CONFIG_ZMK_SPLIT) && IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
  if (event.source != ZMK_POSITION_STATE_CHANGE_SOURCE_LOCAL) {
    zmk_split_central_invoke_behavior(event.source, binding, event, true);
  }
#endif

  return ZMK_BEHAVIOR_OPAQUE;
}

static int on_keymap_binding_released(struct zmk_behavior_binding *binding,
                                      struct zmk_behavior_binding_event event) {
  return ZMK_BEHAVIOR_OPAQUE;
}

static const struct behavior_driver_api behavior_cpi_driver_api = {
    .binding_pressed = on_keymap_binding_pressed,
    .binding_released = on_keymap_binding_released,
    .locality = BEHAVIOR_LOCALITY_CENTRAL,
#if IS_ENABLED(CONFIG_ZMK_BEHAVIOR_METADATA)
    .get_parameter_metadata = zmk_behavior_get_empty_param_metadata,
#endif
};

#if IS_ENABLED(CONFIG_SETTINGS)
static int paw32xx_cpi_settings_set(const char *name, size_t len,
                                    settings_read_cb read_cb, void *cb_arg) {
  const char *next;
  if (settings_name_steq(name, "cpi", &next) && !next) {
    if (len == sizeof(current_cpi_idx)) {
      uint8_t saved_idx;
      int ret = read_cb(cb_arg, &saved_idx, sizeof(saved_idx));
      if (ret >= 0 && saved_idx < CPI_LEVEL_COUNT) {
        current_cpi_idx = saved_idx;
        uint16_t cpi = cpi_levels[current_cpi_idx];
        LOG_INF("Loaded saved CPI index %u (%u CPI)", current_cpi_idx, cpi);
        apply_and_save_cpi();
      }
    }
    return 0;
  }
  return -ENOENT;
}

SETTINGS_STATIC_HANDLER_DEFINE(paw32xx, "paw32xx", NULL,
                               paw32xx_cpi_settings_set, NULL, NULL);
#endif

#define CPI_BEHAVIOR_INIT(n)                                                   \
  static const struct behavior_cpi_config behavior_cpi_config_##n = {          \
      .cmd = DT_INST_PROP(n, cmd),                                             \
      .val = DT_INST_PROP_OR(n, val, 0),                                       \
  };                                                                           \
  BEHAVIOR_DT_INST_DEFINE(n, NULL, NULL, NULL, &behavior_cpi_config_##n,       \
                          POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,    \
                          &behavior_cpi_driver_api);

DT_INST_FOREACH_STATUS_OKAY(CPI_BEHAVIOR_INIT)
