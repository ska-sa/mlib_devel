import casperfpga,time

#Tutorial HBM (Alveo) Python Script to read back the HBM snap shot data and the registers

#parameters
#snapshot read length (can be adjusted)
read_length = 600; 


#Connecting to the Alveo U50
print('connecting to the Alveo U50...')
#Host1fpg - list all alveo u50s with ports using this command: casperfpga.utils.list_alveos('10.8.96.150')
f=casperfpga.CasperFpga('10.8.96.150', 7150)
print('done')

#program the Alveo U50
print('programming the Alveo U50...')
#First light HBM tutorial
f.get_system_information('au50_hbm_data_test_2022-11-23_1954.fpg')
f.transport.upload_to_ram_and_program('au50_hbm_data_test_2022-11-23_1954.fpg')
print('done')

#Set the data rate control
#False = write and read every 2nd clock cycle (HBM can handle the data rate: 240MHz x 256 bits/2 = 30.72bps)
#True = write and read every clock cycle (HBM can't handle the data rate: 240MHz x 256 bits = 61.44Gbps)
f.registers.reg_cntrl.write(data_rate_sel= False)

#arm the snap shots
print('arming snapshot blocks...')
f.snapshots.hbm_in_snap_ss.arm()
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
#time.sleep(3)

#grab the snapshots
print('reading the snapshots...')
hbm_in = f.snapshots.hbm_in_snap_ss.read(arm=False)['data']
hbm_out = f.snapshots.hbm_out_snap_ss.read(arm=False)['data']
print('done')

#disable the HBM write and read process
print('disabling the HBM write and read process...')
f.registers.reg_cntrl.write(wr_rd_en = False)
print('done')

#read back the status registers
print('reading back the status registers...')

print("hbm rd cnt:",f.registers.hbm_rd_cnt_link0.read_uint())
print("hbm wr cnt:",f.registers.hbm_wr_cnt_link0.read_uint())
print("hbm data valid out cnt:",f.registers.hbm_out_cnt_link0.read_uint())
print("hbm empty read cnt:",f.registers.hbm_empty_rd_cnt_link0.read_uint())
print("hbm empty write count cnt:",f.registers.hbm_empty_wr_cnt_link0.read_uint())
print("hbm wr err:",f.registers.hbm_wr_err_link0.read_uint())
print("hbm rd err:",f.registers.hbm_rd_err_link0.read_uint())
print("hbm status:",f.registers.hbm_status.read_uint())

print('done')
#read back the snapshot captured data
print('Displaying the snapshot block data...')
print('HBM SNAPSHOT CAPTURED INPUT')
print('-----------------------------')
print('Num wr_en wr_addr wr_data wr_rdy rd_en rd_addr rd_tag rd_rdy') 
for i in range(0, read_length):
  print('[%i] %i %i %i %i %i %i %i %i'% \
                                      (i, hbm_in['wr_en'][i], hbm_in['wr_addr'][i], \
                                       hbm_in['data'][i], hbm_in['wr_rdy'][i], \
                                       hbm_in['rd_en'][i], hbm_in['rd_addr'][i], \
                                        hbm_in['tag'][i], hbm_in['rd_rdy'][i] ))
#print 'write enable:'
#print hbm_in['wr_en'][0:read_length]
#print 'write address:'
#print hbm_in['wr_addr'][0:read_length]
#print 'write data:'
#print hbm_in['data'][0:read_length]
#print 'write ready:'
#print hbm_in['wr_rdy'][0:read_length]
#print 'read enable:'
#print hbm_in['rd_en'][0:read_length]
#print 'read address:'
#print hbm_in['rd_addr'][0:read_length]
#print 'read tag:'
#print hbm_in['tag'][0:read_length]
#print 'read ready:'
#print hbm_in['rd_rdy'][0:read_length]
print('HBM SNAPSHOT CAPTURED OUTPUT')
print('-----------------------------')
print('Num hbm_read_tag_out hbm_data_out')
for i in range(1, read_length):
  print('[%i] %i %i'%(i, hbm_out['tag'][i], hbm_out['data'][i] ))
#print 'hbm data out:'
#print hbm_out['data'][0:read_length]
#print 'hbm read tag out:'
#print hbm_out['tag'][0:read_length]



