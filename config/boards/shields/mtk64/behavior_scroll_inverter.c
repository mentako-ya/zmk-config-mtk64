/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_behavior_scroll_inverter

#include <zephyr/device.h>
#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <drivers/behavior.h>
#include <zmk/behavior.h>

#include "scroll_inverted_changed.h"

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

enum scroll_inverter_cmd {
    SCROLL_INVERTER_CMD_TOG = 0,
    SCROLL_INVERTER_CMD_NOR = 1,
    SCROLL_INVERTER_CMD_INV = 2,
};

struct behavior_scroll_inverter_config {
    enum scroll_inverter_cmd cmd;
};

static int on_keymap_binding_pressed(struct zmk_behavior_binding *binding,
                                     struct zmk_behavior_binding_event event) {
    const struct device *dev = zmk_behavior_get_binding(binding->behavior_dev);
    if (!dev) {
        return ZMK_BEHAVIOR_OPAQUE;
    }
    const struct behavior_scroll_inverter_config *cfg = dev->config;

    switch (cfg->cmd) {
    case SCROLL_INVERTER_CMD_TOG:
        zmk_scroll_inverter_toggle();
        break;
    case SCROLL_INVERTER_CMD_NOR:
        zmk_scroll_inverter_set(false);
        break;
    case SCROLL_INVERTER_CMD_INV:
        zmk_scroll_inverter_set(true);
        break;
    }

    return ZMK_BEHAVIOR_OPAQUE;
}

static int on_keymap_binding_released(struct zmk_behavior_binding *binding,
                                      struct zmk_behavior_binding_event event) {
    return ZMK_BEHAVIOR_OPAQUE;
}

static const struct behavior_driver_api behavior_scroll_inverter_driver_api = {
    .binding_pressed = on_keymap_binding_pressed,
    .binding_released = on_keymap_binding_released,
    .locality = BEHAVIOR_LOCALITY_CENTRAL,
#if IS_ENABLED(CONFIG_ZMK_BEHAVIOR_METADATA)
    .get_parameter_metadata = zmk_behavior_get_empty_param_metadata,
#endif
};

#define SCROLL_INVERTER_BEHAVIOR_INIT(n)                                                           \
    static const struct behavior_scroll_inverter_config                                            \
        behavior_scroll_inverter_config_##n = {                                                    \
            .cmd = DT_INST_PROP(n, cmd),                                                           \
    };                                                                                             \
    BEHAVIOR_DT_INST_DEFINE(n, NULL, NULL, NULL, &behavior_scroll_inverter_config_##n,              \
                            POST_KERNEL, CONFIG_KERNEL_INIT_PRIORITY_DEFAULT,                      \
                            &behavior_scroll_inverter_driver_api);

DT_INST_FOREACH_STATUS_OKAY(SCROLL_INVERTER_BEHAVIOR_INIT)
