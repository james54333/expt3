module Audio( oAUD_LRCK, oAUD_BCK, oAUD_XCK, iCLK, iRST_N, speed, inter );

	input iCLK;
	input iRST_N;
	output oAUD_LRCK;
	output oAUD_BCK;
	output oAUD_XCK;
	
	input speed;
	input inter;
	
	reg [9:0] BCK_X1_DIV;
	reg [9:0] BCK_X2_DIV;
	reg [9:0] BCK_X3_DIV;
	reg [9:0] BCK_X4_DIV;
	reg [9:0] BCK_X5_DIV;
	reg [9:0] BCK_X6_DIV;
	reg [9:0] BCK_X7_DIV;
	reg [9:0] BCK_X8_DIV;
	reg [9:0] BCK_X1_2_DIV;
	reg [9:0] BCK_X1_3_DIV;
	reg [9:0] BCK_X1_4_DIV;
	reg [9:0] BCK_X1_5_DIV;
	reg [9:0] BCK_X1_6_DIV;
	reg [9:0] BCK_X1_7_DIV;
	reg [9:0] BCK_X1_8_DIV;
    
	reg [15:0] LRCK_X1_DIV;
	reg [15:0] LRCK_X2_DIV;
	reg [15:0] LRCK_X3_DIV;
	reg [15:0] LRCK_X4_DIV;
	reg [15:0] LRCK_X5_DIV;
	reg [15:0] LRCK_X6_DIV;
	reg [15:0] LRCK_X7_DIV;
	reg [15:0] LRCK_X8_DIV;
	reg [15:0] LRCK_X1_2_DIV;
	reg [15:0] LRCK_X1_3_DIV;
	reg [15:0] LRCK_X1_4_DIV;
	reg [15:0] LRCK_X1_5_DIV;
	reg [15:0] LRCK_X1_6_DIV;
	reg [15:0] LRCK_X1_7_DIV;
	reg [15:0] LRCK_X1_8_DIV;
    
	reg [3:0] XCK_X1_2_DIV;
	reg [3:0] XCK_X1_3_DIV;
	reg [3:0] XCK_X1_4_DIV;
	reg [3:0] XCK_X1_5_DIV;
	reg [3:0] XCK_X1_6_DIV;
	reg [3:0] XCK_X1_7_DIV;
	reg [3:0] XCK_X1_8_DIV;
    
	reg oAUD_LRCK;
	reg oAUD_BCK;
	reg oAUD_XCK;
    
	reg BCK_X1;
	reg BCK_X2;
	reg BCK_X3;
	reg BCK_X4;
	reg BCK_X5;
	reg BCK_X6;
	reg BCK_X7;
	reg BCK_X8;
	reg BCK_X1_2;
	reg BCK_X1_3;
	reg BCK_X1_4;
	reg BCK_X1_5;
	reg BCK_X1_6;
	reg BCK_X1_7;
	reg BCK_X1_8;
    
	reg LRCK_X1;
	reg LRCK_X2;
	reg LRCK_X3;
	reg LRCK_X4;
	reg LRCK_X5;
	reg LRCK_X6;
	reg LRCK_X7;
	reg LRCK_X8;
	reg LRCK_X1_2;
	reg LRCK_X1_3;
	reg LRCK_X1_4;
	reg LRCK_X1_5;
	reg LRCK_X1_6;
	reg LRCK_X1_7;
	reg LRCK_X1_8;
    
	reg XCK_X1;
	reg XCK_X1_2;
	reg XCK_X1_3;
	reg XCK_X1_4;
	reg XCK_X1_5;
	reg XCK_X1_6;
	reg XCK_X1_7;
	reg XCK_X1_8;
	
	wire [3:0] speed;
	wire inter;
	
	parameter REF_CLK = 18432000;    // 18.432MHz
	parameter SAMPLE_RATE2 = 32000;   // 16kHz *2
	parameter DATA_WIDTH = 16;      // each sample 16 bits
	parameter CHANNEL_NUM = 2;      // Left & Right channel
    parameter SDC2 = 1024000;         // SAMPLE_RATE * DATA_WIDTH * CHANNEL_NUM * 2
	
	parameter x1 = 4'd1;   // speed
	parameter x2 = 4'd2;
	parameter x3 = 4'd3;
	parameter x4 = 4'd4;
	parameter x5 = 4'd5;
	parameter x6 = 4'd6;
	parameter x7 = 4'd7;
	parameter x8 = 4'd8;
	parameter x1_2 = 4'd9;
	parameter x1_3 = 4'd10;
	parameter x1_4 = 4'd11;
	parameter x1_5 = 4'd12;
	parameter x1_6 = 4'd13;
	parameter x1_7 = 4'd14;
	parameter x1_8 = 4'd15;
	
    
	// generate AUD_BCK
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if(iRST_N) begin
			BCK_X1_DIV = 0;
			BCK_X2_DIV = 0;
			BCK_X3_DIV = 0;
			BCK_X4_DIV = 0;
			BCK_X5_DIV = 0;
			BCK_X6_DIV = 0;
			BCK_X7_DIV = 0;
			BCK_X8_DIV = 0;
			BCK_X1_2_DIV = 0;
			BCK_X1_3_DIV = 0;
			BCK_X1_4_DIV = 0;
			BCK_X1_5_DIV = 0;
			BCK_X1_6_DIV = 0;
			BCK_X1_7_DIV = 0;
			BCK_X1_8_DIV = 0;
			
			BCK_X1 = 0;
			BCK_X2 = 0;
			BCK_X3 = 0;
			BCK_X4 = 0;
			BCK_X5 = 0;
			BCK_X6 = 0;
			BCK_X7 = 0;
			BCK_X8 = 0;
			BCK_X1_2 = 0;
			BCK_X1_3 = 0;
			BCK_X1_4 = 0;
			BCK_X1_5 = 0;
			BCK_X1_6 = 0;
			BCK_X1_7 = 0;
			BCK_X1_8 = 0;
			
		end
		else begin
                        ///////     n     ///////////
			// BCK_X1
			if (BCK_X1_DIV < ((REF_CLK / SDC2) - 1))        BCK_X1_DIV <= ( BCK_X1_DIV + 1 );
			else begin                                      BCK_X1_DIV <= 0;                        BCK_X1 <= (~BCK_X1);    end
			
			// BCK_X2
			if (BCK_X2_DIV < ((REF_CLK / (SDC2*2)) - 1))    BCK_X2_DIV <= ( BCK_X2_DIV + 1 );
			else begin                                      BCK_X2_DIV <= 0;                        BCK_X2 <= (~BCK_X2);    end
			
			// BCK_X3
			if (BCK_X3_DIV < ((REF_CLK / (SDC2*3)) - 1))    BCK_X3_DIV <= ( BCK_X3_DIV + 1 );
			else begin                                      BCK_X3_DIV <= 0;                        BCK_X3 <= (~BCK_X3);    end
			
			// BCK_X4
			if (BCK_X4_DIV < ((REF_CLK / (SDC2*4)) - 1))    BCK_X4_DIV <= ( BCK_X4_DIV + 1 );
			else begin                                      BCK_X4_DIV <= 0;                        BCK_X4 <= (~BCK_X4);    end
			
			// BCK_X5
			if (BCK_X5_DIV < ((REF_CLK / (SDC2*5)) - 1))    BCK_X5_DIV <= ( BCK_X5_DIV + 1 );
			else begin                                      BCK_X5_DIV <= 0;                        BCK_X5 <= (~BCK_X5);    end
			
			// BCK_X6
			if (BCK_X6_DIV < ((REF_CLK / (SDC2*6)) - 1))    BCK_X6_DIV <= ( BCK_X6_DIV + 1 );
			else begin                                      BCK_X6_DIV <= 0;                        BCK_X6 <= (~BCK_X6);    end
			
			// BCK_X7
			if (BCK_X7_DIV < ((REF_CLK / (SDC2*7)) - 1))    BCK_X7_DIV <= ( BCK_X7_DIV + 1 );
			else begin                                      BCK_X7_DIV <= 0;                        BCK_X7 <= (~BCK_X7);    end
			
			// BCK_X8
			if (BCK_X8_DIV < ((REF_CLK / (SDC2*8)) - 1))    BCK_X8_DIV <= ( BCK_X8_DIV + 1 );
			else begin                                      BCK_X8_DIV <= 0;                        BCK_X8 <= (~BCK_X8);    end
			
                        ///////     1/n     ///////////
			// BCK_X1_2
            if (BCK_X1_2_DIV < ((REF_CLK / SDC2)*2 - 1))        BCK_X1_2_DIV <= ( BCK_X1_2_DIV + 1 );
			else begin                                          BCK_X1_2_DIV <= 0;                        BCK_X1_2 <= (~BCK_X1_2);    end
			
			// BCK_X1_3
			if (BCK_X1_3_DIV < ((REF_CLK / SDC2)*3 - 1))        BCK_X1_3_DIV <= ( BCK_X1_3_DIV + 1 );
			else begin                                          BCK_X1_3_DIV <= 0;                        BCK_X1_3 <= (~BCK_X1_3);    end

			// BCK_X1_4
			if (BCK_X1_4_DIV < ((REF_CLK / SDC2)*4 - 1))        BCK_X1_4_DIV <= ( BCK_X1_4_DIV + 1 );
			else begin                                          BCK_X1_4_DIV <= 0;                        BCK_X1_4 <= (~BCK_X1_4);    end

			// BCK_X1_5
			if (BCK_X1_5_DIV < ((REF_CLK / SDC2)*5 - 1))        BCK_X1_5_DIV <= ( BCK_X1_5_DIV + 1 );
			else begin                                          BCK_X1_5_DIV <= 0;                        BCK_X1_5 <= (~BCK_X1_5);    end

			// BCK_X1_6
			if (BCK_X1_6_DIV < ((REF_CLK / SDC2)*6 - 1))        BCK_X1_6_DIV <= ( BCK_X1_6_DIV + 1 );
			else begin                                          BCK_X1_6_DIV <= 0;                        BCK_X1_6 <= (~BCK_X1_6);    end

			// BCK_X1_7
			if (BCK_X1_7_DIV < ((REF_CLK / SDC2)*7 - 1))        BCK_X1_7_DIV <= ( BCK_X1_7_DIV + 1 );
			else begin                                          BCK_X1_7_DIV <= 0;                        BCK_X1_7 <= (~BCK_X1_7);    end

			// BCK_X1_8
			if (BCK_X1_8_DIV < ((REF_CLK / SDC2)*8 - 1))        BCK_X1_8_DIV <= ( BCK_X1_8_DIV + 1 );
			else begin                                          BCK_X1_8_DIV <= 0;                        BCK_X1_8 <= (~BCK_X1_8);    end

		end
	end
	
	
	// generate AUD_LRCK
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if (iRST_N) begin
			LRCK_X1_DIV = 0;
			LRCK_X2_DIV = 0;
			LRCK_X3_DIV = 0;
			LRCK_X4_DIV = 0;
			LRCK_X5_DIV = 0;
			LRCK_X6_DIV = 0;
			LRCK_X7_DIV = 0;
			LRCK_X8_DIV = 0;
			LRCK_X1_2_DIV = 0;
			LRCK_X1_3_DIV = 0;
			LRCK_X1_4_DIV = 0;
			LRCK_X1_5_DIV = 0;
			LRCK_X1_6_DIV = 0;
			LRCK_X1_7_DIV = 0;
			LRCK_X1_8_DIV = 0;
			
			LRCK_X1 = 0;
			LRCK_X2 = 0;
			LRCK_X3 = 0;
			LRCK_X4 = 0;
			LRCK_X5 = 0;
			LRCK_X6 = 0;
			LRCK_X7 = 0;
			LRCK_X8 = 0;
			LRCK_X1_2 = 0;
			LRCK_X1_3 = 0;
			LRCK_X1_4 = 0;
			LRCK_X1_5 = 0;
			LRCK_X1_6 = 0;
			LRCK_X1_7 = 0;
			LRCK_X1_8 = 0;
			
		end
		else begin
        
                        ///////     n     ///////////
			// LRCK_X1
            if (LRCK_X1_DIV < ( REF_CLK/(SAMPLE_RATE2) - 1 ))       LRCK_X1_DIV <= ( LRCK_X1_DIV + 1 );
			else begin                                              LRCK_X1_DIV <= 0;                       LRCK_X1 <= (~LRCK_X1);    end
			
			// LRCK_X2
            if (LRCK_X2_DIV < ( REF_CLK/(SAMPLE_RATE2*2) - 1 ))     LRCK_X2_DIV <= ( LRCK_X2_DIV + 1 );
			else begin                                              LRCK_X2_DIV <= 0;                       LRCK_X2 <= (~LRCK_X2);    end
			
			// LRCK_X3
			if (LRCK_X3_DIV < ( REF_CLK/(SAMPLE_RATE2*3) - 1 ))     LRCK_X3_DIV <= ( LRCK_X3_DIV + 1 );
			else begin                                              LRCK_X3_DIV <= 0;                       LRCK_X3 <= (~LRCK_X3);    end

			// LRCK_X4
			if (LRCK_X4_DIV < ( REF_CLK/(SAMPLE_RATE2*4) - 1 ))     LRCK_X4_DIV <= ( LRCK_X4_DIV + 1 );
			else begin                                              LRCK_X4_DIV <= 0;                       LRCK_X4 <= (~LRCK_X4);    end

			// LRCK_X5
            if (LRCK_X5_DIV < ( REF_CLK/(SAMPLE_RATE2*5) - 1 ))     LRCK_X5_DIV <= ( LRCK_X5_DIV + 1 );
			else begin                                              LRCK_X5_DIV <= 0;                       LRCK_X5 <= (~LRCK_X5);    end

			// LRCK_X6
			if (LRCK_X6_DIV < ( REF_CLK/(SAMPLE_RATE2*6) - 1 ))     LRCK_X6_DIV <= ( LRCK_X6_DIV + 1 );
			else begin                                              LRCK_X6_DIV <= 0;                       LRCK_X6 <= (~LRCK_X6);    end

			// LRCK_X7
			if (LRCK_X7_DIV < ( REF_CLK/(SAMPLE_RATE2*7) - 1 ))     LRCK_X7_DIV <= ( LRCK_X7_DIV + 1 );
			else begin                                              LRCK_X7_DIV <= 0;                       LRCK_X7 <= (~LRCK_X7);    end

			// LRCK_X8
			if (LRCK_X8_DIV < ( REF_CLK/(SAMPLE_RATE2*8) - 1 ))     LRCK_X8_DIV <= ( LRCK_X8_DIV + 1 );
			else begin                                              LRCK_X8_DIV <= 0;                       LRCK_X8 <= (~LRCK_X8);    end
            
                        ///////     1/n     ///////////
			// LRCK_X1_2
            if (LRCK_X1_2_DIV < ( (REF_CLK/(SAMPLE_RATE2)*2) - 1 )) LRCK_X1_2_DIV <= ( LRCK_X1_2_DIV + 1 );
			else begin                                              LRCK_X1_2_DIV <= 0;                     LRCK_X1_2 <= (~LRCK_X1_2);  end
			
			// LRCK_X1_3
			if (LRCK_X1_3_DIV < ( (REF_CLK/(SAMPLE_RATE2)*3) - 1 )) LRCK_X1_3_DIV <= ( LRCK_X1_3_DIV + 1 );
			else begin                                              LRCK_X1_3_DIV <= 0;                     LRCK_X1_3 <= (~LRCK_X1_3);  end
			
			// LRCK_X1_4
			if (LRCK_X1_4_DIV < ( (REF_CLK/(SAMPLE_RATE2)*4) - 1 )) LRCK_X1_4_DIV <= ( LRCK_X1_4_DIV + 1 );
			else begin                                              LRCK_X1_4_DIV <= 0;                     LRCK_X1_4 <= (~LRCK_X1_4);  end
			
			// LRCK_X1_5
			if (LRCK_X1_5_DIV < ( (REF_CLK/(SAMPLE_RATE2)*5) - 1 )) LRCK_X1_5_DIV <= ( LRCK_X1_5_DIV + 1 );
			else begin                                              LRCK_X1_5_DIV <= 0;                     LRCK_X1_5 <= (~LRCK_X1_5);  end
			
			// LRCK_X1_6
			if (LRCK_X1_6_DIV < ( (REF_CLK/(SAMPLE_RATE2)*6) - 1 )) LRCK_X1_6_DIV <= ( LRCK_X1_6_DIV + 1 );
			else begin                                              LRCK_X1_6_DIV <= 0;                     LRCK_X1_6 <= (~LRCK_X1_6);  end
			
			// LRCK_X1_7
			if (LRCK_X1_7_DIV < ( (REF_CLK/(SAMPLE_RATE2)*7) - 1 )) LRCK_X1_7_DIV <= ( LRCK_X1_7_DIV + 1 );
			else begin                                              LRCK_X1_7_DIV <= 0;                     LRCK_X1_7 <= (~LRCK_X1_7);  end
			
			// LRCK_X1_8
			if (LRCK_X1_8_DIV < ( (REF_CLK/(SAMPLE_RATE2)*8) - 1 )) LRCK_X1_8_DIV <= ( LRCK_X1_8_DIV + 1 );
			else begin                                              LRCK_X1_8_DIV <= 0;                     LRCK_X1_8 <= (~LRCK_X1_8);  end
			
		end
	end
	
	
	// generate XCK
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if (iRST_N) begin
			XCK_X1_2_DIV = 0;
			XCK_X1_3_DIV = 0;
			XCK_X1_4_DIV = 0;
			XCK_X1_5_DIV = 0;
			XCK_X1_6_DIV = 0;
			XCK_X1_7_DIV = 0;
			XCK_X1_8_DIV = 0;
			
			XCK_X1_2 = 0;
			XCK_X1_3 = 0;
			XCK_X1_4 = 0;
			XCK_X1_5 = 0;
			XCK_X1_6 = 0;
			XCK_X1_7 = 0;
			XCK_X1_8 = 0;
			
 		end
		else begin
			// XCK_X1
			//XCK_X1 <= (~XCK_X1);
			
			// XCK_X1_2
            if (XCK_X1_2_DIV < 1)       XCK_X1_2_DIV <= ( XCK_X1_2_DIV + 1 );
			else begin                  XCK_X1_2_DIV <= 0;                     XCK_X1_2 <= (~XCK_X1_2);     end
			
			// XCK_X1_3
			if (XCK_X1_3_DIV < 2)       XCK_X1_3_DIV <= ( XCK_X1_3_DIV + 1 );
			else begin                  XCK_X1_3_DIV <= 0;                     XCK_X1_3 <= (~XCK_X1_3);     end
            
			// XCK_X1_4
			if (XCK_X1_4_DIV < 3)       XCK_X1_4_DIV <= ( XCK_X1_4_DIV + 1 );
			else begin                  XCK_X1_4_DIV <= 0;                     XCK_X1_4 <= (~XCK_X1_4);     end
			
			// XCK_X1_5
			if (XCK_X1_5_DIV < 4)       XCK_X1_5_DIV <= ( XCK_X1_5_DIV + 1 );
			else begin                  XCK_X1_5_DIV <= 0;                     XCK_X1_5 <= (~XCK_X1_5);     end
			
			// XCK_X1_6
			if (XCK_X1_6_DIV < 5)       XCK_X1_6_DIV <= ( XCK_X1_6_DIV + 1 );
			else begin                  XCK_X1_6_DIV <= 0;                     XCK_X1_6 <= (~XCK_X1_6);     end
			
			// XCK_X1_7
			if (XCK_X1_7_DIV < 6)       XCK_X1_7_DIV <= ( XCK_X1_7_DIV + 1 );
			else begin                  XCK_X1_7_DIV <= 0;                     XCK_X1_7 <= (~XCK_X1_7);     end
			
			// XCK_X1_8
			if (XCK_X1_8_DIV < 7)       XCK_X1_8_DIV <= ( XCK_X1_8_DIV + 1 );
			else begin                  XCK_X1_8_DIV <= 0;                     XCK_X1_8 <= (~XCK_X1_8);     end
			
		end
	end
	
	
	 // select clock rate
	always @ (*) begin
		XCK_X1 = iCLK;
		case(speed)
			x1: begin
				oAUD_LRCK = LRCK_X1;
				oAUD_BCK = BCK_X1;
				oAUD_XCK = XCK_X1;
			end
			
			x2: begin
				oAUD_LRCK = LRCK_X2;
				oAUD_BCK = BCK_X2;
				oAUD_XCK = XCK_X1;
			end
			
			x3: begin
				oAUD_LRCK = LRCK_X3;
				oAUD_BCK = BCK_X3;
				oAUD_XCK = XCK_X1;
			end
			
			x4: begin
				oAUD_LRCK = LRCK_X4;
				oAUD_BCK = BCK_X4;
				oAUD_XCK = XCK_X1;
			end
			
			x5: begin
				oAUD_LRCK = LRCK_X5;
				oAUD_BCK = BCK_X5;
				oAUD_XCK = XCK_X1;
			end
			
			x6: begin
				oAUD_LRCK = LRCK_X6;
				oAUD_BCK = BCK_X6;
				oAUD_XCK = XCK_X1;
			end
			
			x7: begin
				oAUD_LRCK = LRCK_X7;
				oAUD_BCK = BCK_X7;
				oAUD_XCK = XCK_X1;
			end
			
			x8: begin
				oAUD_LRCK = LRCK_X8;
				oAUD_BCK = BCK_X8;
				oAUD_XCK = XCK_X1;
			end
			
			x1_2: begin
				oAUD_LRCK = LRCK_X1_2;
				oAUD_BCK = BCK_X1_2;
				oAUD_XCK = (inter) ? XCK_X1_2 : XCK_X1 ;
			end
			
			x1_3: begin
				oAUD_LRCK = LRCK_X1_3;
				oAUD_BCK = BCK_X1_3;
				oAUD_XCK = (inter) ? XCK_X1_3 : XCK_X1 ;
			end
			
			x1_4: begin
				oAUD_LRCK = LRCK_X1_4;
				oAUD_BCK = BCK_X1_4;
				oAUD_XCK = (inter) ? XCK_X1_4 : XCK_X1 ;
			end
			
			x1_5: begin
				oAUD_LRCK = LRCK_X1_5;
				oAUD_BCK = BCK_X1_5;
				oAUD_XCK = (inter) ? XCK_X1_5 : XCK_X1 ;
			end
			
			x1_6: begin
				oAUD_LRCK = LRCK_X1_6;
				oAUD_BCK = BCK_X1_6;
				oAUD_XCK = (inter) ? XCK_X1_6 : XCK_X1 ;
			end
			
			x1_7: begin
				oAUD_LRCK = LRCK_X1_7;
				oAUD_BCK = BCK_X1_7;
				oAUD_XCK = (inter) ? XCK_X1_7 : XCK_X1 ;
			end
			
			x1_8: begin
				oAUD_LRCK = LRCK_X1_8;
				oAUD_BCK = BCK_X1_8;
				oAUD_XCK = (inter) ? XCK_X1_8 : XCK_X1 ;
			end
			
			default: begin
				oAUD_LRCK = LRCK_X1;
				oAUD_BCK = BCK_X1;
				oAUD_XCK = XCK_X1;
			end
		endcase
	end
	
endmodule
