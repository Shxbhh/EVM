module clk1Hz(
    input clk_100MHz,       // from Basys 3
    output clk1
    );
    
    reg [25:0] counter_reg = 0;
    reg clk_reg = 0;
    
    always @(posedge clk_100MHz) begin
        if(counter_reg == 49_999_999) begin
            counter_reg <= 0;
            clk_reg <= ~clk_reg;
        end
        else
            counter_reg <= counter_reg + 1;
    end
    
    assign clk1 = clk_reg; //Clock of f=1Hz generated
    
endmodule