// #########################################################################################################
// # Project: meerKAT+ (SKA-SA)
// # Module: axi_rd_wr_state_machine.v
// # Coded by: Adam Isaacson (aisaacson@sarao.ac.za)
// # Date: 02 Nov 2022
// #
// # Description
// #   The purpose of this module is to provide a read and write state machine for the AXI streaming interface.
// #   It ensures that simultaneous read and writes can occur and monitors errors on the AXI bus. It converts
// #   the HBM custom memory interface to AXI-S and visa versa
// #
// #
// ##########################################################################################################
module axi_rd_wr_state_machine #(    
    //Define width of the datapath
    parameter DWIDTH                = 256,  //Leave untouched
    //Define HBM interface width
    parameter NUM_DATA_BYTES        = 32,   //Leave untouched
    parameter AWIDTH                = 27,
    parameter TWIDTH                = 9,  //Tag Width
    parameter HBM_ADD_BANK_SEL      = 0,  //0 = Memory Bank 0 (lower 4GB), 1 = Memory Bank 1 (Upper 4GB) 
    // AXI Interface 
    parameter AXI_ADD_WIDTH         = 33,
    parameter AXI_BURST_SIZE        = 16,
    parameter AXI_BURST_SIZE_LOG2   = 4,  //LOG2(AXI_BURST_SIZE)
    parameter AXI_BURST_LOG2        = 9,  // LOG2(NUM_DATA_BYTES x AXI_BURST_SIZE) 
    parameter ATWIDTH               = 6,  //AXI Tag Width
    parameter TEST_MODE             = 1   //If high = 1, this enables the internal test mode with internally generated addressing and data ramps. If low = 0,
                                           //then the HBM custom interface is enabled and the address and data is externally provided.  


  )  (
    input  wire CLK,
    input  wire RST,
    input  wire INIT_DONE,
    //----------------------------------
    //----Connect AXI Ports
    //----------------------------------
    //From AXI to HMC Ctrl TX
    output  wire                         s_axis_tx_TVALID,  //Write Data Valid
    input   wire                         s_axis_tx_TREADY, //Write Data Ready
    output  wire [DWIDTH-1:0]            s_axis_tx_TDATA, //Write Data
    output  wire [AXI_ADD_WIDTH-1:0]     s_axis_tx_TADD,  //Write Address
    output  wire                         s_axis_tx_TADD_VALID, //write address Valid
    output  wire [2:0]                   s_axis_tx_TADD_SIZE,  //write address size (bytes in transfer = 32, "101")  
    input   wire                         s_axis_tx_TADD_READY, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH, //write address Length (burst length = 1 = "00000001")
    output  wire [1:0]                   s_axis_tx_TADD_BURST, //write addresss Burst (BURST TYPE = INC = "01")      
    output  wire [ATWIDTH-1:0]           s_axis_tx_TADD_ID, //Write address ID
    input   wire [ATWIDTH-1:0]           s_axis_tx_TRESP_ID, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP, //Write Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         s_axis_tx_RESP_VALID, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID, //Read Data Valid
    output  wire                         m_axis_rx_TREADY, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD, //Read Data Address
    input   wire [ATWIDTH-1:0]           m_axis_rx_TID, //Read Data
    output  wire [1:0]                   m_axis_rx_TADD_BURST, //read addresss Burst (BURST TYPE = INC = "01")
    output  wire [2:0]                   m_axis_rx_TADD_SIZE,  //Read address size (bytes in transfer = 32, "101")
    input   wire                         m_axis_rx_TADD_READY, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH, //Read address Length (burst length = 1 = "00000001")
    output  wire [ATWIDTH-1:0]           m_axis_rx_TADD_ID, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP, //Read Data Response ("00" - Okay, "01" - read or write okay, "10" - subordinate error, decode error "11")
    input   wire                         m_axis_rx_TLAST, //Read Data Last
    
    // write interface
    input  wire [AWIDTH-1:0] WR_ADDRESS,
    input  wire [DWIDTH-1:0] DATA_IN,
    input  wire WR_REQ,
    output wire WR_READY,

    // read interface
    input  wire [AWIDTH-1:0] RD_ADDRESS,
    input  wire RD_REQ, 
    output wire [DWIDTH-1:0] DATA_OUT, 
    input  wire [TWIDTH-1:0] WR_TAG_IN,
    input  wire [TWIDTH-1:0] RD_TAG_IN,
    
    output wire [TWIDTH-1:0] TAG_OUT,
    output wire DATA_VALID,
    output wire RD_READY,
    output wire AXI_ERROR_RESP_PULSE,
    output wire [1:0] TX_AXI_ERROR_RESP,
    output wire [1:0] RX_AXI_ERROR_RESP
    
  );
  
