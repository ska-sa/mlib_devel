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
    // HBM Interface Address Width
    parameter AWIDTH                = 27,
    parameter TWIDTH                = 9,
    // AXI Interface
    parameter AXI_ADD_WIDTH         = 32,
    parameter ATWIDTH               = 6


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
  reg [63:0] r_data_valid_rx_hbm_valid_count;


// Signals used in this module
  reg [3:0] wr_axi_state,rd_axi_state;
  reg [15:0] wait_for_time_before_bus_trans_cnt;
  reg [63:0] wr_req_count;
  reg [63:0] rd_req_count;
  reg wr_req_rdy;
  reg rd_req_rdy;
  reg [DWIDTH-1:0] reg_DATA_OUT;
  reg [TWIDTH-1:0] reg_TAG_OUT;
  reg reg_DATA_VALID;

  //AXI Tx registers
  reg reg_s_axis_tx_TADD_VALID;
  reg [2:0] reg_s_axis_tx_TADD_SIZE;
  reg [AXI_ADD_WIDTH-1:0] reg_s_axis_tx_TADD;
  reg [7:0] reg_s_axis_tx_TADD_LENGTH;
  reg [1:0] reg_s_axis_tx_TADD_BURST;
  reg [ATWIDTH-1:0] reg_s_axis_tx_TADD_ID;
  reg [DWIDTH-1:0] reg_s_axis_tx_TDATA;
  reg reg_s_axis_tx_TVALID;
  reg [NUM_DATA_BYTES-1:0] reg_s_axis_tx_TSTROBE;
  reg reg_s_axis_tx_TLAST;

  //AXI Rx Registers
  reg reg_m_axis_rx_TADD_VALID;
  reg [2:0] reg_m_axis_rx_TADD_SIZE;
  reg [AXI_ADD_WIDTH-1:0] reg_m_axis_rx_TADD;
  reg [7:0] reg_m_axis_rx_TADD_LENGTH;
  reg [1:0] reg_m_axis_rx_TADD_BURST;
  reg [ATWIDTH-1:0] reg_m_axis_rx_TADD_ID;
  reg reg_m_axis_rx_TREADY;

  wire [ATWIDTH-1:0] tag_zero_add_id;
  wire [TWIDTH-1:0] tag_zero;
  wire [DWIDTH-1:0] data_zero;
  wire [AWIDTH-1:0] add_zero;
  wire [NUM_DATA_BYTES-1:0] strobe_zero;
  wire [NUM_DATA_BYTES-1:0] strobe_one;
  wire [TWIDTH-ATWIDTH-1:0] tag_diff_zero;

  //assign intialise registers
  assign tag_zero_add_id = {ATWIDTH{1'b0}}; //generic tag address ID zeroed
  assign tag_zero = {TWIDTH{1'b0}}; //generic tag zeroed
  assign data_zero = {DWIDTH{1'b0}}; //generic data zeroed
  assign add_zero = {AWIDTH{1'b0}}; //Address zeroed
  assign strobe_zero = {NUM_DATA_BYTES{1'b0}}; //Strobe zeroed
  assign strobe_one = {NUM_DATA_BYTES{1'b1}}; //Strobe ones
  assign tag_diff_zero = {(TWIDTH-ATWIDTH){1'b0}}; //tag diff zero

  //assign AXI Tx
  assign s_axis_tx_TADD_VALID = reg_s_axis_tx_TADD_VALID;
  assign s_axis_tx_TADD_SIZE = reg_s_axis_tx_TADD_SIZE;
  assign s_axis_tx_TADD = reg_s_axis_tx_TADD;
  assign s_axis_tx_TADD_LENGTH = reg_s_axis_tx_TADD_LENGTH;
  assign s_axis_tx_TADD_BURST = reg_s_axis_tx_TADD_BURST;
  assign s_axis_tx_TADD_ID = reg_s_axis_tx_TADD_ID;
  assign s_axis_tx_TDATA = reg_s_axis_tx_TDATA;
  assign s_axis_tx_TVALID = reg_s_axis_tx_TVALID;
  assign s_axis_tx_TSTROBE = reg_s_axis_tx_TSTROBE;
  assign s_axis_tx_TLAST = reg_s_axis_tx_TLAST;

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


  // State machine state vector elements
  localparam STATE_IDLE         = 4'd0; // Default state: enter on power up or reset, exit on INIT_DONE == 1'b1
  localparam WAIT_AXI_TX_RDY    = 4'd1; // Wait for AXI TX bus to become available
  localparam STATE_WR_DATA      = 4'd2; // Issue write add data and transactions
  localparam STATE_WR_RESP_DATA = 4'd3; // Wait for write response data and check for errors
  localparam STATE_CHK_RD_DATA  = 4'd4; // Check for read data
  
  // ***************************************************************************************************************************************************************************************
  // Write State Machine: Write Data Transmit
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : wr_axi

  if (RST) begin
    wr_axi_state <= STATE_IDLE;
    wait_for_time_before_bus_trans_cnt <= 16'd0;
    wr_req_rdy <= 1'b0;
    wr_req_count <= 64'd0;
    //Write Address
    reg_s_axis_tx_TADD_VALID <= 1'b0; // Assert the write Address Data Valid
    reg_s_axis_tx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
    reg_s_axis_tx_TADD [AXI_ADD_WIDTH-1:0] <= {add_zero, 5'b00000};  //Assert Write Address
    reg_s_axis_tx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
    reg_s_axis_tx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
    reg_s_axis_tx_TADD_ID[ATWIDTH-1:0] <= tag_zero_add_id;
    //Write Data
    reg_s_axis_tx_TDATA[DWIDTH-1:0] <= data_zero;
    reg_s_axis_tx_TVALID <= 1'b0;
    reg_s_axis_tx_TSTROBE[NUM_DATA_BYTES-1:0] <= strobe_zero; //Write Data Strobe
    reg_s_axis_tx_TLAST <= 1'b0; //burst is one, so each transfer is the last
     
  end else begin

      case (wr_axi_state)
        // State: Entry to state machine (from reset)
        STATE_IDLE: begin
          wr_axi_state <= STATE_IDLE;
          if (INIT_DONE == 1'b1) begin // We cannot issue any AXI Transactions if the HBM is not initialized!
            wait_for_time_before_bus_trans_cnt <= wait_for_time_before_bus_trans_cnt + 1'b1; // Give some time after HBM have initialize before doing AXI transactions
          end
          if (wait_for_time_before_bus_trans_cnt[8] == 1'b1) begin
            wr_axi_state <= WAIT_AXI_TX_RDY; // OK waited long enough => time for AXI transactions
          end
        wr_req_rdy <= 1'b0;
        end
        WAIT_AXI_TX_RDY: begin
          wr_req_rdy <= 1'b0;
          wr_axi_state <= WAIT_AXI_TX_RDY; // Wait for TX AXI FIFO to become available
          if (s_axis_tx_TREADY == 1'b1) begin // Make sure AXI TX FIFO is not FULL  
            wr_axi_state <= STATE_WR_DATA;
          end
        end
        // State:Write Address Data (ignoring the subordinate write address ready signals for now. I assume it can handle the throughput with buffers and the data write ready signal should
        // be good enough
        STATE_WR_DATA: begin
          wr_axi_state <= STATE_WR_DATA;
          //if write is enabled            
          if (WR_REQ == 1'b1) begin // Write to AXI-S Tx      
            //Write Address
            reg_s_axis_tx_TADD_VALID <= 1'b1; // Assert the write Address Data Valid
            reg_s_axis_tx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
            reg_s_axis_tx_TADD [AXI_ADD_WIDTH-1:0] <= {WR_ADDRESS, 5'b000000};  //Assert Write Address
            reg_s_axis_tx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
            reg_s_axis_tx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
            reg_s_axis_tx_TADD_ID[ATWIDTH-1:0] <= WR_TAG_IN[ATWIDTH-1:0];
            //Write Data
            reg_s_axis_tx_TDATA[DWIDTH-1:0] <= DATA_IN;
            reg_s_axis_tx_TVALID <= 1'b1;
            reg_s_axis_tx_TSTROBE[NUM_DATA_BYTES-1:0] <= strobe_one; //Write Data Strobe
            reg_s_axis_tx_TLAST <= 1'b1; //burst is one, so each transfer is the last
            wr_req_count <= wr_req_count + 1'b1;
          end else begin
            //Write Address
            reg_s_axis_tx_TADD_VALID <= 1'b0; // Assert the write Address Data Valid
            reg_s_axis_tx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
            reg_s_axis_tx_TADD [AXI_ADD_WIDTH-1:0] <= {add_zero, 5'b00000};  //Assert Write Address
            reg_s_axis_tx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
            reg_s_axis_tx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
            reg_s_axis_tx_TADD_ID[ATWIDTH-1:0] <= tag_zero_add_id;
            //Write Data
            reg_s_axis_tx_TDATA[DWIDTH-1:0] <= data_zero;
            reg_s_axis_tx_TVALID <= 1'b0;
            reg_s_axis_tx_TSTROBE[NUM_DATA_BYTES-1:0] <= strobe_zero; //Write Data Strobe
            reg_s_axis_tx_TLAST <= 1'b0; //burst is one, so each transfer is the last
            wr_req_rdy <= 1'b0;      
          end
          //if AXI bus is not ready, then deassert write ready signals  
          if(s_axis_tx_TREADY == 1'b1) begin
            wr_req_rdy <= 1'b1;
          end else begin
            wr_req_rdy <= 1'b0;
          end
    end    
     endcase
    end    
  end

 
 assign WR_READY = wr_req_rdy;
 
  // ***************************************************************************************************************************************************************************************
  // Read state machine 
  // Checks incoming memory data from HBM that was requested in the Read state machine
  // ***************************************************************************************************************************************************************************************
  
    
  always @(posedge CLK) begin : rd_axi

  if (RST) begin
    // Deassert all control signals on reset
    rd_axi_state <= STATE_IDLE;     // Enter state machine in IDLE state
    reg_m_axis_rx_TREADY <= 1'b0;      // Signal to from this module to
    rd_req_rdy <= 1'b0;
    reg_m_axis_rx_TADD_VALID <= 1'b0; // Assert the read Address Data Valid
    reg_m_axis_rx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
    reg_m_axis_rx_TADD [AXI_ADD_WIDTH-1:0] <= {add_zero, 5'b00000};  //Read Address to zero
    reg_m_axis_rx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
    reg_m_axis_rx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
    reg_m_axis_rx_TADD_ID[ATWIDTH-1:0] <= tag_zero_add_id;
    reg_DATA_OUT[DWIDTH-1:0] <= data_zero;
    reg_TAG_OUT[TWIDTH-1:0] <= tag_zero;
    reg_DATA_VALID <= 1'b0;
    rd_req_count <= 64'd0;
    r_data_valid_rx_hbm_valid_count <= 64'b0;
    
  end else begin
   
            
    reg_m_axis_rx_TREADY <= 1'b1; // After reset this module is always ready
    rd_req_rdy <= 1'b1; //After reset this module in always ready
      
    if ((m_axis_rx_TVALID == 1'b1) && (INIT_DONE == 1'b1))
    begin
        r_data_valid_rx_hbm_valid_count <= r_data_valid_rx_hbm_valid_count + 1'b1;
    end 
            
    // Start state decoding
    case (rd_axi_state)
    // State: Entry to state machine (from reset)
    STATE_IDLE: begin
        rd_axi_state <= STATE_IDLE;
        if (INIT_DONE == 1'b1) begin
            rd_axi_state <= STATE_CHK_RD_DATA;
        end
    end
    STATE_CHK_RD_DATA: begin
        rd_axi_state <= STATE_CHK_RD_DATA;
        //if read is enabled
        if (RD_REQ == 1'b1) begin  // Read request        
            reg_m_axis_rx_TADD_VALID <= 1'b1; // Assert the Read Address Data Valid
            reg_m_axis_rx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
            reg_m_axis_rx_TADD [AXI_ADD_WIDTH-1:0] <= {RD_ADDRESS, 5'b00000};  //Read Address to zero
            reg_m_axis_rx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
            reg_m_axis_rx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
            reg_m_axis_rx_TADD_ID[ATWIDTH-1:0] <= RD_TAG_IN[ATWIDTH-1:0];
            //rd_req_rdy <= 1'b1;
            rd_req_count <= rd_req_count + 1'b1;
        end else begin
            //Write Address
            reg_m_axis_rx_TADD_VALID <= 1'b0; // Assert the read Address Data Valid
            reg_m_axis_rx_TADD_SIZE[2:0] <=  3'd5; //Bytes in transfer 32 bytes
            reg_m_axis_rx_TADD [AXI_ADD_WIDTH-1:0] <= {add_zero, 5'b00000};  //Read Address to zero
            reg_m_axis_rx_TADD_LENGTH[7:0] <= 8'b00000001; //burst length 1
            reg_m_axis_rx_TADD_BURST[1:0] <= 2'b01; //Bust Type INC
            reg_m_axis_rx_TADD_ID[ATWIDTH-1:0] <= tag_zero_add_id;
            //rd_req_rdy <= 1'b0;

        end
        if (m_axis_rx_TVALID == 1'b1) begin
            reg_DATA_OUT[DWIDTH-1:0] <= m_axis_rx_TDATA[DWIDTH-1:0];
            reg_TAG_OUT[TWIDTH-1:0] <= {tag_diff_zero,m_axis_rx_TID[ATWIDTH-1:0]};
            reg_DATA_VALID <= m_axis_rx_TVALID;
        end else begin
            reg_DATA_OUT[DWIDTH-1:0] <= data_zero;
            reg_TAG_OUT[TWIDTH-1:0] <= tag_zero;
            reg_DATA_VALID <= 1'b0;

        end
    end
    endcase  
   end    
  end

assign RD_READY = rd_req_rdy;
  
  
  //State machine AXI_ERROR_RESP Pulse Generate state elements
  localparam STATE_CHECK_ERROR = 3'd0; // Default state: wait for FLIT_ERROR_RESP error to occur, exit when FLIT_ERROR_RESP occurs 
  localparam STATE_ASSERT_ERROR = 3'd1; //Assert FLIT_ERROR_RESP_PULSE signal  
  localparam STATE_DEASSERT_ERROR = 3'd2; //Deassert FLIT_ERROR_RESP_PULSE and exit to STATE_CHECK_ERROR when FLIT_ERROR_RESP is low again
  
  // Signals used in this state machine
  reg [2:0] axi_wr_err_resp_pulse_gen_state;
  reg axi_wr_err_resp_pulse;
  reg [1:0] reg_TX_AXI_ERROR_RESP;
  reg reg_s_axis_tx_RESP_RDY;

  assign TX_AXI_ERROR_RESP = reg_TX_AXI_ERROR_RESP;
  assign s_axis_tx_RESP_RDY = reg_s_axis_tx_RESP_RDY;
 // ***************************************************************************************************************************************************************************************
  // AXI Error Response Write Pulse Generate State Machine: Generate a pulse every time a AXI error response occurs on write, so that the DSP functionality that stops the HBM write process 
  // when a AXI response write error occurs can restart as the single is pulsed and not active high, which causes the mechanism to hang, as the AXI write error response is only cleared when the
  // next transaction is written. This can't occur if the HBM write process is halted.
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_err_wr_resp_pulse_gen

  if (RST) begin
    axi_wr_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
    axi_wr_err_resp_pulse <= 1'b0;
    reg_s_axis_tx_RESP_RDY <= 1'b0;
    reg_TX_AXI_ERROR_RESP <= 2'b00;
   
  end else begin
      reg_s_axis_tx_RESP_RDY <= 1'b1;  //Assert Response is Ready
      case (axi_wr_err_resp_pulse_gen_state)
        // State: Entry to state machine (from reset)
        STATE_CHECK_ERROR: begin
          axi_wr_err_resp_pulse <= 1'b0;
          //Wait until an AXI error response is detected on either read and write and then exit to state that asserts error
          if (s_axis_tx_RESP_VALID == 1'b1 && ( s_axis_tx_TRESP == 2'b10 || s_axis_tx_TRESP == 2'b11)) begin
            reg_TX_AXI_ERROR_RESP <= s_axis_tx_TRESP;
            axi_wr_err_resp_pulse_gen_state <= STATE_ASSERT_ERROR; 
          //Stay in this state if no error
          end else begin
            axi_wr_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
            reg_TX_AXI_ERROR_RESP <= 2'b00;
          end
        end
        STATE_ASSERT_ERROR: begin
          //Assert the error on the FLIT error response pulse signal
          axi_wr_err_resp_pulse <= 1'b1;
          reg_TX_AXI_ERROR_RESP <= s_axis_tx_TRESP;
          axi_wr_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
        end
        STATE_DEASSERT_ERROR: begin
          axi_wr_err_resp_pulse <= 1'b0;
          //Wait in this state until an AXI error response is cleared and exit to STATE_CHECK_ERROR
          if (s_axis_tx_RESP_VALID == 1'b1 && s_axis_tx_TRESP == 2'b00 ) begin
            axi_wr_err_resp_pulse_gen_state <= STATE_CHECK_ERROR; 
            reg_TX_AXI_ERROR_RESP <= s_axis_tx_TRESP;
          //Stay in this state if AXI error response is not cleared
          end else begin
            reg_TX_AXI_ERROR_RESP <= s_axis_tx_TRESP;
            axi_wr_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
          end
        end                    
      endcase
    end    
  end
  
 // Signals used in this state machine
  reg [2:0] axi_rd_err_resp_pulse_gen_state;
  reg axi_rd_err_resp_pulse;
  reg [1:0] reg_RX_AXI_ERROR_RESP;

  assign RX_AXI_ERROR_RESP = reg_RX_AXI_ERROR_RESP;
  
// ***************************************************************************************************************************************************************************************
  // AXI Error Response Read Pulse Generate State Machine: Generate a pulse every time a AXI error response occurs on read, so that the DSP functionality that stops the HBM read process 
  // when a AXI response read error occurs can restart as the single is pulsed and not active high, which causes the mechanism to hang, as the AXI read error response is only cleared when the
  // next transaction is read. This can't occur if the HBM read process is halted.
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : axi_err_rd_resp_pulse_gen

  if (RST) begin
    axi_rd_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
    axi_rd_err_resp_pulse <= 1'b0;
    reg_RX_AXI_ERROR_RESP <= 2'b00;
 
  end else begin
      case (axi_rd_err_resp_pulse_gen_state)
        // State: Entry to state machine (from reset)
        STATE_CHECK_ERROR: begin
          axi_rd_err_resp_pulse <= 1'b0;
          //Wait until an AXI error response is detected on either read and write and then exit to state that asserts error
          if (m_axis_rx_TVALID == 1'b1 && ( m_axis_rx_TRESP == 2'b10 || m_axis_rx_TRESP == 2'b11)) begin
            axi_rd_err_resp_pulse_gen_state <= STATE_ASSERT_ERROR;
            reg_RX_AXI_ERROR_RESP <= m_axis_rx_TRESP;
          //Stay in this state if no error
          end else begin
            reg_RX_AXI_ERROR_RESP <= m_axis_rx_TRESP;
            axi_rd_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
          end
        end
        STATE_ASSERT_ERROR: begin
          //Assert the error on the AXI error response pulse signal
          axi_rd_err_resp_pulse <= 1'b1;
          axi_rd_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
        end
        STATE_DEASSERT_ERROR: begin
          axi_rd_err_resp_pulse <= 1'b0;
          //Wait in this state until an AXI error response is cleared and exit to STATE_CHECK_ERROR
          if (m_axis_rx_TVALID == 1'b1 && m_axis_rx_TRESP == 2'b00 ) begin
            axi_rd_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
            reg_RX_AXI_ERROR_RESP <= m_axis_rx_TRESP;
          //Stay in this state if AXI error response is not cleared
          end else begin
            reg_RX_AXI_ERROR_RESP <= m_axis_rx_TRESP;
            axi_rd_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
          end
        end                    
      endcase
    end    
  end
   
  
  assign AXI_ERROR_RESP_PULSE = axi_wr_err_resp_pulse || axi_rd_err_resp_pulse; //If Write or Read error occurs then pulse

endmodule
