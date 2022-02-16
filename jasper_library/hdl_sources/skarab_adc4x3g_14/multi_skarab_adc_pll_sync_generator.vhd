----------------------------------------------------------------------------------
-- Company: Peralex Electronics
-- Engineer: GT
-- 
-- Create Date: 05.09.2014 10:19:29
-- Design Name: 
-- Module Name: multi_skarab_adc_pll_sync_generator - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Generate SYNC signals with correct timing for ADC32RF45X2 mezzanine across multiple SKARABS.
--
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity multi_skarab_adc_pll_sync_generator is
	port (
        clk                     : in std_logic;
        reset                   : in std_logic;
        adc_sysref_clk          : in std_logic;
        adc_reference_input_clk : in std_logic;
        adc_sync_offset         : in std_logic_vector(3 downto 0); -- GT 15/9/2021 PROVIDE PROGRAMMABLE CONTROL OVER LOCATION OF ADC SYNC
        
        adc_sync_start          : in std_logic;
        adc_sync_part2_start    : in std_logic;
        adc_sync_part3_start    : in std_logic;
        pll_sync_start          : in std_logic;
        pll_pulse_generator_start   : in std_logic;
        sync_complete           : out std_logic;
        
        adc_soft_reset          : out std_logic;
        
        adc_pll_sync            : out std_logic;
        
        debug_sync_state : out std_logic_vector(2 downto 0));
end multi_skarab_adc_pll_sync_generator;

architecture arch_multi_skarab_adc_pll_sync_generator of multi_skarab_adc_pll_sync_generator is

    type T_GEN_SYNC_STATE is (
    IDLE,
	-- GT 14/9/2021 CHANGE TO FALLING EDGE
    WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_ASSERT_SYNC,
    WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_DEASSERT_SYNC,
    GEN_ADC_CORE_RESET,
    WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC,
    WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY, -- GT 14/9/2021
    WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC,
    WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY, -- GT 14/9/2021
    -- GT 7/9/2021 PULSE GENERATOR IS A PLL SYNC SO MUST BE PHASE ALIGNED TO REFERENCE (SINCE RESAMPLED ON BOARD by REFERENCE)
    --WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_PULSE_GEN_ASSERT_SYNC,
    --WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_PULSE_GEN_DEASSERT_SYNC);
    WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_ASSERT_SYNC,
    WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC);

    signal adc_sync_start_z1 : std_logic := '0';
    signal adc_sync_part2_start_z1 : std_logic := '0';
    signal adc_sync_part3_start_z1 : std_logic := '0';    
    signal pll_sync_start_z1 : std_logic := '0';
    signal pll_pulse_generator_start_z1 : std_logic := '0';
    
    signal adc_sysref_clk_z1 : std_logic := '0';
    signal adc_sysref_clk_z2 : std_logic := '0';
    signal adc_sysref_clk_z3 : std_logic := '0';
    signal adc_sysref_clk_z4 : std_logic := '0';
    
    signal adc_reference_input_clk_z1 : std_logic := '0';
    signal adc_reference_input_clk_z2 : std_logic := '0';
    signal adc_reference_input_clk_z3 : std_logic := '0';
    signal adc_reference_input_clk_z4 : std_logic := '0';
    
    signal current_gen_sync_state : T_GEN_SYNC_STATE;
    signal adc_pll_sync_i : std_logic;
    signal adc_soft_reset_i : std_logic;
    
    signal adc_reset_counter : std_logic_vector(7 downto 0);
    signal adc_reset_counter_reset : std_logic;
    
    signal pulse_gen_counter : std_logic_vector(8 downto 0); -- GT 14/9/2021 CHANGE WIDTH BECAUSE REFCLK FASTER THAN SYSREF
    signal pulse_gen_counter_reset : std_logic;
    signal pulse_gen_counter_inc : std_logic;
	
	signal sync_delay_counter : std_logic_vector(3 downto 0); -- GT 14/9/2021 ADD A DELAY TO ADC SYNC TO LOCATE IN MIDDLE OF LMFC
    signal sync_delay_counter_reset : std_logic;
    
	attribute ASYNC_REG : string;
	attribute ASYNC_REG of adc_sysref_clk_z1 : signal is "TRUE";        
	attribute ASYNC_REG of adc_sysref_clk_z2 : signal is "TRUE";
	attribute ASYNC_REG of adc_sysref_clk_z3 : signal is "TRUE";
	attribute ASYNC_REG of adc_sysref_clk_z4 : signal is "TRUE";
	attribute ASYNC_REG of adc_reference_input_clk_z1 : signal is "TRUE";        
	attribute ASYNC_REG of adc_reference_input_clk_z2 : signal is "TRUE";
	attribute ASYNC_REG of adc_reference_input_clk_z3 : signal is "TRUE";
	attribute ASYNC_REG of adc_reference_input_clk_z4 : signal is "TRUE";
    
