/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_input_processor_aml

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <drivers/input_processor.h>
#include <zephyr/logging/log.h>
#include <zephyr/settings/settings.h>

#include "aml_state_changed.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

ZMK_EVENT_IMPL(zmk_aml_state_changed);

static bool g_aml_enabled = true; // デフォルトは有効

struct aml_config {
    int16_t require_prior_idle_ms;
    const uint16_t *excluded_positions;
    size_t num_positions;
};

#if !IS_ENABLED(CONFIG_ZMK_SPLIT) || IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)

#include <zmk/keymap.h>
#include <zmk/behavior.h>
#include <zmk/events/position_state_changed.h>
#include <zmk/events/keycode_state_changed.h>
#include <zmk/events/layer_state_changed.h>

#define MAX_LAYERS ZMK_KEYMAP_LAYERS_LEN

#ifndef CONFIG_ZMK_INPUT_PROCESSOR_AML_MAX_ACTION_EVENTS
#define CONFIG_ZMK_INPUT_PROCESSOR_AML_MAX_ACTION_EVENTS 4
#endif

struct aml_state {
    uint8_t toggle_layer;
    bool is_active;
    int64_t last_tapped_timestamp;
};

struct aml_data {
    const struct device *dev;
    struct k_mutex lock;
    struct aml_state state;
};

/* Static Work Queue Items */
static struct k_work_delayable layer_disable_works[MAX_LAYERS];

/* Position Search */
static bool position_is_excluded(const struct aml_config *config, uint32_t position) {
    if (!config->excluded_positions || !config->num_positions) {
        return false;
    }

    const uint16_t *end = config->excluded_positions + config->num_positions;
    for (const uint16_t *pos = config->excluded_positions; pos < end; pos++) {
        if (*pos == position) {
            return true;
        }
    }

    return false;
}

/* Timing Check */
static bool should_quick_tap(const struct aml_config *config, int64_t last_tapped,
                             int64_t current_time) {
    return (last_tapped + config->require_prior_idle_ms) > current_time;
}

/* Layer State Management */
static void update_layer_state(struct aml_state *state, bool activate) {
    if (state->is_active == activate) {
        return;
    }

    state->is_active = activate;
    if (activate) {
        zmk_keymap_layer_activate(state->toggle_layer, false);
        LOG_DBG("AML Layer %d activated", state->toggle_layer);
    } else {
        zmk_keymap_layer_deactivate(state->toggle_layer, false);
        LOG_DBG("AML Layer %d deactivated", state->toggle_layer);
    }
}

struct layer_state_action {
    uint8_t layer;
    bool activate;
};

K_MSGQ_DEFINE(aml_action_msgq, sizeof(struct layer_state_action),
              CONFIG_ZMK_INPUT_PROCESSOR_AML_MAX_ACTION_EVENTS, 4);

static void layer_action_work_cb(struct k_work *work) {
    const struct device *dev = DEVICE_DT_INST_GET(0);
    if (!dev) {
        return;
    }
    struct aml_data *data = (struct aml_data *)dev->data;

    int ret = k_mutex_lock(&data->lock, K_FOREVER);
    if (ret < 0) {
        LOG_ERR("Error locking for updating AML layer: %d", ret);
        return;
    }

    struct layer_state_action action;

    while (k_msgq_get(&aml_action_msgq, &action, K_MSEC(10)) >= 0) {
        if (!action.activate) {
            if (zmk_keymap_layer_active(action.layer)) {
                update_layer_state(&data->state, false);
            }
        } else {
            if (g_aml_enabled) {
                update_layer_state(&data->state, true);
            }
        }
    }

    k_mutex_unlock(&data->lock);
}

static K_WORK_DEFINE(layer_action_work, layer_action_work_cb);

/* Work Queue Callback */
static void layer_disable_callback(struct k_work *work) {
    struct k_work_delayable *d_work = k_work_delayable_from_work(work);
    int layer_index = ARRAY_INDEX(layer_disable_works, d_work);

    struct layer_state_action action = {.layer = layer_index, .activate = false};

    int ret = k_msgq_put(&aml_action_msgq, &action, K_MSEC(10));
    if (ret == 0) {
        k_work_submit(&layer_action_work);
    }
}

/* Event Handlers */
static int handle_layer_state_changed(const struct device *dev, const zmk_event_t *eh) {
    struct aml_data *data = (struct aml_data *)dev->data;
    int ret = k_mutex_lock(&data->lock, K_FOREVER);
    if (ret < 0) {
        return ret;
    }
    if (!zmk_keymap_layer_active(zmk_keymap_layer_index_to_id(data->state.toggle_layer))) {
        LOG_DBG("Deactivating layer that was activated by AML processor");
        data->state.is_active = false;
        k_work_cancel_delayable(&layer_disable_works[data->state.toggle_layer]);
    }
    ret = k_mutex_unlock(&data->lock);
    if (ret < 0) {
        return ret;
    }

    return ZMK_EV_EVENT_BUBBLE;
}

