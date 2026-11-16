module controller (
    input logic clk,
    input logic arstn,

    // External control
    input logic start,

    // Datapath control
    output logic load,
    output logic round_en,
    output logic finalize,
    output logic [3:0] round_index,

    // External status
    output logic busy,
    output logic done
);

    typedef enum logic [2:0] {
        IDLE,
        LOAD,
        ROUND,
        FINAL,
        DONE
    } state_t;

    state_t current_state, next_state;
    
    //current state logic
    always @(posedge clk or negedge arstn) begin
        if (!arstn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end


    //next state logic
    always_comb begin
        next_state = current_state; // Default assignment to prevent latch
        case(current_state)
            
            IDLE: 
                begin
                   if(start)
                        next_state = LOAD;
                end
            LOAD: 
                begin
                    next_state = ROUND;
                end
            ROUND:
                begin
                    if(round_index == 4'd15)
                        next_state = FINAL;
                end
            FINAL:
                begin
                    next_state = DONE;
                end
            DONE:
                begin
                    next_state = IDLE;
                end
            default: begin
                next_state = IDLE;
            end

        endcase
    end


    // Round counter
    always_ff @(posedge clk or negedge arstn) begin

        if (!arstn)
            round_index <= 4'd0;

        else begin

            case (current_state)

                IDLE: begin
                    round_index <= 4'd0;
                end

                ROUND: begin
                    if (round_index < 4'd15)
                        round_index <= round_index + 1'b1;
                    else 
                        round_index <= 4'd0;
                end

                default: begin
                    round_index <= 4'd0; //hold current value is not correct
                end

            endcase

        end
    end

    // Output logic
    always_comb begin

        // Default outputs
        load     = 1'b0;
        round_en = 1'b0;
        finalize = 1'b0;
        busy     = 1'b0;
        done     = 1'b0;

        case (current_state)

            IDLE: begin
                busy = 1'b0;
            end

            LOAD: begin
                load = 1'b1;
                busy = 1'b1;
            end

            ROUND: begin
                round_en = 1'b1;
                busy     = 1'b1;
            end

            FINAL: begin
                finalize = 1'b1;
                busy     = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: begin
                //deault values already assigned
            end

        endcase

    end

endmodule