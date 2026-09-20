----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.05.2026 17:43:36
-- Design Name: 
-- Module Name: ws2812_control - Behavioral
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

entity ws2812_controller is
    port(
        clk,reset,init: in std_logic;
        led_data: in std_logic_vector(23 downto 0);
        rgb_out, done: out std_logic
        );
                
end ws2812_controller;

architecture Behavioral of ws2812_controller is
--24bits 8 bits por color, cada led toma los datos de la linea serie de entrada (24b) y los siguientes los deja pasar al siguiente led
--Reset: t>50us
--Se transmite GRB, empezando siempre por el msb de cada color
--'0': 400ns a 1 y 850 a 0
--'1': 800ns a 1 y 450ns a 0
    constant T0H: natural:=40;--400ns
    constant T0L: natural:=85;--850ns
    constant T1H: natural:=80;--800ns
    constant T1L: natural:=45;--450ns
    signal data: std_logic_vector(23 downto 0);--Datos color en formato GRB
    signal i: integer range 0 to 23;
    signal cuentaciclo: integer range 0 to (T1H+T1L);--Tenemos que contar 125 ciclos para transmitir 1 bit
    type states is (idle, send);
    signal fsm: states;
begin
    process(clk,reset)
    begin
        if reset='1' then
            fsm<=idle;
            i<=23;--Empezamos siempre desde el msb
            cuentaciclo<=0;
            rgb_out<='0';
            done<='1';
            data<=(others=>'0');
        elsif rising_edge (clk) then
            case fsm is 
                when idle=>
                    done<='1';--Controlador libre
                    rgb_out<='0';
                    if init='1' then
                        i<=23;--Se cuenta desde el msb
                        cuentaciclo<=0;--Inicializamos contador de ciclos
                       -- done<='0';
                        data<=led_data(15 downto 8) & led_data(23 downto 16) & led_data(7 downto 0);--Ponemos color en formato GRB 
                        fsm<=send;
                    else 
                        fsm<=idle;
                    end if;
                when send=>
                    done<='0';--Controlador ocupado
                    if data(i)='1' then--Hay que mandar '1'
                        if cuentaciclo< T1H then --No hemos completado los ciclos a 1
                            rgb_out<='1';--Salida a 1
                        else 
                            rgb_out<='0';--Sino se pone a 0
                        end if;
                        
                        if cuentaciclo < (T1H+T1L -1) then--No hemos llegado a mandar 1 bit entero
                            cuentaciclo<=cuentaciclo+1;--se incrementa numero ciclo
                        else 
                            cuentaciclo<=0;--resetea ciclo
                            if i=0 then--Hemos mandado el color entero
                                fsm<=idle;--Volvemos a inicio
                            else 
                                i<=i-1;--Pasamos a mandar siguiente bit
                                fsm<=send;
                            end if;
                        end if;
                    else--Hay que mandar '0'
                        if cuentaciclo <T0H then
                            rgb_out<='1';
                        else 
                            rgb_out<='0';
                        end if;
                        if cuentaciclo < (T0H+T0L -1) then
                            cuentaciclo<=cuentaciclo+1;
                        else 
                            cuentaciclo<=0;
                            if i=0 then
                                fsm<=idle;
                            else
                                i<=i-1;
                                fsm<=send;
                            end if;
                        end if;
                    end if;
                end case;
            end if;      
    end process;
    

end Behavioral;
