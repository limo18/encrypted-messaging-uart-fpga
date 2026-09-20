-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.03.2026 00:29:31
-- Design Name: 
-- Module Name: emisor_cifr_tb - Behavioral
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
use IEEE.MATH_REAL.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity emisor_cifr_tb is
--  Port ( );
end emisor_cifr_tb;

architecture Behavioral of emisor_cifr_tb is
    --INPUTS
    signal clk, reset, init: std_logic :='0';
    signal addr_dest: std_logic_vector(7 downto 0) := X"B4";
    signal comando: std_logic_vector(7 downto 0) :=(others=>'0');
    --OUTPUT
    signal tx: std_logic;
    --UART SIGNALS
    signal reset_n: std_logic :='1';
    signal rx_data: std_logic_vector(7 downto 0);
    signal rx_busy: std_logic :='0';
    signal rx_error: std_logic :='0';
    --
    constant T: time := 10ns;
    
begin
    uut: entity work.emisor_cifr
        port map( 
            clk=>clk,
            reset=>reset,
            init=> init,
            addr_dest=>addr_dest,
            comando=>comando,
            tx=>tx
            );
    receptor: entity work.uart
        port map(
            clk=>clk,
            reset_n=>reset_n,
            rx=>tx,
            tx_ena=>'0',
            tx_data=>x"00",
            rx_data=>rx_data,
            rx_busy=>rx_busy,
            rx_error=>rx_error,
            tx=>open,--Usamos UART solo como receptor
            tx_busy=>open
            );
    clk_process: process
    begin
        clk<='0';
        wait for T/2;
        clk<='1';
        wait for T/2;
    end process;  
    
    stim_process: process
        variable seed1: integer := 160078;
        variable seed2: integer := 63;
        variable re1: real := 0.0;
    begin
        reset<='1';
        reset_n<='0';
        wait for 32*T;
        reset_n<='1';
        reset<='0';
        wait until rising_edge (clk);
        for i in 1 to 10 loop--Loop para generar y mandar 10 comandos pseudoaleatorios
            uniform(seed1,seed2,re1);
            comando<=std_logic_vector(TO_UNSIGNED (integer((re1)* real (2**8-1)),8));--cargamos comando aleatorio en entrada emisor
            wait until rising_edge (clk);
            init<='1';--iniciamos emision de mensaje
            wait until rising_edge (clk);
            init<='0';
            wait until rising_edge (clk);
            for i in 1 to 10 loop --loop para saber que se han enviado los 10 bytes del mensaje
                wait until rx_busy='1';--recibiendo
                wait until rx_busy='0';--byte recibido
            end loop;
            wait for 5*T;
            report "Mensaje " & integer'image(i) & " enviado correctamente.";--Marcamos que el mensaje ha sido enviado correctamente
        end loop;
        wait;
    end process;
end Behavioral;
