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
*tested and investigated properly 
*************************************************************************************************************************/

module hbm_custom_to_axis_if #(
    //Define width of the datapath
    parameter DWIDTH                = 256,  //Leave untouched
    //Define HBM interface width
    parameter NUM_DATA_BYTES        = 32,   //Leave untouched
    parameter AWIDTH                = 27,
    parameter TWIDTH                = 9,  //Tag Width
    parameter HBM_ADD_BANK_SEL      = 0,  //0 = Memory Bank 0 (lower 4GB), 1 = Memory Bank 1 (Upper 4GB) 
    // AXI Interface 
    parameter AXI_ADD_WIDTH         = 33,
    parameter AXI_BURST_SIZE        = 1,
    parameter ATWIDTH               = 6  //AXI Tag Width
)(

    //Simulink Ports 
    //Link0
    input  wire [DWIDTH-1:0] DATA_IN_LINK0,
    output wire [DWIDTH-1:0] DATA_OUT_LINK0,
    input  wire RD_REQ_LINK0,
    input  wire WR_REQ_LINK0,
    input  wire [AWIDTH-1:0] WR_ADDRESS_LINK0,
    input  wire [AWIDTH-1:0] RD_ADDRESS_LINK0,
    //input  wire [TWIDTH-1:0] WR_TAG_IN_LINK0, //not used for now
    input  wire [TWIDTH-1:0] TAG_IN_LINK0, //RD_TAG_IN_LINK0,
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
    //input  wire [TWIDTH-1:0] WR_TAG_IN_LINK1,
    input  wire [TWIDTH-1:0] TAG_IN_LINK1, // RD_TAG_IN_LINK1,
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
    //input  wire [TWIDTH-1:0] WR_TAG_IN_LINK2,
    input  wire [TWIDTH-1:0] TAG_IN_LINK2, //RD_TAG_IN_LINK2,
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
    //input  wire [TWIDTH-1:0] WR_TAG_IN_LINK3,
    input  wire [TWIDTH-1:0] TAG_IN_LINK3, //RD_TAG_IN_LINK3,
    output wire [TWIDTH-1:0] TAG_OUT_LINK3,
    output wire DATA_VALID_LINK3,
    output wire RD_READY_LINK3,
    output wire WR_READY_LINK3,
    
    //Simulink Ports Clocks and Status
    input  wire USER_CLK,
    input  wire USER_RST,
    output wire HBM_OK,
    input  wire INIT_DONE,
    
    //----------------------------------
    //----Connect AXI Ports Link 0
    //----------------------------------
    //From AXI to HMC Ctrl TX
    output  wire                         s_axis_tx_TVALID_Link0,  //Write Data Valid
    input   wire                         s_axis_tx_TREADY_Link0, //Write Data Ready
    output  wire [DWIDTH-1:0]            s_axis_tx_TDATA_Link0, //Write Data
    output  wire [AXI_ADD_WIDTH-1:0]     s_axis_tx_TADD_Link0,  //Write Address
    output  wire                         s_axis_tx_TADD_VALID_Link0, //write address Valid
    output  wire [2:0]                   s_axis_tx_TADD_SIZE_Link0,  //write address size (bytes in transfer = 32, "101")  
    input   wire                         s_axis_tx_TADD_READY_Link0, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH_Link0, //write address Length (burst length = 1 = "00000001")
    output  wire [1:0]                   s_axis_tx_TADD_BURST_Link0, //write addresss Burst (BURST TYPE = INC = "01")      
    output  wire [ATWIDTH-1:0]           s_axis_tx_TADD_ID_Link0, //Write address ID
    input   wire [ATWIDTH-1:0]           s_axis_tx_TRESP_ID_Link0, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP_Link0, //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         s_axis_tx_RESP_VALID_Link0, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY_Link0, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST_Link0, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE_Link0, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID_Link0, //Read Data Valid
    output  wire                         m_axis_rx_TREADY_Link0, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA_Link0, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD_Link0, //Read Data Address
    input   wire [ATWIDTH-1:0]           m_axis_rx_TID_Link0, //Read Data
    output  wire [1:0]                   m_axis_rx_TADD_BURST_Link0, //read addresss Burst (BURST TYPE = INC = "01")
    output  wire [2:0]                   m_axis_rx_TADD_SIZE_Link0,  //Read address size (bytes in transfer = 32, "101")
    input   wire                         m_axis_rx_TADD_READY_Link0, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH_Link0, //Read address Length (burst length = 1 = "00000001")
    output  wire [ATWIDTH-1:0]           m_axis_rx_TADD_ID_Link0, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID_Link0, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP_Link0, //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         m_axis_rx_TLAST_Link0, //Read Data Last
  
    //----------------------------------
    //----Connect AXI Ports Link 1
    //----------------------------------
    //From AXI to HMC Ctrl TX
    output  wire                         s_axis_tx_TVALID_Link1,  //Write Data Valid
    input   wire                         s_axis_tx_TREADY_Link1, //Write Data Ready
    output  wire [DWIDTH-1:0]            s_axis_tx_TDATA_Link1, //Write Data
    output  wire [AXI_ADD_WIDTH-1:0]     s_axis_tx_TADD_Link1,  //Write Address
    output  wire                         s_axis_tx_TADD_VALID_Link1, //write address Valid
    output  wire [2:0]                   s_axis_tx_TADD_SIZE_Link1,  //write address size (bytes in transfer = 32, "101")  
    input   wire                         s_axis_tx_TADD_READY_Link1, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH_Link1, //write address Length (burst length = 1 = "00000001")
    output  wire [1:0]                   s_axis_tx_TADD_BURST_Link1, //write addresss Burst (BURST TYPE = INC = "01")      
    output  wire [ATWIDTH-1:0]           s_axis_tx_TADD_ID_Link1, //Write address ID
    input   wire [ATWIDTH-1:0]           s_axis_tx_TRESP_ID_Link1, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP_Link1, //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         s_axis_tx_RESP_VALID_Link1, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY_Link1, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST_Link1, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE_Link1, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID_Link1, //Read Data Valid
    output  wire                         m_axis_rx_TREADY_Link1, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA_Link1, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD_Link1, //Read Data Address
    input   wire [ATWIDTH-1:0]           m_axis_rx_TID_Link1, //Read Data
    output  wire [1:0]                   m_axis_rx_TADD_BURST_Link1, //read addresss Burst (BURST TYPE = INC = "01")
    output  wire [2:0]                   m_axis_rx_TADD_SIZE_Link1,  //Read address size (bytes in transfer = 32, "101")
    input   wire                         m_axis_rx_TADD_READY_Link1, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH_Link1, //Read address Length (burst length = 1 = "00000001")
    output  wire [ATWIDTH-1:0]           m_axis_rx_TADD_ID_Link1, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID_Link1, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP_Link1, //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         m_axis_rx_TLAST_Link1, //Read Data Last
    
    //----------------------------------
    //----Connect AXI Ports Link 2
    //----------------------------------
    //From AXI to HMC Ctrl TX
    output  wire                         s_axis_tx_TVALID_Link2,  //Write Data Valid
    input   wire                         s_axis_tx_TREADY_Link2, //Write Data Ready
    output  wire [DWIDTH-1:0]            s_axis_tx_TDATA_Link2, //Write Data
    output  wire [AXI_ADD_WIDTH-1:0]     s_axis_tx_TADD_Link2,  //Write Address
    output  wire                         s_axis_tx_TADD_VALID_Link2, //write address Valid
    output  wire [2:0]                   s_axis_tx_TADD_SIZE_Link2,  //write address size (bytes in transfer = 32, "101")  
    input   wire                         s_axis_tx_TADD_READY_Link2, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH_Link2, //write address Length (burst length = 1 = "00000001")
    output  wire [1:0]                   s_axis_tx_TADD_BURST_Link2, //write addresss Burst (BURST TYPE = INC = "01")      
    output  wire [ATWIDTH-1:0]           s_axis_tx_TADD_ID_Link2, //Write address ID
    input   wire [ATWIDTH-1:0]           s_axis_tx_TRESP_ID_Link2, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP_Link2, //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         s_axis_tx_RESP_VALID_Link2, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY_Link2, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST_Link2, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE_Link2, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID_Link2, //Read Data Valid
    output  wire                         m_axis_rx_TREADY_Link2, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA_Link2, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD_Link2, //Read Data Address
    input   wire [ATWIDTH-1:0]           m_axis_rx_TID_Link2, //Read Data
    output  wire [1:0]                   m_axis_rx_TADD_BURST_Link2, //read addresss Burst (BURST TYPE = INC = "01")
    output  wire [2:0]                   m_axis_rx_TADD_SIZE_Link2,  //Read address size (bytes in transfer = 32, "101")
    input   wire                         m_axis_rx_TADD_READY_Link2, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH_Link2, //Read address Length (burst length = 1 = "00000001")
    output  wire [ATWIDTH-1:0]           m_axis_rx_TADD_ID_Link2, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID_Link2, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP_Link2, //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         m_axis_rx_TLAST_Link2, //Read Data Last
    
    //----------------------------------
    //----Connect AXI Ports Link 3
    //----------------------------------
    //From AXI to HMC Ctrl TX
    output  wire                         s_axis_tx_TVALID_Link3,  //Write Data Valid
    input   wire                         s_axis_tx_TREADY_Link3, //Write Data Ready
    output  wire [DWIDTH-1:0]            s_axis_tx_TDATA_Link3, //Write Data
    output  wire [AXI_ADD_WIDTH-1:0]     s_axis_tx_TADD_Link3,  //Write Address
    output  wire                         s_axis_tx_TADD_VALID_Link3, //write address Valid
    output  wire [2:0]                   s_axis_tx_TADD_SIZE_Link3,  //write address size (bytes in transfer = 32, "101")  
    input   wire                         s_axis_tx_TADD_READY_Link3, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH_Link3, //write address Length (burst length = 1 = "00000001")
    output  wire [1:0]                   s_axis_tx_TADD_BURST_Link3, //write addresss Burst (BURST TYPE = INC = "01")      
    output  wire [ATWIDTH-1:0]           s_axis_tx_TADD_ID_Link3, //Write address ID
    input   wire [ATWIDTH-1:0]           s_axis_tx_TRESP_ID_Link3, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP_Link3, //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         s_axis_tx_RESP_VALID_Link3, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY_Link3, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST_Link3, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE_Link3, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID_Link3, //Read Data Valid
    output  wire                         m_axis_rx_TREADY_Link3, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA_Link3, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD_Link3, //Read Data Address
    input   wire [ATWIDTH-1:0]           m_axis_rx_TID_Link3, //Read Data
    output  wire [1:0]                   m_axis_rx_TADD_BURST_Link3, //read addresss Burst (BURST TYPE = INC = "01")
    output  wire [2:0]                   m_axis_rx_TADD_SIZE_Link3,  //Read address size (bytes in transfer = 32, "101")
    input   wire                         m_axis_rx_TADD_READY_Link3, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH_Link3, //Read address Length (burst length = 1 = "00000001")
    output  wire [ATWIDTH-1:0]           m_axis_rx_TADD_ID_Link3, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID_Link3, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP_Link3, //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         m_axis_rx_TLAST_Link3 //Read Data Last    
);

