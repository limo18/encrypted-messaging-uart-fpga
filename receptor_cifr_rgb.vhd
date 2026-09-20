----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.03.2026 01:52:07
-- Design Name: 
-- Module Name: receptor_cifr - Behavioral
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

entity receptor_cifr_rgb is
--  Port ( );
    generic(
        origen: std_logic_vector(7 downto 0):= X"07";
        clave: std_logic_vector(79 downto 0):=X"F0DDA02026000000FC08"
        );
    port( 
        clk, reset, rx: in std_logic;
        comando: out std_logic_vector(7 downto 0);
        msg_no, msg_err, msg_ok, rgb_out: out std_logic 
        );
end receptor_cifr_rgb;

architecture Behavioral of receptor_cifr_rgb is
    --RX int_reset signals
    signal cont: unsigned(22 downto 0);
    signal int_reset: std_logic;
    type msg_rx is (cuenta,espera);
    signal wait_asm: msg_rx;
    --RX_done process' signals
    signal done_rx, rx_busy_prev: std_logic;
    -- UART SIGNALS
    signal reset_n, rx_error, rx_busy: std_logic;
    signal rx_data: std_logic_vector(7 downto 0);
    --PRESENT SIGNALS
    signal ena, ready: std_logic;--Enable cifrador, señal de salida ready 
    signal data_in, plaintext: std_logic_vector(63 downto 0);
    constant key: std_logic_vector(127 downto 0) := X"000000000000" & clave;--Key (48 0s + key de 80 bits)
    --REG SIGNAL
    signal data_reg: std_logic_vector(63 downto 0);--Guarda el mensaje cifrado recibido por UART
    --RECEPTOR ASM SIGNALS
    type fsm_receptor is (espera_msg, s0, s1, s2, s3, s4, s5, s6, s7, s8);
    signal rx_asm: fsm_receptor;
    signal byte_count: unsigned(2 downto 0);
    --Addresses received
    signal destino, emisor: std_logic_vector(7 downto 0);
    --DIBUJA RGB SIGNALS
    signal init_rgb, stop, transicion: std_logic;
    signal control: std_logic_vector(1 downto 0);
