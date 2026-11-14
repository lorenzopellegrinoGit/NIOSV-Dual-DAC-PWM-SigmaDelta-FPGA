---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PPM version)
-- VHDL code of register
------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ppm_register IS
	PORT (
		clk      : IN  STD_LOGIC;
		reset_n  : IN  STD_LOGIC;
		enable   : IN  STD_LOGIC;
		data_in  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		data_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
	);
END ppm_register;

ARCHITECTURE Behavioral OF ppm_register IS
BEGIN
	-- Register with asynchronous reset and enable
	PROCESS (clk, reset_n)
	BEGIN
		IF reset_n = '0' THEN
			data_out <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			IF enable = '1' THEN
				data_out <= data_in;
			END IF;
		END IF;
	END PROCESS;
END Behavioral;