//wire declarations
//Debug signals

(* mark_debug = "true" *) wire dbg_sTX_AXI_ERROR_RESP_LINK0;
(* mark_debug = "true" *) wire dbg_sRX_AXI_ERROR_RESP_LINK0;
(* mark_debug = "true" *) wire dbg_sTX_AXI_ERROR_RESP_LINK1;
(* mark_debug = "true" *) wire dbg_sRX_AXI_ERROR_RESP_LINK1;
(* mark_debug = "true" *) wire dbg_sTX_AXI_ERROR_RESP_LINK2;
(* mark_debug = "true" *) wire dbg_sRX_AXI_ERROR_RESP_LINK2;
(* mark_debug = "true" *) wire dbg_sTX_AXI_ERROR_RESP_LINK3;
(* mark_debug = "true" *) wire dbg_sRX_AXI_ERROR_RESP_LINK3;

assign dbg_sTX_AXI_ERROR_RESP_LINK0 = sTX_AXI_ERROR_RESP_LINK0;
assign dbg_sRX_AXI_ERROR_RESP_LINK0 = sRX_AXI_ERROR_RESP_LINK0;
assign dbg_sTX_AXI_ERROR_RESP_LINK1 = sTX_AXI_ERROR_RESP_LINK1;
assign dbg_sRX_AXI_ERROR_RESP_LINK1 = sRX_AXI_ERROR_RESP_LINK1;
assign dbg_sTX_AXI_ERROR_RESP_LINK2 = sTX_AXI_ERROR_RESP_LINK2;
assign dbg_sRX_AXI_ERROR_RESP_LINK2 = sRX_AXI_ERROR_RESP_LINK2;
assign dbg_sTX_AXI_ERROR_RESP_LINK3 = sTX_AXI_ERROR_RESP_LINK3;
assign dbg_sRX_AXI_ERROR_RESP_LINK3 = sRX_AXI_ERROR_RESP_LINK3;

