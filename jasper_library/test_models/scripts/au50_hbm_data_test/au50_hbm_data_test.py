import casperfpga,time

#Tutorial HBM (Alveo) Python Script to read back the HBM snap shot data and the registers

#parameters
#snapshot read length (can be adjusted)
read_length = 600; 


#Connecting to the Alveo U50
print('connecting to the Alveo U50...')
#Host1fpg - list all alveo u50s with ports using this command: casperfpga.utils.list_alveos('10.8.96.150')
f=casperfpga.CasperFpga('10.8.96.160', 7152)
print('done')

#program the Alveo U50
print('programming the Alveo U50...')
#First light HBM tutorial
#f.get_system_information('au50_hbm_data_test_2022-11-23_1954.fpg')
#f.transport.upload_to_ram_and_program('au50_hbm_data_test_2022-11-23_1954.fpg')
f.get_system_information('au50_hbm_data_test_ila_demo_2023-04-11_1424.fpg')
f.transport.upload_to_ram_and_program('au50_hbm_data_test_ila_demo_2023-04-11_1424.fpg')
#f.get_system_information('au50_hbm_data_test_hbm_axi_tg_debug_10_ila_2023-01-26_1054.fpg')
#f.transport.upload_to_ram_and_program('au50_hbm_data_test_hbm_axi_tg_debug_10_ila_2023-01-26_1054.fpg')

print('done')


#disable the HBM write and read process
print('Disabling the HBM write and read process...')
f.registers.reg_cntrl.write(wr_rd_en= False)
print('done')

#Set the data rate control
#False = write and read every 2nd clock cycle (HBM can handle the data rate: 240MHz x 256 bits/2 = 30.72bps)
#True = write and read every clock cycle (HBM can't handle the data rate: 240MHz x 256 bits = 61.44Gbps)
f.registers.reg_cntrl.write(data_rate_sel= False)

#time.sleep(2);

#arm the snap shots
print('arming snapshot blocks...')
f.snapshots.hbm_in_wr_snap_ss.arm()
f.snapshots.hbm_in_rd_snap_ss.arm()
f.snapshots.hbm_out_snap_ss.arm()
print('done')

#start the snap shot triggering and reset the counters
print('triggering the snapshots and reset the counters...')
f.registers.reg_cntrl.write(rst = 'pulse')
print('done')

#wait a few seconds for triggering 
#time.sleep(2)

#enable the HBM write and read process
print('enabling the HBM write and read process...')
f.registers.reg_cntrl.write(wr_rd_en= True)
print('done')

#wait a few seconds for snap shots to fill
#time.sleep(5)

#grab the snapshots
print('reading the snapshots...')
hbm_in_wr = f.snapshots.hbm_in_wr_snap_ss.read(arm=False)['data']
hbm_in_rd = f.snapshots.hbm_in_rd_snap_ss.read(arm=False)['data']
hbm_out = f.snapshots.hbm_out_snap_ss.read(arm=False)['data']
print('done')

#disable the HBM write and read process
print('disabling the HBM write and read process...')
f.registers.reg_cntrl.write(wr_rd_en = True)
print('done')

#read back the status registers
print('reading back the status registers...')

print("hbm rd cnt:",f.registers.hbm_rd_cnt_link0.read_uint())
print("hbm wr cnt:",f.registers.hbm_wr_cnt_link0.read_uint())
print("hbm data valid out cnt:",f.registers.hbm_out_cnt_link0.read_uint())
print("hbm empty read cnt:",f.registers.hbm_empty_rd_cnt_link0.read_uint())
print("hbm empty write cnt:",f.registers.hbm_empty_wr_cnt_link0.read_uint())
print("hbm wr err:",f.registers.hbm_wr_err_link0.read_uint())
print("hbm rd err:",f.registers.hbm_rd_err_link0.read_uint())
print("hbm status:",f.registers.hbm_status.read_uint())

print('done')
#read back the snapshot captured write input data
print('Displaying the snapshot block data #1...')
print('HBM SNAPSHOT WRITE CAPTURED INPUT')
print('---------------------------------')
print('Num wr_en wr_addr wr_data wr_rdy') 
for i in range(0, read_length):
  print('[%i] %i %i %i %i'% \
                                      (i, hbm_in_wr['wr_en'][i], hbm_in_wr['wr_addr'][i], \
                                       hbm_in_wr['wr_data'][i], hbm_in_wr['wr_rdy'][i]))
#print 'write enable:'
#irint hbm_in_wr['wr_en'][0:read_length]
print('done')
#read back the snapshot captured read input data
print('Displaying the snapshot block data #2...')
print('HBM SNAPSHOT READ CAPTURED INPUT')
print('---------------------------------')
print('Num rd_en rd_addr rd_tag rd_rdy')
for i in range(0, read_length):
  print('[%i] %i %i %i %i'% \
                                      (i, hbm_in_rd['rd_en'][i], hbm_in_rd['rd_addr'][i], \
                                        hbm_in_rd['rd_tag'][i], hbm_in_rd['rd_rdy'][i]))

print('done')                                      
#read back the snapshot captured read output data                                      
print('Displaying the snapshot block data #3...')
print('HBM SNAPSHOT READ CAPTURED OUTPUT')
print('-----------------------------')
print('Num hbm_read_tag_out rd_hbm_data_out')
for i in range(0, read_length):
  print('[%i] %i %i'%(i, hbm_out['rd_tag'][i], hbm_out['rd_data'][i] ))
#print 'hbm data out:'
#print hbm_out['rd_data'][0:read_length]
print('done')
print('tutorial complete')

