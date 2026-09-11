/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <stdbool.h>
#include <zephyr/kernel.h>
#include <zmk/event_manager.h>

struct zmk_scroll_inverted_changed {
    bool inverted;
};

ZMK_EVENT_DECLARE(zmk_scroll_inverted_changed);

bool zmk_scroll_inverter_is_inverted(void);
void zmk_scroll_inverter_set(bool inverted);
void zmk_scroll_inverter_toggle(void);
