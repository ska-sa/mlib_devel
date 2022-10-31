/*************************************************************************************************************************
* Module: hbm_custom_to_axis_if.v
* Author: Adam Isaacson
* Date: 18 Oct 2022
* 
* Description: This file maps the custon Simulink HBM interface to the AXI 4 Streaming Interface. The HBM IP core is integrated as
* part of the static Alveo U50 BD core for now, so it is always present. I map each HBM yellow block to 4 x AXI Streaming Interfaces. It 
* assumes that the HBM is configured for two Banks (4GB) each with 4 x AXI interfaces and able to access 8GB in total. This means the HBM
* will always consume 10W as it is active all the time. 
*
*NB: If you use the 4th Memory AXI link once all other AXI links are utilised then the bandwidth may drop. This needs to be 
*tested properly 
*************************************************************************************************************************/

module hbm_custom_to_axis_if #(
    //Define width of the datapath
    parameter DWIDTH                = 256,  //Leave untouched
    //Define HBM interface width
    parameter NUM_DATA_BYTES        = 32,   //Leave untouched
    parameter AWIDTH                = 27,
    parameter TWIDTH                = 9
)(

    //Simulink Ports 
    //Link0
    input  wire [DWIDTH-1:0] DATA_IN_LINK0,
    output wire [DWIDTH-1:0] DATA_OUT_LINK0,
    input  wire RD_REQ_LINK0,
    input  wire WR_REQ_LINK0,
    input  wire [AWIDTH-1:0] WR_ADDRESS_LINK0,
    input  wire [AWIDTH-1:0] RD_ADDRESS_LINK0,
    input  wire [TWIDTH-1:0] TAG_IN_LINK0,
    output wire [TWIDTH-1:0] TAG_OUT_LINK0,
    output wire DATA_VALID_LINK0,
    output wire RD_READY_LINK0,
    output wire WR_READY_LINK0,
    
    //Link1
    input  wire [DWIDTH-1:0] DATA_IN_LINK1,
    output wire [DWIDTH-1:0] DATA_OUT_LINK1,
    input  wire RD_REQ_LINK1,
    input  wire WR_REQ_LINK1,
    input  wire [AWIDTH-1:0] WR_ADDRESS_LINK1,
    input  wire [AWIDTH-1:0] RD_ADDRESS_LINK1,
    input  wire [TWIDTH-1:0] TAG_IN_LINK1,
    output wire [TWIDTH-1:0] TAG_OUT_LINK1,
    output wire DATA_VALID_LINK1,
    output wire RD_READY_LINK1,
    output wire WR_READY_LINK1,

    //Link2
    input  wire [DWIDTH-1:0] DATA_IN_LINK2,
    output wire [DWIDTH-1:0] DATA_OUT_LINK2,
    input  wire RD_REQ_LINK2,
    input  wire WR_REQ_LINK2,
    input  wire [AWIDTH-1:0] WR_ADDRESS_LINK2,
    input  wire [AWIDTH-1:0] RD_ADDRESS_LINK2,
    input  wire [TWIDTH-1:0] TAG_IN_LINK2,
    output wire [TWIDTH-1:0] TAG_OUT_LINK2,
    output wire DATA_VALID_LINK2,
    output wire RD_READY_LINK2,
    output wire WR_READY_LINK2,
    
    //Link3 (Please note that by using a 4th AXI that the memory controller bandwidth may drop. This still needs to be tested. 
    input  wire [DWIDTH-1:0] DATA_IN_LINK3,
    output wire [DWIDTH-1:0] DATA_OUT_LINK3,
    input  wire RD_REQ_LINK3,
    input  wire WR_REQ_LINK3,
    input  wire [AWIDTH-1:0] WR_ADDRESS_LINK3,
    input  wire [AWIDTH-1:0] RD_ADDRESS_LINK3,
    input  wire [TWIDTH-1:0] TAG_IN_LINK3,
    output wire [TWIDTH-1:0] TAG_OUT_LINK3,
    output wire DATA_VALID_LINK3,
    output wire RD_READY_LINK3,
    output wire WR_READY_LINK3,
    
    //Simulink Ports Clocks and Status
    input  wire USER_CLK,
    input  wire USER_RST,
    output wire HBM_OK,
    output wire INIT_DONE

    
    
);

//(* mark_debug = "true" *) wire user_rst;
wire user_rst;

(* ASYNC_REG = "true" *) reg user_rstR, user_rstRR, user_rstRRR;

//USER Reset synchronous register
always @(posedge USER_CLK) begin 
  user_rstR <= USER_RST;
  user_rstRR <= user_rstR;
  user_rstRRR <= user_rstRR;
end


(* ASYNC_REG = "true" *) reg init_done_latchR,init_done_latchRR;


//Init done Memory Bank Register
always @(posedge USER_CLK) begin 
  init_done_latchRR <= init_done_latchR;
  INIT_DONE <= init_done_latchRR;  
end

//From HBM Tx to AXI-S Link 0
wire                         s_axis_tx_TVALID_link0;
wire                         s_axis_tx_TREADY_link0;
wire [DWIDTH-1:0]            s_axis_tx_TDATA_link0;
wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TUSER_link0;
//From HBM RX to AXI-S Link 0
wire                         m_axis_rx_TVALID_link0;
wire                         m_axis_rx_TREADY_link0;
wire [DWIDTH-1:0]            m_axis_rx_TDATA_link0;
wire [NUM_DATA_BYTES-1:0]    m_axis_rx_TUSER_link0;
//From HBM Tx to AXI-S Link 1
wire                         s_axis_tx_TVALID_link1;
wire                         s_axis_tx_TREADY_link1;
wire [DWIDTH-1:0]            s_axis_tx_TDATA_link1;
wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TUSER_link1;
//From HBM RX to AXI-S Link 1
wire                         m_axis_rx_TVALID_link1;
wire                         m_axis_rx_TREADY_link1;
wire [DWIDTH-1:0]            m_axis_rx_TDATA_link1;
wire [NUM_DATA_BYTES-1:0]    m_axis_rx_TUSER_link1;
//From HBM Tx to AXI-S Link 2
wire                         s_axis_tx_TVALID_link2;
wire                         s_axis_tx_TREADY_link2;
wire [DWIDTH-1:0]            s_axis_tx_TDATA_link2;
wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TUSER_link2;
//From HBM RX to AXI-S Link 2
wire                         m_axis_rx_TVALID_link2;
wire                         m_axis_rx_TREADY_link2;
wire [DWIDTH-1:0]            m_axis_rx_TDATA_link2;
wire [NUM_DATA_BYTES-1:0]    m_axis_rx_TUSER_link2;
//From HBM Tx to AXI-S Link 3
wire                         s_axis_tx_TVALID_link3;
wire                         s_axis_tx_TREADY_link3;
wire [DWIDTH-1:0]            s_axis_tx_TDATA_link3;
wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TUSER_link3;
//From HBM RX to AXI-S Link 3
wire                         m_axis_rx_TVALID_link3;
wire                         m_axis_rx_TREADY_link3;
wire [DWIDTH-1:0]            m_axis_rx_TDATA_link3;
wire [NUM_DATA_BYTES-1:0]    m_axis_rx_TUSER_link3;






wire data_err_detect_link0, data_err_detect_link1, data_err_detect_link2, data_err_detect_link3;

endmodule

`default_nettype wire

