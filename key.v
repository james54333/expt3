module key( key_num, clk, signal );

	input key_num;
	input clk;
	output signal;
	
	reg flag;
	reg signal;

	always @ ( posedge clk ) begin
		if ( key_num == 1'b0 ) begin
			if ( flag == 1'b0 ) begin
				signal = 1'b1;
				flag = 1'b1;
			end
			else begin
				signal = 1'b0;
			end
		end
		else begin
			flag = 1'b0;
		end		
	end

endmodule