//write tag initialised to zero for now
wire [TWIDTH-1:0] WR_TAG_IN_LINK0;
assign WR_TAG_IN_LINK0 = {TWIDTH{1'b0}}; //generic tag zeroed

wire [TWIDTH-1:0] WR_TAG_IN_LINK1;
assign WR_TAG_IN_LINK1 = {TWIDTH{1'b0}}; //generic tag zeroed

wire [TWIDTH-1:0] WR_TAG_IN_LINK2;
assign WR_TAG_IN_LINK2 = {TWIDTH{1'b0}}; //generic tag zeroed

wire [TWIDTH-1:0] WR_TAG_IN_LINK3;
assign WR_TAG_IN_LINK3 = {TWIDTH{1'b0}}; //generic tag zeroed

//Read Tag assignment
wire [TWIDTH-1:0] RD_TAG_IN_LINK0;
assign RD_TAG_IN_LINK0 = TAG_IN_LINK0;

wire [TWIDTH-1:0] RD_TAG_IN_LINK1;
assign RD_TAG_IN_LINK1 = TAG_IN_LINK1;

wire [TWIDTH-1:0] RD_TAG_IN_LINK2;
assign RD_TAG_IN_LINK2 = TAG_IN_LINK2;

wire [TWIDTH-1:0] RD_TAG_IN_LINK3;
assign RD_TAG_IN_LINK3 = TAG_IN_LINK3;

//Link0

wire sAXI_ERROR_RESP_PULSE_LINK0;
wire [1:0] sTX_AXI_ERROR_RESP_LINK0;
wire [1:0] sRX_AXI_ERROR_RESP_LINK0;

//Link1

wire sAXI_ERROR_RESP_PULSE_LINK1;
wire [1:0] sTX_AXI_ERROR_RESP_LINK1;
wire [1:0] sRX_AXI_ERROR_RESP_LINK1;

//Link2

wire sAXI_ERROR_RESP_PULSE_LINK2;
wire [1:0] sTX_AXI_ERROR_RESP_LINK2;
wire [1:0] sRX_AXI_ERROR_RESP_LINK2;

//Link3

wire sAXI_ERROR_RESP_PULSE_LINK3;
wire [1:0] sTX_AXI_ERROR_RESP_LINK3;
wire [1:0] sRX_AXI_ERROR_RESP_LINK3;



(* ASYNC_REG = "true" *) reg user_rstR, user_rstRR;

//USER Reset synchronous register
always @(posedge USER_CLK) begin 
  user_rstR <= USER_RST;
  user_rstRR <= user_rstR;
end


(* ASYNC_REG = "true" *) reg init_done_latchR,init_done_latchRR;


//Init done Memory Bank Register
always @(posedge USER_CLK) begin 
  init_done_latchR <= INIT_DONE;
  init_done_latchRR <= init_done_latchR;  
end

//AXI State Machine Link0

axi_rd_wr_state_machine #(
    //Define width of the datapath
    .DWIDTH(DWIDTH),
    //Define HBM interface width
    .NUM_DATA_BYTES(NUM_DATA_BYTES),
    // HBM Interface Address Width
    .AWIDTH(AWIDTH),
    .TWIDTH(TWIDTH),
    .HBM_ADD_BANK_SEL(HBM_ADD_BANK_SEL),
    // AXI Interface 
    .AXI_ADD_WIDTH(AXI_ADD_WIDTH),
    .AXI_BURST_SIZE(AXI_BURST_SIZE),
    .ATWIDTH(ATWIDTH)
  )  
  axi_rd_wr_state_machine_link0_inst (
    .CLK(USER_CLK),
    .RST(user_rstRR),
    .INIT_DONE(init_done_latchRR),
    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    .s_axis_tx_TVALID(s_axis_tx_TVALID_Link0),  //Write Data Valid
    .s_axis_tx_TREADY(s_axis_tx_TREADY_Link0), //Write Data Ready
    .s_axis_tx_TDATA(s_axis_tx_TDATA_Link0), //Write Data
    .s_axis_tx_TADD(s_axis_tx_TADD_Link0),  //Write Address
    .s_axis_tx_TADD_VALID(s_axis_tx_TADD_VALID_Link0), //write address Valid
    .s_axis_tx_TADD_SIZE(s_axis_tx_TADD_SIZE_Link0),  //write address size (bytes in transfer = 32, "101")  
    .s_axis_tx_TADD_READY(s_axis_tx_TADD_READY_Link0), //Write address Ready
    .s_axis_tx_TADD_LENGTH(s_axis_tx_TADD_LENGTH_Link0), //write address Length (burst length = 1 = "00000001")
    .s_axis_tx_TADD_BURST(s_axis_tx_TADD_BURST_Link0), //write addresss Burst (BURST TYPE = INC = "01")      
    .s_axis_tx_TADD_ID(s_axis_tx_TADD_ID_Link0), //Write address ID
    .s_axis_tx_TRESP_ID(s_axis_tx_TRESP_ID_Link0), //Write Response ID
    .s_axis_tx_TRESP(s_axis_tx_TRESP_Link0), //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .s_axis_tx_RESP_VALID(s_axis_tx_RESP_VALID_Link0), //Write response valid
    .s_axis_tx_RESP_RDY(s_axis_tx_RESP_RDY_Link0), //Write Response Ready   
    .s_axis_tx_TLAST(s_axis_tx_TLAST_Link0), //Write Data Last
    .s_axis_tx_TSTROBE(s_axis_tx_TSTROBE_Link0), //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    .m_axis_rx_TVALID(m_axis_rx_TVALID_Link0), //Read ATWIDTH
    .m_axis_rx_TREADY(m_axis_rx_TREADY_Link0), //Read Data Ready
    .m_axis_rx_TDATA(m_axis_rx_TDATA_Link0), //Read Data
    .m_axis_rx_TADD(m_axis_rx_TADD_Link0), //Read Data Address
    .m_axis_rx_TID(m_axis_rx_TID_Link0), //Read Data 
    .m_axis_rx_TADD_BURST(m_axis_rx_TADD_BURST_Link0), //read addresss Burst (BURST TYPE = INC = "01")
    .m_axis_rx_TADD_SIZE(m_axis_rx_TADD_SIZE_Link0),  //Read address size (bytes in transfer = 32, "101")
    .m_axis_rx_TADD_READY(m_axis_rx_TADD_READY_Link0), //Read address Ready
    .m_axis_rx_TADD_LENGTH(m_axis_rx_TADD_LENGTH_Link0), //Read address Length (burst length = 1 = "00000001")
    .m_axis_rx_TADD_ID(m_axis_rx_TADD_ID_Link0), //Read Address ID
    .m_axis_rx_TADD_VALID(m_axis_rx_TADD_VALID_Link0), //Read Address valid
    .m_axis_rx_TRESP(m_axis_rx_TRESP_Link0), //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .m_axis_rx_TLAST(m_axis_rx_TLAST_Link0), //Read Data Last
    // write HBM interface
    .WR_ADDRESS(WR_ADDRESS_LINK0),
    .DATA_IN(DATA_IN_LINK0),
    .WR_REQ(WR_REQ_LINK0),
    .WR_READY(WR_READY_LINK0),
    // read HBM interface
    .RD_ADDRESS(RD_ADDRESS_LINK0),
    .RD_REQ(RD_REQ_LINK0), 
    .DATA_OUT(DATA_OUT_LINK0), 
    .WR_TAG_IN(WR_TAG_IN_LINK0),
    .RD_TAG_IN(RD_TAG_IN_LINK0),
    .TAG_OUT(TAG_OUT_LINK0),
    .DATA_VALID(DATA_VALID_LINK0),
    .RD_READY(RD_READY_LINK0),
    .AXI_ERROR_RESP_PULSE(sAXI_ERROR_RESP_PULSE_LINK0),
    .TX_AXI_ERROR_RESP(sTX_AXI_ERROR_RESP_LINK0),
    .RX_AXI_ERROR_RESP(sRX_AXI_ERROR_RESP_LINK0)
  );
  
//AXI State Machine Link1  

axi_rd_wr_state_machine #(
    //Define width of the datapath
    .DWIDTH(DWIDTH),
    //Define HBM interface width
    .NUM_DATA_BYTES(NUM_DATA_BYTES),
    // HBM Interface Address Width
    .AWIDTH(AWIDTH),
    .TWIDTH(TWIDTH),
    .HBM_ADD_BANK_SEL(HBM_ADD_BANK_SEL),
    // AXI Interface 
    .AXI_ADD_WIDTH(AXI_ADD_WIDTH),
    .AXI_BURST_SIZE(AXI_BURST_SIZE),
    .ATWIDTH(ATWIDTH)
  )  
  axi_rd_wr_state_machine_link1_inst (
    .CLK(USER_CLK),
    .RST(user_rstRR),
    .INIT_DONE(init_done_latchRR),
    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    .s_axis_tx_TVALID(s_axis_tx_TVALID_Link1),  //Write Data Valid
    .s_axis_tx_TREADY(s_axis_tx_TREADY_Link1), //Write Data Ready
    .s_axis_tx_TDATA(s_axis_tx_TDATA_Link1), //Write Data
    .s_axis_tx_TADD(s_axis_tx_TADD_Link1),  //Write Address
    .s_axis_tx_TADD_VALID(s_axis_tx_TADD_VALID_Link1), //write address Valid
    .s_axis_tx_TADD_SIZE(s_axis_tx_TADD_SIZE_Link1),  //write address size (bytes in transfer = 32, "101")  
    .s_axis_tx_TADD_READY(s_axis_tx_TADD_READY_Link1), //Write address Ready
    .s_axis_tx_TADD_LENGTH(s_axis_tx_TADD_LENGTH_Link1), //write address Length (burst length = 1 = "00000001")
    .s_axis_tx_TADD_BURST(s_axis_tx_TADD_BURST_Link1), //write addresss Burst (BURST TYPE = INC = "01")      
    .s_axis_tx_TADD_ID(s_axis_tx_TADD_ID_Link1), //Write address ID
    .s_axis_tx_TRESP_ID(s_axis_tx_TRESP_ID_Link1), //Write Response ID
    .s_axis_tx_TRESP(s_axis_tx_TRESP_Link1), //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .s_axis_tx_RESP_VALID(s_axis_tx_RESP_VALID_Link1), //Write response valid
    .s_axis_tx_RESP_RDY(s_axis_tx_RESP_RDY_Link1), //Write Response Ready   
    .s_axis_tx_TLAST(s_axis_tx_TLAST_Link1), //Write Data Last
    .s_axis_tx_TSTROBE(s_axis_tx_TSTROBE_Link1), //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    .m_axis_rx_TVALID(m_axis_rx_TVALID_Link1), //Read Data Valid
    .m_axis_rx_TREADY(m_axis_rx_TREADY_Link1), //Read Data Ready
    .m_axis_rx_TDATA(m_axis_rx_TDATA_Link1), //Read Data
    .m_axis_rx_TADD(m_axis_rx_TADD_Link1), //Read Data Address
    .m_axis_rx_TID(m_axis_rx_TID_Link1), //Read Data 
    .m_axis_rx_TADD_BURST(m_axis_rx_TADD_BURST_Link1), //read addresss Burst (BURST TYPE = INC = "01")
    .m_axis_rx_TADD_SIZE(m_axis_rx_TADD_SIZE_Link1),  //Read address size (bytes in transfer = 32, "101")
    .m_axis_rx_TADD_READY(m_axis_rx_TADD_READY_Link1), //Read address Ready
    .m_axis_rx_TADD_LENGTH(m_axis_rx_TADD_LENGTH_Link1), //Read address Length (burst length = 1 = "00000001")
    .m_axis_rx_TADD_ID(m_axis_rx_TADD_ID_Link1), //Read Address ID
    .m_axis_rx_TADD_VALID(m_axis_rx_TADD_VALID_Link1), //Read Address valid
    .m_axis_rx_TRESP(m_axis_rx_TRESP_Link1), //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .m_axis_rx_TLAST(m_axis_rx_TLAST_Link1), //Read Data Last
    // write HBM interface
    .WR_ADDRESS(WR_ADDRESS_LINK1),
    .DATA_IN(DATA_IN_LINK1),
    .WR_REQ(WR_REQ_LINK1),
    .WR_READY(WR_READY_LINK1),
    // read HBM interface
    .RD_ADDRESS(RD_ADDRESS_LINK1),
    .RD_REQ(RD_REQ_LINK1), 
    .DATA_OUT(DATA_OUT_LINK1), 
    .WR_TAG_IN(WR_TAG_IN_LINK1),
    .RD_TAG_IN(RD_TAG_IN_LINK1),
    .TAG_OUT(TAG_OUT_LINK1),
    .DATA_VALID(DATA_VALID_LINK1),
    .RD_READY(RD_READY_LINK1),
    .AXI_ERROR_RESP_PULSE(sAXI_ERROR_RESP_PULSE_LINK1),
    .TX_AXI_ERROR_RESP(sTX_AXI_ERROR_RESP_LINK1),
    .RX_AXI_ERROR_RESP(sRX_AXI_ERROR_RESP_LINK1)
  );
  
//AXI State Machine Link2
  
  axi_rd_wr_state_machine #(
    //Define width of the datapath
    .DWIDTH(DWIDTH),
    //Define HBM interface width
    .NUM_DATA_BYTES(NUM_DATA_BYTES),
    // HBM Interface Address Width
    .AWIDTH(AWIDTH),
    .TWIDTH(TWIDTH),
    .HBM_ADD_BANK_SEL(HBM_ADD_BANK_SEL),
    // AXI Interface 
    .AXI_ADD_WIDTH(AXI_ADD_WIDTH),
    .AXI_BURST_SIZE(AXI_BURST_SIZE),
    .ATWIDTH(ATWIDTH)
  )  
  axi_rd_wr_state_machine_link2_inst (
    .CLK(USER_CLK),
    .RST(user_rstRR),
    .INIT_DONE(init_done_latchRR),
    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    .s_axis_tx_TVALID(s_axis_tx_TVALID_Link2),  //Write Data Valid
    .s_axis_tx_TREADY(s_axis_tx_TREADY_Link2), //Write Data Ready
    .s_axis_tx_TDATA(s_axis_tx_TDATA_Link2), //Write Data
    .s_axis_tx_TADD(s_axis_tx_TADD_Link2),  //Write Address
    .s_axis_tx_TADD_VALID(s_axis_tx_TADD_VALID_Link2), //write address Valid
    .s_axis_tx_TADD_SIZE(s_axis_tx_TADD_SIZE_Link2),  //write address size (bytes in transfer = 32, "101")  
    .s_axis_tx_TADD_READY(s_axis_tx_TADD_READY_Link2), //Write address Ready
    .s_axis_tx_TADD_LENGTH(s_axis_tx_TADD_LENGTH_Link2), //write address Length (burst length = 1 = "00000001")
    .s_axis_tx_TADD_BURST(s_axis_tx_TADD_BURST_Link2), //write addresss Burst (BURST TYPE = INC = "01")      
    .s_axis_tx_TADD_ID(s_axis_tx_TADD_ID_Link2), //Write address ID
    .s_axis_tx_TRESP_ID(s_axis_tx_TRESP_ID_Link2), //Write Response ID
    .s_axis_tx_TRESP(s_axis_tx_TRESP_Link2), //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .s_axis_tx_RESP_VALID(s_axis_tx_RESP_VALID_Link2), //Write response valid
    .s_axis_tx_RESP_RDY(s_axis_tx_RESP_RDY_Link2), //Write Response Ready   
    .s_axis_tx_TLAST(s_axis_tx_TLAST_Link2), //Write Data Last
    .s_axis_tx_TSTROBE(s_axis_tx_TSTROBE_Link2), //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    .m_axis_rx_TVALID(m_axis_rx_TVALID_Link2), //Read Data Valid
    .m_axis_rx_TREADY(m_axis_rx_TREADY_Link2), //Read Data Ready
    .m_axis_rx_TDATA(m_axis_rx_TDATA_Link2), //Read Data
    .m_axis_rx_TADD(m_axis_rx_TADD_Link2), //Read Data Address
    .m_axis_rx_TID(m_axis_rx_TID_Link2), //Read Data 
    .m_axis_rx_TADD_BURST(m_axis_rx_TADD_BURST_Link2), //read addresss Burst (BURST TYPE = INC = "01")
    .m_axis_rx_TADD_SIZE(m_axis_rx_TADD_SIZE_Link2),  //Read address size (bytes in transfer = 32, "101")
    .m_axis_rx_TADD_READY(m_axis_rx_TADD_READY_Link2), //Read address Ready
    .m_axis_rx_TADD_LENGTH(m_axis_rx_TADD_LENGTH_Link2), //Read address Length (burst length = 1 = "00000001")
    .m_axis_rx_TADD_ID(m_axis_rx_TADD_ID_Link2), //Read Address ID
    .m_axis_rx_TADD_VALID(m_axis_rx_TADD_VALID_Link2), //Read Address valid
    .m_axis_rx_TRESP(m_axis_rx_TRESP_Link2), //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .m_axis_rx_TLAST(m_axis_rx_TLAST_Link2), //Read Data Last
    // write HBM interface
    .WR_ADDRESS(WR_ADDRESS_LINK2),
    .DATA_IN(DATA_IN_LINK2),
    .WR_REQ(WR_REQ_LINK2),
    .WR_READY(WR_READY_LINK2),
    // read HBM interface
    .RD_ADDRESS(RD_ADDRESS_LINK2),
    .RD_REQ(RD_REQ_LINK2), 
    .DATA_OUT(DATA_OUT_LINK2), 
    .WR_TAG_IN(WR_TAG_IN_LINK2),
    .RD_TAG_IN(RD_TAG_IN_LINK2),
    .TAG_OUT(TAG_OUT_LINK2),
    .DATA_VALID(DATA_VALID_LINK2),
    .RD_READY(RD_READY_LINK2),
    .AXI_ERROR_RESP_PULSE(sAXI_ERROR_RESP_PULSE_LINK2),
    .TX_AXI_ERROR_RESP(sTX_AXI_ERROR_RESP_LINK2),
    .RX_AXI_ERROR_RESP(sRX_AXI_ERROR_RESP_LINK2)
  );
  
//AXI State Machine Link3
  
  axi_rd_wr_state_machine #(
    //Define width of the datapath
    .DWIDTH(DWIDTH),
    //Define HBM interface width
    .NUM_DATA_BYTES(NUM_DATA_BYTES),
    // HBM Interface Address Width
    .AWIDTH(AWIDTH),
    .TWIDTH(TWIDTH),
    .HBM_ADD_BANK_SEL(HBM_ADD_BANK_SEL),
    // AXI Interface 
    .AXI_ADD_WIDTH(AXI_ADD_WIDTH),
    .AXI_BURST_SIZE(AXI_BURST_SIZE),
    .ATWIDTH(ATWIDTH)
  )  
  axi_rd_wr_state_machine_link3_inst (
    .CLK(USER_CLK),
    .RST(user_rstRR),
    .INIT_DONE(init_done_latchRR),
    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    .s_axis_tx_TVALID(s_axis_tx_TVALID_Link3),  //Write Data Valid
    .s_axis_tx_TREADY(s_axis_tx_TREADY_Link3), //Write Data Ready
    .s_axis_tx_TDATA(s_axis_tx_TDATA_Link3), //Write Data
    .s_axis_tx_TADD(s_axis_tx_TADD_Link3),  //Write Address
    .s_axis_tx_TADD_VALID(s_axis_tx_TADD_VALID_Link3), //write address Valid
    .s_axis_tx_TADD_SIZE(s_axis_tx_TADD_SIZE_Link3),  //write address size (bytes in transfer = 32, "101")  
    .s_axis_tx_TADD_READY(s_axis_tx_TADD_READY_Link3), //Write address Ready
    .s_axis_tx_TADD_LENGTH(s_axis_tx_TADD_LENGTH_Link3), //write address Length (burst length = 1 = "00000001")
    .s_axis_tx_TADD_BURST(s_axis_tx_TADD_BURST_Link3), //write addresss Burst (BURST TYPE = INC = "01")      
    .s_axis_tx_TADD_ID(s_axis_tx_TADD_ID_Link3), //Write address ID
    .s_axis_tx_TRESP_ID(s_axis_tx_TRESP_ID_Link3), //Write Response ID
    .s_axis_tx_TRESP(s_axis_tx_TRESP_Link3), //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .s_axis_tx_RESP_VALID(s_axis_tx_RESP_VALID_Link3), //Write response valid
    .s_axis_tx_RESP_RDY(s_axis_tx_RESP_RDY_Link3), //Write Response Ready   
    .s_axis_tx_TLAST(s_axis_tx_TLAST_Link3), //Write Data Last
    .s_axis_tx_TSTROBE(s_axis_tx_TSTROBE_Link3), //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    .m_axis_rx_TVALID(m_axis_rx_TVALID_Link3), //Read Data Valid
    .m_axis_rx_TREADY(m_axis_rx_TREADY_Link3), //Read Data Ready
    .m_axis_rx_TDATA(m_axis_rx_TDATA_Link3), //Read Data
    .m_axis_rx_TADD(m_axis_rx_TADD_Link3), //Read Data Address
    .m_axis_rx_TID(m_axis_rx_TID_Link3), //Read Data 
    .m_axis_rx_TADD_BURST(m_axis_rx_TADD_BURST_Link3), //read addresss Burst (BURST TYPE = INC = "01")
    .m_axis_rx_TADD_SIZE(m_axis_rx_TADD_SIZE_Link3),  //Read address size (bytes in transfer = 32, "101")
    .m_axis_rx_TADD_READY(m_axis_rx_TADD_READY_Link3), //Read address Ready
    .m_axis_rx_TADD_LENGTH(m_axis_rx_TADD_LENGTH_Link3), //Read address Length (burst length = 1 = "00000001")
    .m_axis_rx_TADD_ID(m_axis_rx_TADD_ID_Link3), //Read Address ID
    .m_axis_rx_TADD_VALID(m_axis_rx_TADD_VALID_Link3), //Read Address valid
    .m_axis_rx_TRESP(m_axis_rx_TRESP_Link3), //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    .m_axis_rx_TLAST(m_axis_rx_TLAST_Link3), //Read Data Last
    // write HBM interface
    .WR_ADDRESS(WR_ADDRESS_LINK3),
    .DATA_IN(DATA_IN_LINK3),
    .WR_REQ(WR_REQ_LINK3),
    .WR_READY(WR_READY_LINK3),
    // read HBM interface
    .RD_ADDRESS(RD_ADDRESS_LINK3),
    .RD_REQ(RD_REQ_LINK3), 
    .DATA_OUT(DATA_OUT_LINK3), 
    .WR_TAG_IN(WR_TAG_IN_LINK3),
    .RD_TAG_IN(RD_TAG_IN_LINK3),
    .TAG_OUT(TAG_OUT_LINK3),
    .DATA_VALID(DATA_VALID_LINK3),
    .RD_READY(RD_READY_LINK3),
    .AXI_ERROR_RESP_PULSE(sAXI_ERROR_RESP_PULSE_LINK3),
    .TX_AXI_ERROR_RESP(sTX_AXI_ERROR_RESP_LINK3),
    .RX_AXI_ERROR_RESP(sRX_AXI_ERROR_RESP_LINK3)
  );



  
//HBM OK if it initialises and no AXI transmission errors  
assign HBM_OK = init_done_latchRR & (~sAXI_ERROR_RESP_PULSE_LINK0) & (~sAXI_ERROR_RESP_PULSE_LINK1) & (~sAXI_ERROR_RESP_PULSE_LINK2) & (~sAXI_ERROR_RESP_PULSE_LINK3);




endmodule

`default_nettype wire

