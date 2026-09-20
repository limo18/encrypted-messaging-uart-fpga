----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.03.2026 11:13:01
-- Design Name: 
-- Module Name: emisor_cifr - Behavioral
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

entity emisor_cifr is
--  Port ( );
    generic(
        origen: std_logic_vector(7 downto 0):= X"07";
        clave: std_logic_vector(79 downto 0):=X"F0DDA02026000000FC08"
        );
    port(
        clk, reset, init: in std_logic;
        addr_dest, comando: in std_logic_vector(7 downto 0);
        tx: out std_logic
        );
end emisor_cifr;

architecture Behavioral of emisor_cifr is
    signal cont: unsigned(7 downto 0);
    type emision is (idle, s0, s1, s2, s3, s4, s5, s6);
    signal emisor_state: emision;--State machine
    signal plaintext: std_logic_vector (63 downto 0);--Mensaje (Dir. dest (8) | Dir. orig (8)| Comando (8)| Num aleatorio (8)| 32 0s) 
    signal byte_count: unsigned (2 downto 0);--contador de bytes enviados por tx
    -- PRESENT SIGNALS
    signal ena, ready: std_logic;
    signal data_in, ciphertext: std_logic_vector(63 downto 0);
    constant key: std_logic_vector(127 downto 0) := X"000000000000" & clave;--Key (48 0s + key de 80 bits)
    -- UART SIGNALS
    signal reset_n, tx_ena, tx_busy: std_logic;
    signal tx_data: std_logic_vector(7 downto 0);
    -- REG SIGNAL
    signal send_reg: std_logic_vector(63 downto 0);--Guarda mensaje cifrado a enviar por UART
begin
--En este trabajo 2 se ha eliminado el nivel de jerarquia innecesario de registros que estaba en el trabajo 1 (diseños reg_emi y reg_recept) y se ha implementado
-- dentro de cada diseño su propio registro (en este diseño send_reg) sin necesidad de diseños adicionales
--INSTANCIACIONES
    reset_n<=not(reset);
    cifr: entity work.present
        port map( 
            clk=>clk,
            rst=>reset,
            ena=>ena,
            mode_sel=>"00",--Key de 80bits en modo cifrador
            key=>key,
            data_in=>data_in,
            data_out=>ciphertext,
            ready=>ready
            );
    uart_comp: entity work.uart
        port map( 
            clk=>clk,
            reset_n=>reset_n,
            tx_ena=>tx_ena,
            tx_data=>tx_data,
            rx=>'1',--UART en modo transmisor, no usaremos el modo receptor
            rx_busy=>open,
            rx_error=>open,
            rx_data=>open,
            tx_busy=>tx_busy,
            tx=>tx
            );
--PROCESOS
    random: process(clk,reset)--Contador de 8 bits con el que obtenemos el numero aleatorio para el plaintext
    begin
        if reset='1' then
            cont<=(others=>'0');
        elsif rising_edge (clk) then
            cont<=cont+1;
        end if;
    end process;
    
    state_machine:process(clk,reset)
    begin
        if reset='1' then
            plaintext<=(others=>'0');
            ena<='0';
            tx_ena<='0';
            tx_data<=x"00";
            byte_count<=(others=>'0');
            emisor_state<=idle;
            send_reg<=(others=>'0');
        elsif rising_edge(clk) then
            case emisor_state is 
                when idle=>
                    if  init  ='1' then--Inicio de mensaje activado
                        byte_count<=(others=>'0');--Reseteamos contador de bytes
                        plaintext<=addr_dest & origen & comando & std_logic_vector(cont) & X"00000000";--Montamos plaintext
                        emisor_state<=s0;
                    end if;
                when s0=>
                    data_in<=plaintext;--Cargamos plaintext en cifrador
                    ena<='1';--Iniciamos cifrado
                    if ready='0' then--Procesando datos
                        emisor_state<=s1;
                    end if;
                when s1=>
                    ena<='0';
                    if ready='1' and tx_busy='0' then--Cifrador ha terminado de procesar datos
                        tx_data<=addr_dest;--Enviamos primero la direccion de destino
                        tx_ena<='1';
                        send_reg<=ciphertext;--Cargamos mensaje cifrado en registro para poder enviar por UART
                        emisor_state<=s2;
                    end if;
                when s2=>
                    tx_ena<='0';
                    emisor_state<=s3;
                when s3=>
                    if tx_busy='0' then--Transmision finalizada
                        tx_data<=origen;--Enviamos direccion de origen
                        tx_ena<='1';
                        emisor_state<=s4;
                    end if;
                when s4=>
                    tx_ena<='0';
                    emisor_state<=s5;
                when s5=>
                    if tx_busy = '0' then--Transmision finalizada
                        tx_data<=send_reg(7 downto 0);--Enviamos los 8 lsb del mensaje cifrado
                        tx_ena<='1';
                        send_reg<=x"00" & send_reg(63 downto 8);--Actualizamos registro
                        emisor_state<=s6;
                    end if;
                when s6=>
                    tx_ena<='0';
                    if tx_busy = '0' then--Transmision de byte finalizada
                        if byte_count=7 then--Registro vacio
                            emisor_state<=idle;--Transmision de mensaje completo finalizada
                        else --Faltan datos por enviar
                            byte_count<=byte_count+1;--Incrementamos numero de bytes enviados
                            emisor_state<=s5;--mandamos siguiente byte del registro
                        end if;
                    end if;
                end case;
        end if; 
    end process;            
end Behavioral;
