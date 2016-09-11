library verilog;
use verilog.vl_types.all;
entity control is
    port(
        clk50           : in     vl_logic;
        resetn          : in     vl_logic;
        writeEn         : out    vl_logic;
        s_rc            : out    vl_logic;
        s_rl            : out    vl_logic;
        s_dc            : out    vl_logic;
        s_cr            : out    vl_logic;
        s_ln            : out    vl_logic;
        s_d             : out    vl_logic;
        emit_done_board_gen: in     vl_logic;
        emit_display    : in     vl_logic;
        emit_conway     : in     vl_logic;
        emit_reset_load : in     vl_logic;
        emit_load       : in     vl_logic;
        emit_tick       : in     vl_logic
    );
end control;
