----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.05.2026 22:03:51
-- Design Name: 
-- Module Name: uart_limon - Behavioral
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

entity uart_limon is
    generic(
        clk_freq: integer := 100_000_000;
        baud_rate: integer :=19_200;
        d_bits: integer :=8;
        parity: integer :=0;--0 no parity, 1 parity
        parity_type: std_logic:='0'--0 even parity, 1 odd parity
        );
    port(
        clk,reset,tx_ena,rx: in std_logic;
        tx_data: in std_logic_vector(d_bits-1 downto 0);
        rx_done, rx_error, tx_done, tx: out std_logic;
        rx_data: out std_logic_vector(d_bits-1 downto 0)
        );       
end uart_limon;

architecture Behavioral of uart_limon is
    constant os_cycles: integer:= clk_freq/(16*baud_rate);--cada cuanto hay que samplear rx
    type rx_machine is (idle,data);
    type tx_machine is (idle,send);
    signal rx_state: rx_machine;
    signal tx_state: tx_machine;
    signal rx_buffer: std_logic_vector (d_bits+parity downto 0);--bits de datos + paridad + start
    signal tx_buffer: std_logic_vector (d_bits+parity+2 downto 0);--1 + start + datos + paridad + stop 
    signal ena_tick: std_logic;--enable para coger punto medio del bit
    signal s_ticks: integer range 0 to 15;--contador de ticks de os
    signal os_count: integer range 0 to os_cycles-1;--cada cuanto se activa el enable
    signal data_bit: integer range 0 to d_bits + parity;--contador de bits recibidos
    signal tx_count: integer range 0 to d_bits+parity+3;--datos,paridad,start y stop
    signal ena_trans: std_logic;
    signal trans_count: integer range 0 to 15;--contador de ena_ticks para mandar bit de transmision
    signal parity_chain_rx,parity_chain_tx : std_logic_vector(d_bits downto 0);
    signal parity_error: std_logic;
begin
    oversampling_process: process(reset,clk)--Baud rate signal generator
    begin
        if reset='1' then
            ena_tick<='0';
            os_count<=0;
            ena_trans<='0';
            trans_count<=0;
        elsif rising_edge (clk) then
            ena_trans<='0';
            if os_count<os_cycles-1 then
                os_count<=os_count+1;
                ena_tick<='0';
            else 
                os_count<=0;
                ena_tick<='1';
            end if;
            if tx_state=idle then
                trans_count<=0;
                ena_trans<='0';
            elsif ena_tick='1' then
                if trans_count < 15 then
                    trans_count<=trans_count+1;
                else 
                    trans_count<=0;
                    ena_trans<='1';
                end if;
            end if;
        end if;
    end process;
    
    rx_process:process(clk,reset)
    begin
        if reset='1' then
            rx_buffer<=(others=>'0');
            s_ticks<=0;
            data_bit<=0;
            rx_error<='0';
            rx_done<='0';
            rx_state<=idle;
            rx_data<=(others=>'0');
        elsif rising_edge (clk) then
            rx_done<='0';
            if ena_tick='1' then--Flanco de reloj y flanco de oversampling
                case rx_state is
                    when idle=>
                        if rx='0' then--bit de start
                            if s_ticks < 7 then
                                s_ticks<=s_ticks+1;
                                rx_state<=idle;
                            else --Estamos en el punto medio del bit de start
                                s_ticks<=0;
                                data_bit<=0;
                                rx_buffer<=rx & rx_buffer(d_bits+parity downto 1);--Guardamos bit de start
                                rx_state<=data;
                            end if;
                        else 
                            s_ticks<=0;
                            rx_state<=idle;
                        end if;
                    when data=>--Ha recibir los bits de datos
                        if s_ticks<15 then
                            s_ticks<=s_ticks+1;
                            rx_state<=data;
                        else --Punto medio del bit
                            s_ticks<=0;--reseteamos cuenta de ticks de oversampling
                            if data_bit < d_bits+parity then--todavia no hemos recibido todos los bits
                                rx_buffer<=rx & rx_buffer(d_bits+parity downto 1);--guardamos bit de dato
                                data_bit<=data_bit+1;--incrementamos cuenta de bits de datos
                                rx_state<=data;
                            else 
                                rx_data<=rx_buffer(d_bits downto 1);
                                rx_done<='1';
                                rx_state<=idle;
                                rx_error<=parity_error or rx_buffer(0) or (not rx);--error rx sera la or del error de paridad, bit de start y bit de stop
                            end if;
                        end if;                                 
                end case;
            end if;
        end if;
    end process;
    --Calculo de paridad en RX
    parity_chain_rx(0)<=parity_type;--el primer bit de la cadena de paridad sera el tipo de paridad programado
    gen_parity: for i in 0 to d_bits-1 generate
        parity_chain_rx(i+1)<=parity_chain_rx(i) xor rx_buffer(i+1);--siguiente bit de paridad sera bit anterior xor bit recibido
    end generate;
    with parity select
        parity_error<=parity_chain_rx(d_bits) xor rx_buffer(d_bits+parity) when 1,--error de paridad sera la xor de paridad calculada y paridad recibida
                      '0' when others;--no hay paridad, no hay error
    --Calculo paridad TX
    parity_chain_tx(0)<=parity_type;
    gen:for i in 0 to d_bits-1 generate
        parity_chain_tx(i+1)<=parity_chain_tx(i) xor tx_data(i);
    end generate;
    tx_process:process(clk,reset)
    begin
        if reset='1' then
            tx_buffer<=(others=>'1');
            tx_state<=idle;
            tx_done<='0';
            tx_count<=0;
            tx<='1';
        elsif rising_edge(clk) then
            case tx_state is
                when idle=>
                    if tx_ena='1' then 
                        tx_buffer(d_bits+1 downto 0)<=tx_data & '0'&'1';--cargamos datos a transmitir y bit de start en el buffer
                        if parity = 1 then
                            tx_buffer(d_bits+parity+1)<=parity_chain_tx(d_bits);--si hay paridad metemos la paridad calculada
                        end if;
                        tx_count<=0;
                        tx_done<='0';
                        tx_state<=send;
                    else
                        tx_done<='1';
                        tx_state<=idle;
                    end if;
                when send=>
                    if ena_trans='1' then--16 ticks de os
                        if tx_count < d_bits+parity+3 then
                            tx_count<=tx_count+1;--incrementamos numero de bits enviados
                            tx_state<=send;
                        else 
                            tx_state<=idle;
                        end if;
                        tx_buffer<='1' & tx_buffer(d_bits+parity+2 downto 1);--desplazamos buffer de bits enviados
                    end if;
            end case;
            tx<=tx_buffer(0);    
        end if;
    end process;
end Behavioral;
