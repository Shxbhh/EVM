module debounce(input clk, input inbutton, output outbutton);
  reg t0, t1, t2;
  always @(posedge clk) begin
    t0 <= inbutton;
    t1 <= t0;
    t2 <= t1;
  end
  
  assign outbutton=t2;
endmodule
