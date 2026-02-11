`timescale 1ns / 1ps

module scrambler_byte (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    input  wire        is_control,
    input  wire        com,
    output reg  [7:0]  data_out
);

    reg [15:0] lfsr;
    reg [15:0] next_lfsr;
    reg [7:0]  scrambled;
    integer i;

    always @(*) begin
        next_lfsr = lfsr;
        scrambled = data_in;

        if (data_valid && com && !is_control) begin
            for (i = 0; i < 8; i = i + 1) begin
                scrambled[i] = data_in[i] ^ next_lfsr[15];
                next_lfsr = {
                    next_lfsr[14:0],
                    next_lfsr[15] ^ next_lfsr[4] ^ next_lfsr[3] ^ next_lfsr[2]
                };
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr     <= 16'hFFFF;
            data_out <= 8'h00;
        end else if (data_valid) begin
            data_out <= scrambled;
            if (com && !is_control)
                lfsr <= next_lfsr;
        end
    end

endmodule
