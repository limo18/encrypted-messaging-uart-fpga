----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.05.2026 01:23:31
-- Design Name: 
-- Module Name: dibuja_rgb_07_tb - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dibuja_rgb_07_tb is
--  Port ( );
end dibuja_rgb_07_tb;

architecture Behavioral of dibuja_rgb_07_tb is
    signal clk,reset,init,stop: std_logic :='0';
    signal control: std_logic_vector(1 downto 0):="00";
    signal rgb_out: std_logic;
    constant T:time:=10ns;
begin
    uut: entity work.dibuja_rgb_07
        port map(
            clk=>clk,
            reset=>reset,
            init=>init,
            stop=>stop,
            control=>control,
            rgb_out=>rgb_out
            );
    clk_process:process
    begin
        clk<='0';
        wait for T/2;
        clk<='1';
        wait for T/2;
    end process;
    STIM:process
    begin
        -- FASE 1: Reset Inicial del Sistema
        report "Iniciando Fase 1" severity note;
        reset <= '1';
        wait for 100 ns;
        reset <= '0';        
        -- FASE 2: Verificar Modo Apagado (control = "00" o "01")
        report "Fase 1 completada, iniciando fase 2" severity note;
        control <= "00"; 
        init <= '1';--Activamos controlador
        wait for T * 2;
        init <= '0';
        wait for 5 ms; --Esperamos a que de tiempo a que se manden todos los leds
        -- FASE 3: Verificar Modo Dibujo Estático (control = "10")
        report "Fase 2 completada, iniciando fase 3" severity note;
        control <= "10";
        init <= '1';
        wait for T * 2;
        init <= '0';
        wait for 5 ms;
        -- FASE 4: Verificar Modo Animación (control = "11") y botón STOP
        report "Fase 3 terminada, iniciando fase 4" severity note;
        control <= "11";
        init <= '1';
        wait for T * 2;
        init <= '0';
        wait for 505 ms; -- Esperamos lo necesario para que cambie de fotograma
        stop <= '1';--Activamos stop
        wait for T * 2;
        stop <= '0';
        wait for 3 ms;
        report "Simulacion terminada con exito" severity note;
        wait;
    end process;
end Behavioral;
