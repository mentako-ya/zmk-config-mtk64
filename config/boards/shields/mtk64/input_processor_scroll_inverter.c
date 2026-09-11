/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_input_processor_scroll_inverter

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <drivers/input_processor.h>
#include <zephyr/logging/log.h>
#include <zephyr/settings/settings.h>
#include <zephyr/dt-bindings/input/input-event-codes.h>

#include "scroll_inverted_changed.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

ZMK_EVENT_IMPL(zmk_scroll_inverted_changed);

static bool g_scroll_inverted = false; // デフォルトは通常スクロール (反転なし)

struct scroll_inverter_data {
    const struct device *dev;
};

static int scroll_inverter_handle_event(const struct device *dev, struct input_event *event,
                                       uint32_t param1, uint32_t param2,
                                       struct zmk_input_processor_state *state) {
    ARG_UNUSED(dev);
    ARG_UNUSED(param1);
    ARG_UNUSED(param2);
    ARG_UNUSED(state);

    if (event->type == INPUT_EV_REL && event->code == INPUT_REL_WHEEL) {
        if (g_scroll_inverted) {
            event->value = -event->value;
        }
    }

    return ZMK_INPUT_PROC_CONTINUE;
}

static int scroll_inverter_init(const struct device *dev) {
    ARG_UNUSED(dev);
    return 0;
}

static const struct zmk_input_processor_driver_api scroll_inverter_driver_api = {
    .handle_event = scroll_inverter_handle_event,
};

#define SCROLL_INVERTER_INST(n)                                                                    \
    static struct scroll_inverter_data processor_scroll_inverter_data_##n = {};                    \
    DEVICE_DT_INST_DEFINE(n, scroll_inverter_init, NULL,                                           \
                          &processor_scroll_inverter_data_##n, NULL, POST_KERNEL,                  \
                          CONFIG_KERNEL_INIT_PRIORITY_DEFAULT, &scroll_inverter_driver_api);

DT_INST_FOREACH_STATUS_OKAY(SCROLL_INVERTER_INST)

/* Public Scroll Inverter APIs */
bool zmk_scroll_inverter_is_inverted(void) {
    return g_scroll_inverted;
}

void zmk_scroll_inverter_set(bool inverted) {
    if (g_scroll_inverted == inverted) {
        return;
    }
    g_scroll_inverted = inverted;
    LOG_INF("Scroll inverted state changed to %s", g_scroll_inverted ? "INVERTED" : "NORMAL");

#if IS_ENABLED(CONFIG_SETTINGS)
    uint8_t val = g_scroll_inverted ? 1 : 0;
    settings_save_one("scroll/inverted", &val, sizeof(val));
#endif

    raise_zmk_scroll_inverted_changed((struct zmk_scroll_inverted_changed){.inverted = g_scroll_inverted});
}

void zmk_scroll_inverter_toggle(void) {
    zmk_scroll_inverter_set(!g_scroll_inverted);
}

#if IS_ENABLED(CONFIG_SETTINGS)
static int scroll_inverter_settings_set(const char *name, size_t len,
                                        settings_read_cb read_cb, void *cb_arg) {
    const char *next;
    if (settings_name_steq(name, "inverted", &next) && !next) {
        if (len == sizeof(uint8_t)) {
            uint8_t val;
            int ret = read_cb(cb_arg, &val, sizeof(val));
            if (ret >= 0) {
                g_scroll_inverted = (val != 0);
                LOG_INF("Loaded saved scroll inverted state: %s",
                        g_scroll_inverted ? "INVERTED" : "NORMAL");
                raise_zmk_scroll_inverted_changed(
                    (struct zmk_scroll_inverted_changed){.inverted = g_scroll_inverted});
            }
        }
        return 0;
    }
    return -ENOENT;
}

SETTINGS_STATIC_HANDLER_DEFINE(scroll_inverter, "scroll", NULL,
                               scroll_inverter_settings_set, NULL, NULL);
#endif
