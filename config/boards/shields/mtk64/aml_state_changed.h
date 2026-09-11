/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <stdbool.h>
#include <zephyr/kernel.h>
#include <zmk/event_manager.h>

struct zmk_aml_state_changed {
    bool enabled;
};

ZMK_EVENT_DECLARE(zmk_aml_state_changed);

bool zmk_aml_is_enabled(void);
void zmk_aml_set_enabled(bool enabled);
void zmk_aml_toggle(void);
