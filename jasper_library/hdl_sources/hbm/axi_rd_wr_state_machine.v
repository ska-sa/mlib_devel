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
    parameter TWIDTH                = 6,
    // AXI Interface 
    parameter AXI_ADD_WIDTH         = 32

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
    output  wire [2:0]                   s_axis_tx_TADD_SIZE,  //write address size   
    input   wire                         s_axis_tx_TADD_READY, //Write address Ready
    output  wire [7:0]                   s_axis_tx_TADD_LENGTH, //write address Length
    output  wire [1:0]                   s_axis_tx_TADD_BURST, //write addresss Burst     
    output  wire [TWIDTH-1:0]            s_axis_tx_TADD_ID, //Write address ID
    input   wire [TWIDTH-1:0]            s_axis_tx_TRESP_ID, //Write Response ID
    input   wire [1:0]                   s_axis_tx_TRESP, //Write Data Response
    input   wire                         s_axis_tx_RESP_VALID, //Write response valid
    output  wire                         s_axis_tx_RESP_RDY, //Write Response Ready   
    output  wire                         s_axis_tx_TLAST, //Write Data Last
    output  wire [NUM_DATA_BYTES-1:0]    s_axis_tx_TSTROBE, //Write Data Byte Strobe
    //From HMC Ctrl RX to AXI
    input   wire                         m_axis_rx_TVALID, //Read Data Valid
    output  wire                         m_axis_rx_TREADY, //Read Data Ready
    input   wire [DWIDTH-1:0]            m_axis_rx_TDATA, //Read Data
    output  wire [AXI_ADD_WIDTH-1:0]     m_axis_rx_TADD, //Read Data Address
    input   wire [TWIDTH-1:0]            m_axis_rx_TID, //Read Data ID
    output  wire [1:0]                   m_axis_rx_TADD_BURST, //read addresss Burst
    output  wire [2:0]                   m_axis_rx_TADD_SIZE,  //Read address size
    input   wire                         m_axis_rx_TADD_READY, //Read address Ready
    output  wire [7:0]                   m_axis_rx_TADD_LENGTH, //Read address Length
    output  wire [TWIDTH-1:0]            m_axis_rx_TADD_ID, //Read Address ID
    output  wire                         m_axis_rx_TADD_VALID, //Read Address valid
    input   wire [1:0]                   m_axis_rx_TRESP, //Read Data Response
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
    input  wire [TWIDTH-1:0] TAG_IN,   
    output wire [TWIDTH-1:0] TAG_OUT,
    output wire DATA_VALID,
    output wire RD_READY,
    output wire AXI_ERROR_RESP_PULSE,
    output wire [1:0] TX_AXI_ERROR_RESP,
    output wire [1:0] RX_AXI_ERROR_RESP
    
    
  );
  
  
  //Debug HBM Registers
  
  //assign dbg_wr_req_count = wr_req_count;
  //assign dbg_rd_req_count = rd_req_count;
  
  //assign dbg_flit_err_resp_pulse_gen_state = flit_err_resp_pulse_gen_state;
  //assign dbg_flit_err_resp_pulse = flit_err_resp_pulse;
    


