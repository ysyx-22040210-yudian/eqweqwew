
`timescale 1ns / 1ps


module sim_async_FIFO_01;

            parameter          data_width = 8,
								 addr_width = 6,
								 depth = 64,
								 almost_full_gap = 50,
								 almost_empty_gap = 10;
			
			reg rst_n;
            reg wr_clk;
            reg wr_en;
            reg [data_width-1:0] data_in;
            reg rd_clk;
            reg rd_en;
            wire [data_width-1:0] data_out;
            wire full;
            wire empty;
            wire almost_empty;
            wire almost_full;
								 
		async_FIFO_01 x1
					(	
						.rst_n(rst_n),
						.wr_clk(wr_clk),
						.wr_en(wr_en),
						.data_in(data_in),
						.rd_clk(rd_clk),
						.rd_en(rd_en),
						.data_out(data_out),
						.full(full),
						.empty(empty),
						.almost_full(almost_full),
						.almost_empty(almost_empty)
						);
						
		initial
		  begin
		      wr_clk = 1'b0;
		      rst_n = 1'b0;
		      wr_en = 1'b0;
		      rd_clk = 1'b0;
		      rd_en = 1'b0;
		      data_in = 8'b1111_1111;
		      #40 rst_n = 1'b1;
		      #40 wr_en = 1'b1;
		      #20 data_in = 8'b1001_1011;
		      #20 data_in = 8'b0010_1011;
		      #20 data_in = 8'b1001_0000;
		      #20 data_in = 8'b0000_1011;
		      #20 data_in = 8'b1001_1101;
		      #1200 rd_en = 1'b1;
		      #500 wr_en = 1'b0;
		      #20 data_in = 8'b1001_0000;
		      #20 data_in = 8'b0000_1011;
		      #20 data_in = 8'b0000_0000;
		      #20 data_in = 8'b0010_1011;
		      #20 data_in = 8'b0000_1101;
		      #3000 rd_en = 1'b0;
		  end
		  
		  always #10 wr_clk = ~wr_clk;
		  always #20 rd_clk = ~rd_clk;
		  
endmodule


