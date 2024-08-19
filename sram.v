module 	sram  #(parameter data_width = 8,
								 addr_width = 6,
								 depth = 64,
								 almost_full_gap = 50,
								 almost_empty_gap = 20)
			(
			    input 	wr_clk,
				input 	wr_en,
				input   [addr_width-1:0] wr_addr,
				input   rd_clk,
				input   rd_en,
				input   [addr_width-1:0] rd_addr,
				input   [data_width-1:0] data_in,
				output reg [data_width-1:0] data_out);
			
			//存储阵列定义
			reg [data_width-1:0] SRAM_MEM [depth-1:0];
			
			//数据写入
			always @ (posedge wr_clk)
				if (wr_en)
					SRAM_MEM [wr_addr] <= data_in;
				else
					SRAM_MEM [wr_addr] <= SRAM_MEM [wr_addr];
			
			//数据读出
			always @ (posedge rd_clk)
				if (rd_en)
					data_out <= SRAM_MEM [rd_addr];
				else
					data_out <= 'b0;
endmodule		
