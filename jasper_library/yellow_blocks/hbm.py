import logging
from .yellow_block import YellowBlock
from constraints import PortConstraint, ClockConstraint, ClockGroupConstraint, MultiCycleConstraint, \
    OutputDelayConstraint, RawConstraint

from itertools import count

class hbm(YellowBlock): # class hmc inherits from yellowblock.py
    #@staticmethod
    #def factory(blk, plat, hdl_root=None):
    #    return hmc_xilinx_v7(blk, plat , hdl_root)

    def instantiate_hbm(self, top, num=None):
        
        hbm = top.get_instance(name=self.fullname, entity='hbm_custom_to_axis_if')

        hbm.add_port('USER_CLK', 'user_clk', dir='in')
        hbm.add_port('USER_RST', 'user_rst', dir='in')
        hbm.add_port('HBM_OK', '%s_hbm_ok' % self.fullname, dir='out')



        # If HBM Memory Bank 0 selected then connect yellow block to AXI 3 to AXI 0 ports
        if self.mem_bank == 0:
            #Generics
            hbm.add_parameter('DWIDTH', "256")
            hbm.add_parameter('NUM_DATA_BYTES', "32")
            hbm.add_parameter('AWIDTH', "27")
            hbm.add_parameter('TWIDTH', "9")
            hbm.add_parameter('HBM_ADD_BANK_SEL', "0")
            hbm.add_parameter('AXI_ADD_WIDTH', "33")
            hbm.add_parameter('AXI_BURST_SIZE', "1")
            hbm.add_parameter('ATWIDTH', "6")
            hbm.add_parameter('TEST_MODE', "1")


            # AXI Interface Ports 0
            hbm.add_port('m_axis_rx_TADD_Link0', 's_axi_0_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link0', 's_axi_0_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link0', 's_axi_0_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link0', 's_axi_0_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link0', 's_axi_0_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link0', 's_axi_0_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link0', 's_axi_0_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link0', 's_axi_0_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link0', 's_axi_0_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link0', 's_axi_0_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link0', 's_axi_0_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link0', 's_axi_0_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link0', 's_axi_0_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link0', 's_axi_0_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link0', 's_axi_0_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link0', 's_axi_0_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link0', 's_axi_0_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link0', 's_axi_0_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link0', 's_axi_0_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link0', 's_axi_0_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link0', 's_axi_0_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link0', 's_axi_0_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link0', 's_axi_0_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link0', 's_axi_0_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link0', 's_axi_0_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link0', 's_axi_0_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link0', 's_axi_0_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link0', 's_axi_0_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link0', 's_axi_0_rlast',  dir='in', width=1)

            # AXI Interface Ports 1

            hbm.add_port('m_axis_rx_TADD_Link1', 's_axi_1_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link1', 's_axi_1_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link1', 's_axi_1_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link1', 's_axi_1_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link1', 's_axi_1_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link1', 's_axi_1_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link1', 's_axi_1_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link1', 's_axi_1_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link1', 's_axi_1_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link1', 's_axi_1_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link1', 's_axi_1_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link1', 's_axi_1_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link1', 's_axi_1_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link1', 's_axi_1_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link1', 's_axi_1_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link1', 's_axi_1_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link1', 's_axi_1_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link1', 's_axi_1_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link1', 's_axi_1_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link1', 's_axi_1_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link1', 's_axi_1_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link1', 's_axi_1_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link1', 's_axi_1_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link1', 's_axi_1_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link1', 's_axi_1_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link1', 's_axi_1_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link1', 's_axi_1_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link1', 's_axi_1_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link1', 's_axi_1_rlast',  dir='in', width=1)

            # AXI Interface Ports 2

            hbm.add_port('m_axis_rx_TADD_Link2', 's_axi_2_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link2', 's_axi_2_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link2', 's_axi_2_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link2', 's_axi_2_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link2', 's_axi_2_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link2', 's_axi_2_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link2', 's_axi_2_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link2', 's_axi_2_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link2', 's_axi_2_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link2', 's_axi_2_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link2', 's_axi_2_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link2', 's_axi_2_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link2', 's_axi_2_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link2', 's_axi_2_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link2', 's_axi_2_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link2', 's_axi_2_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link2', 's_axi_2_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link2', 's_axi_2_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link2', 's_axi_2_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link2', 's_axi_2_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link2', 's_axi_2_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link2', 's_axi_2_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link2', 's_axi_2_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link2', 's_axi_2_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link2', 's_axi_2_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link2', 's_axi_2_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link2', 's_axi_2_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link2', 's_axi_2_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link2', 's_axi_2_rlast',  dir='in', width=1)

            # AXI Interface Ports 3

            hbm.add_port('m_axis_rx_TADD_Link3', 's_axi_3_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link3', 's_axi_3_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link3', 's_axi_3_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link3', 's_axi_3_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link3', 's_axi_3_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link3', 's_axi_3_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link3', 's_axi_3_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link3', 's_axi_3_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link3', 's_axi_3_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link3', 's_axi_3_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link3', 's_axi_3_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link3', 's_axi_3_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link3', 's_axi_3_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link3', 's_axi_3_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link3', 's_axi_3_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link3', 's_axi_3_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link3', 's_axi_3_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link3', 's_axi_3_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link3', 's_axi_3_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link3', 's_axi_3_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link3', 's_axi_3_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link3', 's_axi_3_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link3', 's_axi_3_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link3', 's_axi_3_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link3', 's_axi_3_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link3', 's_axi_3_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link3', 's_axi_3_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link3', 's_axi_3_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link3', 's_axi_3_rlast',  dir='in', width=1)

            #INIT_DONE from Memory Bank 0
            hbm.add_port('INIT_DONE', 'apb_complete_0_0_0', dir='in', width=1)

        # If HBM Memory Bank 1 selected then connect yellow block to AXI 7 to AXI 4 ports
        elif self.mem_bank == 1:

            #Generics
            hbm.add_parameter('DWIDTH', "256")
            hbm.add_parameter('NUM_DATA_BYTES', "32")
            hbm.add_parameter('AWIDTH', "27")
            hbm.add_parameter('TWIDTH', "9")
            hbm.add_parameter('HBM_ADD_BANK_SEL', "1")
            hbm.add_parameter('AXI_ADD_WIDTH', "33")
            hbm.add_parameter('AXI_BURST_SIZE', "1")
            hbm.add_parameter('ATWIDTH', "6")

            # AXI Interface Ports 4
            hbm.add_port('m_axis_rx_TADD_Link0', 's_axi_4_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link0', 's_axi_4_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link0', 's_axi_4_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link0', 's_axi_4_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link0', 's_axi_4_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link0', 's_axi_4_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link0', 's_axi_4_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link0', 's_axi_4_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link0', 's_axi_4_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link0', 's_axi_4_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link0', 's_axi_4_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link0', 's_axi_4_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link0', 's_axi_4_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link0', 's_axi_4_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link0', 's_axi_4_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link0', 's_axi_4_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link0', 's_axi_4_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link0', 's_axi_4_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link0', 's_axi_4_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link0', 's_axi_4_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link0', 's_axi_4_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link0', 's_axi_4_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link0', 's_axi_4_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link0', 's_axi_4_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link0', 's_axi_4_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link0', 's_axi_4_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link0', 's_axi_4_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link0', 's_axi_4_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link0', 's_axi_4_rlast',  dir='in', width=1)

            # AXI Interface Ports 5

            hbm.add_port('m_axis_rx_TADD_Link1', 's_axi_5_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link1', 's_axi_5_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link1', 's_axi_5_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link1', 's_axi_5_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link1', 's_axi_5_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link1', 's_axi_5_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link1', 's_axi_5_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link1', 's_axi_5_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link1', 's_axi_5_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link1', 's_axi_5_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link1', 's_axi_5_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link1', 's_axi_5_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link1', 's_axi_5_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link1', 's_axi_5_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link1', 's_axi_5_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link1', 's_axi_5_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link1', 's_axi_5_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link1', 's_axi_5_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link1', 's_axi_5_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link1', 's_axi_5_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link1', 's_axi_5_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link1', 's_axi_5_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link1', 's_axi_5_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link1', 's_axi_5_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link1', 's_axi_5_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link1', 's_axi_5_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link1', 's_axi_5_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link1', 's_axi_5_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link1', 's_axi_5_rlast',  dir='in', width=1)

            # AXI Interface Ports 6

            hbm.add_port('m_axis_rx_TADD_Link2', 's_axi_6_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link2', 's_axi_6_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link2', 's_axi_6_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link2', 's_axi_6_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link2', 's_axi_6_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link2', 's_axi_6_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link2', 's_axi_6_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link2', 's_axi_6_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link2', 's_axi_6_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link2', 's_axi_6_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link2', 's_axi_6_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link2', 's_axi_6_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link2', 's_axi_6_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link2', 's_axi_6_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link2', 's_axi_6_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link2', 's_axi_6_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link2', 's_axi_6_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link2', 's_axi_6_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link2', 's_axi_6_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link2', 's_axi_6_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link2', 's_axi_6_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link2', 's_axi_6_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link2', 's_axi_6_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link2', 's_axi_6_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link2', 's_axi_6_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link2', 's_axi_6_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link2', 's_axi_6_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link2', 's_axi_6_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link2', 's_axi_6_rlast',  dir='in', width=1)

            # AXI Interface Ports 7

            hbm.add_port('m_axis_rx_TADD_Link3', 's_axi_7_araddr',  dir='out', width=32)
            hbm.add_port('m_axis_rx_TADD_READY_Link3', 's_axi_7_arready', dir='in', width=1)
            hbm.add_port('m_axis_rx_TADD_VALID_Link3', 's_axi_7_arvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_Link3', 's_axi_7_awaddr', dir='out', width=32)
            hbm.add_port('s_axis_tx_TADD_READY_Link3', 's_axi_7_awready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TADD_VALID_Link3', 's_axi_7_awvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_RESP_RDY_Link3', 's_axi_7_bready',  dir='out', width=1)
            hbm.add_port('s_axis_tx_TRESP_Link3', 's_axi_7_bresp',  dir='in',  width=2)
            hbm.add_port('s_axis_tx_RESP_VALID_Link3', 's_axi_7_bvalid',  dir='in',  width=1)
            hbm.add_port('m_axis_rx_TDATA_Link3', 's_axi_7_rdata', dir='in',  width=256)
            hbm.add_port('m_axis_rx_TREADY_Link3', 's_axi_7_rready', dir='out', width=1)
            hbm.add_port('m_axis_rx_TRESP_Link3', 's_axi_7_rresp', dir='in',  width=2)
            hbm.add_port('m_axis_rx_TVALID_Link3', 's_axi_7_rvalid', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TDATA_Link3', 's_axi_7_wdata',  dir='out', width=256)
            hbm.add_port('s_axis_tx_TREADY_Link3', 's_axi_7_wready', dir='in',  width=1)
            hbm.add_port('s_axis_tx_TSTROBE_Link3', 's_axi_7_wstrb',  dir='out', width=32)
            hbm.add_port('s_axis_tx_TVALID_Link3', 's_axi_7_wvalid', dir='out', width=1)
            hbm.add_port('s_axis_tx_TADD_SIZE_Link3', 's_axi_7_awsize', dir='out', width=3)
            hbm.add_port('s_axis_tx_TADD_LENGTH_Link3', 's_axi_7_awlen',  dir='out',  width=8)
            hbm.add_port('s_axis_tx_TADD_BURST_Link3', 's_axi_7_awburst', dir='out', width=2)
            hbm.add_port('s_axis_tx_TADD_ID_Link3', 's_axi_7_awid', dir='out', width=6)
            hbm.add_port('s_axis_tx_TRESP_ID_Link3', 's_axi_7_bid', dir='in', width=6)
            hbm.add_port('s_axis_tx_TLAST_Link3', 's_axi_7_wlast', dir='out',  width=1)
            hbm.add_port('m_axis_rx_TADD_SIZE_Link3', 's_axi_7_arsize', dir='out', width=3)
            hbm.add_port('m_axis_rx_TADD_LENGTH_Link3', 's_axi_7_arlen', dir='out',  width=8)
            hbm.add_port('m_axis_rx_TADD_BURST_Link3', 's_axi_7_arburst', dir='out', width=2)
            hbm.add_port('m_axis_rx_TADD_ID_Link3', 's_axi_7_arid',  dir='out', width=6)
            hbm.add_port('m_axis_rx_TID_Link3', 's_axi_7_rid',     dir='in',  width=6)
            hbm.add_port('m_axis_rx_TLAST_Link3', 's_axi_7_rlast',  dir='in', width=1)

            # INIT_DONE from Memory Bank 1
            hbm.add_port('INIT_DONE', 'apb_complete_1_0_0', dir='in', width=1)

        else:
            self.logger.error('Invalid HBM Memory Bank selected for HBM. Cannot connect to HBM memory bank')

        # Simulink ports Link0

        hbm.add_port('RD_REQ_LINK0', '%s_rd_en_link0' % self.fullname, dir='in')
        hbm.add_port('WR_REQ_LINK0', '%s_wr_en_link0' % self.fullname, dir='in')
        hbm.add_port('WR_ADDRESS_LINK0', '%s_wr_address_link0' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_IN_LINK0', '%s_data_in_link0' % self.fullname, dir='in', width=256)
        hbm.add_port('RD_ADDRESS_LINK0', '%s_rd_address_link0' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_OUT_LINK0', '%s_data_out_link0' % self.fullname, dir='out', width=256)
        hbm.add_port('TAG_OUT_LINK0', '%s_rd_tag_out_link0' % self.fullname, dir='out', width=9)
        hbm.add_port('TAG_IN_LINK0', '%s_rd_tag_in_link0' % self.fullname, dir='in', width=9)
        hbm.add_port('DATA_VALID_LINK0', '%s_data_valid_link0' % self.fullname, dir='out')
        hbm.add_port('RD_READY_LINK0', '%s_rd_ready_link0' % self.fullname, dir='out')
        hbm.add_port('WR_READY_LINK0', '%s_wr_ready_link0' % self.fullname, dir='out')


        # Simulink ports Link1

        hbm.add_port('RD_REQ_LINK1', '%s_rd_en_link1' % self.fullname, dir='in')
        hbm.add_port('WR_REQ_LINK1', '%s_wr_en_link1' % self.fullname, dir='in')
        hbm.add_port('WR_ADDRESS_LINK1', '%s_wr_address_link1' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_IN_LINK1', '%s_data_in_link1' % self.fullname, dir='in', width=256)
        hbm.add_port('RD_ADDRESS_LINK1', '%s_rd_address_link1' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_OUT_LINK1', '%s_data_out_link1' % self.fullname, dir='out', width=256)
        hbm.add_port('TAG_OUT_LINK1', '%s_rd_tag_out_link1' % self.fullname, dir='out', width=9)
        hbm.add_port('TAG_IN_LINK1', '%s_rd_tag_in_link1' % self.fullname, dir='in', width=9)
        hbm.add_port('DATA_VALID_LINK1', '%s_data_valid_link1' % self.fullname, dir='out')
        hbm.add_port('RD_READY_LINK1', '%s_rd_ready_link1' % self.fullname, dir='out')
        hbm.add_port('WR_READY_LINK1', '%s_wr_ready_link1' % self.fullname, dir='out')


        # Simulink ports Link2

        hbm.add_port('RD_REQ_LINK2', '%s_rd_en_link2' % self.fullname, dir='in')
        hbm.add_port('WR_REQ_LINK2', '%s_wr_en_link2' % self.fullname, dir='in')
        hbm.add_port('WR_ADDRESS_LINK2', '%s_wr_address_link2' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_IN_LINK2', '%s_data_in_link2' % self.fullname, dir='in', width=256)
        hbm.add_port('RD_ADDRESS_LINK2', '%s_rd_address_link2' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_OUT_LINK2', '%s_data_out_link2' % self.fullname, dir='out', width=256)
        hbm.add_port('TAG_OUT_LINK2', '%s_rd_tag_out_link2' % self.fullname, dir='out', width=9)
        hbm.add_port('TAG_IN_LINK2', '%s_rd_tag_in_link2' % self.fullname, dir='in', width=9)
        hbm.add_port('DATA_VALID_LINK2', '%s_data_valid_link2' % self.fullname, dir='out')
        hbm.add_port('RD_READY_LINK2', '%s_rd_ready_link2' % self.fullname, dir='out')
        hbm.add_port('WR_READY_LINK2', '%s_wr_ready_link2' % self.fullname, dir='out')

        # Simulink ports Link3

        hbm.add_port('RD_REQ_LINK3', '%s_rd_en_link3' % self.fullname, dir='in')
        hbm.add_port('WR_REQ_LINK3', '%s_wr_en_link3' % self.fullname, dir='in')
        hbm.add_port('WR_ADDRESS_LINK3', '%s_wr_address_link3' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_IN_LINK3', '%s_data_in_link3' % self.fullname, dir='in', width=256)
        hbm.add_port('RD_ADDRESS_LINK3', '%s_rd_address_link3' % self.fullname, dir='in', width=27)
        hbm.add_port('DATA_OUT_LINK3', '%s_data_out_link3' % self.fullname, dir='out', width=256)
        hbm.add_port('TAG_OUT_LINK3', '%s_rd_tag_out_link3' % self.fullname, dir='out', width=9)
        hbm.add_port('TAG_IN_LINK3', '%s_rd_tag_in_link3' % self.fullname, dir='in', width=9)
        hbm.add_port('DATA_VALID_LINK3', '%s_data_valid_link3' % self.fullname, dir='out')
        hbm.add_port('RD_READY_LINK3', '%s_rd_ready_link3' % self.fullname, dir='out')
        hbm.add_port('WR_READY_LINK3', '%s_wr_ready_link3' % self.fullname, dir='out')


    def initialize(self):

        self.add_source('hbm/*.v')
        self.add_source('hbm/ip/fifo_generator_wr_hbm_cntrl_0/*.xci')
        self.add_source('hbm/ip/fifo_generator_wr_hbm_data_0/*.xci')
        # This block takes an HBM memory bank site and should prevent other blocks from using it
        self.exc_requires = ['hbm_mem_bank%d' % self.mem_bank]

    def modify_top(self,top):

        self.instantiate_hbm(top)
        #If memory bank 0 then use these parameters
        #if self.mem_bank == 0:
        #   top.add_parameter('DWIDTH', "8'd256")
        #  top.add_parameter('NUM_DATA_BYTES', "8'd32")
        #    top.add_parameter('AWIDTH', "8'd27")
        #    top.add_parameter('TWIDTH', "8'd9")
        #    top.add_parameter('HBM_ADD_BANK_SEL', "1'd0")
        #    top.add_parameter('AXI_ADD_WIDTH', "8'd33")
        #    top.add_parameter('AXI_BURST_SIZE', "8'd1")
        #    top.add_parameter('ATWIDTH', "8'd6")
        #else:
        #    top.add_parameter('DWIDTH', "8'd256")
        #    top.add_parameter('NUM_DATA_BYTES', "8'd32")
        #    top.add_parameter('AWIDTH', "8'd27")
        #    top.add_parameter('TWIDTH', "8'd9")
        #    top.add_parameter('HBM_ADD_BANK_SEL', "1'd1")
        #    top.add_parameter('AXI_ADD_WIDTH', "8'd33")
        #    top.add_parameter('AXI_BURST_SIZE', "8'd1")
        #    top.add_parameter('ATWIDTH', "8'd6")

        #top.assign_signal('mez%s_init_done' % self.mez, '%s_init_done' % self.fullname)
        #top.assign_signal('mez%s_post_ok' % self.mez, '%s_post_ok' % self.fullname)
        #top.assign_signal('data_in_xilinx1','32\'d0')
        #top.assign_signal('data_in_xilinx2','32\'d0')
        #top.assign_signal('data_in_xilinx3','32\'d0')
        #top.assign_signal('data_in_xilinx4','32\'d0')
        #top.assign_signal('data_in_xilinx5','32\'d0')
        #top.assign_signal('data_in_xilinx6','32\'d0')
        #top.assign_signal('data_in_xilinx7','32\'d0')
        #top.assign_signal('data_in_xilinx8','32\'d0')

    def gen_constraints(self):
        cons = []

        #cons.append(PortConstraint('MEZZANINE_%s_RESET' % self.mez,'MEZZANINE_%s_RESET' % self.mez))
        #cons.append(PortConstraint('MEZZANINE_%s_CLK_SEL' % self.mez, 'MEZZANINE_%s_CLK_SEL' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_0_P' % self.mez, 'MEZ%s_REFCLK_0_P' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_0_N' % self.mez, 'MEZ%s_REFCLK_0_N' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_1_P' % self.mez, 'MEZ%s_REFCLK_1_P' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_1_N' % self.mez, 'MEZ%s_REFCLK_1_N' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_2_P' % self.mez, 'MEZ%s_REFCLK_2_P' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_2_N' % self.mez, 'MEZ%s_REFCLK_2_N' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_3_P' % self.mez, 'MEZ%s_REFCLK_3_P' % self.mez))
        #cons.append(PortConstraint('MEZ%s_REFCLK_3_N' % self.mez, 'MEZ%s_REFCLK_3_N' % self.mez))
        #cons.append(PortConstraint('MEZ%s_PHY11_LANE_TX_P' % self.mez, 'MEZ%s_PHY11_LANE_TX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY11_LANE_TX_N' % self.mez, 'MEZ%s_PHY11_LANE_TX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY12_LANE_TX_P' % self.mez, 'MEZ%s_PHY12_LANE_TX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY12_LANE_TX_N' % self.mez, 'MEZ%s_PHY12_LANE_TX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY21_LANE_TX_P' % self.mez, 'MEZ%s_PHY21_LANE_TX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY21_LANE_TX_N' % self.mez, 'MEZ%s_PHY21_LANE_TX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY22_LANE_TX_P' % self.mez, 'MEZ%s_PHY22_LANE_TX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY22_LANE_TX_N' % self.mez, 'MEZ%s_PHY22_LANE_TX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY11_LANE_RX_P' % self.mez, 'MEZ%s_PHY11_LANE_RX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY11_LANE_RX_N' % self.mez, 'MEZ%s_PHY11_LANE_RX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY12_LANE_RX_P' % self.mez, 'MEZ%s_PHY12_LANE_RX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY12_LANE_RX_N' % self.mez, 'MEZ%s_PHY12_LANE_RX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY21_LANE_RX_P' % self.mez, 'MEZ%s_PHY21_LANE_RX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY21_LANE_RX_N' % self.mez, 'MEZ%s_PHY21_LANE_RX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY22_LANE_RX_P' % self.mez, 'MEZ%s_PHY22_LANE_RX_P' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))
        #cons.append(PortConstraint('MEZ%s_PHY22_LANE_RX_N' % self.mez, 'MEZ%s_PHY22_LANE_RX_N' % self.mez, port_index=list(range(4)), iogroup_index=list(range(4))))

        # GTH Clock Constraints
        #cons.append(RawConstraint('create_clock -period 6.400 -waveform {0.000 3.200} [get_ports MEZ%s_REFCLK_0_P]' % self.mez))
        #cons.append(ClockConstraint('MEZ%s_REFCLK_0_P' % self.mez,'MEZ%s_REFCLK_0_P' % self.mez, period=6.4, port_en=True, virtual_en=False, waveform_min=0.0, waveform_max=3.2))
        #cons.append(RawConstraint('create_clock -period 6.400 -waveform {0.000 3.200} [get_ports MEZ%s_REFCLK_1_P]' % self.mez))
        #cons.append(ClockConstraint('MEZ%s_REFCLK_1_P' % self.mez,'MEZ%s_REFCLK_1_P' % self.mez, period=6.4, port_en=True, virtual_en=False, waveform_min=0.0, waveform_max=3.2))
        #cons.append(RawConstraint('create_clock -period 6.400 -waveform {0.000 3.200} [get_ports MEZ%s_REFCLK_2_P]' % self.mez))
        #cons.append(ClockConstraint('MEZ%s_REFCLK_2_P' % self.mez,'MEZ%s_REFCLK_2_P' % self.mez, period=6.4, port_en=True, virtual_en=False, waveform_min=0.0, waveform_max=3.2))
        #cons.append(RawConstraint('create_clock -period 6.400 -waveform {0.000 3.200} [get_ports MEZ%s_REFCLK_3_P]' % self.mez))
        #cons.append(ClockConstraint('MEZ%s_REFCLK_3_P' % self.mez,'MEZ%s_REFCLK_3_P' % self.mez, period=6.4, port_en=True, virtual_en=False, waveform_min=0.0, waveform_max=3.2))


        # *******************************************************************************************************
        # HBM Link Timing Constraints
        # *******************************************************************************************************

        # GTH Tx Clock Constraints (This clock is the reference clock for the TX side of all 8 GTHs)
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/TXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/TXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False,  waveform_min=0.0, waveform_max=1.6))

        # GTH Rx Clock Constraints (Rx clock phase is unique for each receiver => generate a constraint for each GTH)
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))

        # cut paths between GTH Tx Clock and GTH Rx Clocks (async fifo crossing) from Rx to Tx clock
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))

        # cut paths between GTH Tx Clock and GTH Rx Clocks (async fifo crossing) from Tx to Rx clock
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))

        #Cut paths between GTH Tx Clock and HMC Static Clock (forty_gbe)
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]','asynchronous'))

        #Cut paths between HMC Static Clock (forty_gbe) and GTH Tx Clock
        #cons.append(ClockGroupConstraint(' -of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', '-include_generated_clocks %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, 'asynchronous'))

        #Cut paths between HMC and forty_gbe clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]', '-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between HMC Link 2 and Link 3 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between SYS_CLK_MMCM_inst/CLKOUT0 and HMC Link 2 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between skarab_infr/USER_CLK_MMCM_inst/CLKOUT0] and HMC Link 2 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))


        # *******************************************************************************************************
        # HBM Link Timing Constraints
        # *******************************************************************************************************

        # GTH Tx Clock Constraints (This clock is the reference clock for the TX side of all 8 GTHs)
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/TXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/TXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))

        # GTH Rx Clock Constraints (Rx clock phase is unique for each receiver => generate a constraint for each GTH)
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))
        #cons.append(RawConstraint('create_clock -period 3.200 -name '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i -waveform {0.000 1.600} [get_pins '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gthe2_i/RXOUTCLK]'))
        #cons.append(ClockConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gthe2_i/RXOUTCLK'% self.fullname,'%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, period=3.2, port_en=False, virtual_en=False, waveform_min=0.0, waveform_max=1.6))

        # cut paths between GTH Tx Clock and GTH Rx Clocks (async fifo crossing) from Rx to Tx clock
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i] -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i]'))
        #cons.append(ClockGroupConstraint('%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname, '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname,'asynchronous'))

        # cut paths between GTH Tx Clock and GTH Rx Clocks (async fifo crossing) from Tx to Rx clock
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt1_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt2_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt3_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt4_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt5_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt6_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))
        #cons.append(RawConstraint('set_clock_groups -asynchronous -group [get_clocks -include_generated_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i] -group [get_clocks '+self.fullname+'/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i]'))
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '%s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt7_hmc_gth_i/gt0_rxoutclk_i' % self.fullname,'asynchronous'))

        #Cut paths between GTH Tx Clock and HMC Static Clock (forty_gbe)
        #cons.append(ClockGroupConstraint('-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, '-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]','asynchronous'))

        #Cut paths between HMC Static Clock (forty_gbe) and GTH Tx Clock
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', '-include_generated_clocks %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/gt0_txoutclk_i' % self.fullname, 'asynchronous'))

        #Cut paths between HMC and forty_gbe clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]', '-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between HMC Link 3 and HMC Link 2 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins %s/hmc_ska_sa_top_link2_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between SYS_CLK_MMCM_inst/CLKOUT0 and HMC Link 3 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))

        #Cut paths between skarab_infr/USER_CLK_MMCM_inst/CLKOUT0] and HMC Link 2 clocks
        #cons.append(ClockGroupConstraint('-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname, '-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]','asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins %s/hmc_ska_sa_top_link3_inst/hmc_gth_inst/txoutclk_mmcm0_inst/mmcm_adv_inst/CLKOUT0]' % self.fullname,'asynchronous'))


        #Timing Constraints
        #Output Constraints
        #cons.append(OutputDelayConstraint(clkname='-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', consttype='min', constdelay_ns=1.0, add_delay_en=True, portname='MEZZANINE_%s_RESET' % self.mez))
        #cons.append(OutputDelayConstraint(clkname='-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', consttype='max', constdelay_ns=2.0, add_delay_en=True, portname='MEZZANINE_%s_RESET' % self.mez))
        #cons.append(OutputDelayConstraint(clkname='-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]', consttype='min', constdelay_ns=1.0, add_delay_en=True, portname='MEZZANINE_%s_RESET' % self.mez))
        #cons.append(OutputDelayConstraint(clkname='-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT1]', consttype='max', constdelay_ns=2.0, add_delay_en=True, portname='MEZZANINE_%s_RESET' % self.mez))

        #multi-cycle constraints
        #cons.append(MultiCycleConstraint(multicycletype='setup',sourcepath='get_clocks -of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', destpath='get_ports MEZZANINE_%s_RESET' % self.mez, multicycledelay=4))
        #cons.append(MultiCycleConstraint(multicycletype='hold',sourcepath='get_clocks -of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', destpath='get_ports MEZZANINE_%s_RESET' % self.mez, multicycledelay=3))
        #cons.append(MultiCycleConstraint(multicycletype='setup',sourcepath='get_clocks -of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', destpath='get_ports MEZZANINE_%s_RESET' % self.mez, multicycledelay=4))
        #cons.append(MultiCycleConstraint(multicycletype='hold',sourcepath='get_clocks -of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', destpath='get_ports MEZZANINE_%s_RESET' % self.mez, multicycledelay=3))

        #cons.append(ClockGroupConstraint('-of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', '-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]', 'asynchronous'))
        #cons.append(ClockGroupConstraint('-of_objects [get_pins */USER_CLK_MMCM_inst/CLKOUT0]' ,' -of_objects [get_pins */SYS_CLK_MMCM_inst/CLKOUT0]', 'asynchronous'))


        #Placement constraints
        #Link 2 and Link3
        #cons.append(RawConstraint('create_pblock MEZ%s_HMC' % self.mez))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list '+self.fullname+'/flit_gen_link2_inst]]'))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list '+self.fullname+'/flit_gen_user_link2_inst]]'))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list '+self.fullname+'/hmc_ska_sa_top_link2_inst]]'))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list ' + self.fullname + '/flit_gen_link3_inst]]'))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list ' + self.fullname + '/flit_gen_user_link3_inst]]'))
        #cons.append(RawConstraint('add_cells_to_pblock [get_pblocks MEZ%s_HMC]' % self.mez + ' [get_cells -quiet [list ' + self.fullname + '/hmc_ska_sa_top_link3_inst]]'))
        #Mez 0 Selected
        #if self.mez == 0:
        #  cons.append(RawConstraint('resize_pblock [get_pblocks MEZ%s_HMC] -add {CLOCKREGION_X0Y4:CLOCKREGION_X0Y7}' % self.mez))
        #Mez 1 Selected
        #elif self.mez == 1:
        #  cons.append(RawConstraint('resize_pblock [get_pblocks MEZ%s_HMC] -add {CLOCKREGION_X0Y0:CLOCKREGION_X0Y3}' % self.mez))
        #Mez 2 Selected
        #elif self.mez == 2:
        #  cons.append(RawConstraint('resize_pblock [get_pblocks MEZ%s_HMC] -add {CLOCKREGION_X1Y0:CLOCKREGION_X1Y3}' % self.mez))
        #else:
        #    self.logger.error('Invalid Mezzanine site selected for HMC. Placement ignored for HMC')

        return cons
