module fpga1(sw, rot_A, rot_B, rot_dwn, BTN0, BTN1, BTN2, reset, clk, LED);   
input [3:0] sw;      
input rot_A, rot_B, rot_dwn, BTN0, BTN1, BTN2, reset, clk;
output reg [7:0] LED;

reg rot_btn, btn00, btn11,btn22, deb_B, deb_A, deb_AA, deb_BB;
reg[7:0]toggle_cnt, bounce_count;
wire [1:0]knob_status;
reg [23:0] cnt24  ;       // why 24bit in length?
reg rr_set, rl_set,rr_continue,rl_continue;

always@(posedge reset or posedge clk)
	if(reset)			cnt24 = 24'h000000;
	else if(cnt24<24'ha00000	cnt24 = cnt24+1;
	else                   		cnt24 = 24'h000000;
	 
assign slowclk= (cnt24==24'ha00000)?  1'b1 : 1'b0; // waveform of slowclk???

always@(posedge reset or posedge clk)
	if(reset)begin 
		deb_A = 1'b1;
		deb_B = 1'b1;
	end else if(rot_A && rot_B)begin 
		deb_A = 1'b1;
		deb_B = deb_B;
	end else if(~rot_A && ~rot_B)begin 
		deb_A = 1'b0;
		deb_B = deb_B;
	end else if(~rot_A && rot_B)begin 
		deb_A = deb_A;
		deb_B = 1'b1;
	end else if(rot_A &&~ rot_B)begin 
		deb_A = deb_A;
		deb_B = 1'b0;
	end

always@(posedge reset or posedge clk)
	if(reset)begin
		deb_AA = 1'b1;
		bounce_count = 8'b00000000;
	end	else	if(bounce_count<8'b11111111) bounce_count = bounce_count +8'b00000001;
	else begin
		deb_AA = deb_A;    // relationship btw // deb_A and deb_AA?
		bounce_count = 8'b00000000;
	end
always@(posedge reset or posedge clk)
	if(reset)begin
		deb_BB = 1'b1;
		bounce_count = 8'b00000000;
	end else if(bounce_count<8'b11111111) 
		bounce_count = bounce_count +8'b00000001;
	else begin
		deb_BB = deb_B;    // relationship btw // deb_A and deb_AA?
		bounce_count = 8'b00000000;
	end

always@(posedge reset or posedge clk)
	if(reset)
		{btn00, btn11, btn22} = 3'b000;
	else if(sw==4'h0 || sw==4'b0111)
		if(BTN0)		{btn00, btn11, btn22} = 3'b100;
      		else if(BTN1)		{btn00, btn11, btn22} = 3'b010;
      		else if(BTN2) 		{btn00, btn11, btn22} = 3'b001;
	   	else if(rot_btn)	{btn00, btn11, btn22} = 3'b000;
	   	else			{btn00, btn11, btn22} = {btn00, btn11, btn22};
   	else         
   		{btn00, btn11, btn22}= 3'b000;

always@(posedge reset or posedge clk)
	if(reset)		rot_btn= 1'b0;
	else if(sw==4'h0)
		if(rot_dwn)                          rot_btn= 1'b1;
		else if(btn00 || btn11 || btn22)     rot_btn= 1'b0;
		else                                 rot_btn= rot_btn;
	else			rot_btn= 1'b0;

assign   knob_status[1]= deb_A & ~deb_AA;
assign   knob_status[0]= deb_B & ~deb_BB; 
// start turning            // detent position

always@(posedge reset or negedge clk)       // why using negedge of the clock??
	if(reset) begin
		LED= 8'h00;
                rr_set= 1'b0;
                rl_set= 1'b0;
	        rr_continue=1'b0;
		rl_continue=1'b0;
        end 
 	else 
 		case(sw[3:0])
 			4'b0011:   LED = {4'b0000, deb_A, deb_B, rot_A, rot_B};
 			4'b0111:   LED = {6'b000000, knob_status[1], knob_status[0]};
 			4'b0000:
			       case({rot_btn, btn00, btn11, btn22})
				       4'b0100	LED= 8'h0F;
				       4'b0010	LED= 8'hF0;
				       4'b0001: if(slowclk)     LED= ~LED;
				                else		LED= LED;
				       4'b1000:         	LED= 8'hC3;
				       default:                 LED= LED;
			       endcase
 			4'b0100:
       				if(LED!=8'h0F && LED!=8'hF0)	LED= 8'h0F;
       				else if(slowclk)		LED= ~LED;
       				else           			LED= LED;
 			4'b1000:
			       if(LED!=8'h55 && LED!=8'haa)	LED= 8'h55;
			       else if(slowclk)  		LED= ~LED;
			       else           			LED= LED;
			                // one knob-click right--> one LED shifting left
			4'b0001: 
				if({knob_status[1], deb_B} == 2'b11)begin
                			if(rr_continue)begin  
                				rr_continue=1'b0;
                         			LED= 8'h11;      //purposely set
                  			end
                			if(~rl_set)begin
                         			rl_continue=1'b1;
                         			rl_set= 1'b1; 
                    				if(LED==8'h01 || LED==8'h02 || LED==8'h04 || LED==8'h08 ||
                          			   LED==8'h10 || LED==8'h20 || LED==8'h40 || LED==8'h80)
                          				LED= {LED[6:0], LED[7]};
                    				else   LED= 8'h01; 
                  			end
                			else begin  
                				rl_continue=rl_continue;
                          			rl_set= rl_set;
                          			LED= LED;
                     			end
             			end else if({knob_status[0], deb_A} == 2'b11)begin                
                			if(rl_continue)begin  
                				rl_continue=1'b0;
                         			LED= 8'h11;    // purposely set
                  			end
                			if(~rr_set)begin
			                         rr_continue= 1'b1;
			                         rr_set= 1'b1; 
				                 if(LED==8'h01 || LED==8'h02 || LED==8'h04 || LED==8'h08 ||
				                    LED==8'h10 || LED==8'h20 || LED==8'h40 || LED==8'h80)
                          				LED= {LED[0], LED[7:1]};
                   				else    LED= 8'h80; 
                  			end else begin  
	        				rr_continue= rr_continue;
	                          		rr_set= rr_set;
	                          		LED= LED;
                     			end
	              		end else begin     
	              			rr_set= 1'b0;
	                       		rl_set= 1'b0;
	                       		LED= LED;
             			end
                  		// one knob-click right--> one LED shifting left
 			4'b0010:  
				if({knob_status[1], deb_B} == 2'b11)begin
               				if(rr_continue)begin  
               					rr_continue=1'b0;
                         			LED= LED;
                  			end                
               				if(~rl_set)begin
                         			rl_continue=1'b1;
					     	rl_set= 1'b1; 
                  				if(LED==8'h01 || LED==8'h02 || LED==8'h04 || LED==8'h08 ||
                     				   LED==8'h10 || LED==8'h20 || LED==8'h40 || LED==8'h80)
                         				LED= {LED[6:0], LED[7]};
                  				else    LED= 8'h01; 
                 			end else begin   
                 				rl_continue=rl_continue;
					        rl_set= rl_set;
                               			LED= LED;
                    			end
              			end else if({knob_status[0], deb_A} == 2'b11)begin
                			if(rl_continue) begin       
                				rl_continue=1'b0;
                              			LED= LED;
                  			end              
                			if(~rr_set)begin
                              			rr_continue=1'b1;
						rr_set= 1'b1; 
				                if(LED==8'h01 || LED==8'h02 || LED==8'h04 || LED==8'h08 ||
				                   LED==8'h10 || LED==8'h20 || LED==8'h40 || LED==8'h80)
                              				LED= {LED[0], LED[7:1]};
                   				else	LED= 8'h80; 
                			end else begin     
                				rr_continue=rr_continue;
					        rr_set= rr_set;
                             			LED= LED;
                     			end
              			end else begin     
              				rr_set= 1'b0;
                        		rl_set= 1'b0;
                        		LED= LED;
              			end
 			default:   
 				if(toggle_cnt<=8'h08)	LED= 8'h00;
             			else               	LED= 8'hFF;
             	endcase

always@(posedge reset or negedge clk)	// why using negedge of the clock??
	if(reset				toggle_cnt = 8'h00;
	else if(slowclk && toggle_cnt<8'h11)	toggle_cnt = toggle_cnt + 8'h01;
	else if(slowclk)          		toggle_cnt = 8'h00;
	else					toggle_cnt = toggle_cnt;
endmodule
