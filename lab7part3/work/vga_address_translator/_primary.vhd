library verilog;
use verilog.vl_types.all;
entity vga_address_translator is
    generic(
        RESOLUTION      : string  := "320x240"
    );
    port(
        x               : in     vl_logic_vector;
        y               : in     vl_logic_vector;
        mem_address     : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of RESOLUTION : constant is 1;
end vga_address_translator;