static int handle_position_state_changed(const struct device *dev, const zmk_event_t *eh) {
    const struct zmk_position_state_changed *ev = as_zmk_position_state_changed(eh);
    if (!ev->state) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    struct aml_data *data = (struct aml_data *)dev->data;
    int ret = k_mutex_lock(&data->lock, K_FOREVER);
    if (ret < 0) {
        return ret;
    }

    const struct aml_config *cfg = dev->config;

    if (data->state.is_active && cfg->excluded_positions && cfg->num_positions > 0) {
        if (!position_is_excluded(cfg, ev->position)) {
            LOG_DBG("Position not excluded, deactivating AML layer");
            update_layer_state(&data->state, false);
        }
    }

    k_mutex_unlock(&data->lock);

    return ZMK_EV_EVENT_BUBBLE;
}

static int handle_keycode_state_changed(const struct device *dev, const zmk_event_t *eh) {
    const struct zmk_keycode_state_changed *ev = as_zmk_keycode_state_changed(eh);
    if (!ev->state) {
        return ZMK_EV_EVENT_BUBBLE;
    }

    struct aml_data *data = (struct aml_data *)dev->data;

    int ret = k_mutex_lock(&data->lock, K_FOREVER);
    if (ret < 0) {
        return ret;
    }

    data->state.last_tapped_timestamp = ev->timestamp;

    ret = k_mutex_unlock(&data->lock);
    if (ret < 0) {
        return ret;
    }

    return ZMK_EV_EVENT_BUBBLE;
}

static int handle_state_changed_dispatcher(const struct device *dev, const zmk_event_t *eh) {
    if (as_zmk_layer_state_changed(eh) != NULL) {
        return handle_layer_state_changed(dev, eh);
    } else if (as_zmk_position_state_changed(eh) != NULL) {
        return handle_position_state_changed(dev, eh);
    } else if (as_zmk_keycode_state_changed(eh) != NULL) {
        return handle_keycode_state_changed(dev, eh);
    }

    return ZMK_EV_EVENT_BUBBLE;
}

#define DISPATCH_EVENT(inst)                                                                       \
    {                                                                                              \
        int err = handle_state_changed_dispatcher(DEVICE_DT_INST_GET(inst), eh);                   \
        if (err < 0) {                                                                             \
            return err;                                                                            \
        }                                                                                          \
    }

static int handle_event_dispatcher(const zmk_event_t *eh) {
    DT_INST_FOREACH_STATUS_OKAY(DISPATCH_EVENT)
    return 0;
}

/* Driver Implementation */
static int aml_handle_event(const struct device *dev, struct input_event *event,
                            uint32_t param1, uint32_t param2,
                            struct zmk_input_processor_state *state) {
    if (param1 >= MAX_LAYERS) {
        LOG_ERR("Invalid layer index: %d", param1);
        return -EINVAL;
    }

    // AML が無効の場合は一時レイヤーを起動せず、入力イベントを素通しする
    if (!g_aml_enabled) {
        return ZMK_INPUT_PROC_CONTINUE;
    }

    struct aml_data *data = (struct aml_data *)dev->data;

    int ret = k_mutex_lock(&data->lock, K_FOREVER);
    if (ret < 0) {
        return ret;
    }

    const struct aml_config *cfg = dev->config;

    data->state.toggle_layer = param1;

    if (!data->state.is_active &&
        !should_quick_tap(cfg, data->state.last_tapped_timestamp, k_uptime_get())) {
        struct layer_state_action action = {.layer = param1, .activate = true};

        int ret = k_msgq_put(&aml_action_msgq, &action, K_MSEC(10));
        if (ret < 0) {
            LOG_ERR("Failed to enqueue action to enable AML layer %d (%d)", param1, ret);
        } else {
            k_work_submit(&layer_action_work);
        }
    }

    if (param2 > 0) {
        k_work_reschedule(&layer_disable_works[param1], K_MSEC(param2));
    }

    k_mutex_unlock(&data->lock);

    return ZMK_INPUT_PROC_CONTINUE;
}

static int aml_init(const struct device *dev) {
    struct aml_data *data = (struct aml_data *)dev->data;
    data->dev = dev;
    k_mutex_init(&data->lock);

    for (int i = 0; i < MAX_LAYERS; i++) {
        k_work_init_delayable(&layer_disable_works[i], layer_disable_callback);
    }

    return 0;
}

/* Driver API */
static const struct zmk_input_processor_driver_api aml_driver_api = {
    .handle_event = aml_handle_event,
};

/* Event Listeners Conditions */
#define NEEDS_POSITION_HANDLERS(n, ...) DT_INST_PROP_HAS_IDX(n, excluded_positions, 0)
#define NEEDS_KEYCODE_HANDLERS(n, ...) (DT_INST_PROP_OR(n, require_prior_idle_ms, 0) > 0)

