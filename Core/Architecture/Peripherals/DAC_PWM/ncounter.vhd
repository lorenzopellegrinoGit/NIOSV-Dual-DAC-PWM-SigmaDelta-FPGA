---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PWM version)
-- VHDL code of n counter
------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ncounter IS
	GENERIC (
		n : POSITIVE := 16 -- Nbit of counter
	);
	PORT (
		clk, enable, clear, cnt, rstn, ld : IN  STD_LOGIC;
		value_in                          : IN  STD_LOGIC_VECTOR(n - 1 DOWNTO 0); -- Input value
		Q                                 : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0)  -- Output value
	);
END ncounter;

ARCHITECTURE Behavior OF ncounter IS
	SIGNAL Q_int : unsigned(n - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN
	PROCESS (clk, rstn)
	BEGIN
		IF rstn = '0' THEN -- Asynchronous reset, active-low
			Q_int <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN -- Synchronous part
			IF clear = '1' THEN
				Q_int <= (OTHERS => '0'); -- Clear output
			ELSIF (ld = '1') THEN
				Q_int <= unsigned(value_in); -- Load input value
			ELSIF enable = '1' THEN
				IF cnt = '1' THEN
					Q_int <= Q_int + 1; -- Count-up
				ELSE
					Q_int <= Q_int - 1; -- Count-down
				END IF;
			END IF;
		END IF;
	END PROCESS;

	Q <= STD_LOGIC_VECTOR(Q_int); -- Assign output
END ARCHITECTURE Behavior;

-- By using RTLViewer can be seen that to implement the circuit are used: -2 adders -4 MUXs -1 register
-- for a total of 7 logic components. The Fmax result being Fmax=1/2.196e-9 Hz=455373406Hz, so around 455 MHz