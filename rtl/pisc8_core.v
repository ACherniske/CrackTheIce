/* * Project: CrackTheIce
 * Author: Aiden Cherniske
 * License: Apache 2.0
 * * Module: pisc8_core
 * Pedagogical Instruction Set Computer — 
 * 8-bit data / 16-bit instruction word
 */

`default_nettype none

module pisc8_core #(
    parameter ROM_FILE = "hello.mem",
    parameter ROM_DEPTH = 256
) (
    input wire clk,
    input wire rst,

    // I/O bus
    output wire [7:0] io_addr,
    output reg [7:0] io_wdata,
    output reg io_we,
    output wire [7:0] io_rdata,
    output reg io_re
);
 
// ---------------------------------------------------------------------------
// Opcode encodings
// ---------------------------------------------------------------------------
localparam OP_LDI  = 4'h0;
localparam OP_MOV  = 4'h1;
localparam OP_ADD  = 4'h2;
localparam OP_SUB  = 4'h3;
localparam OP_AND  = 4'h4;
localparam OP_OR   = 4'h5;
localparam OP_XOR  = 4'h6;
localparam OP_SHL  = 4'h7;
localparam OP_SHR  = 4'h8;
localparam OP_ST   = 4'h9;
localparam OP_LD   = 4'hA;
localparam OP_JMP  = 4'hB;
localparam OP_BZ   = 4'hC;
localparam OP_BNZ  = 4'hD;
localparam OP_NOP  = 4'hE;
localparam OP_HALT = 4'hF;

// ---------------------------------------------------------------------------
// Program ROM
// ---------------------------------------------------------------------------
reg [15:0] rom [0:ROM_DEPTH-1];
initial $readmemh(ROM_FILE, rom, 0, ROM_DEPTH-1);

// ---------------------------------------------------------------------------
// Processor state
// ---------------------------------------------------------------------------
reg [7:0] pc;
reg [15:0] ir;
reg [7:0] regfile [0:7];
reg flag_z;
reg flag_c;
reg phase; // 0 = fetch, 1 = execute

// ---------------------------------------------------------------------------
// Instruction field decode (combinational from IR)
// ---------------------------------------------------------------------------
wire [3:0] opcode = ir[15:12];  // Opcode field
wire [2:0] rd_idx = ir[11:9];   // Destination register index for MOV, ALU ops
wire [2:0] rs_idx = ir[8:6];    // Source register index for MOV, ALU ops
wire [7:0] imm8 = ir[7:0];      // Immediate value for LDI, JMP, BZ, BNZ

wire [7:0] rd_val = (rd_idx == 0) ? 8'h00 : regfile[rd_idx];
wire [7:0] rs_val = (rs_idx == 0) ? 8'h00 : regfile[rs_idx];

// ---------------------------------------------------------------------------
// IO address - combinational logic to determine I/O address based on instruction and phase
// ---------------------------------------------------------------------------
assign io_addr = (phase == 1'b1 && opcode == OP_ST) ? rd_val :
                 (phase == 1'b1 && opcode == OP_LD) ? rs_val :
                 8'h00;

// ---------------------------------------------------------------------------
// ALU result (9-bit to capture carry)
// ---------------------------------------------------------------------------
reg [8:0] alu_result;

// ---------------------------------------------------------------------------
// Register write helper (keeps r0 hardwired to zero)
// ---------------------------------------------------------------------------
task write_reg;
    input [2:0] idx;
    input [7:0] value;
    begin
        if (idx != 3'b000) begin
            regfile[idx] <= value;
        end
    end
endtask

// ---------------------------------------------------------------------------
// Main sequential logic
// ---------------------------------------------------------------------------
integer i;
 
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pc       <= 8'h00;
        ir       <= 16'h0000;
        phase    <= 1'b0;
        flag_z   <= 1'b0;
        flag_c   <= 1'b0;
        io_we    <= 1'b0;
        io_re    <= 1'b0;
        io_wdata <= 8'h00;
        for (i = 0; i < 8; i = i + 1)
            regfile[i] <= 8'h00;
    end else begin
        io_we <= 1'b0;
        io_re <= 1'b0;
 
        if (phase == 1'b0) begin
            // ------------------------------------------------------------------
            // FETCH: load instruction, advance PC
            // ------------------------------------------------------------------
            ir    <= rom[pc];
            pc    <= pc + 8'h01;
            phase <= 1'b1;
 
        end else begin
            // ------------------------------------------------------------------
            // EXECUTE: act on IR
            // ------------------------------------------------------------------
            phase <= 1'b0;
 
            case (opcode)
 
                OP_LDI: begin
                    write_reg(rd_idx, imm8);
                    flag_z <= (imm8 == 8'h00);
                end
 
                OP_MOV: begin
                    write_reg(rd_idx, rs_val);
                    flag_z <= (rs_val == 8'h00);
                end
 
                OP_ADD: begin
                    alu_result = {1'b0, rd_val} + {1'b0, rs_val};
                    write_reg(rd_idx, alu_result[7:0]);
                    flag_z <= (alu_result[7:0] == 8'h00);
                    flag_c <= alu_result[8];
                end
 
                OP_SUB: begin
                    alu_result = {1'b0, rd_val} - {1'b0, rs_val};
                    write_reg(rd_idx, alu_result[7:0]);
                    flag_z <= (alu_result[7:0] == 8'h00);
                    flag_c <= alu_result[8];
                end
 
                OP_AND: begin
                    alu_result = {1'b0, rd_val & rs_val};
                    write_reg(rd_idx, alu_result[7:0]);
                    flag_z <= (alu_result[7:0] == 8'h00);
                    flag_c <= 1'b0;
                end
 
                OP_OR: begin
                    alu_result = {1'b0, rd_val | rs_val};
                    write_reg(rd_idx, alu_result[7:0]);
                    flag_z <= (alu_result[7:0] == 8'h00);
                    flag_c <= 1'b0;
                end
 
                OP_XOR: begin
                    alu_result = {1'b0, rd_val ^ rs_val};
                    write_reg(rd_idx, alu_result[7:0]);
                    flag_z <= (alu_result[7:0] == 8'h00);
                    flag_c <= 1'b0;
                end
 
                OP_SHL: begin
                    write_reg(rd_idx, {rd_val[6:0], 1'b0});
                    flag_c <= rd_val[7];
                    flag_z <= (rd_val[6:0] == 7'h00);
                end
 
                OP_SHR: begin
                    write_reg(rd_idx, {1'b0, rd_val[7:1]});
                    flag_c <= rd_val[0];
                    flag_z <= (rd_val[7:1] == 7'h00);
                end
 
                OP_ST: begin
                    // io_addr = rd_val (set combinationally above)
                    io_wdata <= rs_val;
                    io_we    <= 1'b1;
                end
 
                OP_LD: begin
                    // io_addr = rs_val (set combinationally above)
                    // io_rdata is driven by the mux in pisc8_top the same cycle
                    io_re <= 1'b1;
                    write_reg(rd_idx, io_rdata);
                    flag_z <= (io_rdata == 8'h00);
                end
 
                OP_JMP: begin
                    pc    <= imm8;
                    phase <= 1'b0;
                end
 
                OP_BZ: begin
                    if (flag_z) pc <= imm8;
                    phase <= 1'b0;
                end
 
                OP_BNZ: begin
                    if (!flag_z) pc <= imm8;
                    phase <= 1'b0;
                end
 
                OP_NOP: begin
                    // one execute bubble
                end
 
                OP_HALT: begin
                    pc    <= pc - 8'h01;  // re-fetch the HALT forever
                    phase <= 1'b0;
                end
 
                default: ; // treat unknown as NOP
 
            endcase
        end
    end
end
 
endmodule