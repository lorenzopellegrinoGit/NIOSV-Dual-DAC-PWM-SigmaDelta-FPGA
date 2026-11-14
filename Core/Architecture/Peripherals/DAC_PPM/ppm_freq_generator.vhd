---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PPM version)
-- VHDL code of tick generator
------------------------------------



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY ppm_freq_generator IS
	PORT (
		clk       : IN  STD_LOGIC; -- 50 MHz
		reset_n   : IN  STD_LOGIC;
		freq_sel  : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); -- Frequency selector
		pulse_out : OUT STD_LOGIC
	);
END ppm_freq_generator;

ARCHITECTURE Behavioral OF ppm_freq_generator IS
	-- Clock divider values for each frequency
	-- 00: 400 kHz -> div 125
	-- 01: 200 kHz -> div 250
	-- 10: 100 kHz -> div 500
	--  11: 50 kHz  -> div 1000
	SIGNAL counter   : INTEGER RANGE 0 TO 1000;
	SIGNAL max_count : INTEGER RANGE 0 TO 1000;

BEGIN
	-- Frequency selection
	PROCESS (freq_sel)
	BEGIN
		CASE freq_sel IS
			WHEN "00"   => max_count <= 125;  -- 400 kHz
			WHEN "01"   => max_count <= 250;   -- 200 kHz
			WHEN "10"   => max_count <= 500;  -- 100 kHz
			WHEN "11"   => max_count <= 1000; -- 50   kHz
			WHEN OTHERS => max_count <= 500;
		END CASE;
	END PROCESS;

	-- Counter generates pulse every max_count clock cycles
	PROCESS (clk, reset_n)
	BEGIN
		IF reset_n = '0' THEN
			counter   <= 0;
			pulse_out <= '0';
		ELSIF rising_edge(clk) THEN
			IF counter >= (max_count - 1) THEN
				counter   <= 0;
				pulse_out <= '1';
			ELSE
				counter   <= counter + 1;
				pulse_out <= '0';
			END IF;
		END IF;
	END PROCESS;

END Behavioral;