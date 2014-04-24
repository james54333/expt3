module IR_RECEIVE(
					iCLK,         //clk 50MHz
					iRST_n,       //reset					
					iIRDA,        //IR code input
					oDATA_READY,  //data ready
					oDATA         //decode data output
					);

parameter IDLE               = 2'b00;   
parameter GUIDANCE           = 2'b01;  
parameter DATAREAD           = 2'b10;  

parameter IDLE_HIGH_DUR      =  262143; 
parameter GUIDE_LOW_DUR      =  230000; 
parameter GUIDE_HIGH_DUR     =  210000; 
parameter DATA_HIGH_DUR      =  41500;	
parameter BIT_AVAILABLE_DUR  =  20000;  

input         iCLK;        
input         iRST_n;     
input         iIRDA;     
output        oDATA_READY;
output [31:0] oDATA;      

reg    [31:0] oDATA;                
reg    [17:0] idle_count;            
reg           idle_count_flag;      
reg    [17:0] state_count;          
reg           state_count_flag;    
reg    [17:0] data_count;           
reg           data_count_flag;     
reg     [5:0] bitcount;           
reg     [1:0] state;                
reg    [31:0] data;                
reg    [31:0] data_buf;            
reg           data_ready;            

assign oDATA_READY = data_ready;


//idle counter works on iclk under IDLE state only
always @(posedge iCLK or posedge iRST_n)	
	  if (iRST_n)
		   idle_count <= 0;
	  else if (idle_count_flag)    //the counter works when the flag is 1
			 idle_count <= idle_count + 1'b1;
		else  
			 idle_count <= 0;	         //the counter resets when the flag is 0		      		 	

//idle counter switch when iIRDA is low under IDLE state
always @(posedge iCLK or posedge iRST_n)	
	  if (iRST_n)
		   idle_count_flag <= 1'b0;
	  else if ((state == IDLE) && !iIRDA)
			 idle_count_flag <= 1'b1;
		else                           
			 idle_count_flag <= 1'b0;		     		 	
      
//state counter works on iclk under GUIDE state only
always @(posedge iCLK or posedge iRST_n)	
	  if (iRST_n)
		   state_count <= 0;
	  else if (state_count_flag)    //the counter works when the flag is 1
			 state_count <= state_count + 1'b1;
		else  
			 state_count <= 0;	        //the counter resets when the flag is 0		      		 	

//state counter switch when iIRDA is high under GUIDE state
always @(posedge iCLK or posedge iRST_n)	
	  if (iRST_n)
		   state_count_flag <= 1'b0;
	  else if ((state == GUIDANCE) && iIRDA)
			 state_count_flag <= 1'b1;
		else  
			 state_count_flag <= 1'b0;     		 	

//data read decode counter based on iCLK
always @(posedge iCLK or posedge iRST_n)	
	  if (iRST_n)
		   data_count <= 1'b0;
	  else if(data_count_flag)      //the counter works when the flag is 1
			 data_count <= data_count + 1'b1;
		else 
			 data_count <= 1'b0;        //the counter resets when the flag is 0

//data counter switch
always @(posedge iCLK or posedge iRST_n)
	  if (iRST_n) 
		   data_count_flag <= 0;	
	  else if ((state == DATAREAD) && iIRDA)
			 data_count_flag <= 1'b1;  
		else
			 data_count_flag <= 1'b0; 

//data reg pointer counter 
always @(posedge iCLK or posedge iRST_n)
    if (iRST_n)
       bitcount <= 6'b0;
	  else if (state == DATAREAD)
		begin
			if (data_count == 20000)
					bitcount <= bitcount + 1'b1; //add 1 when iIRDA posedge
		end   
	  else
	     bitcount <= 6'b0;

//state change between IDLE,GUIDE,DATA_READ according to irda edge or counter
always @(posedge iCLK or posedge iRST_n) 
	  if (iRST_n)	     
	     state <= IDLE;
	  else 
			 case (state)
 			    IDLE     : if (idle_count > GUIDE_LOW_DUR)  // state chang from IDLE to Guidance when detect the negedge and the low voltage last for > 4.6ms
			  	              state <= GUIDANCE; 
			    GUIDANCE : if (state_count > GUIDE_HIGH_DUR)//state change from GUIDANCE to DATAREAD when detect the posedge and the high voltage last for > 4.2ms
			  	              state <= DATAREAD;
			    DATAREAD : if ((data_count >= IDLE_HIGH_DUR) || (bitcount >= 33))
			  					      state <= IDLE;
	        default  : state <= IDLE; //default
			 endcase

//data decode base on the value of data_count 	
always @(posedge iCLK or posedge iRST_n)
	  if (iRST_n)
	     data <= 0;
		else if (state == DATAREAD)
		begin
			 if (data_count >= DATA_HIGH_DUR) //2^15 = 32767*0.02us = 0.64us
			    data[bitcount-1'b1] <= 1'b1;  //>0.52ms  sample the bit 1
		end
		else
			 data <= 0;
	
//set the data_ready flag 
always @(posedge iCLK or posedge iRST_n) 
	  if (iRST_n)
	     data_ready <= 1'b0;
    else if (bitcount == 32)   
		begin
			 if (data[31:24] == ~data[23:16])
			 begin		
					data_buf <= data;     //fetch the value to the databuf from the data reg
				  data_ready <= 1'b1;   //set the data ready flag
			 end	
			 else
				  data_ready <= 1'b0 ;  //data error
		end
		else
		   data_ready <= 1'b0 ;

//read data
always @(posedge iCLK or posedge iRST_n)
	  if (iRST_n)
		   oDATA <= 32'b0000;
	  else if (data_ready)
	     oDATA <= data_buf;  //output
					
endmodule
