// UART Transmitter: 8N1 at 115200 baud, 100 MHz system clock
`timescale 1ns / 1ps
module uart_tx(
input  wire       clk,
input  wire       rst_n,
input  wire       tx_start,
input  wire [7:0] tx_data,
output reg        tx
);
parameter CLK_FREQ = 100000000;
parameter BAUD     = 115200;
localparam CLKS_PER_BIT = CLK_FREQ/BAUD;

reg [12:0] clk_cnt;
reg [3:0]  bit_index;
reg [7:0]  tx_shift_reg;
reg        tx_busy;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx       <= 1'b1;
        clk_cnt  <= 13'd0;
        bit_index<= 4'd0;
        tx_busy  <= 1'b0;
        tx_shift_reg <= 8'd0;
    end else begin
        if (tx_start && !tx_busy) begin
            tx_busy       <= 1'b1;
            tx_shift_reg <= tx_data;
            clk_cnt       <= CLKS_PER_BIT-1;
            bit_index     <= 4'd0;
            tx            <= 1'b0; // start bit
        end else if (tx_busy) begin
            if (clk_cnt == 0) begin
                if (bit_index < 8) begin
                    tx <= tx_shift_reg[bit_index];
                    tx_shift_reg[bit_index] <= 1'b0;
                    bit_index <= bit_index + 1;
                    clk_cnt <= CLKS_PER_BIT-1;
                end else begin
                    tx <= 1'b1; // stop bit
                    tx_busy <= 1'b0;
                end
            end else begin
                clk_cnt <= clk_cnt - 1;
            end
        end
    end
end
endmodule
