---------------------------------
-- Group 13 - Laboratory 6
-- DAC (PWM version)
-- VHDL code of DAC PWM
------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY DAC_PWM IS
	PORT (
		CLK      : IN  STD_LOGIC;
		ARST_n   : IN  STD_LOGIC;
		ENABLE   : IN  STD_LOGIC;
		FREQ_SEL : IN  STD_LOGIC_VECTOR(1 DOWNTO 0); -- PWM frequency selector
		DAC_IN   : IN  STD_LOGIC_VECTOR(7 DOWNTO 0); -- Duty cycle value
		DAC_OUT  : OUT STD_LOGIC
	);
END ENTITY DAC_PWM;

ARCHITECTURE behavioral OF DAC_PWM IS

	-- N-bit counter component
	COMPONENT ncounter IS
		GENERIC (
			n : POSITIVE := 16
		);
		PORT (
			clk, enable, clear, cnt, rstn, ld : IN  STD_LOGIC;
			value_in                          : IN  STD_LOGIC_VECTOR(n - 1 DOWNTO 0);
			Q                                 : OUT STD_LOGIC_VECTOR(n - 1 DOWNTO 0)
		);
	END COMPONENT;

	-- Prescaler signals
	SIGNAL PSC_CNT       : unsigned(9 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PSC_THR       : unsigned(9 DOWNTO 0) := (OTHERS => '0');
	SIGNAL PSC_TICK      : STD_LOGIC            := '0';
	SIGNAL PSC_THR_NEXT  : unsigned(9 DOWNTO 0) := (OTHERS => '0');
	
	-- PWM counter signals
	SIGNAL CNT0_EN       : STD_LOGIC            := '0';
	SIGNAL CNT0_LD       : STD_LOGIC            := '0';
	SIGNAL CNT0_Q        : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL CNT1_EN       : STD_LOGIC := '0';
	SIGNAL CNT1_LD       : STD_LOGIC := '0';
	SIGNAL CNT1_DIN      : STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL CNT1_Q        : STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL PWM_OUT    : STD_LOGIC := '0';

	CONSTANT COUNTER_MAX : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111111";

	-- Frequency divider values
	constant FREQ_400KHZ : unsigned(9 downto 0) := "0001111100";  -- 124 400 kHz
	constant FREQ_200KHZ : unsigned(9 downto 0) := "0011111001";  -- 249 200 kHz
	constant FREQ_100KHZ : unsigned(9 downto 0) := "0111110011";  -- 499  100 kHz
	constant FREQ_50KHZ  : unsigned(9 downto 0) := "1111100111";  -- 999  50 kHz

BEGIN
	-- Frequency selection logic
	frequency_selection : PROCESS (CLK, ARST_n)
	BEGIN
		IF (ARST_n = '0') THEN
			PSC_THR_NEXT <= FREQ_400KHZ;
		ELSIF rising_edge(CLK) THEN
			IF (ENABLE = '1') THEN
				CASE FREQ_SEL IS
					WHEN "00"   => PSC_THR_NEXT <= FREQ_400KHZ;
					WHEN "01"   => PSC_THR_NEXT <= FREQ_200KHZ;
					WHEN "10"   => PSC_THR_NEXT <= FREQ_100KHZ;
					WHEN "11"   => PSC_THR_NEXT <= FREQ_50KHZ;
					WHEN OTHERS => PSC_THR_NEXT <= FREQ_400KHZ;
				END CASE;
			END IF;
		END IF;
	END PROCESS frequency_selection;

	-- Prescaler counter
	PSC : PROCESS (CLK, ARST_n)
	BEGIN
		IF (ARST_n = '0') THEN
			PSC_CNT  <= (OTHERS => '0');
			PSC_THR  <= FREQ_400KHZ;
			PSC_TICK <= '0';
		ELSIF rising_edge(CLK) THEN
			IF (PSC_CNT = PSC_THR) THEN
				PSC_CNT  <= (OTHERS => '0');
				PSC_THR  <= PSC_THR_NEXT;
				PSC_TICK <= '1';
			ELSE
				PSC_CNT  <= PSC_CNT + 1;
				PSC_TICK <= '0';
			END IF;
		END IF;
	END PROCESS PSC;
	
	-- Input register for duty cycle value
	input_register : PROCESS (CLK, ARST_n)
	BEGIN
		IF (ARST_n = '0') THEN
			CNT1_DIN <= (OTHERS => '0');
		ELSIF rising_edge(CLK) THEN
			IF (ENABLE = '1') THEN
				CNT1_DIN <= DAC_IN;
			END IF;
		END IF;
	END PROCESS input_register;

	-- PWM controller
	CNT_manager : PROCESS (CLK, ARST_n)
	BEGIN
		IF (ARST_n = '0') THEN
			CNT0_EN    <= '0';
			CNT0_LD    <= '0';
			CNT1_EN    <= '0';
			CNT1_LD    <= '0';
			PWM_OUT <= '0';
		ELSIF rising_edge(CLK) THEN
			IF (ENABLE = '1' AND PSC_TICK = '1') THEN
				IF (CNT0_Q = "00000000") THEN
					-- Start new PWM period
					CNT0_LD    <= '1';
					CNT1_LD    <= '1';
					CNT0_EN    <= '1';
					CNT1_EN    <= '1';
					PWM_OUT <= '1';
				ELSIF (CNT1_Q = "00000000") THEN
					-- Duty cycle complete
					CNT0_LD    <= '0';
					CNT1_LD    <= '0';
					CNT0_EN    <= '1';
					CNT1_EN    <= '0';
					PWM_OUT <= '0';
				ELSE
					-- Count down both counters
					CNT0_LD <= '0';
					CNT1_LD <= '0';
					CNT0_EN <= '1';
					CNT1_EN <= '1';
				END IF;
			ELSE
				CNT0_EN <= '0';
				CNT1_EN <= '0';
				CNT0_LD <= '0';
				CNT1_LD <= '0';
			END IF;
		END IF;
	END PROCESS CNT_manager;

	DAC_OUT <= PWM_OUT WHEN (ENABLE = '1') ELSE 'Z';	-- Three state gate

	-- Period counter
	CNT0_period_counter : ncounter
	GENERIC MAP(
		n => 8
	)
	PORT MAP(
		clk      => CLK,
		enable   => CNT0_EN,
		clear    => '0',
		cnt      => '0',
		rstn     => ARST_n,
		ld       => CNT0_LD,
		value_in => COUNTER_MAX,
		Q        => CNT0_Q
	);

	-- Duty cycle counter
	CNT1_DC_counter : ncounter
	GENERIC MAP(
		n => 8
	)
	PORT MAP(
		clk      => CLK,
		enable   => CNT1_EN,
		clear    => '0',
		cnt      => '0',
		rstn     => ARST_n,
		ld       => CNT1_LD,
		value_in => CNT1_DIN,
		Q        => CNT1_Q
	);

END ARCHITECTURE behavioral;