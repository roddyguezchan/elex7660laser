	component ccom_rx is
		port (
			clk50_clk       : in std_logic                     := 'X';             -- clk
			qpdp1_export    : in std_logic_vector(23 downto 0) := (others => 'X'); -- export
			reset_n_reset_n : in std_logic                     := 'X';             -- reset_n
			qpdp2_export    : in std_logic_vector(23 downto 0) := (others => 'X'); -- export
			dxdy_export     : in std_logic_vector(23 downto 0) := (others => 'X'); -- export
			status_export   : in std_logic_vector(7 downto 0)  := (others => 'X')  -- export
		);
	end component ccom_rx;

	u0 : component ccom_rx
		port map (
			clk50_clk       => CONNECTED_TO_clk50_clk,       --   clk50.clk
			qpdp1_export    => CONNECTED_TO_qpdp1_export,    --   qpdp1.export
			reset_n_reset_n => CONNECTED_TO_reset_n_reset_n, -- reset_n.reset_n
			qpdp2_export    => CONNECTED_TO_qpdp2_export,    --   qpdp2.export
			dxdy_export     => CONNECTED_TO_dxdy_export,     --    dxdy.export
			status_export   => CONNECTED_TO_status_export    --  status.export
		);

