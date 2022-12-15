//////////////////////////////////////////////////////////////////////////////////
//END USER LICENCE AGREEMENT                                                    //
//                                                                              //
//Copyright (c) 2012, ARM All rights reserved.                                  //
//                                                                              //
//THIS END USER LICENCE AGREEMENT (�LICENCE�) IS A LEGAL AGREEMENT BETWEEN      //
//YOU AND ARM LIMITED ("ARM") FOR THE USE OF THE SOFTWARE EXAMPLE ACCOMPANYING  //
//THIS LICENCE. ARM IS ONLY WILLING TO LICENSE THE SOFTWARE EXAMPLE TO YOU ON   //
//CONDITION THAT YOU ACCEPT ALL OF THE TERMS IN THIS LICENCE. BY INSTALLING OR  //
//OTHERWISE USING OR COPYING THE SOFTWARE EXAMPLE YOU INDICATE THAT YOU AGREE   //
//TO BE BOUND BY ALL OF THE TERMS OF THIS LICENCE. IF YOU DO NOT AGREE TO THE   //
//TERMS OF THIS LICENCE, ARM IS UNWILLING TO LICENSE THE SOFTWARE EXAMPLE TO    //
//YOU AND YOU MAY NOT INSTALL, USE OR COPY THE SOFTWARE EXAMPLE.                //
//                                                                              //
//ARM hereby grants to you, subject to the terms and conditions of this Licence,//
//a non-exclusive, worldwide, non-transferable, copyright licence only to       //
//redistribute and use in source and binary forms, with or without modification,//
//for academic purposes provided the following conditions are met:              //
//a) Redistributions of source code must retain the above copyright notice, this//
//list of conditions and the following disclaimer.                              //
//b) Redistributions in binary form must reproduce the above copyright notice,  //
//this list of conditions and the following disclaimer in the documentation     //
//and/or other materials provided with the distribution.                        //
//                                                                              //
//THIS SOFTWARE EXAMPLE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ARM     //
//EXPRESSLY DISCLAIMS ANY AND ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING     //
//WITHOUT LIMITATION WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR //
//PURPOSE, WITH RESPECT TO THIS SOFTWARE EXAMPLE. IN NO EVENT SHALL ARM BE LIABLE/
//FOR ANY DIRECT, INDIRECT, INCIDENTAL, PUNITIVE, OR CONSEQUENTIAL DAMAGES OF ANY/
//KIND WHATSOEVER WITH RESPECT TO THE SOFTWARE EXAMPLE. ARM SHALL NOT BE LIABLE //
//FOR ANY CLAIMS, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, //
//TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE    //
//EXAMPLE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE EXAMPLE. FOR THE AVOIDANCE/
// OF DOUBT, NO PATENT LICENSES ARE BEING LICENSED UNDER THIS LICENSE AGREEMENT.//
//////////////////////////////////////////////////////////////////////////////////


module AHBGPIO(
  input wire HCLK,
  input wire HRESETn,
  input wire [31:0] HADDR,
  input wire [1:0] HTRANS,
  input wire [31:0] HWDATA,
  input wire HWRITE,
  input wire HSEL,
  input wire HREADY,
  input wire [16:0] GPIOIN,
  input wire PARITYSEL,
  
	
	//Output
  output wire HREADYOUT,
  output wire [31:0] HRDATA,
  output wire [16:0] GPIOOUT,
  output reg PARITYERR
  
  );
  
  localparam [7:0] gpio_data_addr = 8'h00;
  localparam [7:0] gpio_dir_addr = 8'h04;
  
  reg [16:0] gpio_dataout;
  reg [16:0] gpio_datain;
  reg [15:0] gpio_dir;
  // reg [16:0] gpio_data_next;
  reg [31:0] last_HADDR;
  reg [1:0] last_HTRANS;
  reg last_HWRITE;
  reg last_HSEL;
  
  assign HREADYOUT = 1'b1;
  
