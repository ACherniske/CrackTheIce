/* * Project: CrackTheIce
 * Author: Aiden Cherniske
 * License: Apache 2.0
 * * Module: uart_tx
 * UART transmitter module - 
 * 8N1, parameterized baud rate
 */

`default_nettype none
 
module uart_tx #(
    parameter CLK_FREQ  = 12_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  wire       clk,
    input  wire       rst,
 
    // Software interface (connects to I/O bus in pisc8_top)
    input  wire [7:0] tx_data,      // byte to send
    input  wire       tx_valid,     // pulse high for 1 cycle to load & start
    output wire       tx_busy,      // high while frame is in progress
 
    // Physical pin
    output reg        tx            // UART TX line (idle = 1)
);
 
// ---------------------------------------------------------------------------
// Baud rate generator
// ---------------------------------------------------------------------------
localparam integer BIT_PERIOD = CLK_FREQ / BAUD_RATE;  // cycles per bit
 
reg [$clog2(BIT_PERIOD)-1:0] baud_cnt;
wire baud_tick = (baud_cnt == BIT_PERIOD - 1);
 
always @(posedge clk or posedge rst) begin
    if (rst)
        baud_cnt <= 0;
    else if (baud_tick || !tx_busy)
        baud_cnt <= 0;
    else
        baud_cnt <= baud_cnt + 1;
end
 
// ---------------------------------------------------------------------------
// Shift register and bit counter
// ---------------------------------------------------------------------------
// Frame: [STOP][D7][D6][D5][D4][D3][D2][D1][D0][START]
// We load this LSB-first and shift right, so START goes out first.
// 10 bits total → need a 10-bit shift register.
 
reg [9:0]  shift;       // shift register holding the full frame
reg [3:0]  bit_cnt;     // counts bits remaining (0 = idle)
 
assign tx_busy = (bit_cnt != 0);
 
always @(posedge clk or posedge rst) begin
    if (rst) begin
        shift   <= 10'h3FF;  // all-ones (idle)
        bit_cnt <= 4'd0;
        tx      <= 1'b1;     // idle mark
    end else begin
        if (!tx_busy && tx_valid) begin
            // Load the frame: stop(1) | data[7:0] | start(0)
            shift   <= {1'b1, tx_data, 1'b0};
            bit_cnt <= 4'd10;
        end else if (tx_busy && baud_tick) begin
            tx      <= shift[0];        // output LSB
            shift   <= {1'b1, shift[9:1]};  // shift right, fill MSB with 1
            bit_cnt <= bit_cnt - 4'd1;
        end else if (!tx_busy) begin
            tx <= 1'b1;  // ensure idle mark when not transmitting
        end
    end
end
 
endmodule
