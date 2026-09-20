library ieee;
use ieee.std_logic_1164.all;

entity key_schedule_128 is
        port (
                clk               : in std_logic;
                rst               : in std_logic;
                ena               : in std_logic;
                key_load_ena      : in std_logic;
                input_key         : in std_logic_vector(127 downto 0);
                round_counter_val : in std_logic_vector(4 downto 0);
                output_key        : out std_logic_vector(127 downto 0)
        );
end entity;

architecture structural of key_schedule_128 is
        signal  shifted_vec,
                tmp,
                reg_out,
                mux_out,
                key_mux_out : std_logic_vector(127 downto 0);
begin

        mux_out <= reg_out when (key_load_ena = '0') else
                   input_key;

        shifted_vec <= mux_out(66 downto 0) & mux_out(127 downto 67);

        sbox_1 : entity work.sbox
                port map(
                        data_in  => shifted_vec(127 downto 124),
                        data_out => tmp(127 downto 124)
                );

        sbox_2 : entity work.sbox
                port map(
                        data_in  => shifted_vec(123 downto 120),
                        data_out => tmp(123 downto 120)
                );

        tmp(119 downto 67) <= shifted_vec(119 downto 67);
        tmp(66 downto 62)  <= shifted_vec(66 downto 62) XOR round_counter_val;
        tmp(61 downto 0)   <= shifted_vec(61 downto 0);
        
        key_mux_out <= tmp when (key_load_ena = '0') else
                       input_key;


        process (clk, rst)
        begin
                if (rst = '1') then -- asynchronous reset
                        reg_out <= (others =>'0');
                elsif rising_edge(clk) then
                        if (ena = '1') then
                               reg_out <= key_mux_out;
                        end if;
                end if;
        end process;

        output_key <= reg_out;

end architecture;