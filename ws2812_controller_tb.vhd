library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ws2812_controller_tb is
end entity ws2812_controller_tb;

architecture sim of ws2812_controller_tb is
    constant CLK_PERIOD    : time := 10 ns;
    constant T0H_CYCLES   : natural := 40;
    constant T0L_CYCLES   : natural := 85;
    constant T1H_CYCLES   : natural := 80;
    constant T1L_CYCLES   : natural := 45;
    constant RESET_CYCLES : natural := 5001;

    -- Colores RGB de entrada. El nibble alto de R, G y B esta siempre a cero.
    constant RED_RGB   : std_logic_vector(23 downto 0) := x"0F0000";
    constant BLUE_RGB  : std_logic_vector(23 downto 0) := x"00000F";
    constant GREEN_RGB : std_logic_vector(23 downto 0) := x"000F00";

    -- Tramas esperadas en la salida WS2812: orden GRB, MSB primero.
    constant RED_GRB   : std_logic_vector(23 downto 0) := x"000F00";
    constant BLUE_GRB  : std_logic_vector(23 downto 0) := x"00000F";
    constant GREEN_GRB : std_logic_vector(23 downto 0) := x"0F0000";

    signal clk      : std_logic;
    signal reset    : std_logic;
    signal led_data : std_logic_vector(23 downto 0);
    signal init     : std_logic;
    signal rgb_out  : std_logic;
    signal done     : std_logic;

    procedure check_zero(signal rgb_out_s : in std_logic) is
    begin
        for i in 0 to T0H_CYCLES - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rgb_out_s = '1'
                report "rgb_out should be high"
                severity error;
        end loop;

        for i in 0 to T0L_CYCLES - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rgb_out_s = '0'
                report "rgb_out should be low"
                severity error;
        end loop;
    end procedure;

    procedure check_one(signal rgb_out_s : in std_logic) is
    begin
        for i in 0 to T1H_CYCLES - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rgb_out_s = '1'
                report "rgb_out should be high"
                severity error;
        end loop;

        for i in 0 to T1L_CYCLES - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rgb_out_s = '0'
                report "rgb_out should be low"
                severity error;
        end loop;
    end procedure;

    procedure check_frame(
        signal rgb_out_s      : in std_logic;
        constant expected_grb : in std_logic_vector(23 downto 0)
    ) is
    begin
        for i in 23 downto 0 loop
            if expected_grb(i) = '1' then
                check_one(rgb_out_s);
            else
                check_zero(rgb_out_s);
            end if;
        end loop;
    end procedure;

    procedure check_reset_time(signal rgb_out_s : in std_logic) is
    begin
        for i in 0 to RESET_CYCLES - 1 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            assert rgb_out_s = '0'
                report "rgb_out should stay low during reset/latch"
                severity error;
        end loop;
    end procedure;

    procedure start_transmission(
        signal led_data_s : out std_logic_vector(23 downto 0);
        signal init_s     : out std_logic;
        constant color    : in  std_logic_vector(23 downto 0)
    ) is
    begin
        led_data_s <= color;
        init_s <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        assert done = '0'
            report "done should be low while transmitting"
            severity error;
        init_s <= '0';
    end procedure;
begin
    clk_gen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    dut : entity work.ws2812_controller
        port map (
            clk      => clk,
            reset    => reset,
            led_data => led_data,
            init     => init,
            rgb_out  => rgb_out,
            done     => done
        );

    stim : process
    begin
        reset <= '1';
        init <= '0';
        led_data <= (others => '0');

        wait for 100 ns;
        reset <= '0';
        wait until rising_edge(clk);

        assert done = '1'
            report "done should be high while idle"
            severity error;

        -- Rojo: R = 0x0F, G = 0x00, B = 0x00.
        start_transmission(led_data, init, RED_RGB);
        check_frame(rgb_out, RED_GRB);
        check_reset_time(rgb_out);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert done = '1'
            report "done should return high after red frame"
            severity error;

        -- Azul: R = 0x00, G = 0x00, B = 0x0F.
        start_transmission(led_data, init, BLUE_RGB);
        check_frame(rgb_out, BLUE_GRB);
        check_reset_time(rgb_out);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert done = '1'
            report "done should return high after blue frame"
            severity error;

        -- Verde: R = 0x00, G = 0x0F, B = 0x00.
        start_transmission(led_data, init, GREEN_RGB);
        check_frame(rgb_out, GREEN_GRB);
        check_reset_time(rgb_out);
        wait until rising_edge(clk);
        wait for 1 ns;
        assert done = '1'
            report "done should return high after green frame"
            severity error;

        wait for 100 ns;
        report "Simulation finished successfully"
            severity note;
        wait;
    end process;
end architecture sim;
