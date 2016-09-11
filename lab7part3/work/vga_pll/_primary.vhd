library verilog;
use verilog.vl_types.all;
entity vga_pll is
    port(
        clock_in        : in     vl_logic;
        clock_out       : out    vl_logic
    );
end vga_pll;
