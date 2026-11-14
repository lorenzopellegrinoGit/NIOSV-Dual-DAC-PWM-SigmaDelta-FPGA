
---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PPM version)
-- VHDL code of delta-sigma adder
------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY sigma_delta_adder IS
	GENERIC (
		DATA_WIDTH : INTEGER := 8
	);
	PORT (
		datain      : IN  STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
		accum_value : IN  STD_LOGIC_VECTOR(DATA_WIDTH + 1 DOWNTO 0);
		ddc         : IN  STD_LOGIC; -- Digital Delta Comparator output
		dataout     : OUT STD_LOGIC_VECTOR(DATA_WIDTH + 1 DOWNTO 0)
	);
END sigma_delta_adder;

ARCHITECTURE Behavioral OF sigma_delta_adder IS
	CONSTANT ACC_WIDTH : INTEGER := DATA_WIDTH + 2;
	SIGNAL s_data_ext  : signed(ACC_WIDTH - 1 DOWNTO 0);
	SIGNAL s_accum     : signed(ACC_WIDTH - 1 DOWNTO 0);
	SIGNAL s_max_val   : signed(ACC_WIDTH - 1 DOWNTO 0);
	SIGNAL s_result    : signed(ACC_WIDTH - 1 DOWNTO 0);
BEGIN
	s_data_ext <= signed("00" & datain);
	s_accum    <= signed(accum_value);
	s_max_val  <= to_signed((2 ** DATA_WIDTH) - 1, ACC_WIDTH); -- Full scale value

	-- Sigma-delta modulator adder
	PROCESS (s_accum, s_data_ext, ddc, s_max_val)
	BEGIN
		IF (ddc = '1') THEN
			-- Subtract full scale when output is high
			s_result <= s_accum + s_data_ext - s_max_val;
		ELSE
			-- Normal accumulation
			s_result <= s_accum + s_data_ext;
		END IF;
	END PROCESS;
	
	dataout <= STD_LOGIC_VECTOR(s_result);

END Behavioral;