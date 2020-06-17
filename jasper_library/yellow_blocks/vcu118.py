from .yellow_block import YellowBlock
from constraints import ClockConstraint, PortConstraint, RawConstraint

class vcu118(YellowBlock):
    def initialize(self):
        self.add_source('infrastructure/vcu118_infrastructure.v')
        #self.add_source('onehundred_gbe/debug.xdc') # Add this to tap the yellow block via ILA
        #self.add_source('wbs_arbiter')
        self.provides = ['sys_clk', 'sys_clk90', 'sys_clk180', 'sys_clk270']

    def modify_top(self,top):
        inst = top.get_instance('vcu118_infrastructure', 'vcu118_infrastructure_inst')
        inst.add_port('sys_clk_buf_n', 'sys_clk_n', parent_port=True, dir='in')
        inst.add_port('sys_clk_buf_p', 'sys_clk_p', parent_port=True, dir='in')
        inst.add_port('sys_clk0     ', 'sys_clk   ')
        inst.add_port('sys_clk180   ', 'sys_clk180')
        inst.add_port('sys_clk270   ', 'sys_clk270')
        inst.add_port('clk_200      ', 'clk_200   ')
        inst.add_port('clk_100      ', 'clk_100   ')
        inst.add_port('sys_rst      ', 'sys_rst   ')
        inst.add_port('idelay_rdy   ', 'idelay_rdy')
        inst.add_port('sys_clk_rst_sync', 'sys_clk_rst_sync')

        top.add_signal('sys_clk90')
        top.assign_signal('sys_clk90', '~sys_clk270')

    def gen_children(self):
        children = [YellowBlock.make_block({'fullpath': self.fullpath,'tag':'xps:sys_block', 'board_id':'12', 'rev_maj':'12', 'rev_min':'0', 'rev_rcs':'32','scratchpad': '0'}, self.platform)]
        # print (self.use_microblaze)
        # print (self.use_jtag_axil_master)
        if self.use_microblaze:
            print ("WARNING! Ignoring use use_microblaze!")
            pass
        # elif self.use_jtag_axil_master: 
        #     #children.append(YellowBlock.make_block({'tag':'xps:jtag_axil_master'}, self.platform))
        #     print ('JTAG to AXI Light Master Memory Mapped bus used')
        else:
            #children.append(YellowBlock.make_block({'tag':'xps:pci_dma_axilite_master'}, self.platform))
            children.append(YellowBlock.make_block({'tag':'xps:jtag_axil_master'}, self.platform))
            print ("JTAG to AXI Light Master Memory Mapped bus used")

        return children

    def gen_constraints(self):
        return [
            PortConstraint('sys_clk_n', 'sys_clk_n'),
            PortConstraint('sys_clk_p', 'sys_clk_p'),
            ClockConstraint('sys_clk_p', period=4.0),#period=3.333),
            #Refer to UG1314 page 23 for settings
            RawConstraint("set_property CONFIG_VOLTAGE 1.8 [ current_design ]"),
            RawConstraint("set_property BITSTREAM.CONFIG.CONFIGFALLBACK Enable [ current_design ]"),
            RawConstraint("set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]"),
            #RawConstraint("set_property CONFIG_MODE SPIx4 [current_design]"),
            #RawConstraint("set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]"),
            RawConstraint("set_property CONFIG_MODE SPIx8 [current_design]"),
            RawConstraint("set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 8 [current_design]"),
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
       #tcl_cmds['promgen'] = ['write_cfgmem -force -format mcs -interface spix4 -size 1024  -loadbit "up 0x01002000 ./myproj.runs/impl_1/top.bit " -checksum -file "./myproj.runs/impl_1/top.mcs"']
       tcl_cmds['promgen'] = ['write_cfgmem -force -format mcs -interface spix8 -size 128  -loadbit "up 0x00000000 ./myproj.runs/impl_1/top.bit " -checksum -file "./myproj.runs/impl_1/top.mcs"']
       #tcl_cmds['promgen'] = ['write_cfgmem -force -format mcs -interface spix8 -size 2048  -loadbit "up 0x00000000 ./myproj.runs/impl_1/Golden.bit up 0x00400000 ./myproj.runs/impl_1/top.bit" -checksum -file "./myproj.runs/impl_1/top.mcs"']
       return tcl_cmds
