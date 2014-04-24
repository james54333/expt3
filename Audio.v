module Audio( oAUD_LRCK, oAUD_BCK, oAUD_XCK, iCLK, iRST_N);

	input iCLK;
	input iRST_N;
	output oAUD_LRCK;
	output oAUD_BCK;
	output oAUD_XCK;
	
	reg [9:0] BCK_X1_DIV;
	reg [15:0] LRCK_X1_DIV;

    
	reg oAUD_LRCK;
	reg oAUD_BCK;
	reg oAUD_XCK;
    
	reg BCK_X1;
	reg LRCK_X1;
	reg XCK_X1;
	
	parameter REF_CLK = 18432000;    // 18.432MHz
	parameter SAMPLE_RATE2 = 32000;   // 16kHz *2
	parameter DATA_WIDTH = 16;      // each sample 16 bits
	parameter CHANNEL_NUM = 2;      // Left & Right channel
    parameter SDC2 = 1024000;         // SAMPLE_RATE * DATA_WIDTH * CHANNEL_NUM * 2
	
	parameter x1 = 4'd1;   // speed
	
    
	// generate AUD_BCK
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if(iRST_N) begin
			BCK_X1_DIV = 0;
			BCK_X1 = 0;
		end
		else begin
			if (BCK_X1_DIV < ((REF_CLK / SDC2) - 1))            BCK_X1_DIV <= ( BCK_X1_DIV + 1 );
			else begin                                          BCK_X1_DIV <= 0;                        BCK_X1 <= (~BCK_X1);    end
            
		end
	end
	
	// generate AUD_LRCK
	always @ ( posedge iCLK or posedge iRST_N ) begin
		if (iRST_N) begin
			LRCK_X1_DIV = 0;		
			LRCK_X1 = 0;
			
		end
		else begin
            if (LRCK_X1_DIV < ( REF_CLK/(SAMPLE_RATE2) - 1 ))   LRCK_X1_DIV <= ( LRCK_X1_DIV + 1 );
			else begin                                          LRCK_X1_DIV <= 0;                       LRCK_X1 <= (~LRCK_X1);    end
		end
	end
	
	 // select clock rate
	always @ (*) begin
		XCK_X1 = iCLK;
		oAUD_LRCK = LRCK_X1;
		oAUD_BCK = BCK_X1;
		oAUD_XCK = XCK_X1;
	end
	
endmodule