/* Event Handlers Registration */
ZMK_LISTENER(processor_aml, handle_event_dispatcher);
ZMK_SUBSCRIPTION(processor_aml, zmk_layer_state_changed);

#if DT_INST_FOREACH_STATUS_OKAY_VARGS(NEEDS_POSITION_HANDLERS, ||)
ZMK_SUBSCRIPTION(processor_aml, zmk_position_state_changed);
#endif

#if DT_INST_FOREACH_STATUS_OKAY_VARGS(NEEDS_KEYCODE_HANDLERS, ||)
ZMK_SUBSCRIPTION(processor_aml, zmk_keycode_state_changed);
#endif

#else /* Peripheral side without Central role */

struct aml_data {
    const struct device *dev;
};

static int aml_handle_event(const struct device *dev, struct input_event *event,
                            uint32_t param1, uint32_t param2,
                            struct zmk_input_processor_state *state) {
    ARG_UNUSED(dev);
    ARG_UNUSED(event);
    ARG_UNUSED(param1);
    ARG_UNUSED(param2);
    ARG_UNUSED(state);
    return ZMK_INPUT_PROC_CONTINUE;
}

static int aml_init(const struct device *dev) {
    ARG_UNUSED(dev);
    return 0;
}

static const struct zmk_input_processor_driver_api aml_driver_api = {
    .handle_event = aml_handle_event,
};

#endif /* !IS_ENABLED(CONFIG_ZMK_SPLIT) || IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL) */

/* Device Instantiation (Central / Peripheral 共通) */
#define AML_INST(n)                                                                                \
    static struct aml_data processor_aml_data_##n = {};                                            \
    static const uint16_t excluded_positions_##n[] = DT_INST_PROP(n, excluded_positions);         \
    static const struct aml_config processor_aml_config_##n = {                                    \
        .require_prior_idle_ms = DT_INST_PROP_OR(n, require_prior_idle_ms, 0),                    \
        .excluded_positions = excluded_positions_##n,                                             \
        .num_positions = DT_INST_PROP_LEN(n, excluded_positions),                                 \
    };                                                                                             \
    DEVICE_DT_INST_DEFINE(n, aml_init, NULL, &processor_aml_data_##n,                             \
                          &processor_aml_config_##n, POST_KERNEL,                                  \
                          CONFIG_KERNEL_INIT_PRIORITY_DEFAULT, &aml_driver_api);

DT_INST_FOREACH_STATUS_OKAY(AML_INST)

/* Public AML Control APIs */
bool zmk_aml_is_enabled(void) {
    return g_aml_enabled;
}

void zmk_aml_set_enabled(bool enabled) {
    if (g_aml_enabled == enabled) {
        return;
    }
    g_aml_enabled = enabled;
    LOG_INF("AML state changed to %s", g_aml_enabled ? "ENABLED" : "DISABLED");

#if !IS_ENABLED(CONFIG_ZMK_SPLIT) || IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    if (!g_aml_enabled) {
        const struct device *dev = DEVICE_DT_INST_GET(0);
        if (dev) {
            struct aml_data *data = (struct aml_data *)dev->data;
            k_mutex_lock(&data->lock, K_FOREVER);
            if (data->state.is_active) {
                update_layer_state(&data->state, false);
                k_work_cancel_delayable(&layer_disable_works[data->state.toggle_layer]);
            }
            k_mutex_unlock(&data->lock);
        }
    }

#if IS_ENABLED(CONFIG_SETTINGS)
    uint8_t val = g_aml_enabled ? 1 : 0;
    settings_save_one("aml/enabled", &val, sizeof(val));
#endif
#endif

    raise_zmk_aml_state_changed((struct zmk_aml_state_changed){.enabled = g_aml_enabled});
}

void zmk_aml_toggle(void) {
    zmk_aml_set_enabled(!g_aml_enabled);
}

#if (!IS_ENABLED(CONFIG_ZMK_SPLIT) || IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)) && IS_ENABLED(CONFIG_SETTINGS)
static int aml_settings_set(const char *name, size_t len,
                            settings_read_cb read_cb, void *cb_arg) {
    const char *next;
    if (settings_name_steq(name, "enabled", &next) && !next) {
        if (len == sizeof(uint8_t)) {
            uint8_t val;
            int ret = read_cb(cb_arg, &val, sizeof(val));
            if (ret >= 0) {
                g_aml_enabled = (val != 0);
                LOG_INF("Loaded saved AML state: %s", g_aml_enabled ? "ENABLED" : "DISABLED");
                raise_zmk_aml_state_changed((struct zmk_aml_state_changed){.enabled = g_aml_enabled});
            }
        }
        return 0;
    }
    return -ENOENT;
}

SETTINGS_STATIC_HANDLER_DEFINE(aml, "aml", NULL, aml_settings_set, NULL, NULL);
#endif