// Signals used in this module
  reg [3:0] wr_axi_state,rd_axi_state;
  reg s_axis_tx_TVALID_i;
  reg [DWIDTH-1:0]  s_axis_tx_TDATA_i;
  reg [NUM_DATA_BYTES-1:0] s_axis_tx_TUSER_i;
  reg m_axis_rx_TREADY_i;
  wire m_axis_rx_TREADY_i;
  reg [8:0] tag;
  reg [15:0] wait_for_NULL_FLITS_to_complete_cnt;
  reg next_flit_case3_second;
  reg next_flit_case3_third;
  reg next_flit_case4_second;
  reg next_flit_case4_third;
  reg tx_data_hold;
  reg [63:0] wr_req_count;
  reg [63:0] rd_req_count;
  reg req_rdy;
  

  // Assign external status ports
  assign s_axis_tx_TVALID = s_axis_tx_TVALID_i; //& s_axis_tx_TREADY;
  assign s_axis_tx_TDATA = s_axis_tx_TDATA_i;
  assign m_axis_rx_TREADY = m_axis_rx_TREADY_i;//m_axis_rx_TREADY_i;


  // State machine state vector elements
  localparam STATE_IDLE         = 4'd0; // Default state: enter on power up or reset, exit on INIT_DONE == 1'b1
  localparam WAIT_AXI_TX_RDY    = 4'd1; // Wait for AXI TX bus to become available
  localparam STATE_WR_DATA      = 4'd2; // Issue write data [255:0] transactions
  localparam STATE_CHK_RD_DATA  = 4'd3; // Wait for RX AXI bus to present valid return data and then check it for errors
  
  // ***************************************************************************************************************************************************************************************
  // Write State Machine: Issue write or 256bit Data Transmit
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : wr_axi

  if (RST) begin
    wr_axi_state <= STATE_IDLE;
    //addr <= 27'd0; // request addr {2'b00,addr,4b000} [33:32] reserved = "00", 16byte addr, [3:0] reserved 0 (min 16 byte transactions) 
    s_axis_tx_TDATA_i  <= DWIDTH'd0;
    s_axis_tx_TVALID_i <= 1'b0; // Deassert all control logic until the HMC is properly initialized
    s_axis_tx_TUSER_i  <= {NUM_DATA_BYTES{1'b0}};
    tag <= TWIDTH'd1; // Tag is used to deal with out of order return sequences 
    wait_for_NULL_FLITS_to_complete_cnt <= 16'd0;
    req_rdy <= 1'b0;
    tx_data_hold <= 1'b0;
    wr_req_count <= 64'd0;
    rd_req_count <= 64'd0;
    
  end else begin
      s_axis_tx_TVALID_i <= 1'b0;
      s_axis_tx_TUSER_i  <= {NUM_DATA_BYTES{1'b0}};
      s_axis_tx_TDATA_i  <= DWIDTH'd0;

      case (wr_axi_state)
        // State: Entry to state machine (from reset)
        STATE_IDLE: begin
          wr_axi_state <= STATE_IDLE;
          if (POST_DONE == 1'b1) begin // We cannot issue any FLITs if the HMC and the openHMC is not initialized!
            wait_for_NULL_FLITS_to_complete_cnt <= wait_for_NULL_FLITS_to_complete_cnt + 1'b1; // Give some time after the openHMC and HMC have initialize before bomming it with FLITs
          end
          if (wait_for_NULL_FLITS_to_complete_cnt[8] == 1'b1) begin
            wr_axi_state <= WAIT_AXI_TX_RDY; // OK waited long enough => bom it with FLITs
          end
        req_rdy <= 1'b0;
        end
        WAIT_AXI_TX_RDY: begin
          req_rdy <= 1'b0;
          wr_axi_state <= WAIT_AXI_TX_RDY; // Wait for TX AXI FIFO to become available
          if (s_axis_tx_TREADY == 1'b1) begin // Make sure AXI TX FIFO is not FULL  
            wr_axi_state <= STATE_WR_DATA;
          end
        end
        // State: Request WR128 header, followed by write data (WR_REQ_DATA[447:0])
        STATE_WR_DATA: begin
           
          
          wr_axi_state <= STATE_WR_DATA;
          //if write is enabled            
          if (WR_REQ == 1'b1) begin // Write request uses FLITs 2..0       
            //s_axis_tx_TVALID_i <= 1'b1; // Issue a write to TX AXI FIFO                
            s_axis_tx_TDATA_i[383:0]  <= {64'd0, DATA_IN, {3'd0,3'd0,{2'd0,WR_ADDRESS,5'd0},tag, 4'd3, 4'd3, 1'b0, 6'b011001}}; // posted write req 32 bytes
            s_axis_tx_TUSER_i[2:0]  <= 3'b111; // all FLITS 2-0 valid  - Write Req 
            s_axis_tx_TUSER_i[6:4]  <= 3'b001; // Header on FLIT0 - Write Req  
            s_axis_tx_TUSER_i[10:8]  <= 3'b100; // Tail on FLIT2 - Write Req 
            wr_req_count <= wr_req_count + 1'b1;
          end
          //if read is enabled
          if (RD_REQ == 1'b1) begin  // Read request uses FLIT 3        
            //s_axis_tx_TVALID_i <= 1'b1; // Issue a write to TX AXI FIFO, with a READ32 command request ie (read 32bytes / 256bits from requested address)
            s_axis_tx_TDATA_i[511:384]  <= {64'd0, {3'd0,3'd0,{2'd0,RD_ADDRESS,5'd0},TAG_IN, 4'd1, 4'd1, 1'b0, 6'b110001}}; // red req 32 bytes
            s_axis_tx_TUSER_i[3]  <= 1'b1; // Valid on FLIT3 - Read Req   
            s_axis_tx_TUSER_i[7]  <= 1'b1; // Header on FLIT3 - Read Req
            s_axis_tx_TUSER_i[11]  <= 1'b1; // Tail on FLIT3 - Read Req  
            rd_req_count <= rd_req_count + 1'b1;
          end
          //if read or write is enabled
          if (WR_REQ == 1'b1 || RD_REQ == 1'b1) begin
            s_axis_tx_TVALID_i <= 1'b1; // Issue a write to TX AXI FIFO
          end else begin
            s_axis_tx_TVALID_i <= 1'b0; // Disable a write to TX AXI FIFO
            s_axis_tx_TUSER_i  <= {NUM_DATA_BYTES{1'b0}};
            s_axis_tx_TDATA_i  <= DWIDTH'd0;
            req_rdy <= 1'b0;      
          end
          //if AXI bus is not ready, then deassert write and read ready signals  
          if(s_axis_tx_TREADY == 1'b1) begin
            req_rdy <= 1'b1;
          end else begin
            req_rdy <= 1'b0;
          end
    end    
      endcase
    end    
  end

  //assign WR_READY = (req_rdy == 1'b1) ? s_axis_tx_TREADY : 1'b0;
  //assign RD_READY = (req_rdy == 1'b1) ? s_axis_tx_TREADY : 1'b0;
 
 assign WR_READY = req_rdy;
 assign RD_READY = req_rdy;

  // ***************************************************************************************************************************************************************************************
  // Read state machine 
  // Checks incomming memory data from HBM that was requested in the Read/Write state machine
  // ***************************************************************************************************************************************************************************************
  reg [8:0] rd_tag,rd_tag_i, rd_tag_hold;
  reg [255:0] rd_data, rd_data_i, rd_data_hold;
  reg [63:0] rd_tail, rd_tail_hold;
  
  reg rd_data_val, rd_data_val_hold;
  reg [63:0] r_data_valid_rx_valid_count;
  reg [63:0] r_data_valid_rx_hmc_valid_count;
  
  reg [63:0] r_flit_case1_first_count;
  reg [63:0] r_flit_case2_first_count;
  reg [63:0] r_flit_case3_first_count;
  reg [63:0] r_flit_case4_first_count;
  reg [63:0] r_flit_case3_second_count;
  reg [63:0] r_flit_case4_second_count;
  reg [63:0] r_flit_case3_second_spec_count;
  reg [3:0] r_flit_error_rsp;
  
  wire [DWIDTH-1:0] m_axis_rx_TDATA_R;
  wire [15:0] m_axis_rx_TUSER_R;
  wire m_axis_rx_TVALID_R;
  
  wire hmc_fifo_overflow;
  wire hmc_fifo_underflow;
  
  //assign data_valid_rx_valid_count = r_data_valid_rx_valid_count;
  //assign data_valid_rx_hmc_valid_count = r_data_valid_rx_hmc_valid_count;
  //This flag represents the FLIT error response. If any of the FLITS has an error in the response packet (e.g. CRC error) then
  //this value will be non-zero
  assign FLIT_ERROR_RESP = r_flit_error_rsp;  
  
  //assign dbg_flit_case1_first_count = r_flit_case1_first_count;
 
    
  always @(posedge CLK) begin : rd_axi

  if (RST) begin
    // Deassert all control signals on reset
    rd_axi_state <= STATE_IDLE;     // Enter state machine in IDLE state
    m_axis_rx_TREADY_i <= 1'b0;      // Signal to from this module to 

    // For 128byte Requests we need 9 FLITs, this will require 3 AXI (4 FLITs per access) accesses (ie 3 clock cycles)

    next_flit_case3_second <= 1'b0;  // AXI access 2 of 3    
    next_flit_case3_third <= 1'b0;   // AXI access 3 of 3    
    next_flit_case4_second <= 1'b0;  // AXI access 2 of 3    
    next_flit_case4_third <= 1'b0;   // AXI access 3 of 3    

    rd_data_val <= 1'b0;
    rd_data_val_hold <= 1'b0;  // in the case were 2 valid responses falls on the same AXI transaction
    rd_data <= 256'd0;
    rd_tag <= 9'd0;
    rd_tail_hold <= 64'd0;
    rd_tail <= 64'd0;
       
    r_data_valid_rx_valid_count <= 64'b0;
    r_data_valid_rx_hmc_valid_count <= 64'b0;
    r_flit_case1_first_count <= 64'b0;
    r_flit_case2_first_count <= 64'b0;
    r_flit_case3_first_count <= 64'b0;
    r_flit_case4_first_count <= 64'b0;
    r_flit_case3_second_count <= 64'b0;
    r_flit_case4_second_count <= 64'b0;
    r_flit_case3_second_spec_count <= 64'b0;
    r_flit_error_rsp <= 4'b0;
    
  end else begin
            
      m_axis_rx_TREADY_i <= 1'b1; // After reset this module is always ready
      rd_data_val <= 1'b0;
      rd_data_val_hold <= 1'b0;
      
      if ((rd_data_val == 1'b1) && (POST_DONE == 1'b1))
      begin
         r_data_valid_rx_hmc_valid_count <= r_data_valid_rx_hmc_valid_count + 1'b1;
      end 
      if ((m_axis_rx_TVALID_R == 1'b1) && (POST_DONE == 1'b1))
      begin
          r_data_valid_rx_valid_count <= r_data_valid_rx_valid_count + 1'b1;
          r_flit_error_rsp [3:0] <= m_axis_rx_TUSER_R[15:12];          
      end
            
      // in the case were 2 valid responses falls on the same AXI transaction on the previous cycle, this module asserted m_axis_rx_TREADY_i <= 1'b0 (not ready - hold off for one cycle)
      // Now generate data valid from 2nd transaction data
      //if (rd_data_val_hold == 1'b1) begin
      if (rd_data_val_hold == 1'b1) begin     
        rd_tag <= rd_tag_hold;      
        rd_data <= rd_data_hold;
        rd_tail <= rd_tail_hold;        
        rd_data_val <= rd_data_val_hold;
        
      // do not decode next axi cycle, as it was put on hold  
      end else begin     
         
          // Start state decoding
          case (rd_axi_state)
            // State: Entry to state machine (from reset)
            STATE_IDLE: begin
              rd_axi_state <= STATE_IDLE;
              if (POST_DONE == 1'b1) begin
                rd_axi_state <= STATE_CHK_RD_DATA;
              end
            end
            // State: Decode AXI bus and figure out what is data, overheads or NULL FLITs
            //        If there is HMC memory data returned, check this data with the data written to HMC memory in the write state machine 
            STATE_CHK_RD_DATA: begin
              rd_axi_state <= STATE_CHK_RD_DATA; 
    
              // 4 FLITs per AXI Access [511:0]:
              //   FLIT0 axis bus [127:0]
              //   FLIT1 axis bus [255:128]
              //   FLIT2 axis bus [383:256]
              //   FLIT3 axis bus [511:384]
    
    
              // ****************** First time around FLITs ******************
              // CASE 1 Start
              // Valid FLITSs 2,1,0
              // This case follows the same sequence as the RD32 request issued by the write state machine
              // The read data returned will be in the same sequence
              // The RD32 tag that is returned in the FLIT header(m_axis_rx_TDATA[23:15])
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[10:8] == 3'b100 && m_axis_rx_TUSER_R[6:4] == 3'b001 && m_axis_rx_TUSER_R[2:0] == 3'b111) begin
                rd_tag <= m_axis_rx_TDATA_R[23:15];
                rd_data [255:0] <= m_axis_rx_TDATA_R[255+64:64];
                rd_tail [63:0] <= m_axis_rx_TDATA_R[255+64+64:255+64+1];
                rd_data_val <= 1'b1;
                r_flit_case1_first_count <= r_flit_case1_first_count + 1'b1;
              end 
    
              // ****************** First time around FLITs ******************
              // CASE 2 Start
              // Valid FLITSs 3,2,1
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11:9] == 3'b100 && m_axis_rx_TUSER_R[7:5] == 3'b001 && m_axis_rx_TUSER_R[3:1] == 3'b111) begin
                rd_tag <= m_axis_rx_TDATA_R[23+128:15+128];
                rd_data [255:0] <= m_axis_rx_TDATA_R[255+64+128:64+128];
                rd_tail [63:0] <= m_axis_rx_TDATA_R[255+64+128+64:255+64+128+1];
                rd_data_val <= 1'b1;
                r_flit_case2_first_count <= r_flit_case2_first_count + 1'b1;
              end 
    
              // ****************** First time around FLITs ******************
              // CASE 3 Start
              // Valid FLITSs 3,2
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11:10] == 2'b00 && m_axis_rx_TUSER_R[7:6] == 2'b01 && m_axis_rx_TUSER_R[3:2] == 2'b11) begin
                rd_tag_i <= m_axis_rx_TDATA_R[23+256:15+256];
                rd_data_i[191:0] <= m_axis_rx_TDATA_R[191+64+256:64+256];
                //No tail
                rd_tail [63:0] <= 64'd0;
                next_flit_case3_second <= 1'b1;  // AXI access 2 of 2 
                r_flit_case3_first_count <= r_flit_case3_first_count + 1'b1;
              end 
    
              // ****************** First time around FLITs ******************
              // CASE 4 Start
              // Valid FLITSs 3
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11] == 1'b0 && m_axis_rx_TUSER_R[7] == 1'b1 && m_axis_rx_TUSER_R[3] == 1'b1) begin
                rd_tag_i <= m_axis_rx_TDATA_R[23+384:15+384];
                rd_data_i[63:0] <= m_axis_rx_TDATA_R[63+64+384:64+384];
                //No tail
                rd_tail [63:0] <= 64'd0;
                next_flit_case4_second <= 1'b1;  // AXI access 2 of 2 
                r_flit_case4_first_count <= r_flit_case4_first_count + 1'b1;
              end 
    
    
              // ****************** Second time around FLITs ******************
              // CASE 3 cont...
              // Valid FLITSs 0
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[8] == 1'b1 && m_axis_rx_TUSER_R[4] == 1'b0 && m_axis_rx_TUSER_R[0] == 1'b1 && next_flit_case3_second == 1'b1) begin
                rd_data [255:192] <= m_axis_rx_TDATA_R[63:0];
                rd_data [191:0] <= rd_data_i[191:0];
                rd_tail [63:0] <= m_axis_rx_TDATA_R[64+63:63+1];
                rd_tag <= rd_tag_i;
                rd_data_val <= 1'b1;
                next_flit_case3_second <= 1'b0;
                r_flit_case3_second_count <= r_flit_case3_second_count + 1'b1;
              //do not clear if there are still case 3 responses coming on FLIT 2,3!
                if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11:10] == 2'b00 && m_axis_rx_TUSER_R[7:6] == 2'b01 && m_axis_rx_TUSER_R[3:2] == 2'b11) begin
                  next_flit_case3_second <= 1'b1;
                end 
                
              end
              
              // Special CASE 3 cont... There can also be 3 valid FLITS in this same cycle, producing a second valid! 
              // Valid FLITSs 0
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11:8] == 4'b1001 && m_axis_rx_TUSER_R[7:4] == 4'b0010 && m_axis_rx_TUSER_R[3:0] == 4'b1111 && next_flit_case3_second == 1'b1) begin
                rd_data [255:192] <= m_axis_rx_TDATA_R[63:0];
                rd_tail [63:0] <= m_axis_rx_TDATA_R[64+63:63+1];
                rd_data [191:0] <= rd_data_i[191:0];
                rd_tag <= rd_tag_i;
                rd_data_val <= 1'b1;
                next_flit_case3_second <= 1'b0;
                m_axis_rx_TREADY_i <= 1'b0; // have to deal with 2 valids -> inform AXI to standby, so that next cycle does not produce data to deal with!
                // valid data from case 2
                rd_tag_hold <= m_axis_rx_TDATA_R[23+128:15+128];
                rd_data_hold [255:0] <= m_axis_rx_TDATA_R[255+64+128:64+128];
                rd_tail_hold [63:0] <= m_axis_rx_TDATA_R[255+64+128+64:255+64+128+1];
                rd_data_val_hold <= 1'b1;
                r_flit_case3_second_spec_count <= r_flit_case3_second_spec_count + 1'b1;
              end          
    
              // CASE 4 cont...
              // Valid FLITSs 1,0
              if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[9:8] == 2'b10 && m_axis_rx_TUSER_R[5:4] == 4'b00 && m_axis_rx_TUSER_R[1:0] == 4'b11 && next_flit_case4_second == 1'b1) begin
                rd_data [255:64] <= m_axis_rx_TDATA_R[191:0];
                rd_data [63:0] <= rd_data_i[63:0];
                rd_tail [63:0] <= m_axis_rx_TDATA_R[191+64:192];
                rd_tag <= rd_tag_i;
                rd_data_val <= 1'b1;
                next_flit_case4_second <= 1'b0;
                //do not clear if there are still case 4 responses coming on FLIT 3!
                if (m_axis_rx_TVALID_R == 1'b1 && m_axis_rx_TUSER_R[11] == 1'b0 && m_axis_rx_TUSER_R[7] == 1'b1 && m_axis_rx_TUSER_R[3] == 1'b1) begin
                  next_flit_case4_second <= 1'b1;
                end                
                r_flit_case4_second_count <= r_flit_case4_second_count + 1'b1;
              end
              
            end
          endcase
       end  
    end    
  end

  //State machine AXI_ERROR_RESP Pulse Generate state elements
  localparam STATE_CHECK_ERROR = 3'd0; // Default state: wait for FLIT_ERROR_RESP error to occur, exit when FLIT_ERROR_RESP occurs 
  localparam STATE_ASSERT_ERROR = 3'd1; //Assert FLIT_ERROR_RESP_PULSE signal  
  localparam STATE_DEASSERT_ERROR = 3'd2; //Deassert FLIT_ERROR_RESP_PULSE and exit to STATE_CHECK_ERROR when FLIT_ERROR_RESP is low again
  
  // Signals used in this state machine
  reg [2:0] flit_err_resp_pulse_gen_state;
  reg flit_err_resp_pulse;
  
 // ***************************************************************************************************************************************************************************************
  // FLIT Error Response Pulse Generate State Machine: Generate a pulse every time a FLIT error response occurs, so that the DSP functionality that stops the HMC write/read process when 
  // a FLIT response error occurs can restart as the single is pulsed and not active high, which causes the mechanism to hang, as the FLIT error response is only cleared when the next
  // transaction is read. This can't occur if the HMC read/write process is halted.
  // ***************************************************************************************************************************************************************************************
  always @(posedge CLK) begin : flit_err_resp_pulse_gen

  if (RST) begin
    flit_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
    flit_err_resp_pulse <= 1'b0;
   
  end else begin

      case (flit_err_resp_pulse_gen_state)
        // State: Entry to state machine (from reset)
        STATE_CHECK_ERROR: begin
          flit_err_resp_pulse <= 1'b0;
          //Wait until a FLIT error response is detected in the Receiver and then exit to state that asserts error
          if (r_flit_error_rsp[0] == 1'b1 || r_flit_error_rsp[1] == 1'b1 || r_flit_error_rsp[2] == 1'b1 || r_flit_error_rsp[3] == 1'b1 ) begin
            flit_err_resp_pulse_gen_state <= STATE_ASSERT_ERROR; 
          //Stay in this state if no error
          end else begin
            flit_err_resp_pulse_gen_state <= STATE_CHECK_ERROR;
          end
        end
        STATE_ASSERT_ERROR: begin
          //Assert the error on the FLIT error response pulse signal
          flit_err_resp_pulse <= 1'b1;
          flit_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
        end
        STATE_DEASSERT_ERROR: begin
          flit_err_resp_pulse <= 1'b0;
          //Wait in this state until a FLIT error response is cleared and exit to STATE_CHECK_ERROR
          if (r_flit_error_rsp[0] == 1'b0 && r_flit_error_rsp[1] == 1'b0 && r_flit_error_rsp[2] == 1'b0 && r_flit_error_rsp[3] == 1'b0 ) begin
            flit_err_resp_pulse_gen_state <= STATE_CHECK_ERROR; 
          //Stay in this state if FLIT error response is not cleared
          end else begin
            flit_err_resp_pulse_gen_state <= STATE_DEASSERT_ERROR;
          end
        end                    
      endcase
    end    
  end
  

  assign TAG_OUT = rd_tag;
  assign DATA_VALID = rd_data_val;
  assign DATA_OUT = rd_data;
  assign FLIT_TAIL_ERRSTAT = rd_tail[26:20]; //Assign ERRSTAT register of FLIT tail
  assign FLIT_ERROR_RESP_PULSE = flit_err_resp_pulse;

endmodule
