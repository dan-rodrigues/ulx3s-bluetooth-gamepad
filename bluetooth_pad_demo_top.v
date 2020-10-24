// bluetooth_pad_demo_top.v
//
// Copyright (C) 2020 Dan Rodrigues <danrr.gh.oss@gmail.com>
//
// SPDX-License-Identifier: MIT

`default_nettype none

module bluetooth_pad_demo_top (
    input clk_25mhz,

    input ftdi_txd,
    output ftdi_rxd,

    // ESP32 ("sd_d" pins in .lpf were renamed to their "wifi_gpio" equivalent)

    output wifi_en,

    input wifi_gpio16,
    input wifi_gpio2,
    input wifi_gpio4,

    output wifi_gpio0,
    output wifi_gpio12,

    input wifi_txd,
    output wifi_rxd,

    // User interaction

    output [7:0] led,
    input [6:0] btn
);
    // --- PLL (50MHz output) ---

    wire pll_locked;
    wire clk;

    pll pll(
        .clkin(clk_25mhz),
        .clkout0(clk),
        .locked(pll_locked)
    );

    // --- Reset generator ---

    wire user_reset = btn_trigger[3];

    reg [23:0] reset_counter = 0;
    wire reset = !reset_counter[23];

    always @(posedge clk) begin
        if (!pll_locked || user_reset) begin
            reset_counter <= 0;
        end else if (reset) begin
            reset_counter <= reset_counter + 1;
        end
    end

    // --- ESP32 ---

    // UART for console:

    assign wifi_rxd = ftdi_txd;
    assign ftdi_rxd = wifi_txd;

    reg [2:0] esp_sync_ff [0:1];

    // ESP32 inputs:

    wire esp_spi_mosi = esp_sync_ff[1][2];
    wire esp_spi_clk = esp_sync_ff[1][1];
    wire esp_spi_csn = esp_sync_ff[1][0];

    always @(posedge clk) begin
        esp_sync_ff[1] <= esp_sync_ff[0];
        esp_sync_ff[0] <= {wifi_gpio4, wifi_gpio16, wifi_gpio2};
    end

    // ESP32 outputs:

    wire [11:0] pad_btn;

    esp32_spi_gamepad esp32_spi_gamepad(
        .clk(clk),
        .reset(reset),

        .user_reset(!btn_level[0]),
        .esp32_en(wifi_en),
        .esp32_gpio0(wifi_gpio0),
        .esp32_gpio12(wifi_gpio12),

        .spi_csn(esp_spi_csn),
        .spi_clk(esp_spi_clk),
        .spi_mosi(esp_spi_mosi),

        .pad_btn(pad_btn)
    );

    // LED paging:

    reg page;

    assign led = page ? pad_btn[11:8] : pad_btn[7:0];

    always @(posedge clk) begin
        if (reset) begin
            page <= 0;
        end else if (btn_trigger[1]) begin
            page <= !page;
        end
    end

    // Button debouncer:

    wire [6:0] btn_level, btn_trigger, btn_released;

    debouncer #(
        .BTN_COUNT(7)
    ) debouncer (
        .clk(clk),
        .reset(reset),

        .btn(btn),

        .level(btn_level),
        .trigger(btn_trigger),
        .released(btn_released)
    );

endmodule
