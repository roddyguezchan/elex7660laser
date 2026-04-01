	component ccom_rx is
		port (
			clk50_clk       : in std_logic                    := 'X';             -- clk
			datarx_export   : in std_logic_vector(7 downto 0) := (others => 'X'); -- export
			reset_n_reset_n : in std_logic                    := 'X'              -- reset_n
		);
	end component ccom_rx;

	u0 : component ccom_rx
		port map (
			clk50_clk       => CONNECTED_TO_clk50_clk,       --   clk50.clk
			datarx_export   => CONNECTED_TO_datarx_export,   --  datarx.export
			reset_n_reset_n => CONNECTED_TO_reset_n_reset_n  -- reset_n.reset_n
		);

