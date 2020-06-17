from .yellow_block import YellowBlock
from constraints import ClockConstraint, PortConstraint, RawConstraint

class alveo_u280(YellowBlock):
    def initialize(self):
        self.add_source('infrastructure/alveo_u280_infrastructure.v')
        #self.add_source('wbs_arbiter')
        self.provides = ['sys_clk', 'sys_clk90', 'sys_clk180', 'sys_clk270']

    def modify_top(self,top):
        inst = top.get_instance('alveo_u280_infrastructure', 'alveo_u280_infrastructure_inst')
        inst.add_port('sys_clk_buf_n', 'sys_clk_n', parent_port=True, dir='in')
        inst.add_port('sys_clk_buf_p', 'sys_clk_p', parent_port=True, dir='in')
        inst.add_port('sys_clk0     ', 'sys_clk   ')
        inst.add_port('sys_clk180   ', 'sys_clk180')
        inst.add_port('sys_clk270   ', 'sys_clk270')
        inst.add_port('clk_200      ', 'clk_200   ')
        inst.add_port('sys_rst      ', 'sys_rst   ')
        inst.add_port('idelay_rdy   ', 'idelay_rdy')
        inst.add_port('sys_clk_rst_sync', 'sys_clk_rst_sync')

        top.add_signal('sys_clk90')
        top.assign_signal('sys_clk90', '~sys_clk270')

        # hbm_cattrip - HBM catastrophic trip
        # tie low to prevent FPGA power rails from shutting off 
        top.add_port('hbm_cattrip', 'hbm_cattrip', parent_port=True, dir='out', width=0)
        top.assign_signal('hbm_cattrip', "1'b0")

        #top.assign_signal('user_rst', 'sys_rst')
        

    def gen_children(self):
        children = [YellowBlock.make_block({'fullpath': self.fullpath,'tag':'xps:sys_block', 'board_id':'12', 'rev_maj':'12', 'rev_min':'0', 'rev_rcs':'32','scratchpad': '0'}, self.platform)]
        if self.use_microblaze:
            pass
        else:
            #children.append(YellowBlock.make_block({'tag':'xps:pci_dma_axilite_master'}, self.platform))
            children.append(YellowBlock.make_block({'tag':'xps:jtag_axil_master'}, self.platform))
            print ("JTAG to AXI Light Master Memory Mapped bus used")
        return children

    def gen_constraints(self):
        return [
            PortConstraint('sys_clk_n', 'sys_clk_n'),
            PortConstraint('sys_clk_p', 'sys_clk_p'),
            ClockConstraint('sys_clk_p', period=10.0),
            PortConstraint('hbm_cattrip', 'hbm_cattrip'),
            #Refer to UG1314 page 23 for settings
            RawConstraint("set_property CONFIG_VOLTAGE 1.8 [ current_design ]"),
            RawConstraint("set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [ current_design ]"),
            RawConstraint("set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]"),
            RawConstraint("set_property CONFIG_MODE SPIx4 [current_design]"),
            RawConstraint("set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]"),
            RawConstraint("set_property BITSTREAM.CONFIG.CONFIGRATE 85.0 [current_design]"),            
            RawConstraint("set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN disable [current_design]"),
            RawConstraint("set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]"),
            RawConstraint("set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]"),            
            RawConstraint("set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]"),
            #RawConstraint("set_property CFGBVS GND [ current_design ]"),            
            #RawConstraint("set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN Enable [current_design]"),
        ]
    def gen_tcl_cmds(self):
       tcl_cmds = {}
       tcl_cmds['promgen'] = ['write_cfgmem -force -format mcs -interface spix4 -size 1024  -loadbit "up 0x01002000 ./myproj.runs/impl_1/top.bit " -checksum -file "./myproj.runs/impl_1/top.mcs"']
       return tcl_cmds
