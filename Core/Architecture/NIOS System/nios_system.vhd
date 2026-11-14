---------------------------------
-- Group 13 - Laboratory 6
-- NIOS V system and custom DACs peripheral
-- VHDL code of top-level entity
------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY nios_system IS
	PORT (
		CLOCK_50 : IN  STD_LOGIC;
		KEY      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		LEDR     : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
		HEX0     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		HEX1     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		GPIO_0   : OUT STD_LOGIC_VECTOR(35 DOWNTO 0)
	);
END ENTITY nios_system;

ARCHITECTURE structural OF nios_system IS
	-- Signals from Platform Designer
	SIGNAL w_val_out  : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- 8-bit value for DAC modules
	SIGNAL w_freq_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);  -- Frequency selection
	
	-- Output signals from modulation modules
	SIGNAL w_pwm_out  : STD_LOGIC;  -- PWM output
	SIGNAL w_ppm_out  : STD_LOGIC;  -- PPM output
	
	SIGNAL sys_clk    : STD_LOGIC;
	SIGNAL sys_rst_n  : STD_LOGIC;
	
	-- Platform Designer component with Nios V processor
	COMPONENT platformdesigner IS
		PORT (
			clk_clk         : IN  STD_LOGIC := 'X';
			reset_reset_n   : IN  STD_LOGIC := 'X';
			val_out_export  : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			freq_sel_export : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			leds_export     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			hex0_export     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
			hex1_export     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
		);
	END COMPONENT platformdesigner;

	-- PWM modulation component
	COMPONENT dac_pwm IS
		PORT (
			CLK      : IN  STD_LOGIC;
			ARST_n   : IN  STD_LOGIC;
			ENABLE   : IN  STD_LOGIC;
			FREQ_SEL : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			DAC_IN   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			DAC_OUT  : OUT STD_LOGIC
		);
	END COMPONENT;

	-- PPM modulation component
	COMPONENT ppm_top IS
		GENERIC (
			DATA_WIDTH : INTEGER := 8
		);
		PORT (
			digital_in    : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
			clk           : IN  STD_LOGIC;
			rstn          : IN  STD_LOGIC;
			freq_sel      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
			Bitstream_out : OUT STD_LOGIC
		);
	END COMPONENT;

BEGIN
	-- Clock and reset assignment
	sys_clk   <= CLOCK_50;
	sys_rst_n <= KEY(0);

	-- Platform Designer instantiation
	u0 : COMPONENT platformdesigner
		PORT MAP(
			clk_clk         => sys_clk,
			reset_reset_n   => sys_rst_n,
			val_out_export  => w_val_out,
			freq_sel_export => w_freq_sel,
			leds_export     => LEDR(1 DOWNTO 0),
			hex0_export     => HEX0,
			hex1_export     => HEX1
		);

	-- PWM modulator instantiation
	inst_pwm : COMPONENT dac_pwm
		PORT MAP(
			CLK      => sys_clk,
			ARST_n   => sys_rst_n,
			ENABLE   => '1',
			FREQ_SEL => w_freq_sel,
			DAC_IN   => w_val_out,
			DAC_OUT  => w_pwm_out
		);

	-- PPM modulator instantiation
	inst_ppm : COMPONENT ppm_top
		GENERIC MAP(
			DATA_WIDTH => 8
		)
		PORT MAP(
			clk           => sys_clk,
			rstn          => sys_rst_n,
			freq_sel      => w_freq_sel,
			digital_in    => w_val_out,
			Bitstream_out => w_ppm_out
		);

	-- GPIO assignments: PWM on pin 0, PPM on pin 1
	GPIO_0(0)           <= w_pwm_out;
	GPIO_0(1)           <= w_ppm_out;
	GPIO_0(35 DOWNTO 2) <= (OTHERS => '0');
	
	-- Unused LEDs
	LEDR(9 DOWNTO 2)    <= (OTHERS => '0');

END ARCHITECTURE structural;