//Debug Signals
  (* mark_debug = "true" *) wire [63:0] dbg_wr_req_count; //Virtual test probe for the logic analyser
  (* mark_debug = "true" *) wire [63:0] dbg_rd_req_count; //Virtual test probe for the logic analyser
  (* mark_debug = "true" *) wire [63:0] dbg_r_data_valid_rx_hbm_valid_count;
  
  (* mark_debug = "true" *) wire [3:0] dbg_wr_axi_state;
  (* mark_debug = "true" *) wire [3:0] dbg_rd_axi_state;
  //(* mark_debug = "true" *) wire [15:0] dbg_wait_for_time_before_bus_trans_cnt;
  (* mark_debug = "true" *) wire dbg_WR_REQ;  
  (* mark_debug = "true" *) wire dbg_INIT_DONE;
  (* mark_debug = "true" *) wire dbg_wr_req_rdy;
  (* mark_debug = "true" *) wire dbg_rd_req_rdy;  
  (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_DATA_OUT;
  (* mark_debug = "true" *) wire [TWIDTH-1:0] dbg_reg_TAG_OUT;
  (* mark_debug = "true" *) wire dbg_reg_DATA_VALID;
  (* mark_debug = "true" *) wire dbg_reg_s_axis_tx_TADD_VALID;
  (* mark_debug = "true" *) wire [2:0] dbg_reg_s_axis_tx_TADD_SIZE;
  (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_s_axis_tx_TADD;
  (* mark_debug = "true" *) wire [7:0] dbg_reg_s_axis_tx_TADD_LENGTH;
  (* mark_debug = "true" *) wire [1:0] dbg_reg_s_axis_tx_TADD_BURST;
  (* mark_debug = "true" *) wire [ATWIDTH-1:0] dbg_reg_s_axis_tx_TADD_ID;
  (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_s_axis_tx_TDATA;
  (* mark_debug = "true" *) wire dbg_reg_s_axis_tx_TVALID;
  (* mark_debug = "true" *) wire [NUM_DATA_BYTES-1:0] dbg_reg_s_axis_tx_TSTROBE;
  (* mark_debug = "true" *) wire dbg_reg_s_axis_tx_TLAST;
  (* mark_debug = "true" *) wire dbg_s_axis_tx_TREADY;
  (* mark_debug = "true" *) wire dbg_s_axis_tx_TADD_READY;
  (* mark_debug = "true" *) wire dbg_AXI_ERROR_RESP_PULSE;
  // Signals used in this write debug state machine
  //(* mark_debug = "true" *) wire  [2:0] dbg_axi_wr_err_resp_pulse_gen_state;
  (* mark_debug = "true" *) wire  dbg_axi_wr_err_resp_pulse;
  (* mark_debug = "true" *) wire  [1:0] dbg_reg_TX_AXI_ERROR_RESP;
  (* mark_debug = "true" *) wire  dbg_reg_s_axis_tx_RESP_RDY;
  //Signals used in this read debug state machine
  //(* mark_debug = "true" *) wire [2:0] dbg_axi_rd_err_resp_pulse_gen_state;
  (* mark_debug = "true" *) wire dbg_axi_rd_err_resp_pulse;
  (* mark_debug = "true" *) wire [1:0] dbg_reg_RX_AXI_ERROR_RESP;
  (* mark_debug = "true" *) wire dbg_HBM_Memory_Bank_Sel;
  (* mark_debug = "true" *) wire dbg_reg_hbm_wr_fifo_cntrl_full;
  (* mark_debug = "true" *) wire dbg_reg_hbm_wr_fifo_data_full;
  (* mark_debug = "true" *) wire dbg_reg_hbm_wr_fifo_cntrl_empty;
  (* mark_debug = "true" *) wire dbg_reg_hbm_wr_fifo_data_empty;
  (* mark_debug = "true" *) wire dbg_wr_hbm_data_ack;
  (* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_ack;
  (* mark_debug = "true" *) wire dbg_rd_hbm_data_valid;
  (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_valid;
  (* mark_debug = "true" *) wire [31:0] dbg_temp_rd_hbm_cntrl_add; 
  (* mark_debug = "true" *) wire [255:0] dbg_temp_rd_hbm_data; 
  (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_en;
  //(* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_en;
  (* mark_debug = "true" *) wire dbg_rd_hbm_data_en;
  //(* mark_debug = "true" *) wire dbg_wr_hbm_data_en;
  //(* mark_debug = "true" *) wire [255:0] dbg_reg_wr_hbm_data;
  //(* mark_debug = "true" *) wire [31:0] dbg_reg_wr_hbm_cntrl_add; 
  (* mark_debug = "true" *) wire [255:0] dbg_rd_hbm_data;
  (* mark_debug = "true" *) wire [31:0] dbg_rd_hbm_cntrl_add;
  (* mark_debug = "true" *) wire dbg_rd_req;
  (* mark_debug = "true" *) wire dbg_m_axis_rx_TVALID; 
  //(* mark_debug = "true" *) wire [31:0] dbg_reg_rd_hbm_cntrl_add;
  (* mark_debug = "true" *) wire dbg_m_axis_rx_TLAST;
  (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_m_axis_rx_TADD;
  (* mark_debug = "true" *) wire dbg_reg_m_axis_rx_TADD_VALID;
  
  //Assign the test write HBM signals 
  (* mark_debug = "true" *) wire [AWIDTH-1:0] dbg_reg_test_wr_address;
  (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_test_wr_data; 
  (* mark_debug = "true" *) wire dbg_reg_test_wr_req;
  //Assign write AXI control and Address ILA 
  (* mark_debug = "true" *) wire [AWIDTH-1:0] dbg_reg_fifo_wr_add;
  (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_fifo_wr_data;
  (* mark_debug = "true" *) wire dbg_reg_fifo_wr_req;
  //(* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_temp_reg_wr_burst_add;
  (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_wr_burst_add; 
  
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Wr_Tx_ADD_VALID;
  //(* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_Fifo_Wr_Tx_ADD;
  //(* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_Fifo_Wr_Tx_DATA;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Wr_Tx_VALID;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Wr_Tx_TLAST;
  (* mark_debug = "true" *) wire [AXI_BURST_SIZE_LOG2-1:0] dbg_reg_Wr_TLAST_count;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Wr_Tx_Req;
  
  //Assign the test read HBM signals 
  (* mark_debug = "true" *) wire [AWIDTH-1:0] dbg_reg_test_rd_address; 
  (* mark_debug = "true" *) wire dbg_reg_test_rd_req;
  (* mark_debug = "true" *) wire [8:0] dbg_reg_read_delay_count;
  (* mark_debug = "true" *) wire dbg_reg_read_enable;
  
  //Assign read AXI control and Address ILA 
  (* mark_debug = "true" *) wire [AWIDTH-1:0] dbg_reg_rd_add;
  (* mark_debug = "true" *) wire dbg_reg_rd_req;
  (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_temp_reg_rd_burst_add;
  (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_rd_burst_add;   
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Rd_Rx_ADD_VALID;
  //(* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_reg_Fifo_Rd_Rx_ADD;
  //(* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_Fifo_Rd_Rx_DATA;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Rd_Rx_VALID;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Rd_Rx_TLAST;
  //reg [AXI_BURST_SIZE_LOG2-1:0] reg_Rd_TLAST_count;
  //(* mark_debug = "true" *) wire dbg_reg_Fifo_Rd_Rx_Req;
  
  //HBM read Control FIFO Signals
 (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_en_read;
 //(* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_en_read;
 (* mark_debug = "true" *) wire [31:0] dbg_rd_hbm_cntrl_add_read;
 (* mark_debug = "true" *) wire [31:0] dbg_temp_rd_hbm_cntrl_add_read;
 (* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_full_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_empty_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_valid_read;
 (* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_rst_busy_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_cntrl_rst_busy_read;
 (* mark_debug = "true" *) wire dbg_wr_hbm_cntrl_ack_read;
 
  //HBM read Data FIFO Signals
 (* mark_debug = "true" *) wire dbg_rd_hbm_data_en_read;
 //(* mark_debug = "true" *) wire dbg_hbm_data_en_read;
 (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_rd_hbm_data_read;
 (* mark_debug = "true" *) wire [DWIDTH-1:0] dbg_reg_axis_rdata_latch; 
 (* mark_debug = "true" *) wire dbg_wr_hbm_data_full_read;
 (* mark_debug = "true" *) wire dbg_wr_hbm_data_ack_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_data_empty_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_data_valid_read;
 (* mark_debug = "true" *) wire dbg_wr_hbm_data_rst_busy_read;
 (* mark_debug = "true" *) wire dbg_rd_hbm_data_rst_busy_read;
 
 (* mark_debug = "true" *) wire [AXI_BURST_SIZE_LOG2-1:0] dbg_burst_size_max;
 (* mark_debug = "true" *) wire dbg_reg_add_rd_burst_start_pulse;
 (* mark_debug = "true" *) wire [AXI_ADD_WIDTH-1:0] dbg_temp_reg_wr_burst_add;
 (* mark_debug = "true" *) wire dbg_reg_axis_ar_add_valid;
 (* mark_debug = "true" *) wire [2:0] dbg_reg_axis_ar_add_burst;
 
  
  
  
  reg [63:0] r_data_valid_rx_hbm_valid_count;


// Signals used in this module
  reg [3:0] wr_axi_state,rd_axi_state;
  //reg [15:0] wait_for_time_before_bus_trans_cnt;
  reg [63:0] wr_req_count;
  reg [63:0] rd_req_count;
  reg wr_req_rdy;
  reg rd_req_rdy;
  reg [DWIDTH-1:0] reg_DATA_OUT;
  reg [TWIDTH-1:0] reg_TAG_OUT;
  reg reg_DATA_VALID;

  //AXI Tx registers
  wire reg_s_axis_tx_TADD_VALID;
  wire [2:0] reg_s_axis_tx_TADD_SIZE;
  wire [AXI_ADD_WIDTH-1:0] reg_s_axis_tx_TADD;
  wire [7:0] reg_s_axis_tx_TADD_LENGTH;
  wire [1:0] reg_s_axis_tx_TADD_BURST;
  wire [ATWIDTH-1:0] reg_s_axis_tx_TADD_ID;
  wire [DWIDTH-1:0] reg_s_axis_tx_TDATA;
  wire reg_s_axis_tx_TVALID;
  wire [NUM_DATA_BYTES-1:0] reg_s_axis_tx_TSTROBE;
  wire reg_s_axis_tx_TLAST;

  //AXI Rx Registers
  wire reg_m_axis_rx_TADD_VALID;
  wire [2:0] reg_m_axis_rx_TADD_SIZE;
  wire [AXI_ADD_WIDTH-1:0] reg_m_axis_rx_TADD;
  wire [7:0] reg_m_axis_rx_TADD_LENGTH;
  wire [1:0] reg_m_axis_rx_TADD_BURST;
  wire [ATWIDTH-1:0] reg_m_axis_rx_TADD_ID;
  wire reg_m_axis_rx_TREADY;
  //reg reg_m_axis_rx_TLAST;
  
  wire HBM_Memory_Bank_Sel;

  wire [ATWIDTH-1:0] tag_zero_add_id;
  wire [TWIDTH-1:0] tag_zero;
  wire [DWIDTH-1:0] data_zero;
  wire [AWIDTH-1:0] add_zero;
  wire [NUM_DATA_BYTES-1:0] strobe_zero;
  wire [NUM_DATA_BYTES-1:0] strobe_one;
  wire [TWIDTH-ATWIDTH-1:0] tag_diff_zero;
  wire [AXI_BURST_SIZE_LOG2-1:0] burst_size_zero;
  
  
  //assign intialise registers
  assign tag_zero_add_id = {ATWIDTH{1'b0}}; //generic tag address ID zeroed
  assign tag_zero = {TWIDTH{1'b0}}; //generic tag zeroed
  assign data_zero = {DWIDTH{1'b0}}; //generic data zeroed
  assign add_zero = {AWIDTH{1'b0}}; //Address zeroed
  assign strobe_zero = {NUM_DATA_BYTES{1'b0}}; //Strobe zeroed
  assign strobe_one = {NUM_DATA_BYTES{1'b1}}; //Strobe ones
  assign tag_diff_zero = {(TWIDTH-ATWIDTH){1'b0}}; //tag diff zero 
  assign HBM_Memory_Bank_Sel = HBM_ADD_BANK_SEL ? 1'b1 : 1'b0; //if HBM_ADD_BANK_SEL is high then select '1' else '0'
  assign burst_size_zero = {AXI_BURST_SIZE_LOG2{1'b0}}; //burst size zero 

  //assign AXI Tx
  assign s_axis_tx_TADD_VALID = reg_s_axis_tx_TADD_VALID;
  assign s_axis_tx_TADD_SIZE = reg_s_axis_tx_TADD_SIZE;
  assign s_axis_tx_TADD = reg_s_axis_tx_TADD;
  assign s_axis_tx_TADD_LENGTH = reg_s_axis_tx_TADD_LENGTH;
  assign s_axis_tx_TADD_BURST = reg_s_axis_tx_TADD_BURST;
  assign s_axis_tx_TADD_ID = reg_s_axis_tx_TADD_ID; //m_axis_hbm_tid;//reg_s_axis_tx_TADD_ID;
  assign s_axis_tx_TDATA = reg_s_axis_tx_TDATA; //m_axis_hbm_tdata;//reg_s_axis_tx_TDATA;
  assign s_axis_tx_TVALID = reg_s_axis_tx_TVALID; //s_axis_hbm_tvalid;//reg_s_axis_tx_TVALID;
  assign s_axis_tx_TSTROBE = reg_s_axis_tx_TSTROBE ;//m_axis_hbm_tstrb;//reg_s_axis_tx_TSTROBE;
  assign s_axis_tx_TLAST = reg_s_axis_tx_TLAST; //m_axis_hbm_tlast;//reg_s_axis_tx_TLAST;

  //assign AXI Rx
  assign m_axis_rx_TADD_VALID = reg_m_axis_rx_TADD_VALID;
  assign m_axis_rx_TADD_SIZE = reg_m_axis_rx_TADD_SIZE;
  assign m_axis_rx_TADD = reg_m_axis_rx_TADD;
  assign m_axis_rx_TADD_LENGTH = reg_m_axis_rx_TADD_LENGTH;
  assign m_axis_rx_TADD_BURST = reg_m_axis_rx_TADD_BURST;
  assign m_axis_rx_TADD_ID = reg_m_axis_rx_TADD_ID;
  assign m_axis_rx_TREADY = reg_m_axis_rx_TREADY;

  assign DATA_OUT = reg_DATA_OUT;
  assign TAG_OUT = reg_TAG_OUT;
  assign DATA_VALID = reg_DATA_VALID;

  //debug

  assign dbg_wr_req_count = wr_req_count;
  assign dbg_rd_req_count = rd_req_count;
  assign dbg_r_data_valid_rx_hbm_valid_count = r_data_valid_rx_hbm_valid_count;
  
 //assign the AXI state machine debug signals ILA
  assign dbg_wr_axi_state = wr_axi_state;
  assign dbg_rd_axi_state = rd_axi_state;
  //assign dbg_wait_for_time_before_bus_trans_cnt = wait_for_time_before_bus_trans_cnt;
  assign dbg_WR_REQ = WR_REQ;  
  assign dbg_INIT_DONE = INIT_DONE;
  assign dbg_wr_req_rdy = wr_req_rdy;  
  assign dbg_rd_req_rdy = rd_req_rdy;
  assign dbg_reg_DATA_OUT = reg_DATA_OUT;
  assign dbg_reg_TAG_OUT = reg_TAG_OUT;
  assign dbg_reg_DATA_VALID = reg_DATA_VALID;
  assign dbg_reg_s_axis_tx_TADD_VALID = reg_s_axis_tx_TADD_VALID;
  assign dbg_reg_s_axis_tx_TADD_SIZE = reg_s_axis_tx_TADD_SIZE;
  assign dbg_reg_s_axis_tx_TADD = reg_s_axis_tx_TADD;
  assign dbg_reg_s_axis_tx_TADD_LENGTH = reg_s_axis_tx_TADD_LENGTH;
  assign dbg_reg_s_axis_tx_TADD_BURST = reg_s_axis_tx_TADD_BURST;
  assign dbg_reg_s_axis_tx_TADD_ID = reg_s_axis_tx_TADD_ID;   //m_axis_hbm_tid;//reg_s_axis_tx_TADD_ID;
  assign dbg_reg_s_axis_tx_TDATA = reg_s_axis_tx_TDATA;//m_axis_hbm_tdata;//reg_s_axis_tx_TDATA;
  assign dbg_reg_s_axis_tx_TVALID = reg_s_axis_tx_TVALID; //s_axis_hbm_tvalid;//reg_s_axis_tx_TVALID;
  assign dbg_reg_s_axis_tx_TSTROBE = reg_s_axis_tx_TSTROBE; //m_axis_hbm_tstrb;//reg_s_axis_tx_TSTROBE;
  assign dbg_reg_s_axis_tx_TLAST = reg_s_axis_tx_TLAST; //m_axis_hbm_tlast;//reg_s_axis_tx_TLAST;
  assign dbg_s_axis_tx_TREADY = s_axis_tx_TREADY;
  assign dbg_s_axis_tx_TADD_READY = s_axis_tx_TADD_READY;
  assign dbg_AXI_ERROR_RESP_PULSE =  axi_wr_err_resp_pulse || axi_rd_err_resp_pulse;
  // Signals used in this write debug state machine
  //assign dbg_axi_wr_err_resp_pulse_gen_state = axi_wr_err_resp_pulse_gen_state;
  assign dbg_axi_wr_err_resp_pulse = axi_wr_err_resp_pulse;
  assign dbg_reg_TX_AXI_ERROR_RESP = reg_TX_AXI_ERROR_RESP;
  assign dbg_reg_s_axis_tx_RESP_RDY = reg_s_axis_tx_RESP_RDY;
  //Signals used in this read debug state machine
  //assign dbg_axi_rd_err_resp_pulse_gen_state = 3'b0;//axi_rd_err_resp_pulse_gen_state;
  assign dbg_axi_rd_err_resp_pulse = axi_rd_err_resp_pulse;
  assign dbg_reg_RX_AXI_ERROR_RESP = reg_RX_AXI_ERROR_RESP;
  assign dbg_HBM_Memory_Bank_Sel = HBM_Memory_Bank_Sel;
  
  assign dbg_reg_hbm_wr_fifo_cntrl_full = wr_hbm_cntrl_full;
  assign dbg_reg_hbm_wr_fifo_data_full = wr_hbm_data_full;
  assign dbg_reg_hbm_wr_fifo_cntrl_empty = rd_hbm_cntrl_empty;
  assign dbg_reg_hbm_wr_fifo_data_empty = rd_hbm_data_empty;
  assign dbg_wr_hbm_data_ack = wr_hbm_data_ack;
  assign dbg_wr_hbm_cntrl_ack = wr_hbm_cntrl_ack;
  assign dbg_rd_hbm_data_valid = rd_hbm_data_valid;
  assign dbg_rd_hbm_cntrl_valid = rd_hbm_cntrl_valid;
  assign dbg_temp_rd_hbm_cntrl_add = temp_rd_hbm_cntrl_add;
  assign dbg_temp_rd_hbm_data = temp_rd_hbm_data; 
  assign dbg_rd_hbm_cntrl_en = rd_hbm_cntrl_en;
  //assign dbg_wr_hbm_cntrl_en = wr_hbm_cntrl_en;
  assign dbg_rd_hbm_data_en = rd_hbm_data_en;
  //assign dbg_wr_hbm_data_en = wr_hbm_data_en;
  //assign dbg_reg_wr_hbm_data = reg_wr_hbm_data;
  //assign dbg_reg_wr_hbm_cntrl_add = reg_wr_hbm_cntrl_add;
  assign dbg_rd_hbm_data = rd_hbm_data;
  assign dbg_rd_hbm_cntrl_add = rd_hbm_cntrl_add;
  assign dbg_rd_req = RD_REQ;
  assign dbg_m_axis_rx_TVALID = m_axis_rx_TVALID;
  //assign dbg_reg_rd_hbm_cntrl_add = reg_rd_hbm_cntrl_add_sm;
  assign dbg_m_axis_rx_TLAST = m_axis_rx_TLAST;
  assign dbg_reg_m_axis_rx_TADD = reg_axis_ar_add;
  assign dbg_reg_m_axis_rx_TADD_VALID = reg_axis_ar_add_valid;
  
  //assign the test write debug signals ILA
  assign dbg_reg_test_wr_address = reg_test_wr_address;
  assign dbg_reg_test_wr_data = reg_test_wr_data; 
  assign dbg_reg_test_wr_req = reg_test_wr_req;
  
  //assign write AXI control and Address ILA 
  assign dbg_reg_fifo_wr_add = reg_fifo_wr_add;
  assign dbg_reg_fifo_wr_data = reg_fifo_wr_data;
  assign dbg_reg_fifo_wr_req = reg_fifo_wr_req;
  //assign dbg_temp_reg_wr_burst_add = temp_req_wr_burst_add;
  assign dbg_reg_wr_burst_add = reg_wr_burst_add; 
  
  //assign dbg_reg_Fifo_Wr_Tx_ADD_VALID = reg_Fifo_Wr_Tx_ADD_VALID;
  //assign dbg_reg_Fifo_Wr_Tx_ADD = reg_Fifo_Wr_Tx_ADD;
  //assign dbg_reg_Fifo_Wr_Tx_DATA = reg_Fifo_Wr_Tx_DATA;
  //assign dbg_reg_Fifo_Wr_Tx_VALID = reg_Fifo_Wr_Tx_VALID;
  //assign dbg_reg_Fifo_Wr_Tx_TLAST = reg_Fifo_Wr_Tx_TLAST;
  assign dbg_reg_Wr_TLAST_count = reg_Wr_TLAST_count;
  //assign dbg_reg_Fifo_Wr_Tx_Req = reg_Fifo_Wr_Tx_Req;
  
  
  //assign the test read degug signals 
  assign dbg_reg_test_rd_address = reg_test_rd_address; 
  assign dbg_reg_test_rd_req = reg_test_rd_req;
  assign dbg_reg_read_delay_count = reg_read_delay_count;
  assign dbg_reg_read_enable = reg_read_enable; 
  
  //Assign read AXI control and Address ILA 
  assign dbg_reg_rd_add = reg_fifo_rd_add;
  assign dbg_reg_rd_req = reg_fifo_rd_req;
  assign dbg_temp_reg_rd_burst_add = temp_reg_rd_burst_add;
  assign dbg_reg_rd_burst_add = reg_rd_burst_add;   
  //assign dbg_reg_Fifo_Rd_Rx_ADD_VALID = reg_Fifo_Rd_Rx_ADD_VALID;
  //assign dbg_reg_Fifo_Rd_Rx_ADD = reg_Fifo_Rd_Rx_ADD;
  //assign dbg_reg_Fifo_Rd_Rx_DATA = reg_Fifo_Rd_Rx_DATA;
  //assign dbg_reg_Fifo_Rd_Rx_VALID = reg_Fifo_Rd_Rx_VALID;
  //assign dbg_reg_Fifo_Rd_Rx_TLAST = reg_Fifo_Rd_Rx_TLAST;
  //reg [AXI_BURST_SIZE_LOG2-1:0] reg_Rd_TLAST_count;
 // assign dbg_reg_Fifo_Rd_Rx_Req = reg_Fifo_Rd_Rx_Req;
  
 //Assign HBM read Control FIFO Signals
 assign dbg_rd_hbm_cntrl_en_read = rd_hbm_cntrl_en_read;
 //assign dbg_wr_hbm_cntrl_en_read = wr_hbm_cntrl_en_read;
 assign dbg_rd_hbm_cntrl_add_read = rd_hbm_cntrl_add_read;
 assign dbg_temp_rd_hbm_cntrl_add_read = temp_rd_hbm_cntrl_add_read;
 assign dbg_wr_hbm_cntrl_full_read = wr_hbm_cntrl_full_read;
 assign dbg_rd_hbm_cntrl_empty_read = rd_hbm_cntrl_empty_read;
 assign dbg_rd_hbm_cntrl_valid_read = rd_hbm_cntrl_valid_read;
 assign dbg_wr_hbm_cntrl_rst_busy_read = wr_hbm_cntrl_rst_busy_read;
 assign dbg_rd_hbm_cntrl_rst_busy_read = rd_hbm_cntrl_rst_busy_read;
 assign dbg_wr_hbm_cntrl_ack_read = wr_hbm_cntrl_ack_read;
 
 //Assign HBM read Data FIFO Signals
 assign dbg_rd_hbm_data_en_read = rd_hbm_data_en_read;
 //assign dbg_hbm_data_en_read = hbm_data_en_read;
 assign dbg_rd_hbm_data_read = rd_hbm_data_read;
 assign dbg_reg_axis_rdata_latch = reg_axis_rdata_latch; 
 assign dbg_wr_hbm_data_full_read = wr_hbm_data_full_read;
 assign dbg_wr_hbm_data_ack_read = wr_hbm_data_ack_read;
 assign dbg_rd_hbm_data_empty_read = rd_hbm_data_empty_read;
 assign dbg_rd_hbm_data_valid_read = rd_hbm_data_valid_read;
 assign dbg_wr_hbm_data_rst_busy_read = wr_hbm_data_rst_busy_read;
 assign dbg_rd_hbm_data_rst_busy_read = rd_hbm_data_rst_busy_read;
 assign dbg_reg_add_rd_burst_start_pulse = reg_add_rd_burst_start_pulse;
 assign dbg_temp_reg_wr_burst_add = temp_reg_wr_burst_add;
 assign dbg_reg_axis_ar_add_valid = reg_axis_ar_add_valid;
 
 
 assign dbg_reg_axis_ar_add_burst = reg_axis_ar_add_burst; 
 


  // ***************************************************************************************************************************************************************************************
  // Write Test Data and Address Gen Process
  //
  // This process generates an internal test data ramp function, contiguous Address signals and write control signals
  // It starts address and data at zero when reset occurs and then counts incrementally until it wraps
  // NB; It emulates the Simulink address and data generation (basic).
  // This function is only utilised when TEST_MODE is high. 
  // ***************************************************************************************************************************************************************************************

  
  reg [AWIDTH-1:0] reg_test_wr_address;
  reg [DWIDTH-1:0] reg_test_wr_data; 
  reg reg_test_wr_req;
  reg [AXI_ADD_WIDTH-1:0] reg_s_axis_tx_full_add;
  
  wire [AWIDTH-1:0] zero_test_wr_add;
  wire [DWIDTH-1:0] zero_test_wr_data;
  
  
  //assign intialise registers
  assign zero_test_wr_add = {AWIDTH{1'b0}}; //generic test write address zeroed
  assign zero_test_wr_add = {DWIDTH{1'b0}}; //generic test write address zeroed
  
  always @(posedge CLK) begin : wr_test_data_address_gen

    if (RST) begin
        //Initialise registers to zero at start up
        reg_test_wr_address <= zero_test_wr_add;
        reg_test_wr_data <= reg_test_wr_data;
        reg_test_wr_req <= 1'b0;
        reg_s_axis_tx_full_add <= {1'b0, 5'b00000, add_zero};
         
    end else begin
        reg_s_axis_tx_full_add <= {HBM_Memory_Bank_Sel, reg_test_wr_address[AWIDTH-1:0], 5'd0};
        //Increment counter from zero that will wrap around for both address and data provided write is ready 
        //This implements test back pressure 
        //Only write when s_axis_tx_TREADY is asserted for the test case 
        if (wr_req_rdy & s_axis_tx_TREADY) begin
          //Keep address within AXI address map link0 for now 
          if (reg_s_axis_tx_full_add >= 33'd0 && reg_s_axis_tx_full_add <= 33'd268435455) begin
            reg_test_wr_address <= reg_test_wr_address + 1;
          end else begin
            reg_test_wr_address <= zero_test_wr_add;
          end  
          reg_test_wr_data <= reg_test_wr_data + 1;
          reg_test_wr_req <= 1'b1; 
        end else begin
          reg_test_wr_req <= 1'b0;  
        end
  
    end
  end

  wire [AWIDTH-1:0] reg_fifo_wr_add;
  wire [DWIDTH-1:0] reg_fifo_wr_data;
  wire reg_fifo_wr_req;
 
  //mux for selecting test address and data or normal simulink address and data
  assign reg_fifo_wr_add = TEST_MODE ? reg_test_wr_address : WR_ADDRESS; //if TEST_MODE is high then select test address else select normal addres
  assign reg_fifo_wr_data = TEST_MODE ? reg_test_wr_data : DATA_IN; //if TEST_MODE is high then select test data else select normal data
  assign reg_fifo_wr_req = TEST_MODE ? reg_test_wr_req : WR_REQ; //if TEST_MODE is high then select test write request else select normal write request
  

  
  // ***************************************************************************************************************************************************************************************
  // Write HBM Address and Data store FIFO
  // ***************************************************************************************************************************************************************************************

 //HBM write Control FIFO Signals
 reg rd_hbm_cntrl_en;
 //reg wr_hbm_cntrl_en;
 wire [31:0]rd_hbm_cntrl_add;
 wire wr_hbm_cntrl_full;
 wire rd_hbm_cntrl_empty;
 wire rd_hbm_cntrl_valid;
 wire wr_hbm_cntrl_rst_busy;
 wire rd_hbm_cntrl_rst_busy;
 wire wr_hbm_cntrl_ack;
 
 
 
 fifo_generator_wr_hbm_cntrl_0 fifo_generator_wr_hbm_cntrl_0_inst (
  
    .srst(RST),
    .clk(CLK),
    .din({1'b0,reg_fifo_wr_req,1'b0,1'b0,1'b0,reg_fifo_wr_add[AWIDTH-1:0]}),
    .wr_en(reg_fifo_wr_req & s_axis_tx_TREADY),
    .rd_en(rd_hbm_cntrl_en & s_axis_tx_TREADY),
    .dout(rd_hbm_cntrl_add),
    .full(wr_hbm_cntrl_full),
    .wr_ack(wr_hbm_cntrl_ack),
    .empty(rd_hbm_cntrl_empty),
    .valid(rd_hbm_cntrl_valid),
    .wr_rst_busy(wr_hbm_cntrl_rst_busy),
    .rd_rst_busy(rd_hbm_cntrl_rst_busy)
  );
  
 //HBM write Data FIFO Signals
 reg rd_hbm_data_en;
 //reg wr_hbm_data_en;
 wire [DWIDTH-1:0]rd_hbm_data; 
 wire wr_hbm_data_full;
 wire wr_hbm_data_ack;
 wire rd_hbm_data_empty;
 wire rd_hbm_data_valid;
 wire wr_hbm_data_rst_busy;
 wire rd_hbm_data_rst_busy;

 
 fifo_generator_wr_hbm_data_0 fifo_generator_wr_hbm_data_0_inst (
  
    .srst(RST),
    .clk(CLK),
    .din(reg_fifo_wr_data),
    .wr_en(reg_fifo_wr_req & s_axis_tx_TREADY),
    .rd_en(rd_hbm_data_en & s_axis_tx_TREADY),
    .dout(rd_hbm_data),
    .full(wr_hbm_data_full),
    .wr_ack(wr_hbm_data_ack),
    .empty(rd_hbm_data_empty),
    .valid(rd_hbm_data_valid),
    .wr_rst_busy(wr_hbm_data_rst_busy),
    .rd_rst_busy(rd_hbm_data_rst_busy)
  );
  
  
  reg [AXI_ADD_WIDTH-1:0] temp_reg_wr_burst_add;
  reg [AXI_ADD_WIDTH-1:0] reg_wr_burst_add; 
  

  reg [AXI_BURST_SIZE_LOG2-1:0] reg_Wr_TLAST_count;
  reg reg_Fifo_Wr_Tx_Req;
  reg [31:0] temp_rd_hbm_cntrl_add;
  reg [DWIDTH-1:0] temp_rd_hbm_data;
  
  reg reg_s_axis_tx_RESP_RDY;
  
  reg reg_add_wr_burst_start_pulse;
  
  //Address write signals
  
  reg reg_axis_aw_add_valid;
  reg [2:0] reg_axis_aw_add_size;
  reg [AXI_ADD_WIDTH-1:0] reg_axis_aw_add;
  reg [7:0] reg_axis_aw_add_length; 
  reg [1:0] reg_axis_aw_add_burst;
  reg [ATWIDTH-1:0] reg_axis_aw_id;
  
  //write data signals
  reg [DWIDTH-1:0] reg_axis_wdata;
  reg reg_axis_wvalid;
  wire reg_axis_tlast;
  reg [NUM_DATA_BYTES-1:0] reg_axis_wstrobe;
  
  //write response signals
  reg reg_axis_bresp_rdy;
  reg [1:0] reg_axis_bresp;
  
    
  
  assign s_axis_tx_RESP_RDY = reg_s_axis_tx_RESP_RDY;
  
  
  // State machine state vector elements
  localparam STATE_IDLE                    = 4'd0; // Default state: enter on power up or reset, exit on INIT_DONE == 1'b1
  localparam WAIT_AXI_TX_RDY               = 4'd1; // Wait for AXI TX bus to become available
  localparam STATE_READ_WR_FIFO_DATA       = 4'd2; // Issue write add transactions  
  localparam STATE_RD_DATA                 = 4'd3; // Check for read data
  
  // ***************************************************************************************************************************************************************************************
  // Read FIFO Write State Machine: performs burst detect too 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : read_fifo_wr_axi

  if (RST) begin
    wr_axi_state <= STATE_IDLE;
    wr_req_rdy <= 1'b0;        
    rd_hbm_data_en <= 1'b0;
    rd_hbm_cntrl_en <= 1'b0;
    temp_rd_hbm_data <= 256'b0;
    temp_rd_hbm_cntrl_add <= 32'b0;  
    reg_wr_burst_add <= {1'b0, 5'b00000, add_zero};
    temp_reg_wr_burst_add <= {1'b0, 5'b00000, add_zero};   
    reg_add_wr_burst_start_pulse <= 1'b0;       
  end else begin

      wr_req_rdy <= 1'b1;
      case (wr_axi_state)
        // State: Entry to state machine (from reset)
        STATE_IDLE: begin
          wr_axi_state <= STATE_IDLE;
          rd_hbm_data_en <= 1'b0;
          rd_hbm_cntrl_en <= 1'b0;
          if (INIT_DONE == 1'b1 && wr_hbm_data_full == 1'b0 && wr_hbm_cntrl_full == 1'b0) begin // We cannot issue any AXI Transactions if the HBM is not initialized!
            wr_req_rdy <= 1'b1;
            wr_axi_state <= WAIT_AXI_TX_RDY;
          end else begin
            wr_req_rdy <= 1'b0;
            wr_axi_state <= STATE_IDLE;       
          end
        end
        WAIT_AXI_TX_RDY: begin
          //enable FIFOs continually (write and read)
          rd_hbm_data_en <= 1'b1;
          rd_hbm_cntrl_en <= 1'b1;
          if (wr_hbm_data_full == 1'b0 && wr_hbm_cntrl_full == 1'b0) begin // Make sure user TX FIFO is not FULL  
            wr_axi_state <= STATE_READ_WR_FIFO_DATA;
            wr_req_rdy <= 1'b1;
          end else begin
            wr_axi_state <= WAIT_AXI_TX_RDY; // Wait for TX AXI FIFO to become available
            wr_req_rdy <= 1'b0;            
          end
        end
        //Write Data
        STATE_READ_WR_FIFO_DATA: begin
          wr_axi_state <= STATE_READ_WR_FIFO_DATA;
          rd_hbm_data_en <= 1'b1;
          rd_hbm_cntrl_en <= 1'b1;

          //if data is valid at the FIFO output then assign output to temp signals
          if( rd_hbm_data_valid == 1'b1 && rd_hbm_cntrl_valid == 1'b1) begin
             temp_rd_hbm_cntrl_add <= rd_hbm_cntrl_add; 
             temp_rd_hbm_data <= rd_hbm_data; 
          end 
          //Look for burst address change
          reg_wr_burst_add <= {1'b0, 5'b00000, temp_rd_hbm_cntrl_add[AWIDTH-1:0] >> AXI_BURST_SIZE_LOG2};
          temp_reg_wr_burst_add <= reg_wr_burst_add; 
          //Detect address write change
          //If Burst Address changes then generate AXI burst start pulse indicator 
          if (temp_reg_wr_burst_add != reg_wr_burst_add ) begin
            reg_add_wr_burst_start_pulse <= 1'b1;
          end else begin
            reg_add_wr_burst_start_pulse <= 1'b0;        
          end          
         
          //if FIFO is full, then deassert write ready signals only  
          if(wr_hbm_cntrl_full == 1'b0 && wr_hbm_data_full == 1'b0) begin
            wr_req_rdy <= 1'b1;
          end else begin
            wr_req_rdy <= 1'b0;
          end       
    end    
     endcase
    end    
  end

 
 assign WR_READY = wr_req_rdy;
 reg reg_add_wr_burst_start_sync;
 reg  [AXI_ADD_WIDTH-1:0] reg_axis_wr_add_latch;
 

 
  // ***************************************************************************************************************************************************************************************
  // AXI address Write process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_wr_add

    if (RST) begin
    
      reg_axis_aw_add_valid <= 1'b0;
      reg_axis_aw_add_size <= 3'd0;
      reg_axis_aw_add <= {1'b0, 5'b00000, add_zero};
      reg_axis_aw_add_length <=  8'b00000000; //burst length 16; 
      reg_axis_aw_add_burst <= 2'b00; //Bust Type INC;
      reg_axis_aw_id <= tag_zero_add_id;
      reg_add_wr_burst_start_sync <= 1'b0;
      reg_axis_wr_add_latch <= {1'b0, 5'b00000, add_zero};
           
    end else begin
    
      //write address metadata
      reg_axis_aw_add_length <=  8'd15; //burst length 16 (busr size = AXLEN + 1 = 15 + 1); 
      reg_axis_aw_add_burst <= 2'b01; //Bust Type INC;
      reg_axis_aw_id <= WR_TAG_IN[ATWIDTH-1:0]; 
      reg_axis_aw_add_size <= 3'd5; //Bytes in transfer 32 bytes      
      //if burst pulse detected then begin the write address process 
      if(reg_add_wr_burst_start_pulse) begin
        reg_axis_aw_add_valid <= 1'b1;
        reg_add_wr_burst_start_sync <= 1'b1;
        reg_axis_wr_add_latch <= {HBM_Memory_Bank_Sel, temp_rd_hbm_cntrl_add[AWIDTH-1:0],5'b00000};
      end
      
      //Once address write ready and address write valid are high end transaction
      if(s_axis_tx_TADD_READY & reg_axis_aw_add_valid) begin
        reg_axis_aw_add <= reg_axis_wr_add_latch;
        reg_axis_aw_add_valid <= 1'b0;
      end
    end
 end 
 
 //assign write address signals to actual AXI HBM signals
 
 assign reg_s_axis_tx_TADD_VALID = reg_axis_aw_add_valid; 
 assign reg_s_axis_tx_TADD_SIZE =  reg_axis_aw_add_size; 
 assign reg_s_axis_tx_TADD = reg_axis_aw_add; 
 assign reg_s_axis_tx_TADD_LENGTH = reg_axis_aw_add_length;
 assign reg_s_axis_tx_TADD_BURST = reg_axis_aw_add_burst;
 assign reg_s_axis_tx_TADD_ID = reg_axis_aw_id; 
 
 reg  [DWIDTH-1:0] reg_axis_wdata_latch; 
 
  // ***************************************************************************************************************************************************************************************
  // AXI Data Write process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_wr_data

    if (RST) begin
    
      reg_axis_wdata <= data_zero;
      reg_axis_wdata_latch <= data_zero;
      reg_axis_wvalid <= 1'b0;
      //reg_axis_tlast <= 1'b0;
      reg_axis_wstrobe <= strobe_zero;
      //reg_Wr_TLAST_count <= 4'd0;
           
    end else begin
    
      //if data valid from FIFO then begin write process 
      if(temp_rd_hbm_cntrl_add[30] & reg_add_wr_burst_start_sync) begin
        reg_axis_wvalid <= 1'b1;    
        reg_axis_wdata_latch <= temp_rd_hbm_data;
        reg_axis_wstrobe <= strobe_one;
      end else begin
        reg_axis_wvalid <= 1'b0;   
      end
      
      //Once data write ready and data write valid are high end transaction
      if(s_axis_tx_TREADY & reg_axis_wvalid) begin
        reg_axis_wdata <= reg_axis_wdata_latch;  
        //reg_axis_wvalid <= 1'b0;
        //reg_Wr_TLAST_count <= reg_Wr_TLAST_count + 1'd1;
      end
      
    end
 end 
 
  // ***************************************************************************************************************************************************************************************
  // AXI Data Write burst TLAST generationprocess 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_wr_tlast_gen

    if (RST) begin
    
      reg_Wr_TLAST_count <= 4'd0;
           
    end else begin
          
      //Once data write ready and data write valid are high increment TLAST write burst counter
      if (s_axis_tx_TREADY & reg_axis_wvalid & reg_axis_tlast ) begin
        reg_Wr_TLAST_count <= 4'd0;
      end else if(s_axis_tx_TREADY & reg_axis_wvalid) begin
        reg_Wr_TLAST_count <= reg_Wr_TLAST_count + 1;
      end     
      
    end
 end 
 
 //Gernerate write TLAST for burst
 assign reg_axis_tlast = (reg_Wr_TLAST_count == 4'd15) ? 1'b1 : 1'b0; 

 //assign Write Data signals to actual HBM AXI signals
 assign reg_s_axis_tx_TDATA = reg_axis_wdata;
 assign reg_s_axis_tx_TVALID = reg_axis_wvalid;
 assign reg_s_axis_tx_TSTROBE = reg_axis_wstrobe;
 assign reg_s_axis_tx_TLAST = reg_axis_tlast;
 
 
  // Signals used for AXI write response
  reg axi_wr_err_resp_pulse;
  reg [1:0] reg_TX_AXI_ERROR_RESP;
 
  // ***************************************************************************************************************************************************************************************
  // AXI Write response process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_wr_response

    if (RST) begin  
      axi_wr_err_resp_pulse <= 1'b0;
      reg_s_axis_tx_RESP_RDY <= 1'b0;
           
    end else begin
      reg_TX_AXI_ERROR_RESP <= s_axis_tx_TRESP;
      //always be ready for a response
      reg_s_axis_tx_RESP_RDY <= 1'b1;
      //if write response ready and write response valid are asserted 
      if(reg_s_axis_tx_RESP_RDY & s_axis_tx_RESP_VALID) begin
        reg_s_axis_tx_RESP_RDY <= 1'b0;
        if(reg_TX_AXI_ERROR_RESP > 0) begin
          axi_wr_err_resp_pulse <= 1'b1;   
        end else begin
          axi_wr_err_resp_pulse <= 1'b0;
        end
      end            
    end
 end 
 

 assign TX_AXI_ERROR_RESP = reg_TX_AXI_ERROR_RESP;
   
 
  // ***************************************************************************************************************************************************************************************
  // Read Test Address Gen Process
  //
  // This process generates an internal test contiguous Address signals and read control signals
  // It starts address and data at zero when reset occurs and then counts incrementally until it wraps
  // NB; It emulates the Simulink read address generation (basic).
  // This function is only utilised when TEST_MODE is high.
  // It is delayed by 512 address cycles to prevent the write and read from accessing the same address simultaneously. I think 
  // the HBM can handle it, but with a performance penalty. 
  // ***************************************************************************************************************************************************************************************

  
  reg [AWIDTH-1:0] reg_test_rd_address; 
  reg reg_test_rd_req;
  reg [8:0] reg_read_delay_count;
  reg reg_read_enable;
  reg [AXI_ADD_WIDTH-1:0] reg_s_axis_rx_full_add;
  
  wire [AWIDTH-1:0] zero_test_rd_add;
  
          
  //assign intialise registers
  assign zero_test_rd_add = {AWIDTH{1'b0}}; //generic test write address zeroed
  
  always @(posedge CLK) begin : rd_test_address_gen

    if (RST) begin
        //Initialise registers to zero at start up
        reg_test_rd_address <= zero_test_rd_add;
        reg_test_rd_req <= 1'b0;
        reg_read_delay_count <= 9'd0;
        reg_read_enable <= 1'b0;
        reg_s_axis_rx_full_add <= {1'b0, 5'b00000, add_zero};
         
    end else begin
        //increment read delay counter 
        reg_read_delay_count <= reg_read_delay_count + 1;
        reg_s_axis_rx_full_add <= {HBM_Memory_Bank_Sel, reg_test_rd_address[AWIDTH-1:0], 5'd0}; 
        //if read enable counter == 512 then enable read (allow time for write function to write to the 
        //memory before reading. Do not want to read and write from the same memory location. 
        if (reg_read_delay_count == 9'd511) begin
          reg_read_enable <= 1'b1;
        end  
        //Increment counter from zero that will wrap around for address provided read is ready and enabled 
        //This implements test back pressure  
        if (rd_req_rdy & reg_read_enable) begin
          //Keep address within AXI address map link0 for now 
          if (reg_s_axis_rx_full_add >= 33'd0 && reg_s_axis_rx_full_add <= 33'd268435455) begin
            reg_test_rd_address <= reg_test_rd_address + 1;
            reg_test_rd_req <= 1'b1;
          end else begin
            reg_test_rd_req <= 1'b0;  
          end
        end else begin
          reg_test_rd_req <= 1'b0;
       end 
    end
  end
  
  wire [AWIDTH-1:0] reg_fifo_rd_add;
  wire reg_fifo_rd_req;

  //mux for selecting test address or normal simulink address and control
  assign reg_fifo_rd_add = TEST_MODE ? reg_test_rd_address : RD_ADDRESS; //if TEST_MODE is high then select test address else select normal address
  assign reg_fifo_rd_req = TEST_MODE ? reg_test_rd_req : RD_REQ; //if TEST_MODE is high then select test read request else select normal read request

   
 // ***************************************************************************************************************************************************************************************
 // Read HBM Address and Data store FIFO
 // ***************************************************************************************************************************************************************************************

 //HBM read Control FIFO Signals
 reg rd_hbm_cntrl_en_read;
 //reg wr_hbm_cntrl_en_read;
 wire [31:0]rd_hbm_cntrl_add_read;
 wire wr_hbm_cntrl_full_read;
 wire rd_hbm_cntrl_empty_read;
 wire rd_hbm_cntrl_valid_read;
 wire wr_hbm_cntrl_rst_busy_read;
 wire rd_hbm_cntrl_rst_busy_read;
 wire wr_hbm_cntrl_ack_read;
 
 
 
 fifo_generator_rd_hbm_cntrl_0 fifo_generator_rd_hbm_cntrl_0_inst (
  
    .srst(RST),
    .clk(CLK),
    .din({1'b0,reg_fifo_rd_req,1'b0,1'b0,1'b0,reg_fifo_rd_add[AWIDTH-1:0]}),
    .wr_en(reg_fifo_rd_req),
    .rd_en(rd_hbm_cntrl_en_read),
    .dout(rd_hbm_cntrl_add_read),
    .full(wr_hbm_cntrl_full_read),
    .wr_ack(wr_hbm_cntrl_ack_read),
    .empty(rd_hbm_cntrl_empty_read),
    .valid(rd_hbm_cntrl_valid_read),
    .wr_rst_busy(wr_hbm_cntrl_rst_busy_read),
    .rd_rst_busy(rd_hbm_cntrl_rst_busy_read)
  );
  
 //HBM read Data FIFO Signals
 reg rd_hbm_data_en_read;
 //reg wr_hbm_data_en_read;
 wire [DWIDTH-1:0]rd_hbm_data_read;
 wire wr_hbm_data_full_read;
 wire wr_hbm_data_ack_read;
 wire rd_hbm_data_empty_read;
 wire rd_hbm_data_valid_read;
 wire wr_hbm_data_rst_busy_read;
 wire rd_hbm_data_rst_busy_read;

 
 fifo_generator_rd_hbm_data_0 fifo_generator_rd_hbm_data_0_inst (
  
    .srst(RST),
    .clk(CLK),
    .din(reg_axis_rdata),
    .wr_en(reg_fifo_dvalid),
    .rd_en(rd_hbm_data_en_read),
    .dout(rd_hbm_data_read),
    .full(wr_hbm_data_full_read),
    .wr_ack(wr_hbm_data_ack_read),
    .empty(rd_hbm_data_empty_read),
    .valid(rd_hbm_data_valid_read),
    .wr_rst_busy(wr_hbm_data_rst_busy_read),
    .rd_rst_busy(rd_hbm_data_rst_busy_read)
  );


 
 
 
   // ***************************************************************************************************************************************************************************************
  // Read State Machine: Read Data Receive
  // ***************************************************************************************************************************************************************************************
 
  reg [AXI_ADD_WIDTH-1:0] temp_reg_rd_burst_add;
  reg [AXI_ADD_WIDTH-1:0] reg_rd_burst_add; 
  reg reg_add_rd_burst_start_pulse;
    
  reg [31:0] temp_rd_hbm_cntrl_add_read;
 
  
  
 
 
  always @(posedge CLK) begin : rd_axi

  if (RST) begin
    rd_axi_state <= STATE_IDLE;
    //wait_for_time_before_bus_trans_cnt <= 16'd0;
    rd_req_rdy <= 1'b0;
    rd_req_count <= 64'd0;
    rd_hbm_data_en_read <= 1'b0;
    rd_hbm_cntrl_en_read <= 1'b0;
    temp_rd_hbm_cntrl_add_read <= 32'b0;
    reg_DATA_OUT[DWIDTH-1:0] <= data_zero;
    reg_TAG_OUT[TWIDTH-1:0] <= tag_zero;
    reg_DATA_VALID <= 1'b0;
    
    reg_rd_burst_add <= {1'b0, 5'b00000, add_zero};
    temp_reg_rd_burst_add <= {1'b0, 5'b00000, add_zero};
    reg_add_rd_burst_start_pulse <= 1'b0;
        
  end else begin
      rd_req_rdy <= 1'b1;
      case (rd_axi_state)
        // State: Entry to state machine (from reset)
        STATE_IDLE: begin
          rd_axi_state <= STATE_IDLE;
          //wr_hbm_data_en_read <= 1'b0;
          rd_hbm_data_en_read<= 1'b0;
          rd_hbm_cntrl_en_read <= 1'b0;
          //wr_hbm_cntrl_en_read <= 1'b0;
          if (INIT_DONE == 1'b1 && wr_hbm_cntrl_full_read == 1'b0 && wr_hbm_data_full_read == 1'b0) begin // We cannot issue any AXI Transactions if the HBM is not initialized!
            rd_req_rdy <= 1'b1;
            rd_axi_state <= WAIT_AXI_TX_RDY;
          end else begin
            rd_req_rdy <= 1'b0;
            rd_axi_state <= STATE_IDLE;       
          end
        end
        WAIT_AXI_TX_RDY: begin
          //enable FIFOs continually (write and read)
          //wr_hbm_data_en_read <= 1'b1;
          rd_hbm_data_en_read <= 1'b1;
          rd_hbm_cntrl_en_read <= 1'b1;
          //wr_hbm_cntrl_en_read <= 1'b1;
          if (wr_hbm_cntrl_full_read == 1'b0 && wr_hbm_data_full_read == 1'b0) begin // Make sure user RX FIFO is not FULL  
            rd_axi_state <= STATE_RD_DATA;
            rd_req_rdy <= 1'b1;
          end else begin
            rd_axi_state <= WAIT_AXI_TX_RDY; // Wait for TX AXI FIFO to become available
            rd_req_rdy <= 1'b0;            
          end
        end
        //Read Data
        STATE_RD_DATA: begin
          rd_axi_state <= STATE_RD_DATA;
          //if data is valid at the FIFO output
          if( rd_hbm_cntrl_valid_read == 1'b1) begin
             temp_rd_hbm_cntrl_add_read <= rd_hbm_cntrl_add_read; 
             //temp_rd_hbm_data_read <= rd_hbm_data_read; 
          end 
          
          //Look for address burst  change     
         reg_rd_burst_add = {HBM_Memory_Bank_Sel, 5'b00000, temp_rd_hbm_cntrl_add_read[AWIDTH-1:0] >> AXI_BURST_SIZE_LOG2};
         temp_reg_rd_burst_add <= reg_rd_burst_add;
         //If Burst Address changes then generate read AXI address start pulse 
       
         if (temp_reg_rd_burst_add != reg_rd_burst_add) begin
           reg_add_rd_burst_start_pulse <= 1'b1;
         end else begin
           reg_add_rd_burst_start_pulse <= 1'b0;
        end
       
                  
       //Read from FIFO Data if FIFO Read Data Valid is high (NB: should be high all the time, so valid should be high too)       
       if (rd_hbm_data_valid_read) begin
          reg_DATA_OUT[DWIDTH-1:0] <= rd_hbm_data_read[DWIDTH-1:0];
          reg_TAG_OUT[TWIDTH-1:0] <= {tag_diff_zero,m_axis_rx_TID[ATWIDTH-1:0]};
          reg_DATA_VALID <= 1'b1;
        end else begin
          reg_DATA_VALID <= 1'b0;
        end          
           
        //if FIFO is full, then deassert read ready signals only  
        if(wr_hbm_cntrl_full_read == 1'b0 && wr_hbm_cntrl_full_read == 1'b0) begin
           rd_req_rdy <= 1'b1;
        end else begin
           rd_req_rdy <= 1'b0;
        end
    end    
     endcase
    end    
  end


  assign RD_READY = rd_req_rdy;
  
  
 //Address read signals 
  reg reg_axis_ar_add_valid;
  reg [2:0] reg_axis_ar_add_size;
  reg [AXI_ADD_WIDTH-1:0] reg_axis_ar_add;
  reg [7:0] reg_axis_ar_add_length; 
  reg [1:0] reg_axis_ar_add_burst;
  reg [ATWIDTH-1:0] reg_axis_ar_id;
  
  
  reg reg_add_rd_burst_start_sync;
  reg  [AXI_ADD_WIDTH-1:0] reg_axis_rd_add_latch;
 

 
  // ***************************************************************************************************************************************************************************************
  // AXI address read process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_rd_add

    if (RST) begin
    
      reg_axis_ar_add_valid <= 1'b0;
      reg_axis_ar_add_size <= 3'd0;
      reg_axis_ar_add <= {1'b0, 5'b00000, add_zero};
      reg_axis_ar_add_length <=  8'b00000000; //burst length 16; 
      reg_axis_ar_add_burst <= 2'b00; //Bust Type INC;
      reg_axis_ar_id <= tag_zero_add_id;
      reg_add_rd_burst_start_sync <= 1'b0;
      reg_axis_rd_add_latch <= {1'b0, 5'b00000, add_zero};
           
    end else begin
    
      //Read address metadata
      reg_axis_ar_add_length <=  8'd15; //burst length 16 (busr size = AXLEN + 1 = 15 + 1); 
      reg_axis_ar_add_burst <= 2'b01; //Bust Type INC;
      reg_axis_ar_id <= RD_TAG_IN[ATWIDTH-1:0]; 
      reg_axis_ar_add_size <= 3'd5; //Bytes in transfer 32 bytes      
      //if burst pulse detected then begin the read address process 
      if(reg_add_rd_burst_start_pulse) begin
        reg_axis_ar_add_valid <= 1'b1; 
        reg_add_rd_burst_start_sync <= 1'b1;
        reg_axis_rd_add_latch <= {HBM_Memory_Bank_Sel, temp_rd_hbm_cntrl_add_read[AWIDTH-1:0],5'b00000};
      end
      
      //Once address read ready and address read valid are high end transaction
      if(m_axis_rx_TADD_READY & reg_axis_ar_add_valid) begin
        reg_axis_ar_add <= reg_axis_rd_add_latch;
        reg_axis_ar_add_valid <= 1'b0;
      end
    end
 end 
 
 //assign write address signals to actual AXI HBM signals
 
 assign reg_m_axis_rx_TADD_VALID = reg_axis_ar_add_valid; 
 assign reg_m_axis_rx_TADD_SIZE =  reg_axis_ar_add_size; 
 assign reg_m_axis_rx_TADD = reg_axis_ar_add; 
 assign reg_m_axis_rx_TADD_LENGTH = reg_axis_ar_add_length;
 assign reg_m_axis_rx_TADD_BURST = reg_axis_ar_add_burst;
 assign reg_m_axis_rx_TADD_ID = reg_axis_ar_id; 
 
  
 //read data signals
 reg [DWIDTH-1:0] reg_axis_rdata;
 reg reg_axis_rvalid;
 reg reg_axis_rready; 
 reg reg_axis_rvalid_latch;
 reg reg_fifo_dvalid;
 
 reg  [DWIDTH-1:0] reg_axis_rdata_latch; 
 
  // ***************************************************************************************************************************************************************************************
  // AXI Data Read process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_rd_data

    if (RST) begin
    
      reg_axis_rdata <= data_zero;
      reg_axis_rdata_latch <= data_zero;
      reg_axis_rready <= 1'b0;
      reg_axis_rvalid_latch <= 1'b0;
      reg_fifo_dvalid <= 1'b0;
           
    end else begin
      //Assert Read Ready high continually for now
      reg_axis_rready <= 1'b1;
      //if data valid from FIFO then begin write process 
      if(m_axis_rx_TVALID & reg_add_rd_burst_start_sync) begin
        //reg_axis_rready <= 1'b1;   
        reg_axis_rdata_latch <= m_axis_rx_TDATA;
        reg_axis_rvalid_latch <= 1'b1;
        //reg_axis_wstrobe <= strobe_one;
      //end else begin
        //reg_axis_rready <= 1'b0;
        //reg_axis_rvalid_latch <= 1'b0;   
      end
      
      //Once data read ready and data read valid are high end transaction
      if(reg_axis_rready & m_axis_rx_TVALID) begin
        reg_axis_rdata  <= reg_axis_rdata_latch; 
        reg_fifo_dvalid <= reg_axis_rvalid_latch;  
        reg_axis_rvalid_latch <= 1'b0;
      end
      
    end
 end 
 
 
 //assign Read Data signals to actual HBM AXI signals
 assign reg_m_axis_rx_TDATA = reg_axis_rdata;
 assign reg_m_axis_rx_TREADY = reg_axis_rready;
   
      
  // Signals used for AXI read response
  reg axi_rd_err_resp_pulse;
  reg [1:0] reg_RX_AXI_ERROR_RESP;
 
  // ***************************************************************************************************************************************************************************************
  // AXI Read response process 
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_rd_response

    if (RST) begin  
      axi_rd_err_resp_pulse <= 1'b0;           
    end else begin
      reg_RX_AXI_ERROR_RESP <= m_axis_rx_TRESP;
      //if write response ready and write response valid are asserted 
      if (m_axis_rx_TVALID && reg_axis_rready) begin
        if(reg_RX_AXI_ERROR_RESP > 0) begin
          axi_rd_err_resp_pulse <= 1'b1;   
        end else begin
          axi_rd_err_resp_pulse <= 1'b0;
        end
      end else begin
         axi_rd_err_resp_pulse <= 1'b0;
      end      
    end
 end 
 

 assign RX_AXI_ERROR_RESP = reg_RX_AXI_ERROR_RESP;
   
  
 assign AXI_ERROR_RESP_PULSE = axi_wr_err_resp_pulse || axi_rd_err_resp_pulse; //If Write or Read error occurs then pulse

endmodule
