---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PPM version)
-- VHDL code of comparator
------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ppm_comparator IS
	PORT (
		data_in   : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		bitstream : OUT STD_LOGIC);
END ppm_comparator;

ARCHITECTURE Behavioral OF ppm_comparator IS
BEGIN
	-- if MSB is 0 positive number, HIGH.
	-- if MSB is 1 negative number, LOW.

	bitstream <= NOT data_in(9);
END Behavioral;