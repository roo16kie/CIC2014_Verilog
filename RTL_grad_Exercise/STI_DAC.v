module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output	reg	so_data, so_valid;

output   oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output reg [4:0] oem_addr;
output reg [7:0] oem_dataout;

//==============================================================================

parameter IDLE = 2'b00 ;
parameter LOAD = 2'b01 ;
parameter MEM  = 2'b11 ;
parameter SO   = 2'b10 ;

parameter mem1 = 2'b00 ; 
parameter mem2 = 2'b01 ;
parameter mem4 = 2'b11 ;
parameter mem3 = 2'b10 ;



//---------------------------define somethings----------------------------------//

reg of , oem_finish;
reg odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
reg [1:0] ns , cs , reg_length , mem_alloc;
reg reg_msb ;
reg [5:0] so_counter ;
reg [1:0] mem_counter ;
reg [2:0] out_counter ;

reg [31:0] data ;
wire odd_check , even_check ;




//-------------------------------design-------------------------------------//

assign odd_check = (odd1_wr | odd2_wr) | (odd3_wr | odd4_wr) ;
assign even_check = (even1_wr | even2_wr) | (even3_wr | even4_wr) ;

always@(posedge clk or posedge reset)
begin
	if(reset)
		of <= 1 ;
	else if(oem_addr[2:0]==3'b011)
		begin
			if(even_check)
				of <= 0 ;
		end
	else if(oem_addr[2:0]==3'b111)
		begin
			if(odd_check)
				of <= 1 ;
		end
end


always@(posedge clk or posedge reset)
begin
	if(reset)
		oem_finish <= 0 ;
	else if((mem_alloc==mem4)&&(oem_addr==5'd31)&&(odd4_wr))
		oem_finish <= 1 ;
end

always@(posedge clk or posedge reset)
begin
	if(reset)
		mem_counter <= 2'd0 ;
	else if(cs==MEM)
		mem_counter <= mem_counter + 2'd1 ;
	else if((cs==IDLE)&&(pi_end==1))
		mem_counter <= mem_counter + 2'd1 ;
end

always@(posedge clk or posedge reset)
begin
	if(reset)
		out_counter <= 3'd0 ;
	else if(cs==MEM)
		out_counter <= out_counter + 3'd1 ;
	else if((cs==IDLE)&&(pi_end==1))
		out_counter <= out_counter + 3'd1 ;
	else
		out_counter <= 0 ;
end

always@(posedge clk or posedge reset)
begin
	if(reset)
		so_counter <= 6'd0 ;
	else if(ns==SO)
		so_counter <= so_counter + 6'd1 ;
	else
		so_counter <= 6'd0 ;
end




always@(posedge clk or posedge reset)
begin
	if(reset)
		cs <= IDLE ;
	else
		cs <= ns ;
end

always@(*)
begin
	case(cs)
		IDLE : ns = (pi_end) ? IDLE : ((load) ? LOAD : IDLE)  ;
		
		LOAD : ns = MEM ;
		
		MEM  : if((reg_length==2'b00)&&(out_counter==3'd1)) ns = SO ;
			   else if((reg_length==2'b01)&&(out_counter==3'd3)) ns = SO ;
			   else if((reg_length==2'b10)&&(out_counter==3'd5)) ns = SO ;
			   else if((reg_length==2'b11)&&(out_counter==3'd7)) ns = SO ;
			   else ns = MEM ;
		
		SO   : if((reg_length==2'b00)&&(so_counter==6'd8)) ns = IDLE ;
			   else if((reg_length==2'b01)&&(so_counter==6'd16)) ns = IDLE ;
			   else if((reg_length==2'b10)&&(so_counter==6'd24)) ns = IDLE ;
			   else if((reg_length==2'b11)&&(so_counter==6'd32)) ns = IDLE ;
			   else ns = SO ;
		
		default : ns = IDLE ;
	endcase		
end


always@(posedge clk or posedge reset)
begin
	if(reset)
		so_valid <= 0 ;
	else if(ns==SO)
		so_valid <= 1 ;
	else
		so_valid <= 0 ;
end

always@(posedge clk)
begin
	if(ns==SO)
		so_data <= data[so_counter] ;
	else
		so_data <= 0 ;
end


always@(posedge clk)
begin
	if(ns==LOAD)
	begin	reg_length <= pi_length ; reg_msb <= pi_msb ; end
end




always@(posedge clk)
begin
	if(ns==LOAD)
	begin
	if(pi_msb)
	begin
		if(pi_length==2'b11)
		begin
			if(pi_fill)
				data <= {16'd0 , pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7],pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15]} ;
			else
				data <= {pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7],pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15] , 16'd0} ;
		end
		else if(pi_length==2'b10)
		begin
			if(pi_fill)
				data <= {16'd0 , pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7],pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15]} ;
			else
				data <= {8'd0 , pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7],pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15] , 8'd0} ;
		end
		else if(pi_length==2'b01)
				data <= {16'd0 , pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7],pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15]} ;
		else if(pi_length==2'b00)
		begin
			if(pi_low)
				data <= {24'd0 , pi_data[8],pi_data[9],pi_data[10],pi_data[11],pi_data[12],pi_data[13],pi_data[14],pi_data[15]} ;
			else
				data <= {24'd0 , pi_data[0],pi_data[1],pi_data[2],pi_data[3],pi_data[4],pi_data[5],pi_data[6],pi_data[7]} ;
		end
	end
	else if(~pi_msb)
	begin
		if(pi_length==2'b11)
		begin
			if(pi_fill)
				data <= {pi_data[15:0] , 16'd0} ;
			else
				data <= {16'd0 , pi_data[15:0]} ;
		end
		else if(pi_length==2'b10)
		begin
			if(pi_fill)
				data <= {8'd0 , pi_data[15:0] , 8'd0} ;
			else
				data <= {16'd0 , pi_data[15:0]} ;
		end
		else if(pi_length==2'b01)
				data <= {16'd0 , pi_data[15:0]} ;
		else if(pi_length==2'b00)
		begin
			if(pi_low)
				data <= {24'd0 , pi_data[15:8]} ;
			else
				data <= {24'd0 , pi_data[7:0]} ;
		end
	end	
	end
end





always@(posedge clk or posedge reset)
begin
	if(reset)
		mem_alloc <= mem1 ;
	else if((oem_addr==5'd31)&&(mem_counter==2'd3))
		mem_alloc <= mem_alloc + 2'b01 ;
end

always@(posedge clk or posedge reset)
begin
	if(reset)
		oem_addr <= 5'd0 ;
	else if(mem_counter==2'd3)
		begin 
			if(oem_addr==5'd31)
			oem_addr <= 5'd0 ;
			else 
			oem_addr <= oem_addr + 5'd1 ;
		end
end

always@(posedge clk or posedge reset)
begin
if(reset)
	begin	odd1_wr <= 0 ; even1_wr <= 0 ;  odd2_wr <= 0 ; even2_wr <= 0 ; odd3_wr <= 0 ; even3_wr <= 0 ;  odd4_wr <= 0 ; even4_wr <= 0 ; end
else if((cs==MEM)||((cs==IDLE)&&(pi_end==1)))
begin
	if(mem_alloc==mem1)
	begin
	if(of)
	begin
		if(mem_counter==2'b00)
		begin    odd1_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 even1_wr <= 1 ; end
		else
		begin	odd1_wr <= 0 ; even1_wr <= 0 ; end
	end
	else
	begin
		if(mem_counter==2'b00)
		begin    even1_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 odd1_wr <= 1 ; end
		else
		begin	odd1_wr <= 0 ; even1_wr <= 0 ; end
	end
	end
	else if(mem_alloc==mem2)
	begin
	if(of)
	begin
		if(mem_counter==2'b00)
		begin    odd2_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 even2_wr <= 1 ; end
		else
		begin	odd2_wr <= 0 ; even2_wr <= 0 ; end
	end
	else
	begin
		if(mem_counter==2'b00)
		begin    even2_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 odd2_wr <= 1 ; end
		else
		begin	odd2_wr <= 0 ; even2_wr <= 0 ; end
	end
	end
	else if(mem_alloc==mem3)
	begin
	if(of)
	begin
		if(mem_counter==2'b00)
		begin    odd3_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 even3_wr <= 1 ; end
		else
		begin	odd3_wr <= 0 ; even3_wr <= 0 ; end
	end
	else
	begin
		if(mem_counter==2'b00)
		begin    even3_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 odd3_wr <= 1 ; end
		else
		begin	odd3_wr <= 0 ; even3_wr <= 0 ; end
	end
	end
	else if(mem_alloc==mem4)
	begin
	if(of)
	begin
		if(mem_counter==2'b00)
		begin    odd4_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 even4_wr <= 1 ; end
		else
		begin	odd4_wr <= 0 ; even4_wr <= 0 ; end
	end
	else
	begin
		if(mem_counter==2'b00)
		begin    even4_wr <= 1  ; end
		else if(mem_counter==2'b10)
		begin	 odd4_wr <= 1 ; end
		else
		begin	odd4_wr <= 0 ; even4_wr <= 0 ; end
	end
	end
end	
end

always@(posedge clk)
begin
	if(ns==MEM)
	begin
		if(reg_length==2'b11)
		begin
			if(out_counter==3'd0)
				oem_dataout <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]} ;
			else if(out_counter==3'd1)
				oem_dataout <= {data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]}  ;
			else if(out_counter==3'd3)
				oem_dataout <= {data[16],data[17],data[18],data[19],data[20],data[21],data[22],data[23]} ;
			else if(out_counter==3'd5)
				oem_dataout <= {data[24],data[25],data[26],data[27],data[28],data[29],data[30],data[31]} ;
		end
		else if(reg_length==2'b10)
		begin
			if(out_counter==3'd0)
				oem_dataout <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]}  ;
			else if(out_counter==3'd1)
				oem_dataout <= {data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]} ;
			else if(out_counter==3'd3)
				oem_dataout <= {data[16],data[17],data[18],data[19],data[20],data[21],data[22],data[23]} ;
		end
		else if(reg_length==2'b01)
		begin
			if(out_counter==3'd0)
				oem_dataout <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]}  ;
			else if(out_counter==3'd1)
				oem_dataout <= {data[8],data[9],data[10],data[11],data[12],data[13],data[14],data[15]} ;
		end
		else if(reg_length==2'b00)
		begin
			if(out_counter==3'd0)
				oem_dataout <= {data[0],data[1],data[2],data[3],data[4],data[5],data[6],data[7]}  ;
		end
	end
	else if((cs==IDLE)&&(pi_end==1))
		oem_dataout <= 8'd0 ;
end



endmodule
