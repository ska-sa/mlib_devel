from .yellow_block import YellowBlock
from constraints import PortConstraint, ClockConstraint
from helpers import to_int_list
from .yellow_block_typecodes import *
from os.path import join

class onehundred_gbe(YellowBlock):
    @staticmethod
    def factory(blk, plat, hdl_root=None):
        #if plat.name in ['vcu118', 'vcu128'] or plat.conf.get('family', None) in ["ultrascaleplus"]:
        if plat.name in ['vcu128'] or plat.conf.get('family', None) in ["ultrascaleplus"]:
            return onehundredgbe_usplus(blk, plat, hdl_root)
        else:
            pass
    """
    Future common methods here.
    """

class onehundredgbe_usplus(onehundred_gbe):
    def initialize(self):
        self.typecode = TYPECODE_ETHCORE
        kdir = "onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl"

        # HK - don't add all the gazillion files in all the directories - just add what we need!
        # self.add_source('onehundred_gbe/*.v')
        # self.add_source(join(kdir, "*.vhd"))
        # self.add_source(join(kdir, "*", "*.vhd"))
        # self.add_source(join(kdir, "udp", "macinterface", "*.vhd"))
        # self.add_source(join(kdir, "udp", "macinterface", "*", "*.vhd"))
        # #self.add_source('onehundred_gbe/kutleng/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/arp/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/lbustoaxis/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/macphy/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/ringbuffer/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/udp/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/udp/macinterface/*.vhd')
        # #self.add_source('onehundred_gbe/kutleng/udp/macinterface/cpuinterface/*.vhd')
        # self.add_source('onehundred_gbe/ip/*/*.xci')

        # HK - don't add all the gazillion files in all the directories - just add what we need!
        self.add_source('onehundred_gbe/casper100g_noaxi.v')
        self.add_source('onehundred_gbe/async.v')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/preconfig/protocolchecksumprconfigsm.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/preconfig/prconfigcontroller.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/preconfig/icapwritersm.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/preconfig/protocolresponderprconfigsm.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/axioffseter.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/udpipinterfacepr.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/udpstreamingapps.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/udpdatastripper.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/udpdatapacker_jh.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/casper100gethernetblock_no_cpu.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/udpstreamingapp.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/macphy/mac100gphy.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/macphy/macaxissender.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/macphy/macaxisdecoupler.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/macphy/macaxisreceiver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/macphy/gmacqsfptop.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/cpudualportpacketringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/packetringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/dualportpacketringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/packetramsp.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/cpuifsenderpacketringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/cpuifreceiverpacketringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/packetstatusram.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/packetramdp.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/ringbuffer/truedualportpacketringbuffer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/arpreceiver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/arpmodule.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/arpramadpwrr.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/arpcache.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/arpramadpwr.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/ramdpwr.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/arp/ramdpwrr.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/macifudpreceiver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/yellow_block_100gbe_udp_rx.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/macifudpsender.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/axisfabricmultiplexer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/cpuethernetmacif.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/macifudpserver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/axistwoportfabricmultiplexer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/axisthreeportfabricmultiplexer.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/cpuinterface/cpumacifudpreceiver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/cpuinterface/cpumacifethernetreceiver.vhd')
        self.add_source('onehundred_gbe/kutleng_skarab2_bsp_firmware/casperbsp/sources/vhdl/rtl/udp/macinterface/cpuinterface/cpumacifudpsender.vhd')
        self.add_source('onehundred_gbe/ip/axispacketbufferfifo/axispacketbufferfifo.xci')
        #self.add_source('onehundred_gbe/ip/async_fifo_513b_512deep/async_fifo_513b_512deep.xci')
        self.add_source('onehundred_gbe/ip/async_fifo_513b_16deep/async_fifo_513b_16deep.xci')
        self.add_source('onehundred_gbe/ip/axis_data_fifo/axis_data_fifo_0.xci')
        self.add_source('onehundred_gbe/ip/EthMACPHY100GQSFP4x/EthMACPHY100GQSFP4x.xci')
        self.add_source('onehundred_gbe/ip/dest_address_fifo/dest_address_fifo.xci')

        self.provides = ['ethernet']
        if self.cpu_rx_en and self.cpu_tx_en:
            self.provides += ['cpu_ethernet']

        # Hard-code to port 0 for now
        #self.port = 0

        try:
            ethconf = self.platform.conf["onehundredgbe"]
        except KeyError:
            self.logger.exception("Failed to find `onehundredgbe` configuration in platform's YAML file")
            raise
        
        try:
            self.refclk_freq_str = ethconf["refclk_freq_str"]
        except KeyError:
            self.logger.error("Missing onehundredgbe `refclk_freq_str` parameter in YAML file")
            raise
        self.refclk_freq = float(self.refclk_freq_str)
        try:
            self.cmac_loc = ethconf["cmac_loc"][self.port]
        except KeyError:
            self.logger.error("Missing onehundredgbe `cmac_loc` parameter in YAML file")
            raise
        except IndexError:
            self.logger.error("Missing entry for port %d in onehundredgbe `cmac_loc` parameter" % self.port)
            raise

    def modify_top(self, top, PlatformName):

        inst = top.get_instance(entity='casper100g_noaxi', name=self.fullname+'_inst')

        # inst.add_parameter('LOCAL_ENABLE',   '%d' % int(self.local_en))
        # inst.add_parameter('LOCAL_MAC',      '48\'d%d' % self.local_mac)
        # inst.add_parameter('LOCAL_IP',       '32\'d%d' % self.local_ip)
        # inst.add_parameter('LOCAL_PORT',     '16\'d%d' % self.local_port)
        # inst.add_parameter('LOCAL_GATEWAY',  '32\'d%d' % self.local_gateway)
        # inst.add_parameter('CPU_PROMISCUOUS', '%d' % int(self.cpu_promiscuous))
        # inst.add_parameter('DIS_CPU_TX',      '%d' % int(self.dis_cpu_tx))
        # inst.add_parameter('DIS_CPU_RX',      '%d' % int(self.dis_cpu_rx))

        # HK - added config from 100GbE mask parameters 
        inst.add_parameter('FABRIC_MAC',      '48\'d%d' % self.fab_mac)
        inst.add_parameter('FABRIC_IP',       '32\'d%d' % self.fab_ip)
        inst.add_parameter('FABRIC_PORT',     '16\'d%d' % self.fab_udp)
        
        inst.add_port('RefClk100MHz', 'axil_clk') # HK - we need a 100MHz clock - lets not over clock this thing! # 'sys_clk')
        inst.add_port('RefClkLocked', 'axil_rst_n', parent_sig=False)
        inst.add_port('aximm_clk', 'axil_clk')
        inst.add_port('icap_clk', 'axil_clk')
        inst.add_port('axis_reset', "1'b0")#'axil_rst')
        # MGT connections
        inst.add_port('mgt_qsfp_clock_p', self.fullname+'_refclk_p', dir='in', parent_port=True)
        inst.add_port('mgt_qsfp_clock_n', self.fullname+'_refclk_n', dir='in', parent_port=True)

        inst.add_port('qsfp_mgt_rx_p', self.fullname+'_qsfp_mgt_rx_p', dir='in', width=4, parent_port=True)
        inst.add_port('qsfp_mgt_rx_n', self.fullname+'_qsfp_mgt_rx_n', dir='in', width=4, parent_port=True)
        inst.add_port('qsfp_mgt_tx_p', self.fullname+'_qsfp_mgt_tx_p', dir='out', width=4, parent_port=True)
        inst.add_port('qsfp_mgt_tx_n', self.fullname+'_qsfp_mgt_tx_n', dir='out', width=4, parent_port=True)

        if PlatformName in ['vcu118']:
            # QSFP config interface
            inst.add_port('qsfp_modsell_ls', self.fullname+'_qsfp_modsell_ls', dir='out', parent_port=True)
            inst.add_port('qsfp_resetl_ls',  self.fullname+'_qsfp_resetl_ls', dir='out', parent_port=True)
            inst.add_port('qsfp_modprsl_ls', self.fullname+'_qsfp_modprsl_ls', dir='in', parent_port=True)
            inst.add_port('qsfp_intl_ls',    '1\'b1') # ignore interrupt #self.fullname+'_qsfp_intl_ls')
            inst.add_port('qsfp_lpmode_ls',  self.fullname+'_qsfp_lpmode_ls', dir='out', parent_port=True)
            print ('VCU118 QSFP pins used')
        elif PlatformName in ['alveo_u280']:
            # don't have access to these pins on FPGA
            inst.add_port('qsfp_modsell_ls', '') #self.fullname+'_qsfp_modsell_ls')
            inst.add_port('qsfp_resetl_ls',  '') #self.fullname+'_qsfp_resetl_ls')
            inst.add_port('qsfp_modprsl_ls', '1\'b0') # always declares that the module is present (signal is active LOW)
            inst.add_port('qsfp_intl_ls',    '1\'b1') #self.fullname+'_qsfp_intl_ls')
            inst.add_port('qsfp_lpmode_ls',  '') #self.fullname+'_qsfp_lpmode_ls')
        else:
            # don't have access to these pins on FPGA
            inst.add_port('qsfp_modsell_ls', '') #self.fullname+'_qsfp_modsell_ls')
            inst.add_port('qsfp_resetl_ls',  '') #self.fullname+'_qsfp_resetl_ls')
            inst.add_port('qsfp_modprsl_ls', self.fullname+'_qsfp_modprsl_ls', dir='in', parent_port=True)
            inst.add_port('qsfp_intl_ls',    '1\'b1') #self.fullname+'_qsfp_intl_ls')
            inst.add_port('qsfp_lpmode_ls',  '') #self.fullname+'_qsfp_lpmode_ls')

        inst.add_port('user_clk', 'user_clk')

        # Simulink Interfaces
        inst.add_port('gbe_tx_afull',         self.fullname+'_tx_afull',       width=1)        
        inst.add_port('gbe_tx_overflow',      self.fullname+'_tx_overflow',    width=1)
        inst.add_port('gbe_rx_data',          self.fullname+'_rx_data',        width=512)
        inst.add_port('gbe_rx_valid',         self.fullname+'_rx_valid',       width=1)
        inst.add_port('gbe_rx_source_ip',     self.fullname+'_rx_source_ip',   width=32)
        inst.add_port('gbe_rx_source_port',   self.fullname+'_rx_source_port', width=16)
        inst.add_port('gbe_rx_dest_ip',       self.fullname+'_rx_dest_ip',     width=32)
        inst.add_port('gbe_rx_dest_port',     self.fullname+'_rx_dest_port',   width=16)
        inst.add_port('gbe_rx_end_of_frame',  self.fullname+'_rx_end_of_frame', width=1)
        inst.add_port('gbe_rx_bad_frame',     self.fullname+'_rx_bad_frame',    width=1)
        inst.add_port('gbe_rx_overrun',       self.fullname+'_rx_overrun',      width=1)
        inst.add_port('gbe_led_up',           self.fullname+'_led_up',          width=1)
        inst.add_port('gbe_led_rx',           self.fullname+'_led_rx',          width=1)
        inst.add_port('gbe_led_tx',           self.fullname+'_led_tx',          width=1)

        inst.add_port('gbe_rst',              self.fullname+'_rst',            width=1)
        inst.add_port('gbe_rx_ack',           self.fullname+'_rx_ack',         width=1)
        inst.add_port('gbe_rx_overrun_ack',   self.fullname+'_rx_overrun_ack', width=1)
        inst.add_port('gbe_tx_dest_ip',       self.fullname+'_tx_dest_ip',     width=32)
        inst.add_port('gbe_tx_dest_port',     self.fullname+'_tx_dest_port',   width=16)
        inst.add_port('gbe_tx_data',          self.fullname+'_tx_data',        width=512)
        inst.add_port('gbe_tx_valid',         self.fullname+'_tx_valid',       width=4)
        inst.add_port('gbe_tx_end_of_frame',  self.fullname+'_tx_end_of_frame',width=1)

    def gen_constraints(self,PlatformName):
        consts = []
        consts += [PortConstraint(self.fullname+'_refclk_p', 'qsfp_mgt_ref_clk_p', iogroup_index=self.port)]
        consts += [PortConstraint(self.fullname+'_refclk_n', 'qsfp_mgt_ref_clk_n', iogroup_index=self.port)]
        consts += [PortConstraint(self.fullname+'_qsfp_mgt_rx_p', 'qsfp_mgt_rx_p', port_index=range(4), iogroup_index=range(4*self.port, 4*(self.port + 1)))]
        consts += [PortConstraint(self.fullname+'_qsfp_mgt_rx_n', 'qsfp_mgt_rx_n', port_index=range(4), iogroup_index=range(4*self.port, 4*(self.port + 1)))]
        consts += [PortConstraint(self.fullname+'_qsfp_mgt_tx_p', 'qsfp_mgt_tx_p', port_index=range(4), iogroup_index=range(4*self.port, 4*(self.port + 1)))]
        consts += [PortConstraint(self.fullname+'_qsfp_mgt_tx_n', 'qsfp_mgt_tx_n', port_index=range(4), iogroup_index=range(4*self.port, 4*(self.port + 1)))]

        if PlatformName in ['vcu118']:
            # QSFP config interface
            consts += [PortConstraint(self.fullname+'_qsfp_modsell_ls', 'qsfp_modsell_ls', iogroup_index=self.port)]
            consts += [PortConstraint(self.fullname+'_qsfp_resetl_ls', 'qsfp_resetl_ls', iogroup_index=self.port)]
            consts += [PortConstraint(self.fullname+'_qsfp_modprsl_ls', 'qsfp_modprsl_ls', iogroup_index=self.port)]
            consts += [PortConstraint(self.fullname+'_qsfp_intl_ls', 'qsfp_intl_ls', iogroup_index=self.port)]
            consts += [PortConstraint(self.fullname+'_qsfp_lpmode_ls', 'qsfp_lpmode_ls', iogroup_index=self.port)]
            print('vcu118 QSFP module pins connected to FPGA')
        elif PlatformName in ['alveo_u280']:
            # FPGA don't have access to QSFP cage pins
            print('alveo_u280 has no QSFP module pins connected to FPGA')
        else:
            # FPGA has limited access to QSFP cage pins
            #consts += [PortConstraint(self.fullname+'_qsfp_modsell_ls', '', iogroup_index=self.port)]
            #consts += [PortConstraint(self.fullname+'_qsfp_resetl_ls', '', iogroup_index=self.port)]
            consts += [PortConstraint(self.fullname+'_qsfp_modprsl_ls', 'qsfp_modprs', iogroup_index=self.port)]
            #consts += [PortConstraint(self.fullname+'_qsfp_intl_ls', '', iogroup_index=self.port)]
            #consts += [PortConstraint(self.fullname+'_qsfp_lpmode_ls', '', iogroup_index=self.port)]

        self.myclk = ClockConstraint(self.fullname+'_refclk_p', name=self.fullname+'_refclk_p', freq=self.refclk_freq)
        consts += [self.myclk]
        return consts

    def gen_tcl_cmds(self):
        tcl_cmds = {}
        # Override the IP reference clock frequency
        tcl_cmds['pre_synth'] = ['set_property -dict [list CONFIG.GT_REF_CLK_FREQ {%s}] [get_ips EthMACPHY100GQSFP4x]' % self.refclk_freq_str]

        # The LOCs seem to get overriden by the user constraints above, but we need to manually unplace the CMAC blocks
        tcl_cmds['post_synth'] = ['unplace_cell [get_cells -hierarchical -filter { PRIMITIVE_TYPE == ADVANCED.MAC.CMACE4 && NAME =~ "*%s*" }]' % self.fullname]
        tcl_cmds['post_synth'] += ['place_cell [get_cells -hierarchical -filter { PRIMITIVE_TYPE == ADVANCED.MAC.CMACE4 && NAME =~ "*%s*" }] %s' % (self.fullname, self.cmac_loc)]
        # Set the 100G clock to be asynchronous to both the user clock and the AXI clock. Do this after synth so we can get the user clock without knowing what the user is clocking from
        tcl_cmds['post_synth'] += ['set_clock_groups -name async_user_%s -asynchronous -group [get_clocks -include_generated_clocks -of_objects [get_nets user_clk]] -group [get_clocks -include_generated_clocks %s]' % (self.myclk.name, self.myclk.name)]
        #tcl_cmds['post_synth'] += ['set_clock_groups -name async_axi_%s -asynchronous -group [get_clocks -include_generated_clocks  axil_clk] -group [get_clocks -include_generated_clocks %s]' % (self.myclk.name, self.myclk.name)]
        return tcl_cmds
