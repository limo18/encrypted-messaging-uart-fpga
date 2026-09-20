----------------------------------------------------------------------------------
-- Original: Charilaos Memeletzoglou (Universidad de Patras, Grecia). 
-- Modify by: Carlos J. Jiménez (Universidad de Sevilla) 
-- 
-- Create Date: feb 2026
-- Design Name: present_tb_80
--
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision: Modify to adapt the patterns
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity present_tb_80 is
end entity;

architecture tb of present_tb_80 is
        component present
                port (
                        clk      : in std_logic;
                        rst      : in std_logic;
                        ena      : in std_logic;
                        mode_sel : in std_logic_vector(1 downto 0);
                        key      : in std_logic_vector(127 downto 0);
                        data_in  : in std_logic_vector(63 downto 0);
                        data_out : out std_logic_vector(63 downto 0);
                        ready    : out std_logic
                );
        end component;

        -- Clock period
        constant clk_period : time := 10 ns;
        -- Generics

        -- Ports
        signal clk      : std_logic;
        signal rst      : std_logic;
        signal ena      : std_logic;
        signal mode_sel : std_logic_vector(1 downto 0);
        signal key      : std_logic_vector(127 downto 0);
        signal data_in  : std_logic_vector(63 downto 0);
        signal data_out : std_logic_vector(63 downto 0);
        signal ready    : std_logic;
        
        signal exp_data_out : std_logic_vector(63 downto 0);
        
begin
        present_inst : present
        port map(
                clk      => clk,
                rst      => rst,
                ena      => ena,
                mode_sel => mode_sel,
                key      => key,
                data_in  => data_in,
                data_out => data_out,
                ready    => ready
        );

        clk_process : process
        begin
                clk <= '1';
                wait for clk_period/2;
                clk <= '0';
                wait for clk_period/2;
        end process clk_process;

        stimuli_proc : process begin

                rst <= '1';
                ena <= '0';
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"FFFFFFFFFFFFFFFF";
                mode_sel <= b"00"; -- 80-bit encryption

                wait for 145 ns;
                rst <= '0';

                wait for clk_period *5;
                
                ------------------------------------------------------------------
                -- Five encryption operation.
                -- Expected output given by the designers
                ------------------------------------------------------------------
                
                -- First operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"00"; -- 80-bit encryption
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"0000000000000000";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: 5579C1387B228445
                exp_data_out <= X"5579C1387B228445";
                
                wait for 10 * clk_period;
                
                -- Second operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"00"; -- 80-bit encryption
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"FFFFFFFFFFFFFFFF";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: A112FFC72F68417B
                exp_data_out <= X"A112FFC72F68417B";
                
                wait for 10 * clk_period;

                -- Third operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"00"; -- 80-bit encryption
                key      <= x"000000000000FFFFFFFFFFFFFFFFFFFF";
                data_in  <= x"0000000000000000";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: E72C46C0F5945049
                exp_data_out <= X"E72C46C0F5945049";
                
                wait for 10 * clk_period;

                -- Fourth operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"00"; -- 80-bit encryption
                key      <= x"000000000000FFFFFFFFFFFFFFFFFFFF";
                data_in  <= x"FFFFFFFFFFFFFFFF";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: 3333DCD3213210D2
                exp_data_out <= X"3333DCD3213210D2";
                
                wait for 10 * clk_period;

                ------------------------------------------------------------------
                -- Five decryption operation.
                -- Expected output defined by the designers
                ------------------------------------------------------------------

                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"01"; -- 80-bit decryption
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"5579C1387B228445";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: 0000000000000000
                exp_data_out <= X"0000000000000000";
                
                wait for 10 * clk_period;
                
                -- Second operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"01"; -- 80-bit decryption
                key      <= x"00000000000000000000000000000000";
                data_in  <= x"A112FFC72F68417B";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: FFFFFFFFFFFFFFFF
                exp_data_out <= X"FFFFFFFFFFFFFFFF";
                
                wait for 10 * clk_period;

                -- Third operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"01"; -- 80-bit decryption
                key      <= x"000000000000FFFFFFFFFFFFFFFFFFFF";
                data_in  <= x"E72C46C0F5945049";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: 0000000000000000
                exp_data_out <= X"0000000000000000";
                
                wait for 10 * clk_period;

                -- Fourth operation
                wait until falling_edge(clk);
                ena <= '1';
                mode_sel <= b"01"; -- 80-bit encryption
                key      <= x"000000000000FFFFFFFFFFFFFFFFFFFF";
                data_in  <= x"3333DCD3213210D2";
                wait until falling_edge(clk);
                ena <= '0';
                
                wait until falling_edge(clk); -- wait ready go to '1'
                wait until ready = '1';       -- wait end of operation
                
                -- ciphertext: FFFFFFFFFFFFFFFF
                exp_data_out <= X"FFFFFFFFFFFFFFFF";
                
                wait for 10 * clk_period;


                wait; -- wait forever, thus halting the simulation
        end process;
end;
