---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PPM version)
-- VHDL code of DAC PPM
------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ppm_top IS
	GENERIC (
		DATA_WIDTH : INTEGER := 8
	);
	PORT (
		digital_in : std_logic_vector(7 DOWNTO 0);
		clk, rstn : IN std_logic;
		freq_sel : IN std_logic_vector(1 DOWNTO 0);
		Bitstream_out : OUT std_logic
	);
END ppm_top;

ARCHITECTURE structural OF ppm_top IS
	SIGNAL output_reg, add_out : std_logic_vector(9 DOWNTO 0);
	SIGNAL comp_out, reg_enable : std_logic;
	COMPONENT sigma_delta_adder IS
		GENERIC (
			DATA_WIDTH : INTEGER
		);
		PORT (
			datain : IN std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
			accum_value : IN std_logic_vector(DATA_WIDTH + 1 DOWNTO 0);
			ddc : IN std_logic;
			dataout : OUT std_logic_vector(DATA_WIDTH + 1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT ppm_freq_generator IS
		PORT (
			clk : IN STD_LOGIC;
			reset_n : IN STD_LOGIC;
			freq_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			pulse_out : OUT STD_LOGIC
		);
	END COMPONENT;
 
	COMPONENT ppm_register IS
		PORT (
			clk : IN STD_LOGIC;
			reset_n : IN STD_LOGIC;
			enable : IN STD_LOGIC;
			data_in : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			data_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT ppm_comparator IS
		PORT (
			data_in : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			bitstream : OUT STD_LOGIC 
		);
	END COMPONENT;

BEGIN
	freqselector : ppm_freq_generator
	PORT MAP(
		clk => clk, 
		reset_n => rstn, 
		freq_sel => freq_sel, 
		pulse_out => reg_enable
	);
 
 
	adders : sigma_delta_adder
		GENERIC MAP(
		DATA_WIDTH => DATA_WIDTH)
		PORT MAP(
			datain => digital_in, 
			accum_value => output_reg, 
			ddc => comp_out, 
			dataout => add_out
		);
 
			reg : ppm_register
			PORT MAP(
				clk => clk, 
				reset_n => rstn, 
				enable => reg_enable, 
				data_in => add_out, 
				data_out => output_reg
	);
 
	comp : ppm_comparator
	PORT MAP(
		data_in => output_reg, 
		bitstream => comp_out
	);
	Bitstream_out <= comp_out;

END structural;