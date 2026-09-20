----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.05.2026 19:16:45
-- Design Name: 
-- Module Name: dibuja_rgb_07 - Behavioral
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

entity dibuja_rgb_07 is
    port(
        clk, reset, init, stop: in std_logic;
        control: in std_logic_vector(1 downto 0);
        rgb_out: out std_logic
        );
end dibuja_rgb_07;

architecture Behavioral of dibuja_rgb_07 is
    --WS2812 CONTROLLER SIGNALS
    signal led_data: std_logic_vector (23 downto 0);
    signal init_w: std_logic;
    signal done_w,done_prev: std_logic;
    --MATRIX DRAWINGS
    constant COLOR_OFF: std_logic_vector (23 downto 0):= (others=>'0');
    constant COLOR_ON: std_logic_vector (23 downto 0) := x"00" & x"0F" & x"00"; --Color verde con el nibble mas significativo puesto a 0
    type dibu_type is array (7 downto 0) of std_logic_vector (7 downto 0);--Definicion del dibujo en array de 8 filas de 8 bits
    constant DIBU: dibu_type:= ("00011001","00110011","01100110","11001100","01100110","00110011","00011001","00000000");
    signal row: integer range 0 to 7;--indice filas
    signal col: integer range 0 to 7;--indice columnas
    signal ani_offset: integer range 0 to 7;--Contador de fotogramas (8 fotogramas diferentes en la animacion)
    --PROCESSES SIGNALS
    type fsm_type is (idle,draw,espera,cuenta_espera);
    signal state: fsm_type;
    signal stop_2,stopped: std_logic;--Señal stop interna y señal de aviso de matriz parada
    constant T_ESPERA: integer:= 500 * 100000;--ms de espera pasados a ciclos de reloj (10ns)
    signal contador: integer range 0 to T_ESPERA-1;--contador de espera entre fotogramas de animacion
    signal modo: std_logic_vector(1 downto 0);--Guarda control en el momento del envio de datos a la matriz
begin
    controller: entity work.ws2812_controller
        port map( 
            clk=>clk,
            reset=>reset,
            init=>init_w,
            led_data=>led_data,
            rgb_out=>rgb_out,
            done=>done_w
            );
            
    stop_process:process(clk,reset)
    begin
        if reset='1' then
            stop_2<='0';
        elsif rising_edge (clk) then
            if stop='1' and modo="11" then--se pulso stop en modo animacion
                stop_2<='1';--activamos stop interno
            elsif stopped='1' then--la animacion ha terminado y se ha parado
                stop_2<='0';--desactivamos stop interno
            end if;
        end if;
    end process;
    
    Dibuja_process:process(clk,reset)
    begin
        if reset='1' then
            state<=idle;
            led_data<=COLOR_OFF;
            init_w<='0';
            row<=0;
            col<=0;
            ani_offset<=0;
            stopped<='0';
            contador<=0;
            modo<="00";
            done_prev<='0';
        elsif rising_edge (clk) then
            done_prev<=done_w;-- En el siguiente ciclo actualizamos valor previo de done del controlador
            case state is
                when idle=>--Estado inicial / parado
                    init_w<='0';
                    stopped<='0';
                    if init='1' and done_w='1' then--hay que pintar algo y el controlador esta libre
                        row<=0;--inicializamos indices de columnas y filas 
                        col<=0;
                        ani_offset<=0;--inicializamos contador de fotogramas
                        modo<=control;--Guardamos valor de control durante el proceso de envio de datos, por si acaso durante este proceso el valor de control cambia
                        state<=draw;--Pasamos a dibujar
                    else
                        state<=idle;
                    end if;      
                                  
                when draw=>
                    case modo is
                        when ("00" or "01")=>--Pantalla apagada
                            led_data<=COLOR_OFF;--Cargamos 0 en el color del controlador
                        when "10"=>--Dibujo estatico
                            if DIBU(row)(col) = '1' then--Si el bit en cuestion es 1
                                led_data<=COLOR_ON;--se carga color verde en el controlador
                            else
                                led_data<=COLOR_OFF;--si no se carga con apagado
                            end if;
                        when "11"=>--Dibujo en movimiento 
                            --Tenemos un offset en el que segun el fotograma en el que estemos, obtenemos que posicion ocuparia en el dibujo original (constante)
                            if DIBU(row)((col + 8 - ani_offset) mod 8) = '1' then
                                led_data<=COLOR_ON;--se carga color verde en el controlador
                            else
                                led_data<=COLOR_OFF;
                            end if;
                        when others=>--En cualquier otro modo pasamos a idle a volver a esperar otro init
                            state<=idle;    
                    end case;
                    init_w<='1';--Activamos controlador
                    state<=espera;--Esperamos 
                    
                when espera=>
                    init_w<='0';--Desactivamos init de controlador
                    if done_prev='0' and done_w='1' then--flanco de subida en done_w (hemos mandado el led completo)
                        if row=7 and col=7 then --Matriz recorrida entera
                            if modo = "11" then--Modo animacion
                                if stop_2 = '1' then--Stop interno activado
                                    stopped<='1';--Avisamos a proceso de que hemos terminado de dibujar
                                    state<=idle;--Volvemos a estado inicial
                                else --sino seguimos con la animacion
                                    contador<=0;
                                    state<=cuenta_espera;--pasamos a esperar el tiempo entre fotogramas
                                end if;
                            else 
                                state<=idle;--En el resto de modos volvemos a idle cuando pintamos la matriz entera
                            end if; 
                        else --Actualizamos indices de fila y columna
                            if col=7 then--Fila terminada
                                col<=0;
                                row<=row+1;--Pasamos a siguiente fila
                            else 
                                col<=col+1;--Pasamos a siguiente bit de la fila
                            end if;
                        state<=draw;--Volvemos a pintar
                        end if;
                    else--Todavia no hay flanco de subida en done del controlador
                        state<=espera;--Seguimos esperando
                    end if;
                    
                when cuenta_espera=>--Estado de espera entre fotogramas de la animacion (0.5s < T_ESPERA < 1s)
                    if stop_2='1' then--Stop interno activado durante la espera
                        stopped<='1';--El dibujo estaba pintado, avisamos de que hemos parado
                        contador<=0;--Reseteamos contador
                        state<=idle;--Volvemos a idle
                    elsif contador < T_ESPERA - 1 then--Todavia no hemos contado el tiempo de espera
                        contador<=contador+1;
                        state<=cuenta_espera;
                    else --Ha pasado T_ESPERA
                        col<=0;--Reiniciamos indices de fila y columna
                        row<=0;
                        if ani_offset = 7 then --pasamos a siguiente fotograma de animacion (8 fotogramas)
                            ani_offset<=0;
                        else
                            ani_offset<=ani_offset+1;
                        end if;
                        state<=draw; --Volvemos a pintar la matriz de nuevo
                    end if;         
            end case;
        end if;
    end process;     

end Behavioral;
