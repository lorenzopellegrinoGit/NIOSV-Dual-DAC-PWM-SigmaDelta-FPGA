---------------------------------
-- Group 13 - Laboratory 6
-- DAC PWM Testbench
-- VHDL testbench for DAC_PWM
------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dac_pwm_tb IS
END ENTITY dac_pwm_tb;

ARCHITECTURE testbench OF dac_pwm_tb IS

	COMPONENT DAC_PWM IS
		PORT (
			CLK       : IN  STD_LOGIC;
			ARST_n    : IN  STD_LOGIC;
			ENABLE    : IN  STD_LOGIC;
			FREQ_SEL  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			DigitalIN : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			AnalogOUT : OUT STD_LOGIC
		);
	END COMPONENT;

	SIGNAL CLK          : STD_LOGIC                    := '0';
	SIGNAL ARST_n       : STD_LOGIC                    := '0';
	SIGNAL ENABLE       : STD_LOGIC                    := '0';
	SIGNAL FREQ_SEL     : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	SIGNAL DigitalIN    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL AnalogOUT    : STD_LOGIC;

BEGIN

	clk_gen: PROCESS
  BEGIN
    CLK <= not CLK;
    wait for 10 ns;
  END PROCESS;

	-- DUT instantiation
	DUT : DAC_PWM
	PORT MAP(
		CLK       => CLK,
		ARST_n    => ARST_n,
		ENABLE    => ENABLE,
		FREQ_SEL  => FREQ_SEL,
		DigitalIN => DigitalIN,
		AnalogOUT => AnalogOUT
	);

	test_process : PROCESS
	BEGIN

		-- Reset
		WAIT FOR 100 ns;
		ARST_n    <= '1';

		-- Test different duty cycles at 400 kHz
		ENABLE    <= '1';
		FREQ_SEL  <= "00";

		DigitalIN <= "10000000"; -- 50% duty cycle
		WAIT FOR 15 us;

		DigitalIN <= "01000000"; -- 25% duty cycle
		WAIT FOR 15 us;

		DigitalIN <= "11000000"; -- 75% duty cycle
		WAIT FOR 15 us;

		-- Test different frequencies at 50% duty cycle
		DigitalIN <= "10000000";

		FREQ_SEL  <= "01"; -- 200 kHz
		WAIT FOR 30 us;

		FREQ_SEL <= "10"; -- 100 kHz
		WAIT FOR 60 us;

		FREQ_SEL <= "11"; -- 50 kHz
		WAIT FOR 100 us;

		-- Test edge cases
		FREQ_SEL  <= "00";

		DigitalIN <= "00000000"; -- 0% duty cycle
		WAIT FOR 20 us;

		DigitalIN <= "11111111"; -- 100% duty cycle
		WAIT FOR 20 us;

		-- Test enable control
		ENABLE <= '0';
		WAIT FOR 10 us;

		ENABLE <= '1';
		WAIT FOR 15 us;

		WAIT;

	END PROCESS;

END ARCHITECTURE testbench;