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
localparam WAIT_SECRET        = 3'd1;
localparam VERIFY_FINGERPRINT = 3'd2;
localparam OPEN_VOTE          = 3'd3;
localparam VOTING             = 3'd4;
localparam CLOSE_VOTE         = 3'd5;
localparam DISPLAY_RESULTS    = 3'd6;

reg [2:0] next_state;
reg       fp_sent_cmd;
reg       fp_verified;
reg [3:0] cmd_index;

// Predefined 12-byte "Search" command packet to R305 (example values)
reg [7:0] search_cmd [0:11];
initial begin
    // Fill search_cmd[0..11] with the correct packet bytes as per R305 datasheet
    search_cmd[0]  = 8'hEF;
    search_cmd[1]  = 8'h01;
    search_cmd[2]  = 8'hFF;
    search_cmd[3]  = 8'hFF;
    search_cmd[4]  = 8'hFF;
    search_cmd[5]  = 8'hFF;
    search_cmd[6]  = 8'h01;
    search_cmd[7]  = 8'h00;
    search_cmd[8]  = 8'h03; // "Search" instruction code high byte
    search_cmd[9]  = 8'h00; // "Search" low byte
    search_cmd[10] = 8'h00; // Start page
    search_cmd[11] = 8'h00; // Page count (adjust per library size)
    // Modify bytes[10] and [11] to match your template index and page count
end

wire secret_match;
// Secret code comparison: 16-bit code equals a predefined 16'h1234, for example
assign secret_match = (code == 16'h1234);

// Latch fingerprint RX byte and set fp_verified when match OK (0x00) appears
always @(posedge fp_clk or posedge reset) begin
    if (reset) begin
        fp_verified <= 1'b0;
    end else if (fp_rx_ready) begin
        if (fp_rx_byte == 8'h00)
            fp_verified <= 1'b1;
        else
            fp_verified <= 1'b0;
    end
end

// Main FSM sequential logic
always @(posedge clk1 or posedge reset) begin
    if (reset) begin
        state        <= IDLE_RANDOM;
        fp_sent_cmd  <= 1'b0;
        cmd_index    <= 4'd0;
        vote_count   <= 4'd0;
        winner       <= 2'd0;
        enable_led   <= 1'b0;
        fp_tx_start  <= 1'b0;
        fp_tx_data   <= 8'd0;
    end else begin
        state <= next_state;
        // Default FPGA TX signals
        fp_tx_start <= 1'b0;
        fp_tx_data  <= 8'd0;
        case (state)
            IDLE_RANDOM: begin
                vote_count <= 4'd0;
                winner     <= 2'd0;
                enable_led <= 1'b0;
            end

            WAIT_SECRET: begin
                fp_sent_cmd <= 1'b0;
                if (secret_match) begin
                    // Move to fingerprint verification
                end
            end

            VERIFY_FINGERPRINT: begin
                if (!fp_sent_cmd) begin
                    // Send Search packet, one byte per clk1
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

            OPEN_VOTE: begin
                enable_led <= 1'b1;
            end

            VOTING: begin
                // Count votes on btn1/btn2/btn3 edges
                if (btn1) vote_count <= vote_count + 1;
                if (btn2) vote_count <= vote_count + 1;
                if (btn3) vote_count <= vote_count + 1;
            end

            CLOSE_VOTE: begin
                enable_led <= 1'b0;
            end

            DISPLAY_RESULTS: begin
                // Determine winner based on vote_count
                // For simplicity, winner = (vote_count[1:0])
                winner <= vote_count[1:0];
            end

            default: ;
        endcase
    end
end

// Combinational next‐state logic
always @(*) begin
    next_state      = state;
    case (state)
        IDLE_RANDOM: begin
            next_state = WAIT_SECRET;
        end

        WAIT_SECRET: begin
            if (secret_match)
                next_state = VERIFY_FINGERPRINT;
        end

        VERIFY_FINGERPRINT: begin
            if (fp_verified)
                next_state = OPEN_VOTE;
        end

        OPEN_VOTE: begin
            if (btn_oc)
                next_state = VOTING;
        end

        VOTING: begin
            if (btn_oc)
                next_state = CLOSE_VOTE;
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
