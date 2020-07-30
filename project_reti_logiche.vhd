-- Politecnico di Milano
-- Silvia Locarno, Luca Leoni
-- Matricole 889442, 889638
-- Prova finale di reti logiche 2020
-----------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------
-- Entity progetto di reti logiche
-------------------------------------------------------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR(7 downto 0);
           o_address : out STD_LOGIC_VECTOR(15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR(7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
type state_type is (
START, 
WRITE_ADDR,
LOAD_WZ, 
WRITE_WZ,
WRITE_MEM,
WAIT_MEM, 
DONE, 
WAIT_DONE
);
signal CURRENT_STATE, P_STATE: state_type; --variabili che tengono conto del cambiamento di stato

begin
    process(i_clk, i_rst)
    
-- variabili

    variable MI: std_logic_vector(7 downto 0); --vettore per contenere valore di ingresso
    variable MO: std_logic_vector(7 downto 0); --vettore per contenere il valore d'uscita
    variable diff: integer range 0 to 127; --differenza tra MI e indirizzo base wz per trovare l'offset
    variable i: std_logic_vector(2 downto 0); --indica il numero di wz in binario
    variable n_wz: integer range 0 to 8; --contatore wz
    variable MI_DEC: integer range 0 to 127;
    variable MO_DEC: integer range 0 to 127;
    
    
begin 

-- Architecture Progetto Reti Logiche

if(i_rst = '1') then --Nel caso arrivi un segnale di reset, resetta le variabili
    o_en <= '0'; --riporta 0 il segnale di lettura a memoria
    o_we <= '0'; --riporta a 0 il segnale di scrittura a memoria
    o_done <= '0'; --riporta a 0 il segnale di fine elaborazione
    n_wz := 0;
    MO := "00000000";
    diff := 127; --differenza max
    CURRENT_STATE <= START; --riporta la macchina allo stato iniziale

elsif(rising_edge(i_clk)) then --Se è passato un ciclo di clock e sono sul fronte di salita
    case CURRENT_STATE is --Definiamo gli stati
    
        when START => --In questo stato aspetto il segnale di start
            if(i_start= '1' AND i_rst = '0') then
                o_en <= '1'; --mi permette di leggere sulla memoria
                o_we <= '0';
                o_address <= std_logic_vector(to_unsigned(8, 16));
                P_STATE <= START;
                CURRENT_STATE <= WAIT_MEM; --Stato corrente
            else
                CURRENT_STATE <= START;
            end if;
            
        when WAIT_MEM =>
            if P_STATE = START then
                CURRENT_STATE <= WRITE_ADDR;
            elsif P_STATE = LOAD_WZ then
                CURRENT_STATE <= WRITE_WZ;
            end if;
            
        when WRITE_ADDR => 
            MI := i_data;
            --report "** MI: " & integer'image(to_integer(unsigned(i_data)));
            n_wz := 0;
            CURRENT_STATE <= LOAD_WZ;
           
        when LOAD_WZ =>
            i := std_logic_vector(to_unsigned(n_wz, 3));
            o_address <= std_logic_vector(to_unsigned(n_wz, 16)); --punto alla working zone numero n_wz
            P_STATE <= LOAD_WZ;
            CURRENT_STATE <= WAIT_MEM;
            
        when WRITE_WZ =>
            MO := i_data;
            --report "** MO: " & integer'image(to_integer(unsigned(i_data)));
            CURRENT_STATE <= WRITE_MEM;
        
        when WRITE_MEM =>
            --MI_DEC := conv_integer(MI);
            --MO_DEC := conv_integer(MO);
            MI_DEC := to_integer(unsigned(MI));
            MO_DEC := to_integer(unsigned(MO));
            diff := MI_DEC - MO_DEC; 
            if(diff = 3) then
                o_we <= '1'; --mi permette di scrivere sulla memoria
                o_data <= ('1' & i(2 downto 0) & "1000");
                o_address <= std_logic_vector(to_unsigned(9, 16));
                CURRENT_STATE <= DONE;
            elsif(diff = 2) then
                o_we <= '1';
                o_data <= ('1' & i(2 downto 0) & "0100");
                o_address <= std_logic_vector(to_unsigned(9, 16));
                CURRENT_STATE <= DONE;
            elsif(diff = 1) then
                o_we <= '1';
                o_data <= ('1' & i(2 downto 0) & "0010");
                o_address <= std_logic_vector(to_unsigned(9, 16));
                CURRENT_STATE <= DONE;
            elsif(diff = 0) then
                o_we <= '1';
                o_data <= ('1' & i(2 downto 0) & "0001");
                o_address <= std_logic_vector(to_unsigned(9, 16));
                CURRENT_STATE <= DONE;
            else
                n_wz := n_wz+1; 
                if(n_wz>7)then
                    o_we <= '1';
                    o_data <= MI;
                    --o_data(7) <= '0';
                    --o_data(6 downto 0) <= i_data;
                    o_address <= std_logic_vector(to_unsigned(9, 16));
                    CURRENT_STATE <= DONE;
                else
                    CURRENT_STATE <= LOAD_WZ;
                end if;
            end if;
                                        
        when DONE =>
            o_we <= '0';  --disabilito la scrittura
            o_en <= '0';  --disabilito la lettura
            o_done <= '1'; --Alzo il segnale di done
            CURRENT_STATE <= WAIT_DONE;
              
        when WAIT_DONE =>
            if(i_start = '0') then --attendo che start si abbassi per abbassare done
                    o_done <= '0'; --abbasso done
                    CURRENT_STATE <= START; --torno allo stato iniziale
            else
                CURRENT_STATE <= WAIT_DONE;
            end if;           
    end case;
end if;
end process;
end Behavioral;