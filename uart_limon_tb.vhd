----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12.03.2026 18:56:52
-- Design Name: 
-- Module Name: uart_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity uart_limon_tb is
--  Port ( );
end uart_limon_tb;

architecture Behavioral of uart_limon_tb is
    constant clk_freq: integer :=100_000_000;
    constant baud_rate: integer := 19_200;
    constant os_rate: integer := 16;
    constant d_width: integer :=8;
    constant parity: integer :=0;
    constant parity_eo: std_logic :='0';
    constant T: time:= 10 ns;
    --inputs
    signal clk: std_logic :='0';
    signal reset: std_logic :='0';
    signal rx: std_logic :='1';
    signal tx_ena: std_logic :='0';
    signal tx_data: std_logic_vector(d_width-1 downto 0) := (others=> '0');
    --outputs
    signal rx_data: std_logic_vector(d_width-1 downto 0);
    signal rx_done: std_logic ;
    signal rx_error: std_logic :='0';
    signal tx: std_logic :='0';
    signal tx_done: std_logic;

begin
    uut: entity work.uart_limon
        generic map(
            clk_freq=>clk_freq,
            baud_rate=>baud_rate,
--            os_rate=>os_rate,
            d_bits=>d_width,
            parity=>parity,
            parity_type=>parity_eo
            )
        port map(
            clk=>clk,
            reset=>reset,
            rx=>rx,
            tx_ena=>tx_ena,
            tx_data=>tx_data,
            rx_data=>rx_data,
            rx_done=>rx_done,
            rx_error=>rx_error,
            tx=>tx,
            tx_done=>tx_done
            );
            
    clock: process
    begin
    clk<='0';
    wait for T/2;
    clk<='1';
    wait for T/2;
    end process;         
    stim: process
    begin
        reset<='1';
        wait for 117 ns;
        reset<='0';
        wait until falling_edge (clk);
        tx_data<="10101010";
        tx_ena<='1';
        wait until rising_edge (clk);
        tx_ena<='0';
        
        wait;
    end process;
    rx<=tx;
end Behavioral;
