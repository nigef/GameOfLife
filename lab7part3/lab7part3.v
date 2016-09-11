/* TODO

•   “Clear board” using asynchronous reset with a KEY.

•   SETTING: Load board with live/dead cells from initial_board based on SW[ : ]

•   SETTING: Select different colors for live/dead cells on SW[ : ]

•   Show the decimal number of living cells on HEX4…HEX0 at each ‘tick’

•   SETTING: Switches choose different speeds “ticks” of game: slow, medium, fast.

•   The 4 Rules of Conway to render the cell states, with the 3 cases: 8 neighbors (middle), 3 neighbors (corner), 5 neighbors (edge).

•   320 x 240px = 160 x 120 cell game board on VGA, with 2x2 pixels blocks = 19,200 registers

•    (Optional: user-defined starting cells… determine a way to ‘pick’ live cells before start with external hardware or something on the board…)

•   (Optional: extra seeder bot that traverses the cells randomly and plants live cells around the board to keep the game going…)


*/


`timescale 1ns / 1ns

module lab7part3 (
        CLOCK_50,                       //  On Board 50 MHz
        KEY,
        SW,
        // The ports below are for the VGA output.  Do not change.
        VGA_CLK,                        //  VGA Clock
        VGA_HS,                         //  VGA H_SYNC
        VGA_VS,                         //  VGA V_SYNC
        VGA_BLANK,                      //  VGA BLANK
        VGA_SYNC,                       //  VGA SYNC
        VGA_R,                          //  VGA Red[9:0]
        VGA_G,                          //  VGA Green[9:0]
        VGA_B,                          //  VGA Blue[9:0]
        // Use the following to display:
        HEX0,
        HEX1,
        HEX2,
        HEX3,
        HEX4,
        HEX5,
        HEX6,
        HEX7,
        LEDR,
        LEDG
    );
    


    // ------------------------------------------------------------
    // Define our parameters: DE1
    // ------------------------------------------------------------
    // input        CLOCK_50;  // 50 MHz
    // input        [9:0]   SW;
    // input        [3:0]    KEY;
    // output       [9:0]   LEDR;
    // output       [7:0]    LEDG;
    // output       [6:0]    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

    // ------------------------------------------------------------
    // Define our parameters: DE2
    // ------------------------------------------------------------
    input        CLOCK_50;  // 50 MHz
    input        [17:0]   SW;
    input        [3:0]    KEY;
    output       [17:0]   LEDR;
    output       [7:0]    LEDG;
    output       [6:0]    HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output          VGA_CLK;                //  VGA Clock
    output          VGA_HS;                 //  VGA H_SYNC
    output          VGA_VS;                 //  VGA V_SYNC
    output          VGA_BLANK;              //  VGA BLANK
    output          VGA_SYNC;               //  VGA SYNC
    output  [9:0]   VGA_R;                  //  VGA Red[9:0]
    output  [9:0]   VGA_G;                  //  VGA Green[9:0]
    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]
    


    // ------------------------------------------------------------
    // Define our datapath/controlpath signals...
    // ------------------------------------------------------------
    wire resetn;
    assign resetn = KEY[0];   // active low reset
    
    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    // For X we need eight bits and for Y we need seven bits.
    wire [8:0] x;
    wire [8:0] y;
    wire writeEn;  // signal to plot on the VGA...

    wire [2:0] colour;
    wire [2:0] colourSW;
    assign colourSW = SW[2:0];
    wire resetPlotBlack;
    
    // lots of wires to connect our datapath and control with the states
    wire s_rc, s_rl, s_dc, s_cr, s_ln, s_d;
    
    // signal to indicate when looping has finished over 4x4px
    wire emit_done_board_gen, emit_display, emit_conway, emit_reset_load, emit_load;

    wire emit_tick;

    wire [1:0] tickSelectSwitch;
    assign tickSelectSwitch = SW[6:5];

    // Count the generations of the board.
    wire [10:0] genCount;  // max fits 2 HEXs is 4,095


    // ------------------------------------------------------------
    // Drawer Constants
    // ------------------------------------------------------------
    // define constants:
    // Max is 320x240 px < 2^9 x 2^x = [8:0] x [7:0]
    // = 76,800 px < 2^17 = [16:0]
    // !!!!!!!!!!!!!!!!!!!!!!!!!!! make sure you set the right height and width below.
    localparam BOARDHEIGHT = 9'd40;   // 1-indexed
    localparam BOARDWIDTH = 9'd40;
    // !!!!!!!!!!!!!!!!!!!!!!!!!!!
    localparam MAXFLATINDEX = BOARDHEIGHT*BOARDWIDTH - 1;  // 0-indexed
    wire [16:0] cellIndex;
    localparam BLACKRGB = 3'b000;  // black RGB color



    // ------------------------------------------------------------
    // Define Board, and associated values
    // ------------------------------------------------------------
    // 'n' bits requires size [n-1:0]
    wire [MAXFLATINDEX:0] current_board;
    wire [MAXFLATINDEX:0] next_board;

    // the boards that we use to reset back.
    wire [MAXFLATINDEX:0] initial_board_flat1;
    wire [MAXFLATINDEX:0] initial_board_flat2;
    wire [MAXFLATINDEX:0] initial_board_flat3;
    wire [MAXFLATINDEX:0] initial_board_flat4;

    // our special zero board
    wire [MAXFLATINDEX:0] zero_board;

    // to go through from MSB to LSB
    wire [MAXFLATINDEX:0] reverse_index;
    wire [MAXFLATINDEX:0] reverse_neighbour;



    // ------------------------------------------------------------
    // Variables for Drawing on VGA Display
    // ------------------------------------------------------------
    wire [16:0] liveCellCount;
    assign liveCellCount = 0;
    wire [16:0] cellCountOutput;
     
    wire cellState;
    assign cellState = current_board[cellIndex];

    // always black (regardless of current board) for reset State s_rc
    // only color when not in reset State && cell live at current_board[yCount][xCount] == 1
    // assign colour = (~s_rc && current_board[cellIndex] == 1) ? colourSW : BLACKRGB;

    wire [1:0] boardSelectSwitch;
    assign boardSelectSwitch = SW[4:3];


    // ------------------------------------------------------------
    // Module Instantiations
    // ------------------------------------------------------------
    // Create one instance of a VGA controller.
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(colour),
        .x(x),
        .y(y),
        .plot(writeEn),
        /* Signals for the DAC to drive the monitor. */
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK(VGA_BLANK),
        .VGA_SYNC(VGA_SYNC),
        .VGA_CLK(VGA_CLK));
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1; // Define number of colours.
    // Define initial background image file (.MIF)
    defparam VGA.BACKGROUND_IMAGE = "black.mif";

    control C0 (
        .clk50(CLOCK_50),
        .resetn(resetn),
        .writeEn(writeEn),

        .s_rc(s_rc),
        .s_rl(s_rl),
        .s_dc(s_dc),
        .s_cr(s_cr), 
        .s_ln(s_ln),
        .s_d(s_d),
          
        .emit_done_board_gen(emit_done_board_gen),
        .emit_display(emit_display),
        .emit_conway(emit_conway),
        .emit_reset_load(emit_reset_load),
        .emit_load(emit_load),
        .emit_tick(emit_tick)

    );

    datapath D0 (
        .clk50(CLOCK_50),
        .resetn(resetn),

        .s_rc(s_rc),
        .s_rl(s_rl),
        .s_dc(s_dc),
        .s_cr(s_cr), 
        .s_ln(s_ln),
        .s_d(s_d),

        .x(x[8:0]),
        .y(y[8:0]),

        .colour(colour[2:0]),
        .colourSW(colourSW),
          
        .emit_done_board_gen(emit_done_board_gen),
        .emit_display(emit_display),
        .emit_conway(emit_conway),
        .emit_reset_load(emit_reset_load),
        .emit_load(emit_load),

        .emit_tick(emit_tick),

        // our boards
        .current_board(current_board[MAXFLATINDEX:0]),
        .next_board(next_board[MAXFLATINDEX:0]),

        .initial_board_flat1(initial_board_flat1[MAXFLATINDEX:0]),
        .initial_board_flat2(initial_board_flat2[MAXFLATINDEX:0]),
        .initial_board_flat3(initial_board_flat3[MAXFLATINDEX:0]),
        .initial_board_flat4(initial_board_flat4[MAXFLATINDEX:0]),
        .zero_board(zero_board[MAXFLATINDEX:0]),

        .reverse_index(reverse_index[MAXFLATINDEX:0]),
        .reverse_neighbour(reverse_neighbour[MAXFLATINDEX:0]),

        // other stuff for drawer
        .resetPlotBlack(resetPlotBlack),
        .liveCellCount(liveCellCount[16:0]),
        .cellCountOutput(cellCountOutput[16:0]),
        .cellIndex(cellIndex[16:0]),
        .cellState(cellState),
        .boardSelectSwitch(boardSelectSwitch[1:0])

    );

    tickGenerator t0 (
        .clk50(CLOCK_50),
        .resetn(resetn),
        .tickSelectSwitch(tickSelectSwitch[1:0]),
        .emit_tick(emit_tick)
    );



    // ------------------------------------------------------------
    // LEDG
    // ------------------------------------------------------------
    // States are shown on green LEDs.
    assign LEDG[0] = s_rc; // S_RESET_CLEAR
    assign LEDG[1] = s_rl; // S_RESET_LOAD
    assign LEDG[2] = s_dc; // S_DISPLAY_AND_COUNT
    assign LEDG[3] = s_cr; // S_CONWAY_RULES
    assign LEDG[4] = s_ln; // S_LOAD_NEXT
    assign LEDG[5] = s_d;  // S_DONE



    // ------------------------------------------------------------
    // LEDR
    // ------------------------------------------------------------
    // Only light the switches that do things:
    // assign LEDR[17:0] = SW[17:0];
    // assign LEDR[9:0] = SW[9:0];
    assign LEDR[6:0] = SW[6:0];  // only light ones that do things.


    // assign LEDR[17:9] = current_board;  // see the board


    // ------------------------------------------------------------
    // Display on HEX
    // ------------------------------------------------------------
    // Turn off all other hex for ease of viewing
    assign HEX3[6:0] = 7'b111_1111;

    // Display the tick speed (concat to make size 4)
    hex_decoder h7 ( .hex_digit({2'b00, tickSelectSwitch[1:0]}), .segments(HEX7[6:0] ));

    // Display the board selected
    hex_decoder h6 ( .hex_digit({2'b00, boardSelectSwitch[1:0]}), .segments(HEX6[6:0] ));

    // Display the Generation count
    hex_decoder h5 ( .hex_digit(genCount[3:0]), .segments(HEX5[6:0] ));
    hex_decoder h4 ( .hex_digit(genCount[3:0]), .segments(HEX4[6:0] ));
    // Display the total count of live cells
    // hex_decoder h0( .hex_digit(cellCountOutput[]), .segments(HEX3[6:0] );
    hex_decoder h2 ( .hex_digit(cellCountOutput[11:8]), .segments(HEX2[6:0] ));
    hex_decoder h1 ( .hex_digit(cellCountOutput[7:4]), .segments(HEX1[6:0] ));
    hex_decoder h0 ( .hex_digit(cellCountOutput[3:0]), .segments(HEX0[6:0] ));

endmodule





////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module tickGenerator(
        input clk50,
        input resetn,
        input [1:0] tickSelectSwitch,
        output emit_tick
    );

    // count to determine the period based on CLOCK_50...
    // (set to defaults)
    reg [25:0] hertzCount = 26'd22_499_999;
    reg [25:0] selected_speed = 26'd22_499_999;

    // define speeds here.
    localparam SUPER = 26'd0_499_999;
    localparam FAST = 26'd12_499_999;
    localparam MEDIUM = 26'd49_499_999;
    localparam SLOW = 26'd199_499_999;

    // ------------------------------------------------------------
    // Counter to customize the period
    // ------------------------------------------------------------
    // ...with asynchronous reset.
    // Load the tick speed based on switches.
    always @ (posedge clk50, negedge resetn)
    begin
        // reset it
        if (resetn == 1'b0) begin
            if (tickSelectSwitch == 2'd3) begin
                hertzCount <= SUPER;
                selected_speed <= SUPER;
            end
            else if (tickSelectSwitch == 2'd2) begin
                hertzCount <= FAST;
                selected_speed <= FAST;
            end
            else if (tickSelectSwitch == 2'd1) begin
                hertzCount <= MEDIUM;
                selected_speed <= MEDIUM;
            end
            else if (tickSelectSwitch == 2'd0) begin
                hertzCount <= SLOW;
                selected_speed <= SLOW;
            end
            else begin
                hertzCount <= MEDIUM;  // default, unused.
                selected_speed <= MEDIUM;
            end
        end // end reset
        else if (hertzCount == 26'd0) begin
            hertzCount <= selected_speed;        // reset it to saved value.
        end
        else
            hertzCount <= hertzCount - 26'd1;
    end


    // ------------------------------------------------------------
    // Emit the signal.
    // ------------------------------------------------------------
    // set a flag when hertzCount periodically reaches zero.
    // note that emit_tick gets reset to zero based on the values set in the 
    // always block making this ternary zero:
    assign emit_tick = (hertzCount == 26'd0) ? 1'b1 : 1'b0;

endmodule




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module control(
    input clk50,
    input resetn,
    output writeEn,

    output reg s_rc, s_rl, s_dc, s_cr, s_ln, s_d,
     
    input emit_done_board_gen,
    input emit_display,
    input emit_conway,
    input emit_reset_load,
    input emit_load,

    input emit_tick

    );

    reg [5:0] current_state, next_state; 

    // Different states (unique identifiers) that we assign to current_state, next_state.
    // 5 bits wide to hold the different numerical values.
    localparam  S_RESET_CLEAR           = 5'd0,
                // S_RESET_CLEAR_WAIT      = 5'd1,
                S_RESET_LOAD            = 5'd2,
                // S_RESET_LOAD_WAIT       = 5'd3,
                S_DISPLAY_AND_COUNT      = 5'd4,
                // S_DISPLAY_AND_COUNT_WAIT = 5'd5,
                S_CONWAY_RULES          = 5'd6,
                // S_CONWAY_RULES_WAIT     = 5'd7,
                S_LOAD_NEXT             = 5'd8,
                // S_LOAD_NEXT_WAIT        = 5'd9;
                S_DONE                  = 5'd10;
                // S_DONE_WAIT             = 5'd11;
    


    // ------------------------------------------------------------
    // Next-state logic
    // ------------------------------------------------------------
    // State table to determine next_state based on current_state and inputs.
    // Notice the sensitivity list is start (*), so we use blocking assignments.
    always @ (*)
    begin: state_table 
        case (current_state)
            
            // S_LOAD_X: next_state = (load) ? S_LOAD_X_WAIT : S_LOAD_X;
            S_RESET_CLEAR: begin
                /* This state is responsible for doing:
                    • Set tick count back to 0.
                    • Set colour to black
                    • Set position on screen back to (0, 0).
                    • Set back emit_done_board_gen=0
                    • 
                */
                if (emit_reset_load == 1'b1) begin
                    next_state = S_RESET_LOAD;
                end
                else begin
                    next_state = S_RESET_CLEAR; //loop in next state.
                end
            end
                 
            S_RESET_LOAD: begin
                /* This state is responsible for doing:
                    • Load the initial_board from SW[ ] into current_board
                    • 
                */
                // do the display no faster than the emit_tick signal.
                if (emit_display == 1'b1 && emit_tick == 1) begin
                    next_state = S_DISPLAY_AND_COUNT;
                end
                else begin
                    next_state = S_RESET_LOAD; //loop in next state.
                end
            end

            S_DISPLAY_AND_COUNT: begin
                /* This state is responsible for doing:
                    • Set back emit_display=0
                    • Transitions to this state when (tick == 1)
                    • Then sets (tick = 0)
                    • Sets color from SW[ ] 
                    • Write the current_board to screen by looping over px locations
                    • And counts live cells while looping, and emits this value.
                    • Emit conway_done=1 signal when loop is finished
                    • 
                */
                if (emit_conway == 1'b1) begin
                    next_state = S_CONWAY_RULES;
                end
                else begin
                    next_state = S_DISPLAY_AND_COUNT; //loop in next state.
                end
            end

            S_CONWAY_RULES: begin
                /* This state is responsible for doing:
                    • Set conway_done=0
                    • Loop over board and build next_board based on neighbor amount
                    • Set emit_load=1 when finished loop
                    • 
                */
                if (emit_load == 1'b1) begin
                    next_state = S_LOAD_NEXT;
                end
                else begin
                    next_state = S_CONWAY_RULES; //loop in next state.
                end
            end

            S_LOAD_NEXT: begin
                /* This state is responsible for doing:
                    • Set back to emit_load=0
                    • First compare both boards in a loop to see if == or != and emit_done_board_gen=1 if boards are same.
                    • Load current_board <= next_board
                    • Increment generation_count +=1 if the boards are different, and emit this signal to display in the top module.
                    • If boards are not different, emit_display=1
                    • 
                */
                if (emit_done_board_gen == 1'b1) begin
                    next_state = S_DONE;
                end
                // do the display no faster than the emit_tick signal.
                else if (emit_display == 1'b1 && emit_tick == 1) begin
                    next_state = S_DISPLAY_AND_COUNT;
                end
                else begin
                    next_state = S_LOAD_NEXT; //loop in next state.
                end
            end

            // We don't need this one here because it actually gets set in
            // the "always @ (posedge clk50)" block.
            S_DONE: begin
                /* This state is responsible for doing:
                    • Wait in this state until user presses reset.
                    • 
                */
                if (!resetn) begin
                    next_state = S_RESET_CLEAR;
                end
                else begin
                    next_state = S_DONE; //loop in next state.
                end
            end

            default:
                next_state = S_RESET_CLEAR;
        endcase
    end // state_table
   


    // ------------------------------------------------------------
    // Output logic aka all of our datapath control signals.
    // ------------------------------------------------------------
    // Emit signals for current state separately from the next_state assignment
    // because the next_state can sometimes loop for a while without being
    // changed to the current state. 
    always @(*)
    begin: state_signals
        // By default make all our signals 0
        s_rc = 1'b0;
        s_rl = 1'b0;
        s_dc = 1'b0;
        s_cr = 1'b0;
        s_ln = 1'b0;
        s_d = 1'b0;

        // sets the control signals to determine which state we're in.
        case (current_state)
            S_RESET_CLEAR:
                s_rc = 1'b1;
            S_RESET_LOAD:
                s_rl = 1'b1;
            S_DISPLAY_AND_COUNT:
                s_dc = 1'b1;
            S_CONWAY_RULES:
                s_cr = 1'b1;
            S_LOAD_NEXT:
                s_ln = 1'b1;
            S_DONE:
                s_d = 1'b1;
        // default:    
        // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // state_signals



    // ------------------------------------------------------------
    // Current_state State machine registers.
    // ------------------------------------------------------------
    // The default on clock edge is to assign the next state.
    // These are the signals emitted from the datapath to communicate with the
    // control path: "emit_..."
    // [Note: otherwise, the datapath should never directly modify the control
    // path signals -- there should be this separation, and these emit signals
    // provide the communication between controlpath and datapath.]
    always @ (posedge clk50)
    begin: state_FFs
        // current state gets reset, asynchronously, from ANY current state.
        if (!resetn) begin // if KEY[0] == 0
            current_state <= S_RESET_CLEAR;
        end
        else if (emit_done_board_gen == 1'b1)
            current_state <= S_DONE;
            // note you cannot set emit_done_board_gen here because it has type "input"
            // and there is no way around this. therefore we can only set
            // emit_done_board_gen in the datapath.
            // emit_done_board_gen <= 1'b0;
        else
            // current state gets value stored in next state
            current_state <= next_state;
    end // state_FFS


    // ------------------------------------------------------------
    // WriteEnable
    // ------------------------------------------------------------
    // (VGA plots pixels) whenever we are in the following states:
    assign writeEn = (s_rc || s_dc);

endmodule




////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
module datapath (
        input clk50,
        input resetn,
        input s_rc, s_rl, s_dc, s_cr, s_ln, s_d,
        output [8:0] x,
        output [8:0] y,
        output reg [2:0] colour,
        input [2:0] colourSW,

        output reg emit_done_board_gen,
        output reg emit_display,
        output reg emit_conway,
        output reg emit_reset_load,
        output reg emit_load,
        input emit_tick,

        // Our Boards
        // remember to set the sizes in:
        // [ : ]current_board, [ : ]next_board.
        output reg [1599:0] current_board,
        output reg [1599:0] next_board,
        output reg [1599:0] initial_board_flat1,  // 399
        output reg [1599:0] initial_board_flat2,
        output reg [1599:0] initial_board_flat3,
        output reg [1599:0] initial_board_flat4,
        output reg [1599:0] zero_board,
        output [1599:0] reverse_index,
        output [1599:0] reverse_neighbour,

        output reg resetPlotBlack,
        output reg [16:0] liveCellCount,
        output reg [16:0] cellCountOutput,
        output reg [16:0] cellIndex,
        input cellState,
        input [1:0] boardSelectSwitch  // switches 10:9

    );

    // Amount to add to the (x, y) position, to build the square.
    // Registers to offset the initial values loaded onto x and y
    reg [7:0] x_offset = 8'd50;  // 8'd70
    reg [6:0] y_offset = 7'd40;  // 7'd50
    
    reg [9:0] xCount = 0;
    reg [9:0] yCount = 0;

    reg [9:0] m, n;

    // zero-index counter to get us 3 accross and 3 down for all the neighbors.
    reg [9:0] mcount = 0;
    reg [9:0] ncount = 0;

    // State of x and y.
    // Keep in mind the max x is 160, and max y is 120
    assign y = y_offset + yCount;
    assign x = x_offset + xCount;

    // Start out by checking the surrounding environment/neighbors in state for Conway's rules.
    reg checkEnvironment = 1;
    reg checkOnNextTick = 0;
    reg environmentCycle = 1;

    // maximum cells in an 'environment' is 8, which takes 4 bits.
    reg [3:0] environment;

    // Note the following are equivalent:
    // current_board[reverse_index] == current_board[yCount][xCount];
    assign reverse_index = lab7part3.MAXFLATINDEX - (yCount*lab7part3.BOARDWIDTH + xCount);

    assign reverse_neighbour = lab7part3.MAXFLATINDEX - (m*(lab7part3.BOARDWIDTH) + n);

    // fuck ^^^


    // ------------------------------------------------------------
    // Initialize the boards
    // (Tried 100 ways to have this in another module.)
    // ------------------------------------------------------------
    integer i;
    initial begin
        // Set the initial value of the index to the max because it counts down.
        cellIndex[16:0] <= lab7part3.MAXFLATINDEX;

        // Then set some live cells: current_board[y][x]
        // concatenation:  {4'b1001,4'b10x1}  = 100110x1
        // replication:     {4{4'b1001}}       = 1001100110011001
        // concatenation & replication: {4{4'b1001,1'bz}} = 1001z1001z1001z1001z

        // TODO: replace these with verilog's "Inferred RAM" instead?
        
        // Switches set to 0
        // initial_board_flat1 <= {3'b101,
        //                         3'b101,
        //                         3'b101};

        // // Switches set to 1
        // initial_board_flat2 <= {3'b111,
        //                         3'b101,
        //                         3'b111};
        
        // // Switches set to 2
        // initial_board_flat3 <= {3'b111,
        //                         3'b111,
        //                         3'b111};

        // // Switches set to 3
        // initial_board_flat4 <= {3'b101,
        //                         3'b111,
        //                         3'b101};

        // initial_board_flat1 <= {20'b11110111101011111101,
        //                         20'b11110101011011001010,
        //                         20'b01110111100101111111,
        //                         20'b11110111011000111010,
        //                         20'b11111100111111110110,
        //                         20'b00110011011010111101,
        //                         20'b11111100111001110101,
        //                         20'b11101111101011111111,
        //                         20'b11101111111011110111,
        //                         20'b11111111101110110001,
        //                         20'b01111111110111110010,
        //                         20'b11001011111111111111,
        //                         20'b01001111110001101111,
        //                         20'b10110000111111110011,
        //                         20'b10111010101110101010,
        //                         20'b11111111011100001101,
        //                         20'b11111111101101111001,
        //                         20'b11111110111011011111,
        //                         20'b10011101111111111110,
        //                         20'b11010100101101101110};


        // initial_board_flat1 <= {50'b10101110011010110001000111101000011000110110111011,
        //     50'b01010111111110101011010010000101111100100011101100,
        //     50'b00010011000011011001000010100100011110110110111011,
        //     50'b11010111000101110001101101000111001111001100111011,
        //     50'b01001100110101001000110101001010101110011110000111,
        //     50'b10111110100001011011000001100100000001001100101111,
        //     50'b10100010110000100101111101101111000000100101110111,
        //     50'b01100010111100101010010000001110101010011001001010,
        //     50'b10011011111000101011011001101011010010110010111101,
        //     50'b10000111001001010011000100011111111011001111111110,
        //     50'b10111111110010010101011001110000111110001010000111,
        //     50'b10111110111111011000110110111111010101011101001110,
        //     50'b11001101110001011011111100011111100011001111010111,
        //     50'b01101010100011000011110110101011001001011011011110,
        //     50'b01001111110110100011001111110000111001111001111010,
        //     50'b10011001110000100111001001110011111101100001101100,
        //     50'b01110101010011011011001110100101011011000000101110,
        //     50'b10011101001111101101110010100000000010010001110100,
        //     50'b10110011100000101111110011111001000111101111000000,
        //     50'b10101011010110001011010111010010101111011110010110,
        //     50'b01111110110111101101100100000110000111010010011001,
        //     50'b00100110001111100001010100100110000111010110111101,
        //     50'b01011011100000111111110110101111010011100000010110,
        //     50'b11101111000010110011110110100001110111110000100101,
        //     50'b01110100000001010111101100100100011101111101000110,
        //     50'b01011100001010111001100100101111111110010101111110,
        //     50'b01010100111010100000111011110100111110110000101011,
        //     50'b01001011011010101001010100100100110001111101100111,
        //     50'b01011011011110111001001111000011000001001101010101,
        //     50'b01011110100110111111010001101101100011011101110000,
        //     50'b11001011110010001111001000011010101000010001000110,
        //     50'b11111101111000001110000010101000111111000100010110,
        //     50'b10100000000010001100101010000111001001000111110100,
        //     50'b11001101010110110000111110110111101001110000001111,
        //     50'b11110101111110000111110110111000111111001111000101,
        //     50'b11101111101000100101010101110010010001101111110100,
        //     50'b11000111110000001011011011010111101110111101111001,
        //     50'b01111000101110101101011111100101011111001101111001,
        //     50'b01101011010000100000011111010111100010010111011010,
        //     50'b10101001001000111100110111110011100000101100000101,
        //     50'b11000010000110001101111010111101011011011111111110,
        //     50'b11101111110111111001010010011100101000001100001110,
        //     50'b11111111001010010011110011001111001000011111000100,
        //     50'b11111111110111100011011111111010000011010010100010,
        //     50'b10111110010110000110000111010011011010111101100000,
        //     50'b10110100010010011010101010111011001011110111100100,
        //     50'b00110010111000110011101011100101001100101101100101,
        //     50'b00011110101011011001001100101110001110001001010011,
        //     50'b10010111101010111001110110001101011111100111001101,
        //     50'b10011111110111001011100001011110100100110001111110};

        


        // initial_board_flat1 <= {20'b11111101111101110101,
        //                         20'b11110110011100100100,
        //                         20'b10111001110010011011,
        //                         20'b11011010110011111110,
        //                         20'b00010111001010101100,
        //                         20'b11101010011000110011,
        //                         20'b11111101010101011100,
        //                         20'b11011111001010011011,
        //                         20'b00000001100110010000,
        //                         20'b01110011101111110101,
        //                         20'b10101111111001110001,
        //                         20'b11001101101011010100,
        //                         20'b10011101001111100011,
        //                         20'b10011000111101011111,
        //                         20'b11001001000000111001,
        //                         20'b11011110101111111101,
        //                         20'b10101110111011111000,
        //                         20'b10101010000111000111,
        //                         20'b10010111110000011011,
        //                         20'b01100100011101111000};

        // // Switches set to 1
        // initial_board_flat2 <= {20'b10101110000111111110,
        //                         20'b10110111011011101011,
        //                         20'b10010011000010110111,
        //                         20'b11010011111000011100,
        //                         20'b11011001011111110101,
        //                         20'b10000001111111101110,
        //                         20'b10101000011100011101,
        //                         20'b01000110111000010000,
        //                         20'b11101111001011100101,
        //                         20'b01001100111110101000,
        //                         20'b11011000001011001111,
        //                         20'b01101110011100000111,
        //                         20'b00010111101111101111,
        //                         20'b01100010101110110110,
        //                         20'b10110100110111000001,
        //                         20'b11100010001001110010,
        //                         20'b01101100101000101100,
        //                         20'b01100001101001011010,
        //                         20'b01001110110110111011,
        //                         20'b10111111001110100110};

        
        // // Switches set to 2
        // initial_board_flat3 <= {20'b00100011101111101011,
        //                         20'b11100101000010101010,
        //                         20'b10001100111110101001,
        //                         20'b01011110010011101010,
        //                         20'b00101110011111100111,
        //                         20'b00111000110111011010,
        //                         20'b11100110111100001101,
        //                         20'b11011101000001011010,
        //                         20'b10010001110011100010,
        //                         20'b01101111110101100000,
        //                         20'b10101001011001010000,
        //                         20'b11101000010010000101,
        //                         20'b00001100000111011110,
        //                         20'b01110111101111101100,
        //                         20'b10111101100110010111,
        //                         20'b11100100110011111100,
        //                         20'b10010111101000110101,
        //                         20'b00010111011010101110,
        //                         20'b10110111010111110110,
        //                         20'b10101001100101111111};

        // // Switches set to 3
        // initial_board_flat4 <= {20'b10111110101100100011,
        //                         20'b01011010101001010110,
        //                         20'b11101011100000001010,
        //                         20'b01001011000010011110,
        //                         20'b00001011101110000011,
        //                         20'b00101100111011011010,
        //                         20'b01010101100111010110,
        //                         20'b10011001001001010110,
        //                         20'b10010111100100111111,
        //                         20'b00111011110001110111,
        //                         20'b00001110111101010010,
        //                         20'b10011111111000100000,
        //                         20'b01110101011111100111,
        //                         20'b01010111010011001100,
        //                         20'b01110111111110000011,
        //                         20'b10111000100110100010,
        //                         20'b11111111010100110010,
        //                         20'b10000110111000111001,
        //                         20'b00101011000101110001,
        //                         20'b01110010101010101000};



        // Switches set to 0
        initial_board_flat1 <= {40'b0110000001011110000000111000000000001100,
                                40'b0000000000000100010000100000000000000111,
                                40'b1000000101000001000000100000100100100000,
                                40'b0010001000000100001000100000000011010010,
                                40'b0111000000101001000000100010100000001000,
                                40'b0000001000000100000000001010000000011001,
                                40'b0000000100000001011010100001110100100000,
                                40'b0110011001000110011000000000000001100000,
                                40'b0000001001000000101000001101111001010000,
                                40'b0001000100000110000000000100010100000001,
                                40'b0000101000000101100000000000000100010110,
                                40'b0001000001000000010010001000000001000010,
                                40'b1100010000100101000001010000000000001000,
                                40'b1100010000110000010000001010001000100000,
                                40'b0010010001000011101000000000000000100001,
                                40'b0000011000000000000100000000100100110100,
                                40'b1000000100000000010010000110000100010000,
                                40'b1100000001001101000111010011001001011000,
                                40'b0001010100010000001000100000000100001110,
                                40'b0100000000100010000010000001000000110100,
                                40'b0000001000010000000110010000000000001010,
                                40'b1011000001000010010000000110000000000010,
                                40'b0000010000010001010000001001001011100001,
                                40'b0100001000000011100011100000100100001000,
                                40'b0000000010000010001100000111010000100001,
                                40'b0001011001000000001100000010000111000010,
                                40'b1000000100010000010100000001011000001100,
                                40'b0001000010000100001000010000001100101010,
                                40'b1010000000100101010000100000101000001010,
                                40'b1100010001010000010100000011010000010000,
                                40'b0101001000100000100101110000010000011001,
                                40'b0000011100001001000000000100000001000000,
                                40'b0000101011010101010000010000100010011000,
                                40'b1100001000000011100110010000000001000001,
                                40'b0000000000010010100000100000000000000111,
                                40'b0110001000011001100010101000001010100000,
                                40'b0010001110100000010010000001010101100001,
                                40'b0010000001001000000000010110100001101000,
                                40'b0101000000001101001000111000000000001001,
                                40'b1100000100100000000100110101100010000101};

        // Switches set to 1
        initial_board_flat2 <= {40'b1000100001000100101001110000000000100001,
        40'b1000000000000100001000010010000000001100,
        40'b0011100000010000010010100001000100011010,
        40'b0001100001100000000000001010001000100100,
        40'b0010000000110100000000001010110100100000,
        40'b0100100000010000010000000000000100000001,
        40'b0011000000101001000101000011000101000010,
        40'b0000101110001010000010000000000101100101,
        40'b0000000000000001000101000111000100000011,
        40'b0001000010000000101001101010101100000000,
        40'b1001001000000011100010000001000001000000,
        40'b1000000011000000101000001000101110000000,
        40'b0000000001000011010001000000000010000100,
        40'b0110101000100000100100000000001000111010,
        40'b0010000100100000001010100000000010010100,
        40'b0000010000000100010000010001000001000000,
        40'b0010110101000001000001011001000000100101,
        40'b0000000010010100000010011001100000000010,
        40'b1110000101010011101100101000100001000000,
        40'b1100000001010100000100010110100000000101,
        40'b0000100000100000000110000000001101011010,
        40'b1100000000001000111000110001000000000000,
        40'b1011100011100001000001100101000100010000,
        40'b0011010101000011011000110000110000100000,
        40'b0100000100000000001000010000000000000001,
        40'b0010000010000100000001100000000000010001,
        40'b0000000110100001010000001001010000010110,
        40'b0100101010100000000000000101110001100001,
        40'b0001000000010000100000001000100000000000,
        40'b0000010000100000000010000000000100000000,
        40'b0000011110010010001000000100000011010000,
        40'b1100000000000000000100100000000100100001,
        40'b0010111000010100000001100010100001001111,
        40'b0010100010100000000000110000000100000000,
        40'b1001111100000000100001000101100000011000,
        40'b1011100000000000000010100010010000000000,
        40'b0101000010110000000000000011010001001001,
        40'b0010000000000000010010000101000000010110,
        40'b0000010011010000011000000001011010000011,
        40'b0001000101100000001111000110010010110101};
        
        // Switches set to 2
        initial_board_flat3 <= {40'b0110100100011000000000110010100000000011,
        40'b0010000000101101000101011100000000000000,
        40'b0101110000000000000000000100010000010000,
        40'b0000000100010100001010100000011000110001,
        40'b0100100011000010010100001000010000100011,
        40'b0000000000000000000100110000101000001010,
        40'b1000001000001100010001000101000000000000,
        40'b1011000000010100100100001010010001000001,
        40'b0000101001010100001000110100010011000111,
        40'b0001000000000001000000000000000000010000,
        40'b0011000000011001011100010000101000010110,
        40'b0000100011000000100000100000010001011100,
        40'b0000000100010000000000000000110110001010,
        40'b0000110000011001101010001001000100000010,
        40'b0000000100101000100010010101001001001010,
        40'b1000000000011010100101001010010001000111,
        40'b1111110101011000111100100101100100001000,
        40'b0100001000100000000000100010000000000101,
        40'b0000000000010001010101011000011110000100,
        40'b1001001000100000000001100010000001011001,
        40'b0100010101011000000000101000000100001111,
        40'b0001101100100010000010000000001110100011,
        40'b1011010000000000100100000010000000111010,
        40'b0000000100000000101010011010000100000001,
        40'b1001100001001100011000000000101010000000,
        40'b0000000001000000000000000100000110000110,
        40'b0010101001000001000100000010000000000001,
        40'b0001010010001000101000000001010000100010,
        40'b0010001001000100101101010000000001001000,
        40'b0001000000011000000000001001100011100000,
        40'b0000001000010000011010001000000100011000,
        40'b0000000001000000001000000000001100100010,
        40'b0001110100000000100000000000001000000001,
        40'b0000100000000001001001100010000100000000,
        40'b0010001110000000100000100000110000000011,
        40'b1001000100000100000010001010000100000000,
        40'b0011001000110010001010000000110100000001,
        40'b0000010001000000011000001001100000000010,
        40'b0011000000010000010010110000000000000000,
        40'b0000000001010001100001000000100000011000};

        // Switches set to 3
        initial_board_flat4 <= {40'b1000000111000000000000000001010100000100,
        40'b1100000000000000010101001001000001000001,
        40'b0110000000000000000000010000000001000000,
        40'b0010001001000000000000000001010001010110,
        40'b0000000000000000010011000010000100100000,
        40'b0100110000100001000110011100100011010111,
        40'b0110000001000000100000000000000000100001,
        40'b0111001010010010101000000010010001100010,
        40'b1000000100110000000001000001010011000010,
        40'b0000000010000011011010001010001000000000,
        40'b0000001000000000110000000001000001010001,
        40'b0001011000000010011000100011000100000100,
        40'b1001001000101100001001001010001010100000,
        40'b0001000011000000100001000001010000000010,
        40'b0010000000000000101001001000000000001101,
        40'b1000000100000001010001000010110100100010,
        40'b1100000100011010000000100000000001000000,
        40'b0000010000010001000010000001111100010010,
        40'b0011000001000100000001110000101000000001,
        40'b0100000100100000001001000000001100000010,
        40'b0011000010000110001100001010000000000000,
        40'b1100100000000000010000000000100000001000,
        40'b0010101010100110000001000000000000010011,
        40'b1000100000010101001100100100000010000000,
        40'b0001011100010000001001010000010000001010,
        40'b1000001100001001010010000000000100000101,
        40'b1010000000110011100110110000100000010000,
        40'b1010010000110000000111010100010010010000,
        40'b1011010100010100000000000001100100110011,
        40'b0000010001100001000000100101100110000111,
        40'b0010000000100000001000000000000000101000,
        40'b1010100000011000100110000000000011010100,
        40'b1000101100000000000010000100000000000000,
        40'b1001010100001010100101000001010000101001,
        40'b0010011001000101010000000010001110001100,
        40'b1011001100000001000000000100001000010000,
        40'b1000000000010010000000100010000100001010,
        40'b0101010001001001010000000100000010011011,
        40'b1101000000000011010110000010100000010000,
        40'b0101011000000000000010000001010111001001};





        // initialize next_board to all zero.
        for (i = 0; i < lab7part3.MAXFLATINDEX+1; i = i + 1) begin
            next_board[i] <= 0;
            current_board[i] <= 0;
            zero_board[i] <= 0;
        end
    end
        

    // ------------------------------------------------------------
    // These signals represent the communication from controlpath-->datapath.
    // ------------------------------------------------------------
    // Perform all the actions for each state here.
    always @ (posedge clk50) begin
        if (!resetn) begin
            
            // Reset: plot black over our all px on our board.
            colour <= 3'b000;

            // Stuff for drawing
            // --------------------------------------
            cellIndex <= lab7part3.MAXFLATINDEX;
            liveCellCount <= 0;
            cellCountOutput <= 0;
            // reset coordinates on board location to location (0,0)
            xCount <= 0;
            yCount <= 0;

            // clear all "emit" signals, where applicable.
            // --------------------------------------
            emit_done_board_gen <= 1'b0;
            emit_display <= 1'b0;
            emit_conway <= 1'b0;
            emit_reset_load <= 1'b0;
            emit_load <= 1'b0;

            checkEnvironment <= 1'b1;

        end
        else begin

            // STATE: S_RESET_CLEAR
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (s_rc) begin

                // load all zeros into our board.
                current_board <= zero_board;

                // Set the Control Path Signal:
                // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                // go to next state
                emit_reset_load <= 1'b1;

                emit_done_board_gen <= 1'b0;
                emit_conway <= 1'b0;
                emit_load <= 1'b0;

            end



            // STATE: S_RESET_LOAD
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (s_rl) begin

                // load the board from the SW[ ]
                if (boardSelectSwitch == 0)
                    current_board <= initial_board_flat1;
                else if (boardSelectSwitch == 1)
                    current_board <= initial_board_flat2;
                else if (boardSelectSwitch == 2)
                    current_board <= initial_board_flat3;
                else if (boardSelectSwitch == 3)
                    current_board <= initial_board_flat4;

                // Set the Control Path Signal:
                // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                // once the board is fully loaded, we go to the next state (display)
                // turn off emit_display flag, if any
                emit_display <= 1'b1;

            end
            
            

            // STATE: S_DISPLAY_AND_COUNT
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (s_dc) begin

                // set it back
                emit_display <= 1'b0;

                // count backwards from MSB -> LSB
                cellIndex <= cellIndex - 1; 

                // Live Cell
                // count the live cells.
                // set plot colour
                if (cellState == 1) begin
                    // note there is a 1px delay from the clock
                    // so this is not a good place to draw.
                    liveCellCount <= liveCellCount + 1'b1;

                    // Set colour if we're not plotting the black for the reset.
                    if (~resetPlotBlack)
                        colour <= colourSW;
                end
                else
                    colour <= 3'b000;  // black for dead cells

                // At the end of a draw cycle, we have traversed the whole board.
                // turn off the reset-state if we are at the end of the board.
                if (cellIndex == 0) begin
                    
                    // After completing one full plot cycle, we don't want to plot black anymore.
                    resetPlotBlack <= 1'b0;

                    // done <= 1'b1;
                    cellIndex <= lab7part3.MAXFLATINDEX;

                    // first, display final amount (but not when were plotting black for the reset)
                    if (~resetPlotBlack)  // "resetPlotBlack == 1'b0"
                        cellCountOutput <= liveCellCount;

                    // reset liveCellCount for next cycle:
                    liveCellCount <= 0;

                    // reset to start again:
                    xCount <= 0;
                    yCount <= 0;

                    // Set the Control Path Signal:
                    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    emit_conway <= 1'b1;

                end
                // at end of the row, go to next row, and reset column values.
                // location of last cell on board, depends board size
                else if (xCount == lab7part3.BOARDWIDTH - 1) begin
                    xCount <= 0;
                    yCount <= yCount + 1;
                end
                // go to next cell in row: increment column values.
                else
                    xCount <= xCount + 1;
            
            end // end S_DISPLAY_AND_COUNT




            // Aside: signals:
            // reg [9:0] xCount = 0;
            // reg [9:0] yCount = 0;
            // reg [9:0] m, n;
            // reg [9:0] mcount = 0;
            // reg [9:0] ncount = 0;
            // reg checkEnvironment = 1;
            // reg environmentCycle = 1;
            // reg [3:0] environment;
            // assign reverse_neighbour = lab7part3.MAXFLATINDEX - (m*(lab7part3.BOARDWIDTH) + n);
            // reverse_index = lab7part3.MAXFLATINDEX - (yCount*(lab7part3.BOARDWIDTH) + xCount);
            // current_board[yCount][xCount] == current_board[reverse_index]

            // STATE: S_CONWAY_RULES
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            // # -- start:
            // # -- for all the cells on the board
            // # -- * check whole environment around one (x, y) cell
            // # -- set next_board, and go to next (x, y) cell
            // # -- repeat * until whole board is checked
            // # -- move on to next state
            // mcount, ncount is index for the row/column.
            // m, n is index for the position in each row/column.
            if (s_cr) begin

                // If just starting to check Conway's Rules
                if (emit_conway == 1'b1) begin
                    // set to start at (0, 0)
                    xCount <= 0;
                    yCount <= 0;
                    m <= yCount - 1;
                    n <= xCount - 1;
                    
                    // and turn this emit_conway signal off 
                    emit_conway <= 0;
                end

                // Check surrounding environment --> or move to next board location
                if (checkEnvironment) begin
                    // At each clock tick - check cell's environment i.e. all
                    // neighbors of (xCount, yCount).

                    // Set these values only once per environment-check cycle.
                    if (environmentCycle) begin
                        
                        environmentCycle <= 0; // remember to set back to 1 somewhere
                        
                        // # neighbor live count:
                        environment <= 0;

                        // 'm' and 'n' are coordinates of cells surrounding our cell,
                        // to check the pairs at: x-1...x+1, y-1...y+1.
                        // example: (x, y)
                        //      (n-1, m-1)   (n, m-1)  (n+1, m-1)
                        //      (n-1, m)     (n, m)    (n+1, m)
                        //      (n-1, m+1)   (n, m+1)  (n+1, m+1)
                        // 
                        // note: m or n could become out of bounds: negative, or greater than max.
                        // if the're negative then we just ignore them.
                        // start with the lowest.
                        m <= yCount - 1;
                        n <= xCount - 1;

                        // # zero-index counter to get us 3 across and 3 down for all the neighbors.
                        // # note that this includes the don't care values that are negative
                        // # or greater than max.
                        mcount <= 0;
                        ncount <= 0;
                    end

                    // At each Iteration of the environment check:
                    // *********************************************
                    // *********************************************

                    // At every tick 'iteration'...
                    // we dont count the 'self' cell at (xCount, yCount) as a neighbor.
                    if (m != yCount || n != xCount) begin

                        // If not off board: not negative and not greater than max.
                        if (n >= 0 && n < lab7part3.BOARDWIDTH && m >= 0 && m < lab7part3.BOARDHEIGHT) begin

                            // # check if live cell
                            if (current_board[reverse_neighbour] == 1) begin
                                environment <= environment + 1;

                                // If the environment value changed, wait
                                // until next clock tick to change the next_board.
                                // checkOnNextTick <= 1;

                                if (current_board[reverse_index] == 1) begin
                                    if (environment != 2 && environment != 3)
                                        next_board[reverse_index] <= 0;
                                    else
                                        next_board[reverse_index] <= 1;
                                end
                                // if dead cell:
                                else if (current_board[reverse_index] == 0) begin
                                    if (environment == 3)
                                        next_board[reverse_index] <= 1;
                                    else
                                        next_board[reverse_index] <= 0;
                                end

                            end
                            
                        end
                    end


                    // Done examining environment.
                    // we have traversed the area of 3...(3x3)-1 neighboring cells.
                    if (mcount == 2 && ncount == 2) begin

                        // Do the conway logic here, populating the cells based on rules
                        if (current_board[reverse_index] == 1) begin
                            if (environment != 2 && environment != 3)
                                next_board[reverse_index] <= 0;
                            else
                                next_board[reverse_index] <= 1;
                        end
                        // if dead cell:
                        else if (current_board[reverse_index] == 0) begin
                            if (environment == 3)
                                next_board[reverse_index] <= 1;
                            else
                                next_board[reverse_index] <= 0;
                        end

                        // dont check environment on next clock tick
                        checkEnvironment <= 0;

                        // checkOnNextTick <= 0;

                    end
                    // after the count goes three wide, we go down to the next row.
                    else if (ncount == 2) begin
                        ncount <= 0;  // reset column (n) values.
                        mcount <= mcount + 1;  // go to next row.
                        
                        // and adjust the positions.
                        n <= xCount - 1;
                        m <= m + 1;
                    end
                    // go to next cell in row: increment column values.
                    else begin
                        ncount <= ncount + 1;
                        n <= n + 1;
                    end
                    // *********************************************
                    // *********************************************
                end
                
                // We are not in the environment-examination cycle here...
                else begin

                    // Set for re-entering the environment cycle on the next clock tick.
                    environmentCycle <= 1;
                    checkEnvironment <= 1;

                    // Done traversing the whole board!
                    // If on last (x, y), emit the signal to change state.
                    if (xCount == lab7part3.BOARDWIDTH - 1 && yCount == lab7part3.BOARDHEIGHT - 1) begin

                        // reset signals/counts/etc to start again for next time:
                        xCount <= 0;
                        yCount <= 0;
                        environment <= 0;

                        // Set the Control Path Signal:
                        // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                        emit_load <= 1'b1;

                    end
                    // We are not done traversing the board
                    else begin
                        // At clock tick - increment the (x, y) to check.
                        // at end of the row, go to next row, and reset column values.
                        // location of last cell on board, depends board size
                        if (xCount == lab7part3.BOARDWIDTH - 1) begin
                            xCount <= 0;
                            yCount <= yCount + 1;
                        end
                        // go to next cell in row: increment column values.
                        else
                            xCount <= xCount + 1;
                    end

                end

            end // end conway state



            // STATE: S_LOAD_NEXT
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (s_ln) begin
                
                // reset back to 0 for next round
                emit_load <= 1'b0;
                emit_done_board_gen <= 1'b0;

                // First, while we have different next_board and current_board,
                // we check to see if they are equal, and if they are the same,
                // then we have a board that does not change.
                if (next_board == current_board)
                    // Set the Control Path Signal:
                    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    // This is asynchronous in the control module.
                    emit_done_board_gen <= 1'b1;
                else begin
                    // If boards are different,
                    // load next_board into current_board
                    current_board <= next_board;

                    // Set the Control Path Signal:
                    // >>>>>>>>>>>>>>>>>>>>>>>>>>>>
                    // If boards are different, we go back to display the next generation board.
                    emit_display <= 1'b1;
                end
            end

            // STATE: S_DONE
            // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            if (s_d) begin
                emit_done_board_gen <= 1'b0;   // reset back to 0 for next round
                // We just keep looping here until user presses reset.
            end
        end
    end
endmodule






////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// module hex_decoder(hex_digit, segments);
//     input [3:0] hex_digit;
//     output reg [6:0] segments;
   
//     always @(*)
//         case (hex_digit)
//             4'h0: segments = 7'b100_0000;
//             4'h1: segments = 7'b111_1001;
//             4'h2: segments = 7'b010_0100;
//             4'h3: segments = 7'b011_0000;
//             4'h4: segments = 7'b001_1001;
//             4'h5: segments = 7'b001_0010;
//             4'h6: segments = 7'b000_0010;
//             4'h7: segments = 7'b111_1000;
//             4'h8: segments = 7'b000_0000;
//             4'h9: segments = 7'b001_1000;
//             4'hA: segments = 7'b000_1000;
//             4'hB: segments = 7'b000_0011;
//             4'hC: segments = 7'b100_0110;
//             4'hD: segments = 7'b010_0001;
//             4'hE: segments = 7'b000_0110;
//             4'hF: segments = 7'b000_1110;
//             default: segments = 7'h7f;
//         endcase
// endmodule



