module clk2Hz(input clk_100MHz, output clk2);
  reg [24:0] clkcounter=0;
  reg clk_reg=0;
  
  always @(posedge clk_100MHz) begin
    if (clkcounter==24999999) begin
      clkcounter <=0;
      clk_reg=~clk_reg;
    end
    else
      clkcounter <= clkcounter+1;
  end
  
  assign clk2=clk_reg;   //Clock of f=2Hz generated
  
endmodule