module IR_Control( iCLK, iRST_N, code, inter );
	
	input iCLK;
	input iRST_N;
	input [7:0] code;
	output inter;
	
	reg inter;
	
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if (iRST_N) begin
			inter = 1'b0;
		end
		else begin
			case(code)
				8'h01: inter = 1'b1;
				8'h02: inter = 1'b0;
				default: inter = 1'b0;
			endcase
		end
	end
	
endmodule
