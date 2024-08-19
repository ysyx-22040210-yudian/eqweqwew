module async_FIFO_01 #(parameter data_width = 8,
								 addr_width = 6,
								 depth = 64,
								 almost_full_gap = 50,
								 almost_empty_gap = 10)
					(	
						input rst_n,		//复位
						input wr_clk,		//写时钟
						input wr_en,		//写使能信号
						input [data_width-1:0] data_in,		//外部输入数据
						input rd_clk,		//读时钟
						input rd_en,		//读使能
						output [data_width-1:0] data_out,	//数据输出
						output reg full,
						output reg empty,
						output reg almost_full,
						output reg almost_empty
						);
						
					reg [addr_width:0] wr_addr_ptr,wr_addr_ptr_next; 		//write address pointer
					reg [addr_width:0] rd_addr_ptr,rd_addr_ptr_next;		//read address pointer
					wire [addr_width:0] wr_addr_ptr_gray;
					wire [addr_width:0] rd_addr_ptr_gray;
					reg [addr_width:0] wr_addr_ptr_gray_1,wr_addr_ptr_gray_2;
					reg [addr_width:0] rd_addr_ptr_gray_1,rd_addr_ptr_gray_2;
					
					
					reg [addr_width-1:0] wr_addr;							//write address
					wire [addr_width-1:0] wr_addr_next;					
					reg [addr_width-1:0] rd_addr;							//read address
					wire [addr_width-1:0] rd_addr_next;				
					
					wire full_next,empty_next;
					wire almost_full_next,almost_empty_next;

					assign SRAM_wr_en = wr_en && !full_next;
					assign SRAM_rd_en = rd_en && !empty_next;	
									
					//write address pointer update
					always @ (*)
						if (!rst_n)
							wr_addr_ptr_next = 'b0;
						else if (wr_en && !full_next)
							wr_addr_ptr_next = wr_addr_ptr + 1'b1;
						else
							wr_addr_ptr_next = wr_addr_ptr;
					
					//read address pointer update
					always @ (*)
						if (!rst_n)
							rd_addr_ptr_next = 'b0;
						else if (rd_en && !empty_next)
							rd_addr_ptr_next = rd_addr_ptr + 1'b1;
						else
							rd_addr_ptr_next = rd_addr_ptr;
					
					//write and read address update
					assign wr_addr_next = wr_addr_ptr_next[addr_width-1:0];
					assign rd_addr_next = rd_addr_ptr_next[addr_width-1:0];
					
					//写地址指针格雷码转换
					assign wr_addr_ptr_gray = (wr_addr_ptr >> 1) ^ wr_addr_ptr;
					//读地址指针格雷码转换
					assign rd_addr_ptr_gray = (rd_addr_ptr >> 1) ^ rd_addr_ptr;
					
					//写地址指针格雷码同步到读时钟域
					always @ (posedge rd_clk or negedge rst_n)
						if (!rst_n)
							begin
								wr_addr_ptr_gray_1 <= 'b0;
								wr_addr_ptr_gray_2 <= 'b0;
							end
						else
							begin
								wr_addr_ptr_gray_1 <= wr_addr_ptr_gray;
								wr_addr_ptr_gray_2 <= wr_addr_ptr_gray_1;
							end
						
					//读地址指针格雷码同步到写时钟域
					always @ (posedge wr_clk or negedge rst_n)
						if (!rst_n)
							begin
								rd_addr_ptr_gray_1 <= 'b0;
								rd_addr_ptr_gray_2 <= 'b0;
							end
						else
							begin
								rd_addr_ptr_gray_1 <= rd_addr_ptr_gray;
								rd_addr_ptr_gray_2 <= rd_addr_ptr_gray_1;
							end
					
					//同步过后的格雷码进行二进制转换，用于产生将空将满
					wire [addr_width:0] wr_addr_ptr_gray_to_bin;
					wire [addr_width:0] rd_addr_ptr_gray_to_bin;
					
					assign	wr_addr_ptr_gray_to_bin[addr_width] = wr_addr_ptr_gray_2[addr_width];
					assign  rd_addr_ptr_gray_to_bin[addr_width] = rd_addr_ptr_gray_2[addr_width];
					genvar i;
					generate
						for (i=0;i<addr_width;i=i+1)
							begin
								assign wr_addr_ptr_gray_to_bin[i] = wr_addr_ptr_gray_2[i]^wr_addr_ptr_gray_to_bin[i+1];
								assign rd_addr_ptr_gray_to_bin[i] = rd_addr_ptr_gray_2[i]^rd_addr_ptr_gray_to_bin[i+1];
							end
					endgenerate
					
					
					
                    //full_next信号产生
					assign full_next = ({~wr_addr_ptr_gray[addr_width:addr_width-1],wr_addr_ptr_gray[addr_width-2:0]}) == rd_addr_ptr_gray_2 ? 1'b1:1'b0;
					
					//empty_next信号产生
					assign empty_next = wr_addr_ptr_gray_2 == rd_addr_ptr_gray ? 1'b1: 1'b0;
					
					reg [addr_width-1:0] data_avail;
					reg [addr_width-1:0] room_avail;
					
					//data_avail信号生成，用于进行将满判断
					always @ (*)
						begin
							if (wr_addr_ptr[addr_width]!=rd_addr_ptr_gray_to_bin[addr_width])
								begin
									if (wr_addr_ptr[addr_width-1:0]==rd_addr_ptr_gray_to_bin[addr_width-1:0])
												data_avail = depth-1;
									else
												data_avail = depth-(rd_addr_ptr_gray_to_bin[addr_width-1:0]-wr_addr_ptr[addr_width-1:0]);
								end
							else
								
												data_avail = wr_addr_ptr[addr_width-1:0]-rd_addr_ptr_gray_to_bin[addr_width-1:0];
						end
					
					
					assign almost_full_next = (data_avail >= almost_full_gap)? 1'b1: 1'b0;
					
					
					//room_avail信号生成，用于进行将空判断

					always @ (*)
						begin
							if (rd_addr_ptr[addr_width]==wr_addr_ptr_gray_to_bin[addr_width])
								begin
									if (wr_addr_ptr_gray_to_bin[addr_width-1:0]==rd_addr_ptr[addr_width-1:0])
												room_avail = depth-1;
									else
												room_avail = depth-(wr_addr_ptr_gray_to_bin[addr_width-1:0]-rd_addr_ptr[addr_width-1:0]);
								end
							else
												room_avail = rd_addr_ptr[addr_width-1:0]-wr_addr_ptr_gray_to_bin[addr_width-1:0];
						end
					assign almost_empty_next = (room_avail >= (depth-almost_empty_gap))? 1'b1:1'b0;
				
			
			//输出信号打拍
			
					always @ (posedge wr_clk or negedge rst_n)
						if (!rst_n)
							begin
								wr_addr_ptr <= 'b0;
								full <= 'b0;
								almost_full <= 'b0;
								wr_addr <= 'b0;
							end
						else
							begin
								wr_addr_ptr <= wr_addr_ptr_next;
								full <= full_next;
								almost_full <= almost_full_next;
								wr_addr <= wr_addr_next;
							end
					
					always @ (posedge rd_clk or negedge rst_n)
						if (!rst_n)
							begin
								rd_addr_ptr <= 'b0;
								empty <= 'b0;
								almost_empty <= 'b0;
								rd_addr <= 'b0;
							end
						else
							begin
								rd_addr_ptr <= rd_addr_ptr_next;
								empty <= empty_next;
								almost_empty <= almost_empty_next;
								rd_addr <= rd_addr_next;
							end
							
							
			//模块例化
					sram m0 (
						.wr_clk (wr_clk),
						.wr_en (SRAM_wr_en ),
						.wr_addr (wr_addr),
						.rd_clk (rd_clk),
						.rd_en (SRAM_rd_en ),
						.rd_addr (rd_addr),
						.data_in (data_in),
						.data_out (data_out));
endmodule
