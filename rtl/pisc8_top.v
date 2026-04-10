/* * Project: CrackTheIce
 * Author: Aiden Cherniske
 * License: Apache 2.0
 * * Module: pisc8_top
 * Top-level module for PISC-8 soft core on
 * iCEbreaker FPGA board. Instantiates the core
 * and peripherals.
 *
 * See pisc8.pcf for pin assignments.
 */

`default_nettype none

module pisc8_top (
    input  wire clk_12mhz, // 12 MHz oscillator on iCEbreaker

    // UART
    output wire uart_tx_pin, // → P1 header, connect AD2 DIO0

    // Optional GPIO (LEDs on iCEbreaker PMOD 1A)
    output wire [4:0] ledn, // active-low LED bank (PMOD)

    // Reset button (BTN_N on iCEbreaker, active low)
    input  wire btn_n
);

// ---------------------------------------------------------------------------
// Reset synchronizer - debounce and synchronize the button
// ---------------------------------------------------------------------------
wire rst_async = ~btn_n; // button is active-low → invert for active-high rst
reg  rst_r0, rst_sync;

always @(posedge clk_12mhz or posedge rst_async) begin
    if (rst_async) begin
        rst_r0   <= 1'b1;
        rst_sync <= 1'b1;
    end else begin
        rst_r0   <= 1'b0;
        rst_sync <= rst_r0;
    end
end

// ---------------------------------------------------------------------------
// I/O bus
// ---------------------------------------------------------------------------
wire [7:0] io_addr; // combinational from core - valid same cycle as io_we/io_re
wire [7:0] io_wdata;
wire        io_we;
wire        io_re;
reg  [7:0] io_rdata;

// ---------------------------------------------------------------------------
// Peripheral registers
// ---------------------------------------------------------------------------

// UART TX peripheral
wire        uart_busy;
reg         uart_tx_valid;
reg  [7:0]  uart_tx_data;

uart_tx #(
    .CLK_FREQ  (12_000_000),
    .BAUD_RATE (115_200)
) u_uart_tx (
    .clk      (clk_12mhz),
    .rst      (rst_sync),
    .tx_data  (uart_tx_data),
    .tx_valid (uart_tx_valid),
    .tx_busy  (uart_busy),
    .tx       (uart_tx_pin)
);

// GPIO output register
reg [7:0] gpio_out_reg;
assign ledn = ~gpio_out_reg[4:0];  // PMOD LEDs are active-low

// ---------------------------------------------------------------------------
// I/O write decoder
// ---------------------------------------------------------------------------
always @(posedge clk_12mhz or posedge rst_sync) begin
    if (rst_sync) begin
        uart_tx_valid <= 1'b0;
        uart_tx_data  <= 8'h00;
        gpio_out_reg  <= 8'h00;
    end else begin
        // Only clear tx_valid if we're NOT writing to UART this cycle
        if (io_we && io_addr == 8'h00) begin
            // UART_DATA - latch byte and pulse tx_valid
            uart_tx_data  <= io_wdata;
            uart_tx_valid <= 1'b1;
        end else begin
            uart_tx_valid <= 1'b0;
        end
        
        // Handle other I/O writes
        if (io_we) begin
            case (io_addr)
                8'h02: begin
                    // GPIO_OUT
                    gpio_out_reg  <= io_wdata;
                end
                default: ; // ignore writes to unknown ports
            endcase
        end
    end
end

// ---------------------------------------------------------------------------
// I/O read mux (combinational - same cycle as LD execute)
// ---------------------------------------------------------------------------
always @(*) begin
    case (io_addr)
        8'h01:   io_rdata = {7'b0, uart_busy};   // UART_BUSY
        8'h03:   io_rdata = 8'h00;               // GPIO_IN (not wired here)
        default: io_rdata = 8'hFF;               // unimplemented → 0xFF
    endcase
end

// ---------------------------------------------------------------------------
// Soft-core processor
// ---------------------------------------------------------------------------
parameter MEM_FILE = "asm/hello.mem";

pisc8_core #(
    .ROM_FILE  (MEM_FILE),
    .ROM_DEPTH (256)
) u_core (
    .clk      (clk_12mhz),
    .rst      (rst_sync),
    .io_addr  (io_addr),
    .io_wdata (io_wdata),
    .io_we    (io_we),
    .io_rdata (io_rdata),
    .io_re    (io_re)
);

endmodule