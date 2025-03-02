`timescale 1ns / 1ps
module leds(input clk2, input enable_led, output reg [15:0] led_op);
  parameter S0 = 16'b0101010101010101;
  parameter S1 = 16'b1010101010101010;
    
    reg x= 0;
    
  always @(posedge clk2) begin
        x <= ~x;
      if(enable_led)
          if(x == 0)
                led_op = S0;
            else
                led_op = S1;
        else
            led_op = 16'b1000000000000001;
    
  end
  
endmodule