begin

    gen_debug_sync_state : process(current_gen_sync_state)
    begin
        case current_gen_sync_state is
            when IDLE => debug_sync_state <= "000";
            when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_ASSERT_SYNC => debug_sync_state <= "001"; -- GT 14/9/2021
            when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_DEASSERT_SYNC => debug_sync_state <= "010"; -- GT 14/9/2021
            when GEN_ADC_CORE_RESET => debug_sync_state <= "011";
            when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC => debug_sync_state <= "100";
            when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY => debug_sync_state <= "100"; -- GT 14/9/2021
            when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC => debug_sync_state <= "101";
            when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY => debug_sync_state <= "101"; -- GT 14/9/2021
            when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_ASSERT_SYNC => debug_sync_state <= "110"; -- GT 7/9/2021
            when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC => debug_sync_state <= "111"; -- GT 7/9/2021
        end case;
    end process;

----------------------------------------------------------------------------------------------
-- REGISTER START SIGNALS TO DETECT START
----------------------------------------------------------------------------------------------

    gen_adc_pll_sync_start_z : process(clk)
    begin
        if (rising_edge(clk))then
            adc_sync_start_z1 <= adc_sync_start;
            adc_sync_part2_start_z1 <= adc_sync_part2_start;
            adc_sync_part3_start_z1 <= adc_sync_part3_start;
            pll_sync_start_z1 <= pll_sync_start;  
            pll_pulse_generator_start_z1 <= pll_pulse_generator_start; 
        end if;
    end process;

----------------------------------------------------------------------------------------------
-- TRIPLE REGISTER TIMING REFERENCE CLOCKS TO PREVENT METASTABILITY - MAY NEED A FIFO
----------------------------------------------------------------------------------------------

    gen_sync_timing_clks_z : process(clk)
    begin
        if (rising_edge(clk))then
            adc_sysref_clk_z1 <= adc_sysref_clk;
            adc_sysref_clk_z2 <= adc_sysref_clk_z1;
            adc_sysref_clk_z3 <= adc_sysref_clk_z2;
            adc_sysref_clk_z4 <= adc_sysref_clk_z3;

            adc_reference_input_clk_z1 <= adc_reference_input_clk;
            adc_reference_input_clk_z2 <= adc_reference_input_clk_z1;
            adc_reference_input_clk_z3 <= adc_reference_input_clk_z2;
            adc_reference_input_clk_z4 <= adc_reference_input_clk_z3;
        end if;
    end process;    

