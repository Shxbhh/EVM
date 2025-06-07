//UART Receiver: 8N1 at 115200 baud, 50 MHz system clock
`timescale 1ns / 1ps
module uart_rx(
input  wire       clk,
input  wire       rst_n,
input  wire       rx,
output reg [7:0]  data_out,
output reg        data_ready
);
parameter CLK_FREQ = 100000000;
parameter BAUD     = 115200;
localparam CLKS_PER_BIT = CLK_FREQ/BAUD

reg [12:0] clk_cnt;
reg [3:0]  bit_index;
reg [7:0]  rx_shift_reg;
reg        rx_busy;
reg        rx_d;
reg        rx_sync;

// Synchronize and detect start bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_sync <= 1'b1;
        rx_d    <= 1'b1;
    end else begin
        rx_sync <= rx;
        rx_d    <= rx_sync;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_busy     <= 1'b0;
        clk_cnt     <= 13'd0;
        bit_index   <= 4'd0;
        rx_shift_reg<= 8'd0;
        data_ready  <= 1'b0;
        data_out    <= 8'd0;
    end else begin
        data_ready <= 1'b0;
        if (!rx_busy) begin
            if (rx_d == 1'b0) begin // start bit detected
                rx_busy <= 1'b1;
                clk_cnt <= CLKS_PER_BIT/2;
                bit_index <= 4'd0;
            end
        end else begin
            if (clk_cnt == 0) begin
                if (bit_index < 8) begin
                    bit_index <= bit_index + 1;
                    rx_shift_reg[bit_index] <= rx_d;
                    clk_cnt <= CLKS_PER_BIT-1;
                end else begin
                    data_out   <= rx_shift_reg;
                    data_ready <= 1'b1;
                    rx_busy    <= 1'b0;
                end
            end else begin
                clk_cnt <= clk_cnt - 1;
            end
        end
    end
end
endmodule
