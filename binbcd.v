module binbcd(input [3:0] bin, output tens, output[3:0] ones);
  assign tens= bin/10;
  assign ones=bin%10;
endmodule