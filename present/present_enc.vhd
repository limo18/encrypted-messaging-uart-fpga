----------------------------------------------------------------------------------
-- Original: Charilaos Memeletzoglou (Universidad de Patras, Grecia). 
-- Modify by: Carlos J. Jiménez (Universidad de Sevilla) 
-- 
-- Create Date: feb 2026
-- Design Name: present_enc
--
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision: Modify to eliminate low leve hierarchy modules
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity present_enc is
        port (
                clk        : in std_logic;
                rst        : in std_logic;
                ena        : in std_logic;
                load_ena   : in std_logic;
                plaintext  : in std_logic_vector(63 downto 0);
                round_key  : in std_logic_vector(63 downto 0); -- read from round keys mem
                ciphertext : out std_logic_vector(63 downto 0)
        );
end present_enc;

architecture structural of present_enc is
        constant BLOCK_SIZE : natural := 64;

        signal  mux_sel,
                ciph_enable : std_logic;

        signal  state_reg_mux_out,
                state : std_logic_vector(BLOCK_SIZE - 1 downto 0);

        signal  sbox_layer_input,
                pbox_layer_input,
                pbox_layer_out : std_logic_vector(BLOCK_SIZE - 1 downto 0);
begin
        -- Control signal for the multiplexer controlling the input of the State register
        -- When encrypting, the round counter is counting upwards starting from "00000".
        -- We need to fetch the round keys from the round keys memory.
        -- Thus, when the encryption datapath is enabled and the counter has its initial value,
        -- we need to load the plaintext into the State register.                
        mux_sel <= '1' when (load_ena = '1' and ena = '1') else '0';

        -- 64-bit mux which drives the state register
        state_reg_mux_out <= pbox_layer_out when (mux_sel = '0') else
                             plaintext;

        -- 64-bit state register
        
        process (clk, rst)
        begin
            if (rst = '1') then -- asynchronous reset
                 state <= (others =>'0');
            elsif rising_edge(clk) then
                 if (ena = '1') then
                     state <= state_reg_mux_out;
                 end if;
            end if;
        end process;

        -- 64-bit xor to add current round key to state
        sbox_layer_input <= state XOR round_key;
        
        -- S-Box layer (16 S-Boxes in parallel), the *confusion* layer
        sbox_layer : entity work.sbox_layer
                port map(
                        sbox_layer_in  => sbox_layer_input,
                        sbox_layer_out => pbox_layer_input
                );

        -- P-Box layer, the *diffusion* layer
        pbox_layer : entity work.pbox
                port map(
                        data_in  => pbox_layer_input,
                        data_out => pbox_layer_out
                );
        
        ciphertext <= sbox_layer_input;
        
end structural;