----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.03.2026 17:08:12
-- Design Name: 
-- Module Name: emisor_receptor_cifr_tb - Behavioral
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

entity emisor_receptor_cifr_rgb_tb is
--  Port ( );
end emisor_receptor_cifr_rgb_tb;

architecture Behavioral of emisor_receptor_cifr_rgb_tb is
    signal clk, reset: std_logic := '0';
    signal comando_rx: std_logic_vector(7 downto 0);
    signal rgb_out, msg_no, msg_err, msg_ok: std_logic;
    --
    signal addr_dest: std_logic_vector(7 downto 0):= x"00";
    signal comando_tx: std_logic_vector(7 downto 0) := x"00";
    signal init: std_logic := '0';
    signal tx: std_logic;
    --
    constant T: time := 10ns;
    constant origen: std_logic_vector (7 downto 0):=X"07";
begin
    
    uut: entity work.receptor_cifr_rgb
        port map(
            clk=>clk,
            reset=>reset,
            rx=>tx,
            msg_no=>msg_no,
            msg_err=>msg_err,
            msg_ok=>msg_ok,
            comando=>comando_rx,
            rgb_out=>rgb_out
            );
    emi: entity work.emisor_cifr
        port map( 
            clk=>clk,
            reset=>reset,
            addr_dest=>addr_dest,
            init=>init,
            comando=>comando_tx,
            tx=>tx
            );
    clk_process: process
    begin
        clk<='0';
        wait for T/2;
        clk<='1';
        wait for T/2;
    end process;
    
    stim: process
    begin
        -- FASE 1: Reset Inicial del Sistema
        report "Iniciando fase 1" severity note;
        reset <= '1';
        wait for 32*T;
        reset <= '0';
        wait until rising_edge(clk);        
        -- FASE 2: Mandando a direccion incorrecta
        report "Fase 1 terminada, iniciando fase 2" severity note;
        addr_dest  <= x"03"; -- otra direccion
        comando_tx <= x"17"; -- Intentamos activar dibujo en movimiento
        wait until rising_edge(clk);
        init <= '1'; -- Iniciamos transmision
        wait until rising_edge(clk);
        init <= '0';
        -- Esperamos a que se terminen de recibir los datos por UART
        wait until (msg_ok = '1' or msg_no = '1' or msg_err = '1');
        if msg_no = '1' then
            report "Fase 2 completada con exito" severity note;
        else
            report "ERROR EN FASE 2" severity failure;
        end if;
        wait for 50 ms;
        -- FASE 3: Enviando a direccion correcta, modo animacion
        report "Fase 2 terminada, iniciando fase 3" severity note;
        addr_dest  <= origen; -- Dirección correcta (x"07")
        comando_tx <= x"17";  -- Comando de dibujo en movimiento
        wait until rising_edge(clk);
        init <= '1';
        wait until rising_edge(clk);
        init <= '0';
        wait until (msg_ok = '1' or msg_no = '1' or msg_err = '1');
        if msg_ok = '1' then
            report "Fase 3 completada con exito" severity note;
        else
            report "ERROR EN FASE 3" severity failure;
        end if;
        wait for 600 ms;--Esperamos lo suficiente para que haga mas de 1 fotograma
        -- FASE 4: Enviando modo dibujo estatico
        report "Fase 3 terminada, iniciando fase 4" severity note;
        addr_dest  <= origen;
        comando_tx <= x"07";--Comando de dibujo estatico
        wait until rising_edge(clk);
        init <= '1';
        wait until rising_edge(clk);
        init <= '0';
        wait until (msg_ok = '1' or msg_no = '1' or msg_err = '1');
        if msg_ok = '1' then
            report "FASE 4 COMPLETADA CON EXITO" severity note;
        else
            report "ERROR EN FASE 4" severity failure;
        end if;
        wait for 50 ms;
        -- FASE 5: Mandando borrado de pantalla
        report "Fase 4 completada, iniciando fase 5" severity note;
        addr_dest  <= origen;
        comando_tx <= x"00";  -- Comando de apagado
        wait until rising_edge(clk);
        init <= '1';
        wait until rising_edge(clk);
        init <= '0';
        wait until (msg_ok = '1' or msg_no = '1' or msg_err = '1');
        if msg_ok = '1' then
            report "Fase 5 completada con exito" severity note;
        else
            report "ERROR EN FASE 5" severity failure;
        end if;
        wait for 5 ms;
        report "SIMULACION COMPLETADA CON EXITO" severity note;
        wait;
    end process;
            

end Behavioral;
