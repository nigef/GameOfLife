library verilog;
use verilog.vl_types.all;
entity vga_controller is
    generic(
        BITS_PER_COLOUR_CHANNEL: integer := 1;
        MONOCHROME      : string  := "FALSE";
        RESOLUTION      : string  := "160x120";
        C_VERT_NUM_PIXELS: vl_logic_vector(0 to 9) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0);
        C_VERT_SYNC_START: vl_logic_vector(0 to 9) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi1);
        C_VERT_SYNC_END : vl_logic_vector(0 to 9) := (Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0);
        C_VERT_TOTAL_COUNT: vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi1);
        C_HORZ_NUM_PIXELS: vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0);
        C_HORZ_SYNC_START: vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1, Hi1);
        C_HORZ_SYNC_END : vl_logic_vector(0 to 9) := (Hi1, Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0);
        C_HORZ_TOTAL_COUNT: vl_logic_vector(0 to 9) := (Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0)
    );
    port(
        vga_clock       : in     vl_logic;
        resetn          : in     vl_logic;
        pixel_colour    : in     vl_logic_vector;
        memory_address  : out    vl_logic_vector;
        VGA_R           : out    vl_logic_vector(9 downto 0);
        VGA_G           : out    vl_logic_vector(9 downto 0);
        VGA_B           : out    vl_logic_vector(9 downto 0);
        VGA_HS          : out    vl_logic;
        VGA_VS          : out    vl_logic;
        VGA_BLANK       : out    vl_logic;
        VGA_SYNC        : out    vl_logic;
        VGA_CLK         : out    vl_logic
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of BITS_PER_COLOUR_CHANNEL : constant is 1;
    attribute mti_svvh_generic_type of MONOCHROME : constant is 1;
    attribute mti_svvh_generic_type of RESOLUTION : constant is 1;
    attribute mti_svvh_generic_type of C_VERT_NUM_PIXELS : constant is 1;
    attribute mti_svvh_generic_type of C_VERT_SYNC_START : constant is 1;
    attribute mti_svvh_generic_type of C_VERT_SYNC_END : constant is 1;
    attribute mti_svvh_generic_type of C_VERT_TOTAL_COUNT : constant is 1;
    attribute mti_svvh_generic_type of C_HORZ_NUM_PIXELS : constant is 1;
    attribute mti_svvh_generic_type of C_HORZ_SYNC_START : constant is 1;
    attribute mti_svvh_generic_type of C_HORZ_SYNC_END : constant is 1;
    attribute mti_svvh_generic_type of C_HORZ_TOTAL_COUNT : constant is 1;
end vga_controller;
