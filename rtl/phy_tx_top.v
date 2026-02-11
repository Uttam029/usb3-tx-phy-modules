`timescale 1ns / 1ps

module phy_tx_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    input  wire        is_control,
    input  wire        com,

    output wire [7:0]  scrambled_byte,
    output wire        scrambled_valid,
    output wire [9:0]  encoded_symbol,
    output wire        encoded_valid,
    output wire        rd_out
);

    wire [7:0] scr_out;

    scrambler_byte u_scrambler (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .data_valid(data_valid),
        .is_control(is_control),
        .com(com),
        .data_out(scr_out)
    );

    assign scrambled_byte  = scr_out;
    assign scrambled_valid = data_valid;

    encoder_8b10b u_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(scrambled_valid),
        .din(scrambled_byte),
        .in_k(is_control),
        .dout(encoded_symbol),
        .dout_valid(encoded_valid),
        .rd_out(rd_out)
    );

endmodule