begin
--En este trabajo 2 se ha eliminado el nivel de jerarquia innecesario de registros que estaba en el trabajo 1 (diseños reg_emi y reg_recept) y se ha implementado
-- dentro de cada diseño su propio registro (en este diseño data_reg) sin necesidad de diseños adicionales
    --INSTANCIACIONES
    reset_n<=not(reset);
    recept: entity work.uart
        port map( 
            clk=>clk,
            reset_n=>reset_n,
            tx_ena=>'0',--Usamos la UART como receptora por lo que nunca transmitira mensajes
            tx_data=>x"00",
            rx=>rx,
            rx_busy=>rx_busy,
            rx_error=>rx_error,
            rx_data=>rx_data,
            tx_busy=>open,
            tx=>open
            );
    descifr: entity work.present
        port map( 
            clk=>clk,
            rst=>reset,
            ena=>ena,
            mode_sel=>"01",--Key de 80bits en modo descifrador
            key=>key,
            data_in=>data_in,
            data_out=>plaintext,
            ready=>ready
            );
    dibuja: entity work.dibuja_rgb_07
        port map(
            clk=>clk,
            reset=>reset,
            init=>init_rgb,
            stop=>stop,
            control=>control,
            rgb_out=>rgb_out
            );
            
    --PROCESOS      
    msg_wait: process(reset, clk)--Proceso que resetea la maquina de estados de recepcion cuando tarda mucho tiempo en recibir un nuevo mensaje
    begin
        if reset='1' then
            cont<=(others=>'0');
            wait_asm<=cuenta;
            int_reset<='0';
        elsif rising_edge(clk) then
            case wait_asm is 
                when cuenta=>
                    cont<= cont+1;
                    if rx= '0' then--se ha recibido un mensaje
                        cont<=(others=>'0');--se resetea el contador
                        wait_asm<=cuenta;
                    elsif cont(22)='1' then--se ha activado el msb del contador
                        int_reset<='1';--activamos reset interno
                        cont<=(others=>'0');--ponemos a 0 el contador
                        wait_asm<=espera;
                    else 
                        wait_asm<=cuenta;
                    end if;
                when espera=>
                    int_reset<='0';--desactivamos reset
                    if rx='0' then--se recibe nuevo mensaje
                        wait_asm<=cuenta;--volvemos a iniciar el contador
                    else 
                        wait_asm<=espera;
                    end if;
                end case;
         end if;               
    end process;
    
    rx_done: process(reset, clk)--Proceso que genera señal done cuando recibe 8 bits completos por UART, sirve para ayudar a contar mejor los bytes recibidos
    begin
        if reset='1' then
            done_rx<='0';
            rx_busy_prev<='0';
        elsif rising_edge(clk) then
           if rx_busy='0' and rx_busy_prev='1' then--Ha terminado la recepcion del mensaje
                done_rx<='1';--activamos done 1 ciclo de reloj
            else
                done_rx<='0';
           end if;
           rx_busy_prev<=rx_busy;--actualizamos valor rx_busy previo
        end if;  
    end process;
    
    receptor_asm: process(clk,reset)
    begin
        if reset='1' then
            rx_asm<=espera_msg;--Por defecto espera un mensaje
            byte_count<=(others=>'0');--Contador de bytes a 0
            ena<='0';
            data_in<=(others=>'0');--entrada descifrador a 0
            data_reg<=(others=>'0');--Registro que guarda mensaje cifrado puesto a 0
            msg_err<='0';--Salidas a 0 
            msg_ok<='0';
            msg_no<='0';
            init_rgb<='0';
            stop<='0';
            control<="00";
            comando<=X"00";--Por defecto comando esta puesto a 0
            transicion<='0';
        elsif rising_edge (clk) then
            if int_reset='1' then--Reset interno activado
                rx_asm<=espera_msg;--Por defecto espera un mensaje
                byte_count<=(others=>'0');--Contador de bytes a 0
                ena<='0';
            else 
                case rx_asm is 
                    when espera_msg =>
                        init_rgb<='0';--Desactivado pintado de matriz
                        stop<='0';
                        if  rx='0' then--Recibe bit de start
                            rx_asm<=s0;
                            msg_err<='0';--Ponemos salidas de estado de mensaje a 0
                            msg_ok<='0';
                            msg_no<='0';
                            transicion<='0';
                        end if;
                    when s0 =>
                        if done_rx='1' then--Byte recibido 
                            destino<=rx_data;--Guardamos direccion de destino 
                            byte_count<=(others=>'0');--Reseteamos contador de bytes
                            data_reg<=(others=>'0');
                            rx_asm<=s1;
                        end if;
                    when s1 =>
                        if rx='0' then--Recibimos nuevo mensaje
                            rx_asm<=s2;
                        end if;
                    when s2 =>
                        if done_rx = '1' then--Byte recibido 
                            emisor<=rx_data;--Guardamos direccion del emisor
                            rx_asm<=s3;
                        end if;
                    when s3 =>
                        if rx='0' then--Nuevo mensaje
                            rx_asm<=s4;
                        end if;
                    when s4 =>
                        if done_rx='1' then--Byte recibido
                            data_reg<=rx_data & data_reg(63 downto 8);--Cargamos byte en el MSB del registro de mensaje cifrado
                            if byte_count=7 then--¿Hemos guardado 8 bytes?
                                rx_asm<=s5;--terminado
                            else 
                                byte_count<=byte_count+1;--incrementamos cuenta de bytes
                                rx_asm<=s3;--Volvemos a esperar al siguiente byte del mensaje
                            end if;
                        end if;
                    when s5 =>
                        if destino = origen then--¿Coinciden destino del mensaje y origen de este dispositivo?
                            data_in<=data_reg;--Este mensaje es para nosotros, lo cargamos en el descifrador
                            ena<='1';--Iniciamos descifrado
                            if ready='0' then--Procesando datos
                                rx_asm<=s6;
                            end if;
                        else 
                            msg_no<='1';--No es para nosotros
                            comando<=x"00";--Ponemos comando a 0
                            rx_asm<=espera_msg;--Esperamos nuevo mensaje
                        end if;
                    when s6 =>
                        ena<='0';
                        if ready='1' then--Mensaje descifrado
                            rx_asm<=s7;
                        end if;
                    when s7 =>
                        if plaintext(63 downto 48) = (destino & emisor) then--Destino y origen enviados coinciden con las direcciones del mensaje cifrado
                            msg_ok<='1';--Mensaje valido
                            comando<=plaintext(47 downto 40);--Ponemos comando en salida
                            if plaintext(47 downto 40)=x"07" then--Dibujo estatico
                                if control="11" then--Si estabamos en modo animacion primero debemos pararla
                                    stop<='1';--Activamos Stop
                                    init_rgb<='0';--Init no esta activo en este momento
                                    control<="10";--Ponemos el modo que queremos 
                                    rx_asm<=s8;
                                    transicion<='1';--Señal para activar stop durante 1 ciclo de reloj y posteriormente activar init 1 ciclo de reloj
                                elsif control="10" then--Estamos ya en este modo
                                    rx_asm<=espera_msg;--Pasamos a esperar el siguiente mensaje
                                else --Estabamos en otro modo
                                    stop<='0';
                                    control<="10";
                                    rx_asm<=s8;
                                end if;    
                            elsif plaintext(47 downto 40)=x"17" then --Modo animacion
                                if control="11" then--Ya estabamos en este modo
                                    rx_asm<=espera_msg;--Esperamos al siguiente mensaje
                                else 
                                    control<="11";--Ponemos modo en el controlador
                                    rx_asm<=s8;
                                    stop<='0';
                                end if;
                            elsif plaintext(47 downto 40)=x"00" then--Modo apagado de matriz
                                if control="11" then
                                    transicion<='1';
                                    stop<='1';
                                    init_rgb<='0';
                                    control<="00";
                                    rx_asm<=s8;
                                elsif control="00" then
                                    rx_asm<=espera_msg;
                                    stop<='0';
                                else 
                                    control<="00";
                                    rx_asm<=s8;
                                end if;
                            else--Otro comando diferente, no hacemos nada
                                rx_asm<=espera_msg;--Esperamos nuevo mensaje
                            end if;
                        else 
                            msg_err<='1';--Mensaje fraudulento
                            comando<=x"00";--Ponemos comando a 0
                            rx_asm<=espera_msg;--Esperamos nuevo mensaje
                        end if;
                    when s8=>
                        if transicion='1' then --Tuvimos que parar la animacion (stop estaba a 1)
                            stop<='0';--stop solo esta activo 1 ciclo de reloj
                            rx_asm<=s8;--Seguimos aqui
                            transicion<='0';
                        else 
                            init_rgb<='1';--Activamos init durante 1 ciclo de reloj
                            rx_asm<=espera_msg;--Pasamos a esperar al siguiente mensaje
                        end if;
                        
                end case;
            end if;
        end if;
    end process;
end Behavioral;
