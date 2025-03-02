module votingmachine(input btn1, input btn2, input btn3, input btn_oc, input clk1, input reset, input [15:0] code, output reg[1:0]winner, output enable_led, output reg[3:0] vote_count, output [1:0] state);
  
  reg[1:0] closevote_reg; //voting closed count register
  reg[3:0] candidate1_votes, candidate2_votes,candidate3_votes;
  reg[15:0] password=16'b1000011001110000;
  reg[1:0] state_reg;      //characterising states
  
  parameter IDLE= 2'b00;
  parameter VOTING_OPEN=2'b01;
  parameter VOTING_CLOSED=2'b10;
  parameter WINNER_DISPLAY=2'b11;
  
  always @(posedge clk1 or posedge reset) begin
    if (reset)
      state_reg<=IDLE;
    else
      case(state_reg)
        IDLE: if(btn_oc)
          		if(code==password)
                  state_reg<=VOTING_OPEN;
        VOTING_OPEN: if(btn_oc)
          				if(code==password)
                          state_reg<=VOTING_CLOSED;
        VOTING_CLOSED: if(closevote_reg)
          					state_reg<=WINNER_DISPLAY;
        WINNER_DISPLAY: if(btn_oc)
          					state_reg<=IDLE;
      endcase
  end
  
  // Total Votes Register Logic
    always @(posedge clk1 or posedge reset) begin
        if(reset)
            total_votes <= 0;
        else
            if(btn1 | btn2 | btn3)
                if(state_reg == VOTING_OPEN)
                    total_votes <= total_votes + 1;
    end
    
    // Candidate1 Votes Register Logic
    always @(posedge clk1 or posedge reset) begin
        if(reset)
            candidate1_votes <= 0;
        else
            if(btn1)
                if(state_reg == VOTING_OPEN)
                    candidate1_votes <= candidate1_votes + 1;
    end
    
    // Candidate2 Votes Register Logic
    always @(posedge clk1 or posedge reset) begin
        if(reset)
            candidate2_votes <= 0;
        else
            if(btn2)
                if(state_reg == VOTING_OPEN)
                    candidate2_votes <= candidate2_votes + 1;
    end
    
    // Candidate3 Votes Register Logic
    always @(posedge clk1 or posedge reset) begin
        if(reset)
            candidate3_votes <= 0;
        else
            if(btn3)
                if(state_reg == VOTING_OPEN)
                    candidate3_votes <= candidate3_votes + 1;
    end
    
  // Voting Closed Counter Register Logic
    always @(posedge clk1 or posedge reset) begin
      if(reset)
            closevote_reg <= 0;
        else
            if(state_reg == VOTING_CLOSED)
                closevote_reg <= closevote_reg + 1;
    end
 // Winner Register Control Logic
    always @(posedge clk1 or posedge reset) begin
        if(reset)
            winner <= 0;
        else
            if(candidate1_votes > candidate2_votes && candidate1_votes > candidate3_votes)
                winner<= 2'b01;
            else if(candidate2_votes > candidate1_votes && candidate2_votes > candidate3_votes)
                winner<= 2'b10;
            else if(candidate3_votes > candidate1_votes && candidate3_votes > candidate2_votes)
                winner <= 2'b11;
            else
                winner <= 2'b00;    // no winner, a tie, need a revote
    
    end
    
    // Assigning outputs
    assign vote_count = total_votes;
    assign enable_led = (state_reg == VOTING_OPEN) ? 1 : 0;
    assign state = state_reg;
    
endmodule   