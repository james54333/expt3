module I2C (	//	Host Side
        iCLK,
        iRST_N,
        ready,

        //	I2C Side
        I2C_SCLK,
        I2C_SDAT	);
	
	 //=======================================================
    //  PARAMETER declarations
    //=======================================================
	//	Clock Setting
    parameter Freq          =   2500;
    //parameter	CLK_Freq	=	50000000;	//	50	MHz
    //parameter	I2C_Freq	=	   20000;	//	20	KHz
    //	LUT Data Number
    parameter	LUT_SIZE	=	4'd10;
    //	Audio Data Index
    parameter	SET_LIN_L	=	4'd0;
    parameter	SET_LIN_R	=	4'd1;
    parameter	SET_HEAD_L	=	4'd2;
    parameter	SET_HEAD_R	=	4'd3;
    parameter	A_PATH_CTRL	=	4'd4;
    parameter	D_PATH_CTRL	=	4'd5;
    parameter	POWER_ON	=	4'd6;
    parameter	SET_FORMAT	=	4'd7;
    parameter	SAMPLE_CTRL	=	4'd8;
    parameter	SET_ACTIVE	=	4'd9;
	
	 //=======================================================
    //  PORT declarations
    //=======================================================
    //	Host Side
    input		iCLK;
    input		iRST_N;
    output      ready;
	 
    //	I2C Side
    output		I2C_SCLK;
    inout		I2C_SDAT;
	 
    //=======================================================
    //  REG/WIRE declarations
    //=======================================================
    reg	[15:0]	mI2C_CLK_DIV;
    wire[15:0]	mI2C_CLK_DIV_temp;
    
    reg	[23:0]	mI2C_DATA;
    reg	[23:0]	mI2C_DATA_temp;
    
    reg		    mI2C_CTRL_CLK;
    wire	    mI2C_CTRL_CLK_temp;
    
    reg		    mI2C_GO;
    reg		    mI2C_GO_temp;
    
    wire	    mI2C_END;
    wire	    mI2C_ACK;
    
    reg	[15:0]	LUT_DATA;
    
    reg	 [3:0]	LUT_INDEX;
    reg  [3:0]	LUT_INDEX_temp;
    
    reg	 [1:0]	mSetup_ST;
    reg  [1:0]	mSetup_ST_temp;
    
    reg         ready;
    wire        ready_temp;

    //=============================================================================
    // Structural coding
    //=============================================================================
    assign mI2C_CLK_DIV_temp = (mI2C_CLK_DIV < Freq)? mI2C_CLK_DIV+16'd1 : 16'd0;
    assign mI2C_CTRL_CLK_temp = (mI2C_CLK_DIV < Freq)? mI2C_CTRL_CLK : ~mI2C_CTRL_CLK;    

    /////////////////////	I2C Control Clock	////////////////////////
    
    always@(posedge iCLK or posedge iRST_N)
    begin
        if(iRST_N)
        begin
            mI2C_CTRL_CLK	<=	1'd0;
            mI2C_CLK_DIV	<=	16'd0;
        end
        else begin
            mI2C_CTRL_CLK	<=	mI2C_CTRL_CLK_temp;
            mI2C_CLK_DIV	<=	mI2C_CLK_DIV_temp;
        end
    end


    I2C_control u1 (	
            .CLOCK(mI2C_CTRL_CLK),
            .I2C_SCLK(I2C_SCLK),
            .I2C_SDAT(I2C_SDAT),
            .I2C_DATA(mI2C_DATA),
            .GO(mI2C_GO),
            .END(mI2C_END),
            .ACK(mI2C_ACK),
            .iRST_N(iRST_N),
	);


    ////////////////////////////////////////////////////////////////////

    assign ready_temp = (LUT_INDEX<LUT_SIZE)? 1'd0 : 1'd1;

    always@(posedge mI2C_CTRL_CLK or posedge iRST_N) begin
        if(iRST_N) begin
            LUT_INDEX	<= 4'd0;
            mSetup_ST	<= 2'd0;
            mI2C_GO		<= 1'd0;
            ready       <= 1'd0;
            mI2C_DATA   <= 24'd0;
        end
        else begin
            LUT_INDEX	<= LUT_INDEX_temp;
            mSetup_ST	<= mSetup_ST_temp;
            mI2C_GO		<= mI2C_GO_temp;
            ready       <= ready_temp;
            mI2C_DATA   <= mI2C_DATA_temp;
        end
    end
    ////////////////////////////////////////////////////////////////////
    
    always@(*) begin
        if(LUT_INDEX<LUT_SIZE) begin
            case(mSetup_ST)
                //2'd0:       LUT_INDEX_temp <= LUT_INDEX;
                //2'd1:       LUT_INDEX_temp <= LUT_INDEX;
                2'd2:       LUT_INDEX_temp <= LUT_INDEX+4'd1;
                default:    LUT_INDEX_temp <= LUT_INDEX;
            endcase
        end
        else LUT_INDEX_temp <= LUT_INDEX;
    end
    
    always@(*) begin        //mSetup_ST
        if(LUT_INDEX<LUT_SIZE) begin
            case(mSetup_ST)
                2'd0:       mSetup_ST_temp <= 2'd1;
                2'd1:       mSetup_ST_temp <= (~mI2C_ACK)? 2'd2 : 2'd0;
                //2'd2:       mSetup_ST_temp <= 2'd0;
                default:    mSetup_ST_temp <= 2'd0;
            endcase
        end
        else mSetup_ST_temp <= 2'd0;
    end
    
    always@(*) begin        //mI2C_GO
        if(LUT_INDEX<LUT_SIZE) begin
            case(mSetup_ST)
                2'd0:       mI2C_GO_temp <= 1'd1;
                //2'd1:       mI2C_GO_temp <= 1'd0;
                //2'd2:       mI2C_GO_temp <= 1'd0;
                default:    mI2C_GO_temp <= 1'd0;
            endcase
        end
        else mI2C_GO_temp <= 1'd0;
    end
    
    always @(*) begin
        case(LUT_INDEX)
            //	Audio Config Data
            SET_LIN_L:   LUT_DATA <= 16'h009A;
			SET_LIN_R:   LUT_DATA <= 16'h029A;
			SET_HEAD_L:  LUT_DATA <= 16'h057F;
			SET_HEAD_R:  LUT_DATA <= 16'h077F;
			A_PATH_CTRL: LUT_DATA <= 16'h08DC;
			D_PATH_CTRL: LUT_DATA <= 16'h0A06;
			POWER_ON:    LUT_DATA <= 16'h0C00;
			SET_FORMAT:  LUT_DATA <= 16'h0E01;
			SAMPLE_CTRL: LUT_DATA <= 16'h1002;
			SET_ACTIVE:  LUT_DATA <= 16'h1201;
			default:     LUT_DATA <= 16'hxxx;
        endcase
    end
    
    always@(*) begin
        if(LUT_INDEX<LUT_SIZE) begin
            case(mSetup_ST)
                2'd0:       mI2C_DATA_temp <= {8'h34,LUT_DATA};
                //2'd1:       mI2C_DATA_temp <= mI2C_DATA;
                //2'd2:       mI2C_DATA_temp <= mI2C_DATA;
                default:    mI2C_DATA_temp <= mI2C_DATA;
            endcase
        end
        else mI2C_DATA_temp <= mI2C_DATA;
    end
    ////////////////////////////////////////////////////////////////////
endmodule

