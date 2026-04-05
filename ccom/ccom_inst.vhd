	component ccom is
		port (
			button_pio_export : in  std_logic                     := 'X';             -- export
			clk50_clk         : in  std_logic                     := 'X';             -- clk
			leds_export       : out std_logic_vector(7 downto 0);                     -- export
			qpdp1_export      : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			reset_n_reset_n   : in  std_logic                     := 'X';             -- reset_n
			status_export     : in  std_logic_vector(11 downto 0) := (others => 'X'); -- export
			stepper_export    : out std_logic_vector(7 downto 0);                     -- export
			qpdp2_export      : in  std_logic_vector(11 downto 0) := (others => 'X')  -- export
		);
	end component ccom;

	u0 : component ccom
		port map (
			button_pio_export => CONNECTED_TO_button_pio_export, -- button_pio.export
			clk50_clk         => CONNECTED_TO_clk50_clk,         --      clk50.clk
			leds_export       => CONNECTED_TO_leds_export,       --       leds.export
			qpdp1_export      => CONNECTED_TO_qpdp1_export,      --      qpdp1.export
			reset_n_reset_n   => CONNECTED_TO_reset_n_reset_n,   --    reset_n.reset_n
			status_export     => CONNECTED_TO_status_export,     --     status.export
			stepper_export    => CONNECTED_TO_stepper_export,    --    stepper.export
			qpdp2_export      => CONNECTED_TO_qpdp2_export       --      qpdp2.export
		);

