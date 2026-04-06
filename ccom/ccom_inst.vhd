	component ccom is
		port (
			clk50_clk       : in std_logic                     := 'X';             -- clk
			reset_n_reset_n : in std_logic                     := 'X';             -- reset_n
			status_export   : in std_logic_vector(11 downto 0) := (others => 'X')  -- export
		);
	end component ccom;

	u0 : component ccom
		port map (
			clk50_clk       => CONNECTED_TO_clk50_clk,       --   clk50.clk
			reset_n_reset_n => CONNECTED_TO_reset_n_reset_n, -- reset_n.reset_n
			status_export   => CONNECTED_TO_status_export    --  status.export
		);

