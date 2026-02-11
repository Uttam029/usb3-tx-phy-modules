`timescale 1ns / 1ps

module encoder_8b10b (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,
    input  wire [7:0]  din,
    input  wire        in_k,
    output reg  [9:0]  dout,
    output reg         dout_valid,
    output reg         rd_out
);

    wire [4:0] five  = din[7:3];
    wire [2:0] three = din[2:0];

    reg [5:0] code6_pos, code6_neg;
    reg [3:0] code4_pos, code4_neg;
    reg       disp6_pos, disp6_neg;
    reg       disp4_pos, disp4_neg;

    reg current_rd;
    reg [9:0] chosen_code;
    integer net_disp;

    // ---------- 5b/6b TABLE ----------
    task table_5b6b(
        input  [4:0] d5,
        output [5:0] cpos, output [5:0] cneg,
        output       dpos, output       dneg
    );
        begin
            cpos = 6'b000000; cneg = 6'b000000; dpos = 0; dneg = 0;
            case (d5)
                5'b00000: begin cpos=6'b100111; cneg=6'b011000; dpos=1; dneg=0; end
                5'b00001: begin cpos=6'b011101; cneg=6'b100010; dpos=1; dneg=0; end
                5'b00010: begin cpos=6'b101101; cneg=6'b010010; dpos=1; dneg=0; end
                5'b00011: begin cpos=6'b011001; cneg=6'b100110; dpos=0; dneg=1; end
                5'b00100: begin cpos=6'b110101; cneg=6'b001010; dpos=1; dneg=0; end
                5'b00101: begin cpos=6'b101001; cneg=6'b010110; dpos=0; dneg=1; end
                5'b00110: begin cpos=6'b011101; cneg=6'b100010; dpos=1; dneg=0; end
                5'b00111: begin cpos=6'b010011; cneg=6'b101100; dpos=0; dneg=1; end
                5'b01000: begin cpos=6'b110011; cneg=6'b001100; dpos=0; dneg=1; end
                5'b01001: begin cpos=6'b100101; cneg=6'b011010; dpos=1; dneg=0; end
                5'b01010: begin cpos=6'b010101; cneg=6'b101010; dpos=0; dneg=1; end
                5'b01011: begin cpos=6'b110001; cneg=6'b001110; dpos=0; dneg=1; end
                5'b01100: begin cpos=6'b101011; cneg=6'b010100; dpos=1; dneg=0; end
                5'b01101: begin cpos=6'b011011; cneg=6'b100100; dpos=0; dneg=1; end
                5'b01110: begin cpos=6'b111001; cneg=6'b000110; dpos=0; dneg=1; end
                5'b01111: begin cpos=6'b110100; cneg=6'b001011; dpos=0; dneg=1; end
                5'b10000: begin cpos=6'b101111; cneg=6'b010000; dpos=1; dneg=0; end
                5'b10001: begin cpos=6'b100011; cneg=6'b011100; dpos=0; dneg=1; end
                5'b10010: begin cpos=6'b010011; cneg=6'b101100; dpos=0; dneg=1; end
                5'b10011: begin cpos=6'b110111; cneg=6'b001000; dpos=1; dneg=0; end
                5'b10100: begin cpos=6'b110101; cneg=6'b001010; dpos=1; dneg=0; end
                5'b10101: begin cpos=6'b101001; cneg=6'b010110; dpos=0; dneg=1; end
                5'b10110: begin cpos=6'b011101; cneg=6'b100010; dpos=1; dneg=0; end
                5'b10111: begin cpos=6'b010111; cneg=6'b101000; dpos=0; dneg=1; end
                5'b11000: begin cpos=6'b111011; cneg=6'b000100; dpos=1; dneg=0; end
                5'b11001: begin cpos=6'b100111; cneg=6'b011000; dpos=1; dneg=0; end
                5'b11010: begin cpos=6'b010111; cneg=6'b101000; dpos=0; dneg=1; end
                5'b11011: begin cpos=6'b110011; cneg=6'b001100; dpos=0; dneg=1; end
                5'b11100: begin cpos=6'b101011; cneg=6'b010100; dpos=1; dneg=0; end
                5'b11101: begin cpos=6'b011011; cneg=6'b100100; dpos=0; dneg=1; end
                5'b11110: begin cpos=6'b111001; cneg=6'b000110; dpos=0; dneg=1; end
                5'b11111: begin cpos=6'b011111; cneg=6'b100000; dpos=0; dneg=1; end
            endcase
        end
    endtask

    // ---------- 3b/4b TABLE ----------
    task table_3b4b(
        input  [2:0] d3,
        output [3:0] cpos, output [3:0] cneg,
        output       dpos, output       dneg
    );
        begin
            cpos = 4'b0000; cneg = 4'b0000; dpos = 0; dneg = 0;
            case (d3)
                3'b000: begin cpos=4'b1011; cneg=4'b0100; dpos=1; dneg=0; end
                3'b001: begin cpos=4'b1001; cneg=4'b0110; dpos=1; dneg=0; end
                3'b010: begin cpos=4'b0101; cneg=4'b1010; dpos=0; dneg=1; end
                3'b011: begin cpos=4'b1100; cneg=4'b0011; dpos=0; dneg=1; end
                3'b100: begin cpos=4'b1101; cneg=4'b0010; dpos=1; dneg=0; end
                3'b101: begin cpos=4'b1010; cneg=4'b0101; dpos=0; dneg=1; end
                3'b110: begin cpos=4'b0110; cneg=4'b1001; dpos=0; dneg=1; end
                3'b111: begin cpos=4'b1110; cneg=4'b0001; dpos=1; dneg=0; end
            endcase
        end
    endtask

    // ---------- Disparity Calculation ----------
    function integer disp10_val;
        input [9:0] c10;
        integer ones, i;
        begin
            ones = 0;
            for (i = 0; i < 10; i = i + 1)
                ones = ones + c10[i];
            disp10_val = ones - (10 - ones);
        end
    endfunction

    // ---------- K28.5 ----------
    localparam [9:0] K28_5_RD_NEG = 10'b0011111010;
    localparam [9:0] K28_5_RD_POS = 10'b1100000101;

    always @(*) begin
        table_5b6b(five, code6_pos, code6_neg, disp6_pos, disp6_neg);
        table_3b4b(three, code4_pos, code4_neg, disp4_pos, disp4_neg);

        if (!in_k) begin
            if (current_rd == 1'b0)
                chosen_code = {code6_pos, code4_pos};
            else
                chosen_code = {code6_neg, code4_neg};
        end else begin
            if (din == 8'hBC)
                chosen_code = (current_rd == 1'b0) ? K28_5_RD_POS : K28_5_RD_NEG;
            else
                chosen_code = {code6_pos, code4_pos};
        end
    end

    // ---------- Sequential ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= 0;
            dout_valid <= 0;
            current_rd <= 0;
            rd_out     <= 0;
        end else begin
            if (in_valid) begin
                dout       <= chosen_code;
                dout_valid <= 1;

                net_disp = disp10_val(chosen_code);
                if (net_disp > 0)      current_rd <= 1'b1;
                else if (net_disp < 0) current_rd <= 1'b0;

                rd_out <= current_rd;
            end else begin
                dout_valid <= 0;
            end
        end
    end

endmodule
