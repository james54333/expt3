module xpt3( CLOCK_50, SW, KEY, GPIO, LEDR, // control
				  AUD_DACLRCK, AUD_ADCLRCK, AUD_ADCDAT, AUD_DACDAT, AUD_XCK, AUD_BCLK, I2C_SCLK, I2C_SDAT, // AUDIO CODEC
				  SRAM_DQ, SRAM_ADDR, SRAM_WE_N, SRAM_OE_N, SRAM_CE_N, SRAM_UB_N, SRAM_LB_N, // SRAM
				  LCD_DATA, LCD_RW, LCD_EN, LCD_RS, LCD_ON, LCD_BLON, // LCD module
				  TD_CLK27, // TV Decoder
				  IRDA_RXD  // IR_RECEIVER
				  );

	// define input and output
	input CLOCK_50;
	input [3:0] KEY;
	input [9:0] SW;
	
	inout AUD_DACLRCK;
	inout AUD_ADCLRCK;
	input AUD_ADCDAT;
	output AUD_DACDAT;
	output AUD_XCK;
	inout AUD_BCLK;
	output I2C_SCLK;
	inout I2C_SDAT;
	
	inout [15:0] SRAM_DQ;
	output [19:0] SRAM_ADDR;
	output SRAM_WE_N;
	output SRAM_OE_N;
	output SRAM_CE_N;
	output SRAM_UB_N;
	output SRAM_LB_N;
	
	output [7:0] LCD_DATA;
	output LCD_RW;
	output LCD_EN;
	output LCD_RS;
	output LCD_ON;
	output LCD_BLON;
	
	input TD_CLK27;
	input IRDA_RXD;
	
	//////////////// debug ////////////////
	output [35:0] GPIO;
	assign GPIO[0] = SW[9];
	assign GPIO[1] = AUD_ADCLRCK;
	assign GPIO[2] = AUD_DACLRCK;
	assign GPIO[3] = AUD_BCLK;
	assign GPIO[4] = AUD_XCK;
	assign GPIO[5] = AUD_CTRL_CLK;
	assign GPIO[6] = temp_sdata[15];
	assign GPIO[7] = SRAM_DQ[15];
	assign GPIO[8] = AUD_ADCDAT;
	assign GPIO[9] = AUD_DACDAT;
	assign GPIO[14:10] = Lcounter;
	assign GPIO[15] = SRAM_ADDR[0];
	
	output [17:0] LEDR;
	reg [17:0] LEDR;
	///////////////////////////////////////
		
	// define reg and wire
	wire reset;
	wire i2c_ready;
	wire play;
	wire rec;
	wire stop;
	wire spdswitch;
	wire spdctrl;
	wire lowspeed;
	wire mLCD_Done;
	wire AUD_CTRL_CLK;
	wire data_ready;
	wire [31:0] hex_data;
	
	reg mLCD_Start;
	reg mLCD_RS;
	reg AUD_DACDAT;
	reg full;
	reg speed_flag;
	reg [5:0] LUT_INDEX;
	reg [8:0] LUT_DATA;
	reg [5:0] mLCD_ST;
	reg [17:0] mDLY;
	reg [7:0] mLCD_DATA;
	reg [2:0] state;
	reg [2:0] state_next;
    
    reg [2:0] counter;
    reg [2:0] counter_limit;
    
	reg [4:0] Lcounter;
	reg [4:0] Lcounter_next;
	reg [4:0] Rcounter;
	reg [4:0] Rcounter_next;
    
	reg [15:0] SRAM_DQ;
	reg [15:0] sdata;
	reg [18:0] temp_sdata;
    reg [15:0] temp_sdata_P;
    
    reg [15:0] sdata_now;
    reg [15:0] sdata_past;
    
	reg [19:0] SRAM_ADDR;
	reg [19:0] temp_addr;
	reg [19:0] full_addr;
	reg [3:0] speed;
	reg [3:0] speed_next;
	reg [8:0] step;
	reg [26:0] time_div;
	reg [6:0] time_sec;
	
	// define parameter
	parameter IDLE = 3'd0;
	parameter PLAY = 3'd1;
	parameter REC = 3'd2;
	parameter REC_PAUSE = 3'd3;
	parameter PLAY_PAUSE = 3'd4;
	
	parameter LCD_INITIAL = 0;
	parameter LCD_LINE1 = 5;
	parameter LCD_CH_LINE = LCD_LINE1 + 16;
	parameter LCD_LINE2 = LCD_LINE1 + 16 + 1;
	parameter LUT_SIZE = LCD_LINE1 + 32 + 1;
	
	parameter x1    = 4'd8 ;
	parameter x2    = 4'd9 ;
	parameter x3    = 4'd10;
	parameter x4    = 4'd11;
	parameter x5    = 4'd12;
	parameter x6    = 4'd13;
	parameter x7    = 4'd14;
	parameter x8    = 4'd15;
	parameter x1_2  = 4'd1;
	parameter x1_3  = 4'd2;
	parameter x1_4  = 4'd3;
	parameter x1_5  = 4'd4;
	parameter x1_6  = 4'd5;
	parameter x1_7  = 4'd6;
	parameter x1_8  = 4'd7;
		
	// assignment
	assign spdswitch = SW[0];
	assign lowspeed = SW[1];
	//assign inter = SW[2];
	assign reset = SW[3];
	assign SRAM_WE_N = ( ( state == REC ) || (reset) ) ? 1'b0 : 1'b1;
	assign SRAM_OE_N = 1'b0;
	assign SRAM_CE_N = 1'b0;
	assign SRAM_UB_N = 1'b0;
	assign SRAM_LB_N = 1'b0;
	assign LCD_ON = 1'b1;
	assign LCD_BLON = 1'b1;
	
	
	// KEY handle
	key key_0( KEY[0], CLOCK_50, play );
	key key_1( KEY[1], CLOCK_50, rec );
	key key_2( KEY[2], CLOCK_50, stop );
	key key_3( KEY[3], CLOCK_50, spdctrl );
	
	// I2C handle
	I2C I2C_setting( CLOCK_50, reset, i2c_ready, I2C_SCLK, I2C_SDAT );
	
	// Audio handle
	assign AUD_ADCLRCK = AUD_DACLRCK;
	Audio Audio_setting( AUD_DACLRCK, AUD_BCLK, AUD_XCK, AUD_CTRL_CLK, reset );
	Audio_PLL Audio_clock( .areset(~i2c_ready), .inclk0(TD_CLK27), .c1(AUD_CTRL_CLK) );
	
	
	//============================== main function start ==============================
	
	// time counter
	always @ ( posedge AUD_ADCLRCK ) begin
		if (reset) begin
			time_div = 27'b0;
			time_sec = 7'b0;
		end
		else begin
			case(state)
				IDLE: begin
					time_div = 27'b0;
					time_sec = 7'b0;
				end
				
				PLAY, REC: begin
					if ( time_div < 27'd15576 ) begin  // LRCK_X1 = 15.576kHz
						time_div = ( time_div + 27'b1 );
					end
					else begin
						time_div = 27'b0;
						time_sec = ( time_sec + 7'b1 );
					end
				end
				
				PLAY_PAUSE, REC_PAUSE: begin
					time_div = time_div;
					time_sec = time_sec;
				end
				
				default: begin
					time_div = 27'b0;
					time_sec = 7'b0;
				end
			endcase
		end
	end
	
	
	// state control
	always @ ( posedge CLOCK_50 ) begin
		state = ( i2c_ready == 0 ) ? IDLE : state_next;
	end

	always @ (*) begin
		case(state)
			IDLE: begin
				if ( ( play == 1 ) && ( rec != 1 ) && ( stop != 1 ) ) begin
					state_next = PLAY;
				end
				else if ( ( play != 1 ) && ( rec == 1 ) && ( stop != 1 ) ) begin
					state_next = REC;
				end
				else begin
					state_next = IDLE;
				end
			end
			
			PLAY: begin
				if ( ( play == 1 ) && ( rec != 1 ) && ( stop != 1 ) ) begin
					state_next = PLAY_PAUSE;
				end
				else if ( ( play != 1 ) && ( rec != 1 ) && ( stop == 1 ) || (full) ) begin
					state_next = IDLE;
				end
				else begin
					state_next = PLAY;
				end
			end
			
			REC: begin
				if ( ( play != 1 ) && ( rec == 1 ) && ( stop != 1 ) ) begin
					state_next = REC_PAUSE;
				end
				else if ( ( play != 1 ) && ( rec != 1 ) && ( stop == 1 ) || (full) ) begin
					state_next = IDLE;
				end
				else begin
					state_next = REC;
				end
			end
			
			PLAY_PAUSE: begin
				if ( ( play == 1 ) && ( rec != 1 ) && ( stop != 1 ) ) begin
					state_next = PLAY;
				end
				else if ( ( play != 1 ) && ( rec != 1 ) && ( stop == 1 ) ) begin
					state_next = IDLE;
				end
				else begin
					state_next = PLAY_PAUSE;
				end
			end
			
			REC_PAUSE: begin
				if ( ( play != 1 ) && ( rec == 1 ) && ( stop != 1 ) ) begin
					state_next = REC;
				end
				else if ( ( play != 1 ) && ( rec != 1 ) && ( stop == 1 ) ) begin
					state_next = IDLE;
				end
				else begin
					state_next = REC_PAUSE;
				end
			end			
			default:
				state_next = IDLE;
		endcase
	end
	
	
	// speed control
	always @ ( posedge CLOCK_50 ) begin
		speed = (reset)? x1 : speed_next;
        counter_limit = (reset)? 3'b0 : speed_next[2:0];
	end
	
	always @ (*) begin
		if (~spdswitch) begin
			speed_next = x1;
		end
		else begin
			case(speed)
				x1: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x2;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_2;
					end
					else begin
						speed_next = x1;
					end
				end
				
				x2: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x3;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1;
					end
					else begin
						speed_next = x2;
					end
				end
				
				x3: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x4;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x2;
					end
					else begin
						speed_next = x3;
					end
				end
				
				x4: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x5;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x3;
					end
					else begin
						speed_next = x4;
					end
				end
				
				x5: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x6;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x4;
					end
					else begin
						speed_next = x5;
					end
				end
				
				x6: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x7;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x5;
					end
					else begin
						speed_next = x6;
					end
				end
				
				x7: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x8;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x6;
					end
					else begin
						speed_next = x7;
					end
				end
				
				x8: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x7;
					end
					else begin
						speed_next = x8;
					end
				end
				
				x1_2: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_3;
					end
					else begin
						speed_next = x1_2;
					end
				end
				
				x1_3: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_2;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_4;
					end
					else begin
						speed_next = x1_3;
					end
				end
				
				x1_4: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_3;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_5;
					end
					else begin
						speed_next = x1_4;
					end
				end
				
				x1_5: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_4;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_6;
					end
					else begin
						speed_next = x1_5;
					end
				end
				
				x1_6: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_5;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_7;
					end
					else begin
						speed_next = x1_6;
					end
				end
				
				x1_7: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_6;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_8;
					end
					else begin
						speed_next = x1_7;
					end
				end
				
				x1_8: begin
					if ( ( lowspeed == 0 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1_7;
					end
					else if ( ( lowspeed == 1 ) && ( spdctrl == 1 ) ) begin
						speed_next = x1;
					end
					else begin
						speed_next = x1_8;
					end
				end
				
				default: begin
					speed_next = x1;
				end
			endcase
		end
	end
	
	
	// ADC and DAC with SRAM
	always @ ( posedge AUD_BCLK ) begin
		if (reset) begin
			Lcounter = 5'd0;
			Rcounter = 5'd0;
			sdata = 16'b0;
		end
		else begin
			Lcounter = Lcounter_next;
			Rcounter = Rcounter_next;
			sdata = temp_sdata[15:0];
		end
	end
	
    wire [2:0] counter_temp = (counter==counter_limit)? 3'd0 : counter + 3'd1;
    
	always @ ( posedge AUD_ADCLRCK ) begin
		case(state)
			IDLE: begin
				temp_addr = 20'b0;
				full = 1'b0;
			end
		
			PLAY: begin
                counter <= counter_temp;
                
                case(speed)
                    x1  : temp_addr = SRAM_ADDR + 20'd1;
                    x2  : temp_addr = SRAM_ADDR + 20'd2;
                    x3  : temp_addr = SRAM_ADDR + 20'd3;
                    x4  : temp_addr = SRAM_ADDR + 20'd4;
                    x5  : temp_addr = SRAM_ADDR + 20'd5;
                    x6  : temp_addr = SRAM_ADDR + 20'd6;
                    x7  : temp_addr = SRAM_ADDR + 20'd7;
                    x8  : temp_addr = SRAM_ADDR + 20'd8;
                    default: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_2: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_3: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_4: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_5: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_6: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_7: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                    //x1_8: temp_addr = (counter==counter_limit)? SRAM_ADDR + 20'd1 : SRAM_ADDR;
                endcase
				full = ( ( temp_addr >= 20'b11111111111111111111 ) || ( temp_addr >= full_addr ) ) ? 1'b1 : 1'b0 ;
			end
		
			REC: begin
				temp_addr = ( SRAM_ADDR + 20'b1 );
				full = ( temp_addr >= 20'b11111111111111111111 ) ? 1'b1 : 1'b0 ;
			end
		
			PLAY_PAUSE: begin
				temp_addr = SRAM_ADDR;
				full = 1'b0;
			end
			
			REC_PAUSE: begin
				temp_addr = SRAM_ADDR;
				full = 1'b0;
			end
			
			default: begin
				temp_addr = 20'b0;
				full = 1'b0;
			end
		endcase
	end
	
	always @ ( posedge AUD_XCK ) begin
		if(reset) begin
			full_addr = 20'b0;
			SRAM_ADDR = ( SRAM_ADDR >= 20'b11111111111111111111 ) ?  20'b0 :( SRAM_ADDR + 20'b1 );
			SRAM_DQ <= 16'b0;
            sdata_now = 16'd0;
            sdata_past = 16'd0;
		end
		else if ( AUD_ADCLRCK == 1 ) begin
			Rcounter_next = 5'd0;
			Lcounter_next = ( Lcounter == 16 ) ? 5'd0 : ( Lcounter + 5'd1 );
			
			case(state)
				IDLE: begin
					temp_sdata[15:0] = 16'b0;
					SRAM_ADDR = temp_addr;
					AUD_DACDAT = 1'b0;
				end
			
				PLAY: begin
					SRAM_DQ <= 'bz;
					SRAM_ADDR = temp_addr;
					
                    if (Lcounter==5'd0 && counter==3'd0)            sdata_now = SRAM_DQ;
                    if (Lcounter==5'd0 && counter==counter_limit)   sdata_past = sdata_now;
					
                    if ( Lcounter == 5'd0 ) begin
                        case(speed)
                            x1_2: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/2;
                            x1_3: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/3;
                            x1_4: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/4;
                            x1_5: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/5;
                            x1_6: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/6;
                            x1_7: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/7;
                            x1_8: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/8;
                            default: temp_sdata[15:0] = SRAM_DQ;
                        endcase
					end
					else begin
                        temp_sdata[15:0] = { sdata[14:0], 1'b0 };
					end
					
					AUD_DACDAT = temp_sdata[15];
				end
				
				REC: begin
					SRAM_ADDR = temp_addr;
					full_addr = temp_addr;
					
					case(Lcounter)
						5'd1: temp_sdata[15:0] = { AUD_ADCDAT, sdata[14:0] };
						5'd2: temp_sdata[15:0] = { sdata[15], AUD_ADCDAT, sdata[13:0] };
						5'd3: temp_sdata[15:0] = { sdata[15:14], AUD_ADCDAT, sdata[12:0] };
						5'd4: temp_sdata[15:0] = { sdata[15:13], AUD_ADCDAT, sdata[11:0] };
						5'd5: temp_sdata[15:0] = { sdata[15:12], AUD_ADCDAT, sdata[10:0] };
						5'd6: temp_sdata[15:0] = { sdata[15:11], AUD_ADCDAT, sdata[9:0] };
						5'd7: temp_sdata[15:0] = { sdata[15:10], AUD_ADCDAT, sdata[8:0] };
						5'd8: temp_sdata[15:0] = { sdata[15:9], AUD_ADCDAT, sdata[7:0] };
						5'd9: temp_sdata[15:0] = { sdata[15:8], AUD_ADCDAT, sdata[6:0] };
						5'd10: temp_sdata[15:0] = { sdata[15:7], AUD_ADCDAT, sdata[5:0] };
						5'd11: temp_sdata[15:0] = { sdata[15:6], AUD_ADCDAT, sdata[4:0] };
						5'd12: temp_sdata[15:0] = { sdata[15:5], AUD_ADCDAT, sdata[3:0] };
						5'd13: temp_sdata[15:0] = { sdata[15:4], AUD_ADCDAT, sdata[2:0] };
						5'd14: temp_sdata[15:0] = { sdata[15:3], AUD_ADCDAT, sdata[1:0] };
						5'd15: temp_sdata[15:0] = { sdata[15:2], AUD_ADCDAT, sdata[0] };
						5'd16: temp_sdata[15:0] = { sdata[15:1], AUD_ADCDAT };
						default: temp_sdata[15:0] = sdata;
					endcase
					
					if ( Lcounter == 5'd16 ) begin
						SRAM_DQ <= temp_sdata[15:0];
					end
					else begin
						SRAM_DQ <= 16'b0;
					end
					
					AUD_DACDAT = 1'b0;
				end
				
				PLAY_PAUSE: begin
					SRAM_ADDR = temp_addr;
				end
				
				REC_PAUSE: begin
					SRAM_ADDR = temp_addr;
				end

				default: begin
					temp_sdata[15:0] = 16'b0;
					SRAM_ADDR = temp_addr;
					AUD_DACDAT = 1'b0;
				end
			endcase
		end
		else begin
			Lcounter_next = 5'd0;
			Rcounter_next = ( Rcounter == 16 ) ? 5'd0 : ( Rcounter + 5'd1 );
			
			case(state)
				IDLE: begin
					temp_sdata[15:0] = 16'b0;
					SRAM_ADDR = temp_addr;
					AUD_DACDAT = 1'b0;
				end
			
				PLAY: begin
					SRAM_DQ <= 'bz;
					SRAM_ADDR = temp_addr;
					//SRAM_ADDR =  ( ( temp_addr + 1 ) >= 20'b11111111111111111111 ) ? (temp_addr) : ( temp_addr + 1 );
					
					if (Rcounter==5'd0 && counter==3'd0)            sdata_now = SRAM_DQ;
                    if (Rcounter==5'd0 && counter==counter_limit)   sdata_past = sdata_now;
					
                    if ( Rcounter == 5'd0 ) begin
                        case(speed)
                            x1_2: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/2;
                            x1_3: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/3;
                            x1_4: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/4;
                            x1_5: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/5;
                            x1_6: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/6;
                            x1_7: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/7;
                            x1_8: temp_sdata =((counter_limit-counter+3'd1)*sdata_past + counter*sdata_now)/8;
                            default: temp_sdata[15:0] = SRAM_DQ;
                        endcase
					end
					else begin
                        temp_sdata[15:0] = { sdata[14:0], 1'b0 };
					end
					
					AUD_DACDAT = temp_sdata[15];
				end
				
				REC: begin 
					AUD_DACDAT = 1'b0;
				end
				
				PLAY_PAUSE: begin
					SRAM_ADDR = temp_addr;
				end
				
				REC_PAUSE: begin
					SRAM_ADDR = temp_addr;
				end
				
				default: begin
					temp_sdata[15:0] = 16'b0;
					SRAM_ADDR = temp_addr;
					AUD_DACDAT = 1'b0;
				end
			endcase
		end
	end
	
	
	// LCD display
	always@( posedge CLOCK_50 or posedge reset ) begin
		if ( reset ) begin
			LUT_INDEX	<=	0;
			mLCD_ST		<=	0;
			mDLY		<=	0;
			mLCD_Start	<=	0;
			mLCD_DATA	<=	0;
			mLCD_RS		<=	0;
		end
		else begin
			if ( LUT_INDEX < LUT_SIZE )
			begin
				case(mLCD_ST)
				0:	begin
						mLCD_DATA	<=	LUT_DATA[7:0];
						mLCD_RS		<=	LUT_DATA[8];
						mLCD_Start	<=	1;
						mLCD_ST		<=	1;
					end
				1:	begin
						if (mLCD_Done) begin
							mLCD_Start	<=	0;
							mLCD_ST		<=	2;
						end
					end
				2:	begin
						if (mDLY<18'h3FFFE)
						mDLY <= ( mDLY + 1 );
						else begin
							mDLY	<=	0;
							mLCD_ST	<=	3;
						end
					end
				3:	begin
						LUT_INDEX <= ( LUT_INDEX == LCD_LINE2 + 15 ) ? ( LCD_INITIAL + 4 ) : ( LUT_INDEX + 1 );
						mLCD_ST <= 0;
					end
				endcase
			end
		end
	end

	always @ ( posedge CLOCK_50 ) begin
		case(LUT_INDEX)
		//	Initial
		LCD_INITIAL+0:	LUT_DATA	<=	9'h038;
		LCD_INITIAL+1:	LUT_DATA	<=	9'h00C;
		LCD_INITIAL+2:	LUT_DATA	<=	9'h001;
		LCD_INITIAL+3:	LUT_DATA	<=	9'h006;
		LCD_INITIAL+4:	LUT_DATA	<=	9'h080;
		//	Line 1	
		LCD_LINE1+0:	LUT_DATA	<=	9'h120;//	
		LCD_LINE1+1:	LUT_DATA	<=	9'h120;//
		LCD_LINE1+2:	LUT_DATA	<=	9'h120;//
		LCD_LINE1+3:	begin              // I R P P R
							case(state)
							IDLE: LUT_DATA <= 9'h149;
							REC:  LUT_DATA <= 9'h152;
							PLAY, REC_PAUSE, PLAY_PAUSE: LUT_DATA <= 9'h150;
							default: LUT_DATA <= 9'h120;
							endcase            
		end
		LCD_LINE1+4:	begin              // D E L A E
							case(state)
								IDLE: LUT_DATA <= 9'h144;
								REC:  LUT_DATA <= 9'h145;
								PLAY: LUT_DATA <= 9'h14C;
								REC_PAUSE, PLAY_PAUSE: LUT_DATA <= 9'h141;
								default: LUT_DATA <= 9'h120;
							endcase
		end
		LCD_LINE1+5:	begin              // L C A U V
							case(state)
								IDLE: LUT_DATA <= 9'h14C;
								REC:  LUT_DATA <= 9'h143;
								PLAY: LUT_DATA <= 9'h141;
								REC_PAUSE, PLAY_PAUSE: LUT_DATA <= 9'h155;
								default: LUT_DATA <= 9'h120;
							endcase
		end
		LCD_LINE1+6:	begin              // E   Y S E
							case(state)
								IDLE: LUT_DATA <= 9'h145;
								REC:  LUT_DATA <= 9'h120;
								PLAY: LUT_DATA <= 9'h159;
								REC_PAUSE, PLAY_PAUSE: LUT_DATA <= 9'h153;
								default: LUT_DATA <= 9'h120;
							endcase
		end
		LCD_LINE1+7:	begin              //       E R
							case(state)
								IDLE, REC, PLAY: LUT_DATA <= 9'h120;
								REC_PAUSE, PLAY_PAUSE: LUT_DATA <= 9'h145;
								default: LUT_DATA <= 9'h120;
							endcase
		end 
		LCD_LINE1+8:	LUT_DATA	<=	9'h120;// 
		LCD_LINE1+9:	LUT_DATA	<=	9'h14d;// M
		LCD_LINE1+10:	LUT_DATA	<=	9'h14f;// O
		LCD_LINE1+11:	LUT_DATA	<=	9'h144;// D
		LCD_LINE1+12:	LUT_DATA	<=	9'h145;// D
		LCD_LINE1+13:	LUT_DATA	<=	9'h120;// 
		LCD_LINE1+14:	LUT_DATA	<=	9'h120;// 
		LCD_LINE1+15:	LUT_DATA	<=	9'h120;// 
		
		//	Change Line
		LCD_CH_LINE:	LUT_DATA	<=	9'h0C0;
		
		//	Line 2
		LCD_LINE2+0:	begin              //    T  T  T  T
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h154;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+1:	begin              //    I  I  I  I
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h149;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end 
		LCD_LINE2+2:	begin              //    M  M  M  M
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h14d;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+3:	begin              // Z  E  E  E  E
							case(state)
                            IDLE:   LUT_DATA <= 9'h15a;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h145;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+4:	begin              // z  :  :  :  :
							case(state)
                            IDLE:   LUT_DATA <= 9'h17a;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h13a;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+5:	begin              // (  sec sec sec sec
							case(state)
                            IDLE:   LUT_DATA <= 9'h17b;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE: begin case(time_sec)
                                                                       7'd0, 7'd1, 7'd2, 7'd3, 7'd4, 7'd5, 7'd6, 7'd7, 7'd8, 7'd9: LUT_DATA	<=	9'h130;// 0
                                                                       7'd10, 7'd11, 7'd12, 7'd13, 7'd14, 7'd15, 7'd16, 7'd17, 7'd18, 7'd19: LUT_DATA	<=	9'h131;// 1
                                                                       7'd20, 7'd21, 7'd22, 7'd23, 7'd24, 7'd25, 7'd26, 7'd27, 7'd28, 7'd29: LUT_DATA	<=	9'h132;// 2
                                                                       7'd30, 7'd31, 7'd32, 7'd33, 7'd34, 7'd35, 7'd36, 7'd37, 7'd38, 7'd39: LUT_DATA	<=	9'h133;// 3
                                                                       7'd40, 7'd41, 7'd42, 7'd43, 7'd44, 7'd45, 7'd46, 7'd47, 7'd48, 7'd49: LUT_DATA	<=	9'h134;// 4
                                                                       7'd50, 7'd51, 7'd52, 7'd53, 7'd54, 7'd55, 7'd56, 7'd57, 7'd58, 7'd59: LUT_DATA	<=	9'h135;// 5
                                                                       7'd60, 7'd61, 7'd62, 7'd63, 7'd64, 7'd65, 7'd66, 7'd67, 7'd68, 7'd69: LUT_DATA	<=	9'h136;// 6
                                                                       7'd70, 7'd71, 7'd72, 7'd73, 7'd74, 7'd75, 7'd76, 7'd77, 7'd78, 7'd79: LUT_DATA   <= 9'h137;// 7
                                                                       default: LUT_DATA	<=	9'h120;
                                                                       endcase ;
                                                                       end
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+6:	begin              // '  sec sec sec sec
							case(state)
                            IDLE:   LUT_DATA <= 9'h12f;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE: begin case(time_sec)
                                                                       7'd1, 7'd11, 7'd21, 7'd31, 7'd41, 7'd51, 7'd61: LUT_DATA	<=	9'h131;// 1
                                                                       7'd2, 7'd12, 7'd22, 7'd32, 7'd42, 7'd52, 7'd62: LUT_DATA	<=	9'h132;// 2
                                                                       7'd3, 7'd13, 7'd23, 7'd33, 7'd43, 7'd53, 7'd63: LUT_DATA	<=	9'h133;// 3
                                                                       7'd4, 7'd14, 7'd24, 7'd34, 7'd44, 7'd54, 7'd64: LUT_DATA	<=	9'h134;// 4
                                                                       7'd5, 7'd15, 7'd25, 7'd35, 7'd45, 7'd55, 7'd65: LUT_DATA	<=	9'h135;// 5
                                                                       7'd6, 7'd16, 7'd26, 7'd36, 7'd46, 7'd56, 7'd66: LUT_DATA	<=	9'h136;// 6
                                                                       7'd7, 7'd17, 7'd27, 7'd37, 7'd47, 7'd57, 7'd67: LUT_DATA	<=	9'h137;// 7
                                                                       7'd8, 7'd18, 7'd28, 7'd38, 7'd48, 7'd58, 7'd68: LUT_DATA	<=	9'h138;// 8
                                                                       7'd9, 7'd19, 7'd29, 7'd39, 7'd49, 7'd59, 7'd69: LUT_DATA	<=	9'h139;// 9
                                                                       7'd0, 7'd10, 7'd20, 7'd30, 7'd40, 7'd50, 7'd60, 7'd70: LUT_DATA	<=	9'h130;// 0
                                                                       default: LUT_DATA	<=	9'h120;
                                                                       endcase ;
                                                                       end
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+7:	begin              // -  s  s  s  s
							case(state)
                            IDLE:   LUT_DATA <= 9'h12d;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h173;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+8:	begin              // w   
							case(state)
                            IDLE:   LUT_DATA <= 9'h177;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h120;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+9:	begin              // -  S  S  S  S
							case(state)
                            IDLE:   LUT_DATA <= 9'h12d;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h153;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+10:	begin              // '  P  P  P  P
							case(state)
                            IDLE:   LUT_DATA <= 9'h160;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h150;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+11:	begin              // *  D  D  D  D
							case(state)
                            IDLE:   LUT_DATA <= 9'h12a;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h144;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+12:	begin              // )  :  :  :  :
							case(state)
                            IDLE:   LUT_DATA <= 9'h17d;
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  LUT_DATA <= 9'h13a;
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+13:	begin                  
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;//
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  begin 
                                case(speed)
								x1_2, x1_3, x1_4, x1_5, x1_6, x1_7, x1_8: LUT_DATA <= 9'h131;//1
								x1,x2,x3,x4,x5,x6,x7,x8: LUT_DATA <= 9'h178;//x
								default: LUT_DATA <= 9'h120;
                            endcase
                            end
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+14:	begin                  
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;//
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  begin 
                                case(speed)
								x1_2, x1_3, x1_4, x1_5, x1_6, x1_7, x1_8: LUT_DATA <= 9'h12f;// /
                                x1: LUT_DATA <= 9'h131;//1
								x2: LUT_DATA <= 9'h132;//2
								x3: LUT_DATA <= 9'h133;//3
								x4: LUT_DATA <= 9'h134;//4
								x5: LUT_DATA <= 9'h135;//5
								x6: LUT_DATA <= 9'h136;//6
								x7: LUT_DATA <= 9'h137;//7
								x8: LUT_DATA <= 9'h138;//8
								default: LUT_DATA <= 9'h120;
							endcase
                            end
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		LCD_LINE2+15:	begin                  
							case(state)
                            IDLE:   LUT_DATA <= 9'h120;//
                            REC, PLAY, REC_PAUSE, PLAY_PAUSE:  begin 
                                case(speed)
								x1_2: LUT_DATA <= 9'h132;// 2
                                x1_3: LUT_DATA <= 9'h133;// 3 
                                x1_4: LUT_DATA <= 9'h134;// 4
                                x1_5: LUT_DATA <= 9'h135;// 5
                                x1_6: LUT_DATA <= 9'h136;// 6
                                x1_7: LUT_DATA <= 9'h137;// 7
                                x1_8: LUT_DATA <= 9'h138;// 8
								x1,x2,x3,x4,x5,x6,x7,x8: LUT_DATA <= 9'h120;//
								default: LUT_DATA <= 9'h120;//
							endcase
                            end
                            default: LUT_DATA <= 9'h120;
                            endcase
                        end
		default:		LUT_DATA	<=	9'hxxx;
		endcase
	end

	LCD_Controller 		u0	(	//	Host Side
								.iDATA(mLCD_DATA),
								.iRS(mLCD_RS),
								.iStart(mLCD_Start),
								.oDone(mLCD_Done),
								.iCLK(CLOCK_50),
								.iRST_N(reset),
								//	LCD Interface
								.LCD_DATA(LCD_DATA),
								.LCD_RW(LCD_RW),
								.LCD_EN(LCD_EN),
								.LCD_RS(LCD_RS)	);

		
endmodule 