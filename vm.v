`timescale 1ns / 1ps
`timescale 1ns / 1ps

module top_voting_machine(
    input clk_100MHz,           // from Basys 3
    input [15:0] code,            // 16 switches to input code to open/close voting
    input btn1,                // button for candidate 1
    input btn2,                // button for candidate 2
    input btn3,                // button for candidate 3
    input btn_oc,            // button for opening/closing voting
    input reset,                // button for system reset
    output [0:6] seg,           // 7 segment cathodes
    output [3:0] an,            // 7 segment anodes
    output [15:0] led_op         // 16 LEDs show when voting is open
    );
    wire w_1Hz, w_2Hz;                                      // output from freq generators
    wire wbtn1, wbtn2, wbtn3, wbtn_oc, w_reset;      // output from debouncers to machine
    wire w_en_leds;                                         // output from machine to led driver
    wire [3:0] wvote_count;                                // output from machine to 7 seg control
    wire [1:0] wstate;                                 // output from machine to 7 seg control
    wire [1:0] wwinner;
    wire wtens;
    wire [3:0] wones;
    
    // Instantiate inner modules
    // Hz Generators
    clk1Hz one(.clk_100MHz(clk_100MHz), .clk1(w_1Hz));
    clk2Hz two(.clk_100MHz(clk_100MHz), .clk2(w_2Hz));
    // Button Debouncers
    debounce b1(.clk(clk_100MHz), .inbutton(btn1), .outbutton(wbtn1));
    debounce b2(.clk(clk_100MHz), .inbutton(btn2), .outbutton(wbtn2));
    debounce b3(.clk(clk_100MHz), .inbutton(btn3), .outbutton(wbtn3));
    debounce bovcv(.clk(clk_100MHz), .inbutton(btn_oc), .outbutton(wbtn_oc));
    debounce rst(.clk(clk_100MHz), .inbutton(reset), .outbutton(w_reset));
    // Binary to BCD Converter
    binbcd b2b(.bin(wvote_count), .tens(wtens), .ones(wones));
    // LED Driver
    leds led_d(.clk_2(w_2Hz), .enable_led(w_en_leds), .led_op(led_op));
    // State Machine
    votingmachine machine(.btn1(wbtn1), .btn2(wbtn2), .btn3(wbtn3), .btn_oc(wbtn_oc),.clk1(w_1Hz),  
                     .reset(w_reset), .code(code), .winner(wwinner),.enable_led(w_en_leds),
                     .vote_count(wvote_count), .state(wstate));
    // 7 Segment Display Controller
    seg_7 seg7(.clk_100MHz(clk_100MHz),.reset(w_reset), .state(wstate), .tens(wtens), .ones(wones), 
                      .winner(wwinner), .seg(seg), .an(an));
    
endmodule
