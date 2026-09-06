/*
 * Copyright (c) 2026 The ZMK Contributors
 * SPDX-License-Identifier: MIT
 */

#pragma once

#include <zephyr/kernel.h>
#include <zmk/event_manager.h>

struct zmk_paw32xx_cpi_changed {
    uint16_t cpi;
};

ZMK_EVENT_DECLARE(zmk_paw32xx_cpi_changed);

uint16_t zmk_paw32xx_cpi_get_current(void);