----------------------------------------------------------------------------------------------
-- STATE MACHINE TO GENERATE THE REQUIRED TIMING
----------------------------------------------------------------------------------------------

    gen_current_gen_sync_state : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                adc_pll_sync_i <= '0';
                pulse_gen_counter_inc <= '0';
                adc_soft_reset_i <= '0';
                current_gen_sync_state <= GEN_ADC_CORE_RESET; -- DO A RESET OF JESD CORES ON STARTUP
            else        
                pulse_gen_counter_inc <= '0';
                adc_soft_reset_i <= '0';
    
                case current_gen_sync_state is
                    when IDLE =>
                    current_gen_sync_state <= IDLE;
        
                    if ((pll_sync_start_z1 = '0')and(pll_sync_start = '1'))then
                        current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_ASSERT_SYNC; -- GT 14/9/2021
                    elsif ((adc_sync_start_z1 = '0')and(adc_sync_start = '1'))then
                        current_gen_sync_state <= GEN_ADC_CORE_RESET;
                    elsif ((adc_sync_part2_start_z1 = '0')and(adc_sync_part2_start = '1'))then
                        current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC;
                    elsif ((adc_sync_part3_start_z1 = '0')and(adc_sync_part3_start = '1'))then
                        current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC;
                    elsif ((pll_pulse_generator_start_z1 = '0')and(pll_pulse_generator_start = '1'))then
                        -- GT 7/9/2021 current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_PULSE_GEN_ASSERT_SYNC;
                        current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_ASSERT_SYNC;
                    end if;
                    
                    -- GT 14/9/2021 CHANGE TO RISING EDGE OF REFCLK
					when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_ASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_ASSERT_SYNC;
        
                    -- RISING EDGE OF REFERENCE CLOCK INPUT
                    -- INVERSION RESULT OF HARDWARE
                    if ((adc_reference_input_clk_z4 = '1')and(adc_reference_input_clk_z3 = '0'))then
                        adc_pll_sync_i <= '1';
                        current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_DEASSERT_SYNC;
                    end if;
                    
                    -- GT 14/9/2021 CHANGE TO RISING EDGE OF REFCLK
					when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_DEASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_DEASSERT_SYNC;
        
                    -- RISING EDGE OF REFERENCE CLOCK INPUT
                    if ((adc_reference_input_clk_z4 = '1')and(adc_reference_input_clk_z3 = '0'))then
                        adc_pll_sync_i <= '0';
                        current_gen_sync_state <= IDLE;
                    end if;
            
                    when GEN_ADC_CORE_RESET =>
                    current_gen_sync_state <= GEN_ADC_CORE_RESET;
        
                    adc_soft_reset_i <= '1';
    
                    if (adc_reset_counter = X"FF")then
                        current_gen_sync_state <= IDLE;
                    end if;
                    
                    -- GT 14/9/2021 CHANGE TO A DELAYED ADC SYNC RELATIVE TO SYSREF TO LOCATE IN MIDDLE OF LMFC
                    when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC;
                    
                    -- FALLING EDGE OF SYSREF
                    if ((adc_sysref_clk_z4 = '1')and(adc_sysref_clk_z3 = '0'))then
                        --adc_pll_sync_i <= '1';
                        --current_gen_sync_state <= IDLE;
                        current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY;
                    end if;

                    when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY =>
                    current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY;
                    
                    if (sync_delay_counter = adc_sync_offset)then
                        adc_pll_sync_i <= '1';
                        current_gen_sync_state <= IDLE;
                    end if;
                    
                    -- GT 14/9/2021 CHANGE TO A DELAYED ADC SYNC RELATIVE TO SYSREF TO LOCATE IN MIDDLE OF LMFC
                    when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC;
                    
                    -- FALLING EDGE OF SYSREF
                    if ((adc_sysref_clk_z4 = '1')and(adc_sysref_clk_z3 = '0'))then
                        --adc_pll_sync_i <= '0';
                        --current_gen_sync_state <= IDLE;
                       current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY;
                    end if;

                    when WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY =>
                    current_gen_sync_state <= WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY;
                    
                    -- FALLING EDGE OF SYSREF
                    if (sync_delay_counter = adc_sync_offset)then
                        adc_pll_sync_i <= '0';
                        current_gen_sync_state <= IDLE;
                    end if;
        
                    -- GT 7/9/2021 CHANGE TO REFERENCE INPUT CLOCK FOR SYSREF PULSE GENERATOR
                    when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_ASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_ASSERT_SYNC;
                    
                    -- RISING EDGE OF REFERENCE CLOCK INPUT
                    -- INVERSION RESULT OF HARDWARE
                    if ((adc_reference_input_clk_z4 = '1')and(adc_reference_input_clk_z3 = '0'))then
                        adc_pll_sync_i <= '1';
                        current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC;
                    end if;
                    
                    when WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC =>
                    current_gen_sync_state <= WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC;
        
                    -- RISING EDGE OF REFERENCE CLOCK INPUT
                    -- INVERSION RESULT OF HARDWARE
                    if ((adc_reference_input_clk_z4 = '1')and(adc_reference_input_clk_z3 = '0'))then
                        if (pulse_gen_counter = "111111111")then
                            adc_pll_sync_i <= '0';
                            current_gen_sync_state <= IDLE;
                        else
                            pulse_gen_counter_inc <= '1';
                        end if;
                    end if;
        
                end case;
            end if;
        end if;
    end process;

    sync_complete <= '1' when (current_gen_sync_state = IDLE) else '0';    
    adc_reset_counter_reset <= '0' when (current_gen_sync_state = GEN_ADC_CORE_RESET) else '1';
    pulse_gen_counter_reset <= '0' when (current_gen_sync_state = WAIT_UNTIL_RISING_EDGE_REFERENCE_INPUT_CLK_PULSE_GEN_DEASSERT_SYNC) else '1'; -- GT 7/9/2021
    sync_delay_counter_reset <= '0' when ((current_gen_sync_state = WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_ASSERT_SYNC_DELAY)or(current_gen_sync_state = WAIT_UNTIL_FALLING_EDGE_SYSREF_CLK_DEASSERT_SYNC_DELAY)) else '1'; -- GT 14/9/2021
    
    gen_adc_reset_counter : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                adc_reset_counter <= (others => '0');
            else
                if (adc_reset_counter_reset = '1')then
                    adc_reset_counter <= (others => '0');
                else
                    adc_reset_counter <= adc_reset_counter + X"01";
                end if;
            end if;
        end if;
    end process;

    gen_pulse_gen_counter : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                pulse_gen_counter <= (others => '0');
            else
                if (pulse_gen_counter_reset = '1')then
                    pulse_gen_counter <= (others => '0');
                else
                    if (pulse_gen_counter_inc = '1')then
                        pulse_gen_counter <= pulse_gen_counter + "000000001"; -- GT 14/9/2021
                    end if;
                end if;
            end if;
        end if;
    end process;
  
    -- GT 14/9/2021 PROVIDE DELAY BETWEEN SYSREF AND LOCATION OF SYNC CHANGE
    gen_sync_delay_counter : process(clk)
    begin
        if (rising_edge(clk))then
            if (reset = '1')then
                sync_delay_counter <= (others => '0');
            else
                if (sync_delay_counter_reset = '1')then
                    sync_delay_counter <= (others => '0');
                else
                    sync_delay_counter <= sync_delay_counter + "0001";
                end if;
            end if;
        end if;
    end process;
        
----------------------------------------------------------------------------------------------
-- REGISTER OUTPUT TO IMPROVE TIMING
----------------------------------------------------------------------------------------------

    gen_adc_pll_sync : process(clk)
    begin
        if (rising_edge(clk))then
            adc_pll_sync <= adc_pll_sync_i;
        end if;
    end process;
    
    gen_adc_soft_reset : process(clk)
    begin
        if (rising_edge(clk))then
            adc_soft_reset <= adc_soft_reset_i;
        end if;
    end process;

end arch_multi_skarab_adc_pll_sync_generator;
