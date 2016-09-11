library verilog;
use verilog.vl_types.all;
entity datapath is
    port(
        clk50           : in     vl_logic;
        resetn          : in     vl_logic;
        s_rc            : in     vl_logic;
        s_rl            : in     vl_logic;
        s_dc            : in     vl_logic;
        s_cr            : in     vl_logic;
        s_ln            : in     vl_logic;
        s_d             : in     vl_logic;
        x               : out    vl_logic_vector(8 downto 0);
        y               : out    vl_logic_vector(8 downto 0);
        colour          : out    vl_logic_vector(2 downto 0);
        colourSW        : in     vl_logic_vector(2 downto 0);
        emit_done_board_gen: out    vl_logic;
        emit_display    : out    vl_logic;
        emit_conway     : out    vl_logic;
        emit_reset_load : out    vl_logic;
        emit_load       : out    vl_logic;
        emit_tick       : in     vl_logic;
        current_board   : out    vl_logic_vector(8 downto 0);
        next_board      : out    vl_logic_vector(8 downto 0);
        initial_board_flat1: out    vl_logic_vector(8 downto 0);
        initial_board_flat2: out    vl_logic_vector(8 downto 0);
        initial_board_flat3: out    vl_logic_vector(8 downto 0);
        initial_board_flat4: out    vl_logic_vector(8 downto 0);
        zero_board      : out    vl_logic_vector(8 downto 0);
        reverse_index   : out    vl_logic_vector(8 downto 0);
        reverse_neighbour: out    vl_logic_vector(8 downto 0);
        resetPlotBlack  : out    vl_logic;
        liveCellCount   : out    vl_logic_vector(16 downto 0);
        cellCountOutput : out    vl_logic_vector(16 downto 0);
        cellIndex       : out    vl_logic_vector(16 downto 0);
        cellState       : in     vl_logic;
        boardSelectSwitch: in     vl_logic_vector(1 downto 0)
    );
end datapath;