// Set Registers from address phase  
  always @(posedge HCLK)
  begin
    if(HREADY)
    begin
      last_HADDR <= HADDR;
      last_HTRANS <= HTRANS;
      last_HWRITE <= HWRITE;
      last_HSEL <= HSEL;
    end
  end

  // Update in/out switch
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
    begin
      gpio_dir <= 16'h0000;
      //PARITYERR <= 1'b0;
    end
    else if ((last_HADDR[7:0] == gpio_dir_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
      gpio_dir <= HWDATA[15:0];
  end
  
  // Update output value
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
    begin
      gpio_dataout <= 17'h0000;
    end
    else if ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == gpio_data_addr) & last_HSEL & last_HWRITE & last_HTRANS[1])
      //Generate parity bit, PARITYSEL = 1 is for odd parity (XNOR), 0 for even parity (XOR)
      gpio_dataout <= {PARITYSEL ? ~^HWDATA[15:0] : ^HWDATA[15:0], HWDATA[15:0]};
  end
  
  // Update input value
  always @(posedge HCLK, negedge HRESETn)
  begin
    if(!HRESETn)
    begin
      gpio_datain <= 17'h0000;
    end
    else if (gpio_dir == 16'h0000) begin
      //Check parity bit of GPIOIN, flag PARITYERR if incorrect
      if(GPIOIN[16]!=(PARITYSEL ? ~^GPIOIN[15:0] : ^GPIOIN[15:0])) PARITYERR <= 1'b1;
      else PARITYERR <= 1'b0;
      //Transfer proceeds even if parity bit is wrong
      gpio_datain <= GPIOIN;
    end else if (gpio_dir == 16'h0001)
      gpio_datain <= GPIOOUT;
  end
  
  assign HRDATA[31:16] = 16'h0000;
  assign HRDATA[15:0] = gpio_datain[15:0];  
  assign GPIOOUT = gpio_dataout;

  // assert (GPIOOUT == gpio_dataout) else $error("GPIOOUT is different from gpio_dataout");
  // assert (HRDATA[15:0] == gpio_datain[15:0]) else $error("HRDATA is different from gpio_datain");

  update_input: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                (gpio_dir == 16'h0000) |=> (gpio_datain == $past(GPIOIN))
                              );

  update_output: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                ((gpio_dir == 16'h0001) & (last_HADDR[7:0] == 8'h00) 
                                & last_HSEL & last_HWRITE & last_HTRANS[1]) |=> (gpio_dataout[15:0] == $past(HWDATA[15:0]))
                              );

  output_update_if: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                ($changed(gpio_dataout)) |-> 
                                (($past(gpio_dir)==16'h0001) && ($past(last_HADDR[7:0])==8'h00) && 
                                $past(last_HSEL) && $past(last_HWRITE) && $past(last_HTRANS[1]))
                              );

  update_direction: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                ((last_HADDR[7:0] == 8'h04) & last_HSEL & last_HWRITE & last_HTRANS[1]) 
                                |=> (gpio_dir == $past(HWDATA[15:0]))
                              );

  direction_update_if: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                ($changed(gpio_dir)) |-> 
                                (($past(last_HADDR[7:0])==8'h04) && $past(last_HSEL) && 
                                $past(last_HWRITE) && $past(last_HTRANS[1]))
                              );

  parity_gen: assert property(
                                @(posedge HCLK) disable iff(!HRESETn)
                                ($changed(gpio_dataout)) |-> 
                                (gpio_dataout[16]==($past(PARITYSEL) ? ~^gpio_dataout[15:0] : ^gpio_dataout[15:0]))
                              );

  parity_checking_dir: assert property(
                                    @(posedge HCLK) disable iff(!HRESETn)
                                    ($changed(PARITYERR)) |-> ($past(gpio_dir)==16'h0000)
                                  ) else $display("Parityerr changed on unexpected direction, Dir = %0h, GPIOIN = %0h, PARITYSEL = %0b", $past(gpio_dir), $past(GPIOIN), $past(PARITYSEL));

  parity_checking: assert property(
                                    @(posedge HCLK) disable iff(!HRESETn)
                                    (gpio_dir == 16'h0000) |=> (PARITYERR==($past(GPIOIN[16])!=($past(PARITYSEL) ? ~^$past(GPIOIN[15:0]) : ^$past(GPIOIN[15:0]))))
                                  ) else $display("Parity check assertion failed, GPIOIN = %0h, PARITYSEL = %0b", $past(GPIOIN), $past(PARITYSEL)); 

endmodule
