module I2C_control( CLOCK, I2C_SCLK, I2C_SDAT, I2C_DATA, GO, END, W_R, ACK, iRST_N, 
							  SD_COUNTER, SDO // test
);

	input CLOCK;
	input [23:0] I2C_DATA;
	input GO;
	input iRST_N;
	input W_R;
	inout I2C_SDAT;
	output I2C_SCLK;
	output END;
	output ACK;

	// test
	output [5:0] SD_COUNTER;
	output SDO;
	
	reg SDO;
	reg SCLK;
	reg END;
	reg [23:0] SD;
	reg [5:0] SD_COUNTER;
	
	wire I2C_SCLK = SCLK | ( ( ( SD_COUNTER >= 4 ) & ( SD_COUNTER <= 30 ) ) ? (~CLOCK) : 0 );
	wire I2C_SDAT = SDO ? 1'bz : 0 ;
	
	reg ACK1, ACK2, ACK3;
	wire ACK = ACK1 | ACK2 | ACK3 ;
	
	// I2C SD_COUNTER
	always @ ( posedge CLOCK or posedge iRST_N ) begin
		if (iRST_N) begin
			SD_COUNTER = 6'b111111;
		end
		else begin
			if ( GO == 0 ) begin
				SD_COUNTER = 6'b0;
			end
			else begin
				if ( SD_COUNTER < 6'b111111 ) begin
					SD_COUNTER = ( SD_COUNTER + 1 );
				end
			end
		end
	end
	
	// I2C SD_COUNTER output ACK
	always @ ( posedge CLOCK or posedge iRST_N ) begin
		if (iRST_N) begin
			SCLK = 1;
			SDO = 1;
			ACK1 = 0;
			ACK2 = 0;
			ACK3 = 0;
			END = 1;
		end
		else begin
			case(SD_COUNTER)
				6'd0: begin
					SCLK = 1;
					SDO = 1;
					ACK1 = 0;
					ACK2 = 0;
					ACK3 = 0;
					END = 0;
				end
				
				// Start
				6'd1: begin
					SD = I2C_DATA;
					SDO = 0;
				end
				6'd2: SCLK = 0;
				
				// Slave Address
				6'd3: SDO = SD[23];
				6'd4: SDO = SD[22];
				6'd5: SDO = SD[21];
				6'd6: SDO = SD[20];
				6'd7: SDO = SD[19];
				6'd8: SDO = SD[18];
				6'd9: SDO = SD[17];
				6'd10: SDO = SD[16];
				6'd11: SDO = 1'b1;    // ACK
				
				// Sub Address
				6'd12: begin
					SDO = SD[15];
					ACK1 = I2C_SDAT;
				end
				6'd13: SDO = SD[14];
				6'd14: SDO = SD[13];
				6'd15: SDO = SD[12];
				6'd16: SDO = SD[11];
				6'd17: SDO = SD[10];
				6'd18: SDO = SD[9];
				6'd19: SDO = SD[8];
				6'd20: SDO = 1'b1;    // ACK
				
				// DATA
				6'd21: begin
					SDO = SD[7];
					ACK2 = I2C_SDAT;
				end
				6'd22: SDO = SD[6];
				6'd23: SDO = SD[5];
				6'd24: SDO = SD[4];
				6'd25: SDO = SD[3];
				6'd26: SDO = SD[2];
				6'd27: SDO = SD[1];
				6'd28: SDO = SD[0];
				6'd29: SDO = 1'b1;    // ACK
				
				// Stop
				6'd30: begin
					SDO = 1'b0;
					SCLK = 1'b0;
					ACK3 = I2C_SDAT;
				end
				6'd31: SCLK = 1'b1;
				6'd32: begin
					SDO = 1'b1;
					END = 1;
				end
			endcase
		end
		
	end
	
endmodule
