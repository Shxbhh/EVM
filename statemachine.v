module statemachine(
input  wire        btn1,
input  wire        btn2,
input  wire        btn3,
input  wire        btn_oc,
input  wire        clk1,
input  wire        reset,
input  wire [15:0] code,
input  wire        fp_clk,
input  wire [7:0]  fp_rx_byte,
input  wire        fp_rx_ready,
output reg         fp_tx_start,
output reg  [7:0]  fp_tx_data,
output reg [1:0]   winner,
output reg         enable_led,
output reg [3:0]   vote_count,
output reg [2:0]   state
);
  
// FSM state encoding
localparam IDLE_RANDOM        = 3'd0;
localparam WAIT_FINGER       = 3'd1;
localparam VERIFY_FINGERPRINT = 3'd2;
localparam CHECK_VOTED       = 3'd3;
localparam OPEN_VOTE         = 3'd4;
localparam VOTING            = 3'd5;
localparam CLOSE_VOTE        = 3'd6;
localparam DISPLAY_RESULTS   = 3'd7;

reg [2:0] next_state;
reg [3:0] cmd_index;
reg       fp_sent_cmd;
reg       frame_parsed;
reg [3:0] rx_count;
reg [7:0] id_high;
reg [7:0] id_low;
reg [7:0] voter_id;
reg       fp_verified;

// Track which voter IDs have cast a vote
reg [255:0] voted_flags;

// Predefined 12-byte "Search" command packet to R305
reg [7:0] search_cmd [0:11];
initial begin
    // Default search packet (modify page high/low as needed)
    search_cmd[0]  = 8'hEF;
    search_cmd[1]  = 8'h01;
    search_cmd[2]  = 8'hFF;
    search_cmd[3]  = 8'hFF;
    search_cmd[4]  = 8'hFF;
    search_cmd[5]  = 8'hFF;
    search_cmd[6]  = 8'h01;
    search_cmd[7]  = 8'h00;
    search_cmd[8]  = 8'h03; // "Search" instruction high byte
    search_cmd[9]  = 8'h00; // "Search" instruction low byte
    search_cmd[10] = 8'h00; // Start page high
    search_cmd[11] = 8'h00; // Start page low (modify to reflect templates per page)
end

// Main FSM sequential logic
always @(posedge clk1 or posedge reset) begin
    if (reset) begin
        state        <= IDLE_RANDOM;
        cmd_index    <= 4'd0;
        fp_tx_start  <= 1'b0;
        fp_tx_data   <= 8'd0;
        rx_count     <= 4'd0;
        frame_parsed <= 1'b0;
        voter_id     <= 8'd0;
        fp_verified  <= 1'b0;
        vote_count   <= 4'd0;
        winner       <= 2'd0;
        enable_led   <= 1'b0;
        voted_flags  <= 256'd0;  // clear all flags
    end else begin
        state       <= next_state;
        fp_tx_start <= 1'b0;
        fp_tx_data  <= 8'd0;
        case (state)
            IDLE_RANDOM: begin
                // Idle until user places finger
            end

            WAIT_FINGER: begin
                // Do nothing until starting admin code (if needed)
            end

            VERIFY_FINGERPRINT: begin
                if (!fp_sent_cmd) begin
                    // Send one byte of the Search packet per clk1 tick
                    fp_tx_start <= 1'b1;
                    fp_tx_data  <= search_cmd[cmd_index];
                    if (cmd_index == 4'd11) begin
                        fp_sent_cmd <= 1'b1;
                        cmd_index   <= 4'd0;
                    end else begin
                        cmd_index <= cmd_index + 1'b1;
                    end
                end
            end

            CHECK_VOTED: begin
                // After parsing complete, check if this voter already voted
                if (voted_flags[voter_id] == 1'b0) begin
                    voted_flags[voter_id] <= 1'b1;
                end
            end

            OPEN_VOTE: begin
                enable_led <= 1'b1;
            end

            VOTING: begin
                if (btn1) vote_count <= vote_count + 1;
                if (btn2) vote_count <= vote_count + 1;
                if (btn3) vote_count <= vote_count + 1;
            end

            CLOSE_VOTE: begin
                enable_led <= 1'b0;
            end

            DISPLAY_RESULTS: begin
                winner <= vote_count[1:0];
            end

            default: ;
        endcase
    end
end

// UART response parsing (runs on fp_clk)
always @(posedge fp_clk or posedge reset) begin
    if (reset) begin
        rx_count     <= 4'd0;
        frame_parsed <= 1'b0;
        id_high      <= 8'd0;
        id_low       <= 8'd0;
        voter_id     <= 8'd0;
        fp_verified  <= 1'b0;
    end else if (fp_rx_ready && (state == VERIFY_FINGERPRINT)) begin
        rx_count <= rx_count + 1'b1;
        if (rx_count == 4'd8) begin
            // 9th byte: high byte of matched ID
            id_high <= fp_rx_byte;
        end else if (rx_count == 4'd9) begin
            // 10th byte: low byte of matched ID
            id_low <= fp_rx_byte;
            voter_id <= fp_rx_byte; // assuming ID fits in 8 bits; else combine with id_high
            frame_parsed <= 1'b1;
            fp_verified <= 1'b1;  // mark as verified if we got an ID
        end
    end
end

// Combinational next-state logic
always @(*) begin
    next_state = state;
    case (state)
        IDLE_RANDOM: begin
            next_state = WAIT_FINGER;
        end

        WAIT_FINGER: begin
            // Polling agent places finger on sensor to vote
            if (btn_oc) begin
                // Admin might use button to bypass (optional)
                next_state = OPEN_VOTE;
            end else if (1'b1) begin
                // Immediately try fingerprint
                next_state = VERIFY_FINGERPRINT;
            end
        end

        VERIFY_FINGERPRINT: begin
            if (fp_verified) begin
                next_state = CHECK_VOTED;
            end
        end

        CHECK_VOTED: begin
            if (voted_flags[voter_id] == 1'b0) begin
                next_state = OPEN_VOTE;
            end else begin
                next_state = IDLE_RANDOM; // Already voted; reset
            end
        end

        OPEN_VOTE: begin
            if (btn_oc) begin
                next_state = VOTING;
            end
        end

        VOTING: begin
            if (btn_oc) begin
                next_state = CLOSE_VOTE;
            end
        end

        CLOSE_VOTE: begin
            next_state = DISPLAY_RESULTS;
        end

        DISPLAY_RESULTS: begin
            next_state = IDLE_RANDOM;
        end

        default: next_state = IDLE_RANDOM;
    endcase
end
endmodule   
