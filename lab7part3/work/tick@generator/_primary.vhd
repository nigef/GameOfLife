library verilog;
use verilog.vl_types.all;
entity tickGenerator is
    port(
        clk50           : in     vl_logic;
        resetn          : in     vl_logic;
        tickSelectSwitch: in     vl_logic_vector(1 downto 0);
        emit_tick       : out    vl_logic
    );
end tickGenerator;
