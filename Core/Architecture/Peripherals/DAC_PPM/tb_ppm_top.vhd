---------------------------------
-- Group 13 - Laboratory 6
-- DAC PPM Testbench
-- VHDL testbench for DAC_PPM
------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY tb_ppm_top IS
END ENTITY tb_ppm_top;

ARCHITECTURE testbench OF tb_ppm_top IS

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

	SIGNAL digital_in    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL clk           : STD_LOGIC := '0';
	SIGNAL rstn          : STD_LOGIC := '0';
	SIGNAL freq_sel      : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
	SIGNAL Bitstream_out : STD_LOGIC;

BEGIN

	-- Clock generation
	clk_gen : PROCESS
	BEGIN
		clk <= NOT clk;
		WAIT FOR 10 ns;
	END PROCESS;

	-- DUT instantiation
	DUT : ppm_top
	GENERIC MAP(
		DATA_WIDTH => 8
	)
	PORT MAP(
		digital_in    => digital_in,
		clk           => clk,
		rstn          => rstn,
		freq_sel      => freq_sel,
		Bitstream_out => Bitstream_out
	);

	-- Test
	test_process : PROCESS
	BEGIN

		-- Reset
		WAIT FOR 100 ns;
		rstn <= '1';
		WAIT FOR 100 ns;

		-- Test at 400 kHz with 50% input value
		freq_sel   <= "00";
		digital_in <= STD_LOGIC_VECTOR(to_unsigned(128, 8));
		WAIT FOR 20 us;

		-- Low value (low pulse density)
		digital_in <= STD_LOGIC_VECTOR(to_unsigned(20, 8));
		WAIT FOR 20 us;

		-- High value (high pulse density)
		digital_in <= STD_LOGIC_VECTOR(to_unsigned(230, 8));
		WAIT FOR 20 us;

		-- Test at 100 kHz
		freq_sel   <= "10";
		digital_in <= STD_LOGIC_VECTOR(to_unsigned(128, 8));
		WAIT FOR 50 us;

		-- Test at 50 kHz
		freq_sel   <= "11";
		digital_in <= STD_LOGIC_VECTOR(to_unsigned(160, 8));
		WAIT FOR 200 us;

		WAIT;

	END PROCESS;

END ARCHITECTURE testbench;