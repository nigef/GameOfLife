library verilog;
use verilog.vl_types.all;
entity vga_adapter is
    generic(
        BITS_PER_COLOUR_CHANNEL: integer := 1;
        MONOCHROME      : string  := "FALSE";
        RESOLUTION      : string  := "160x120";
        BACKGROUND_IMAGE: string  := "black.mif"
    );
    port(
        resetn          : in     vl_logic;
        clock           : in     vl_logic;
        colour          : in     vl_logic_vector;
        x               : in     vl_logic_vector;
        y               : in     vl_logic_vector;
        plot            : in     vl_logic;
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
    attribute mti_svvh_generic_type of BACKGROUND_IMAGE : constant is 1;
end vga_adapter;
