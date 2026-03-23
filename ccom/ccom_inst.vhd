	component ccom is
		port (
			button_pio_export : in  std_logic                     := 'X';             -- export
			clk50_clk         : in  std_logic                     := 'X';             -- clk
			leds_export       : out std_logic_vector(7 downto 0);                     -- export
			q0_data_export    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			q1_data_export    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			q2_data_export    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			q3_data_export    : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			reset_n_reset_n   : in  std_logic                     := 'X'              -- reset_n
		);
	end component ccom;

	u0 : component ccom
		port map (
			button_pio_export => CONNECTED_TO_button_pio_export, -- button_pio.export
			clk50_clk         => CONNECTED_TO_clk50_clk,         --      clk50.clk
			leds_export       => CONNECTED_TO_leds_export,       --       leds.export
			q0_data_export    => CONNECTED_TO_q0_data_export,    --    q0_data.export
			q1_data_export    => CONNECTED_TO_q1_data_export,    --    q1_data.export
			q2_data_export    => CONNECTED_TO_q2_data_export,    --    q2_data.export
			q3_data_export    => CONNECTED_TO_q3_data_export,    --    q3_data.export
			reset_n_reset_n   => CONNECTED_TO_reset_n_reset_n    --    reset_n.reset_n
		);

