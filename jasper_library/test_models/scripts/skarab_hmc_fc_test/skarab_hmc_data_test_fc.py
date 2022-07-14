import casperfpga,time, sys

#HMC (SKARAB) Python Script to perform a walking ones test that first writes the full number of bits (256 bits of data)
# and to all memory locations (2^27) for link 2 and then reads it back and compares to the data written to the memory - i.e. the expected read data in
#firmware. If the same then the HMC passes for that link, then link 3 is tested the same way. The test is automated. 
#If it passes then the HMC is working and if there is a fail then there is an issue with the address or data bits internally to the HMC or externally.
#This script only works on one HMC per a board for now.
#The above performs the walking ones test for the full 256 bit data width and full memory locations. 
#Walking ones: It derives its name from the pattern that is written to memory during the test. The walking ones
#for 256 bit wide memory involves writing a value of "0000...00000001" into the first location
#in read/write memory. The value is then shifted one position to the left so that the binary value is
#"0000...00000010". The value is written to the next location in memory. When the "1" is left shifted 
#out of the 256 bit value, the original value "0000...00000001" is reused and the left shifting begins from there.
#The pattern of left shift by one bit then writing the new value to the next memory location is repeated until all the 
#memory is written. Once the full hmc address range is written then the process waits to be reset before starting again
#Once all the memory is written then the memory is read location by location using firmware and compared to
#the left-shifted pattern originally written in firmware. This test is intended to uncover data or address bus problems both
#internal to the memory device as well as external. This can be used to verify for SDRAM and RAM.  



from optparse import OptionParser
#Mezz0 fpg Walking ones HMC Test
mezz0_fpg = 'skarab_hmc_data_test_fc_2022-07-09_2133.fpg'
#Mezz1 fpg walking ones HMC test
mezz1_fpg = 'skarab_hmc_data_test_fc_2022-07-09_2324.fpg'
#mezz2 fpg walking ones HMC test
mezz2_fpg = 'skarab_hmc_data_test_fc_2022-07-11_1755.fpg'
p = OptionParser()
p.set_usage('skarab_hmc_data_test_fc.py <BOARD_HOSTNAME_or_IP> [options]')
p.set_description(__doc__)
p.add_option('-m', '--mezz_site', dest='mezz', type=int, action='store', default=0,
    help='Specify the mezzanine to select [0, 1 or 2]')  
opts, args = p.parse_args(sys.argv[1:])

if args==[]:
    print 'Please specify a board hostname or IP address. \nExiting.'
    sys.exit()
else:
    host = args[0]
#if opts.mezz != '':
#    mezz_site = opts.mezz

#Connecting to the SKARAB 
print 'connecting to the SKARAB...'
f=casperfpga.CasperFpga(host=host)
print 'done'

#parameters
#snapshot read length (can be adjusted to 2^7)
read_length = 16

#snapshot reorder readlength (can be adjusted to 2^7)
read_reorder_length = 16

#Connecting to the SKARAB skarab020204-01
#print 'connecting to SKARAB...'
#f=casperfpga.CasperFpga('10.0.0.7')
#print 'done'

#fpg file
#fpg_file = 'skarab_hmc_data_test_fc_2022-07-08_2242.fpg'
#Mez0 without hmc_read_end_ext
#fpgfile = 'skarab_hmc_data_test_fc_2022-07-09_1413.fpg'
#Mez0 with hmc_read_end_ext - 128 clock cycles (Mezo)
#fpg_file = 'skarab_hmc_data_test_fc_2022-07-09_1750.fpg'
#Check to see how many reads have occurred for Link 2
link2_hmc_reorder_rd_en_cnt = 0
#Check to see if there have been any read or write failures for Link2
link2_hmc_fail_cnt = 0

#Check to see how many reads have occurred for Link 3
link3_hmc_reorder_rd_en_cnt = 0
#Check to see if there have been any read or write failures for Link2
link3_hmc_fail_cnt = 0

#program the SKARAB
print 'programming the SKARAB...'
if opts.mezz == 0:
  f.upload_to_ram_and_program(mezz0_fpg)
elif opts.mezz == 1:
  f.upload_to_ram_and_program(mezz1_fpg)
elif opts.mezz == 2:
  f.upload_to_ram_and_program(mezz2_fpg)
else:
  f.upload_to_ram_and_program(mezz0_fpg)
print 'done'

#HMC Link2 Pass Flag
hmc_link2_pass = 0

#HMC Link3 Pass Flag
hmc_link3_pass = 0


#set the data rate control
#data_rate_sel = False, then data is written to the HMC every second clock cycle  at 256bits/2*240MHz=30.72Gbps
#data_rate_sel = True, then data is written every clock cycle at 256bits x 240MHz = 61.44Gbps (HMC can't keep up with this rate, so
#don't use it! The data is also not aligned correctly for this rate
f.registers.reg_cntrl.write(data_rate_sel = False)  

#############################################################
#HMC LINK 2 TESTING START
#############################################################

#Set the HMC Software Register Control for writing to the HMC
#hmc_link_sel = False, Link 2 is selected, hmc_link_sel= True, Link 3 is
#selected
f.registers.reg_cntrl.write(hmc_link_sel = False)

#Disable write and read to the HMC
f.registers.reg_cntrl.write(wr_en = False)
f.registers.reg_cntrl.write(rd_en = False) 

#arm the snap shots - just for initial debugging
print 'arming snapshot blocks...'
f.snapshots.hmc_wr_snap_link2_ss.arm()
print 'done'

#start the write snap shot triggering and reset the counters
print 'triggering the write snapshots and reset the counters...'
f.registers.reg_cntrl.write(rst_wr = 'pulse')
f.registers.reg_cntrl.write(rst_rd = 'pulse')
print 'done'

#start the read snap shot triggering and reset the counters
#print 'triggering the read snapshots and reset the counters...'
#f.registers.reg_cntrl.write(rst_rd = 'pulse')
#print 'done'

#enable the HMC write process
print 'enabling the HMC write Link2 process...'
f.registers.reg_cntrl.write(wr_en= True)
print 'done'

#wait a few seconds for snap shots to fill and wr enable signals to propogate fully - needs to be more than 1 second or > 1.12s
time.sleep(2)

#grab the snapshots
print 'reading the write snapshots...'
hmc_in_link2 = f.snapshots.hmc_wr_snap_link2_ss.read(arm=False)['data'] 
print 'done'

#disable the HMC write prcoess when complete
#check write address register = 2^27-1 to know when done
print 'disabling the HMC write link 2 process when done...'
#wait here until all the HMC data is written to the HMC at the last memory location
while (f.registers.hmc_wr_end.read_uint() == 0):
  print 'Busy writing to the HMC...'
else:
  print 'HMC data for Link2 is done being written to...prepare for reading and comparison testing'
  f.registers.reg_cntrl.write(wr_en = False)
  print 'The Maximum write adddress is:', f.registers.reg_hmc_wr_address.read_uint()
print 'done'

#read back the status registers for link2
print 'reading back the write status registers for Link2...'

print "hmc empty wr cnt link2:",f.registers.hmc_empty_wr_cnt_link2.read_uint()
print "hmc wr error link2 cnt:",f.registers.hmc_wr_err_link2.read_uint()
print "hmc status:",f.registers.hmc_status.read_uint()

print 'NUMBER OF READ or WRITE FAILURES (AFTER WRITE):', f.registers.hmc_fail_cnt.read_uint()

print 'done'
#read back the snapshot captured data for link 2
print 'Displaying the snapshot block data for Link2...'
print 'HMC SNAPSHOT CAPTURED INPUT LINK2'
print '-----------------------------'
print 'Num wr_en wr_addr wr_data wr_rdy' 
for i in range(0, read_length):
  print '[%i] %i %i %i %i'% \
  (i, hmc_in_link2['wr_en'][i], hmc_in_link2['wr_addr'][i], \
  hmc_in_link2['data'][i], hmc_in_link2['wr_rdy'][i] )
print 'done'

#read back the values from the HMC Link 2
#all read addresses - see read_add_length parameter
#Disable write and enable read to the HMC
f.registers.reg_cntrl.write(rd_en = False)
#f.registers.reg_cntrl.write(rd_en = True)

#arm the snap shots - just for initial debugging
print 'arming snapshot blocks...'
f.snapshots.hmc_rd_snap_in_link2_ss.arm()
f.snapshots.hmc_rd_snap_out_link2_ss.arm()
f.snapshots.hmc_reorder_snap_ss.arm()
print 'done'

#start the read snap shot triggering and reset the counters
print 'triggering the read snapshots and reset the counters...'
f.registers.reg_cntrl.write(rst_rd = 'pulse')
print 'done'

print 'NUMBER OF READ or WRITE FAILURES (AFTER READ RESET):', f.registers.hmc_fail_cnt.read_uint()

#enable the HMC read process
print 'enabling the HMC read Link2 process...'
f.registers.reg_cntrl.write(rd_en= True)
print 'done'

#wait a few  seconds for snap shots to fill and rd enable signals to propogate - needs to be greater than 0.55seconds 
time.sleep(2)

print 'NUMBER OF READ or WRITE FAILURES (AFTER READ ENABLED):', f.registers.hmc_fail_cnt.read_uint()

#grab the snapshots
print 'reading the read snapshots...'
hmc_read_in_link2 = f.snapshots.hmc_rd_snap_in_link2_ss.read(arm=False)['data']
hmc_read_out_link2 = f.snapshots.hmc_rd_snap_out_link2_ss.read(arm=False)['data']
hmc_read_out_reorder_link2 = f.snapshots.hmc_reorder_snap_ss.read(arm=False)['data']
print 'done'

#disable the HMC read prcoess when complete
#check read address register = 2^27-1 to know when done. NB: There are more read cycles to ensure all the data is compared
print 'disabling the HMC read link 2 process when done...'
#wait here until all the HMC data is read from the HMC at the last memory location
while (f.registers.hmc_rd_end.read_uint() == 0):
  print 'Busy reading from the HMC...'
else:
  print 'HMC data for Link2 is done being read from...prepare for comparison testing'
  f.registers.reg_cntrl.write(rd_en = False)
  f.registers.reg_cntrl.write(wr_en = False)
  #It will be more than the write to ensure all data is compared
  print 'The Maximum read adddress is:', f.registers.reg_hmc_rd_address.read_uint()
print 'NUMBER OF READ or WRITE FAILURES (AFTER READING):', f.registers.hmc_fail_cnt.read_uint()  
#Disable Read

print 'NUMBER OF READ or WRITE FAILURES (AFTER WRITE DISABLED AND READ ENABLED):', f.registers.hmc_fail_cnt.read_uint()

#Read back the snap shot read input data
print 'Displaying the snapshot read input block data for Link2...'
print 'HMC SNAPSHOT CAPTURED READ INPUT LINK2'
print '--------------------------------------'
print 'Num rd_en rd_tag rd_address'

for i in range(0, read_length):

  #hmc_read_data_link2 = (f.registers.hmc_data_out_link2_255_224.read_uint()<<224) \
  #+ (f.registers.hmc_data_out_link2_223_192.read_uint()<<192) \
  #+ (f.registers.hmc_data_out_link2_191_160.read_uint()<<160) \
  #+ (f.registers.hmc_data_out_link2_159_128.read_uint()<<128) \
  #+ (f.registers.hmc_data_out_link2_127_96.read_uint()<<96) \
  #+ (f.registers.hmc_data_out_link2_95_64.read_uint()<<64) \
  #+ (f.registers.hmc_data_out_link2_63_32.read_uint()<<32) \
  #+ (f.registers.hmc_data_out_link2_31_0.read_uint());
  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 2
  print '[%i] %i %i %i'% \
  (i, hmc_read_in_link2['rd_en'][i], hmc_read_in_link2['rd_tag'][i], \
  hmc_read_in_link2['rd_address'][i])
print 'done'
#Read back the snap shot read input data
  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 2
print 'Displaying the snapshot read output block data for Link2...'
print 'HMC SNAPSHOT CAPTURED READ OUTPUT LINK2'
print '--------------------------------------'
print 'Num rd_exp_data rd_data rd_rdy rd_tag rd_data_valid hmc_reorder_rd_en_cnt hmc_fail_cnt' 

for i in range(0, read_length):

  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 2
  print '[%i] %i %i %i %i %i %i %i' % \
  (i, hmc_read_out_link2['rd_expected_data'][i], hmc_read_out_link2['data'][i], \
  hmc_read_out_link2['rd_rdy'][i], hmc_read_out_link2['rd_tag'][i], hmc_read_out_link2['rd_data_valid'][i], \
  hmc_read_out_link2['hmc_reorder_rd_en_cnt'][i], hmc_read_out_link2['hmc_fail_cnt'][i])
print 'done'

#read back the snapshot captured reorder data for link 2
print 'Displaying the snapshot read output reorder block data for Link2...'
print 'HMC SNAPSHOT CAPTURED READ REORDER OUTPUT LINK2'
print '----------------------------------------------'
print 'Num data rd_en rd_addr expected_data'

for i in range(0, read_reorder_length):

  #read back the snapshot captured data for link 2
  print '[%i] %i %i %i %i' % \
  (i, hmc_read_out_reorder_link2['data'][i], hmc_read_out_reorder_link2['rd_en'][i], \
  hmc_read_out_reorder_link2['rd_addr'][i], hmc_read_out_reorder_link2['expected_data'][i])
print 'done'

#Read back read status
print 'reading back the read status registers for Link2...'
print "hmc empty rd cnt link2:",f.registers.hmc_empty_rd_cnt_link2.read_uint()
print "hmc rd error link2 cnt:",f.registers.hmc_rd_err_link2.read_uint()
print "hmc status:",f.registers.hmc_status.read_uint()

print 'done'


#Memory Test Pass Check for Link2
if(f.registers.hmc_fail_cnt.read_uint() >0):
  print 'HMC LINK 2 READ -  FAIL'
  hmc_link2_pass = 0  
else:
  print 'HMC LINK2 WRITE AND READ - PASS'
  hmc_link2_pass = 1
print 'NUMBER OF READ HMC REORDER READ ENABLE COUNTS',f.registers.hmc_reorder_rd_en_cnt.read_uint()+1 
print 'NUMBER OF READ or WRITE FAILURES:', f.registers.hmc_fail_cnt.read_uint()  
#Store these variables as the FPGA is reconfigured for Link3
link2_hmc_reorder_rd_en_cnt = f.registers.hmc_reorder_rd_en_cnt.read_uint()
link2_hmc_fail_cnt = f.registers.hmc_fail_cnt.read_uint()


#############################################################
#HMC LINK 2 TESTING END
#############################################################


##################################################################################################


#############################################################
#HMC LINK 3 TESTING START
#############################################################

#Reconfigure the FPGA for link 3 testing
#program the SKARAB
#program the SKARAB
print 'programming the SKARAB...'
if opts.mezz == 0:
  f.upload_to_ram_and_program(mezz0_fpg)
elif opts.mezz == 1:
  f.upload_to_ram_and_program(mezz1_fpg)
elif opts.mezz == 2:
  f.upload_to_ram_and_program(mezz2_fpg)
else:
  f.upload_to_ram_and_program(mezz0_fpg)
print 'done'

#set the data rate control
#data_rate_sel = False, then data is written to the HMC every second clock cycle  at 256bits/2*240MHz=30.72Gbps
#data_rate_sel = True, then data is written every clock cycle at 256bits x 240MHz = 61.44Gbps (HMC can't keep up with this rate, so
#don't use it! The data is also not aligned correctly for this rate
f.registers.reg_cntrl.write(data_rate_sel = False)

#Set the HMC Software Register Control for writing to the HMC
#hmc_link_sel = False, Link 2 is selected, hmc_link_sel= True, Link 3 is
#selected
f.registers.reg_cntrl.write(hmc_link_sel = True)

#Disable write and read to the HMC
f.registers.reg_cntrl.write(wr_en = False)

#Disable write and read to the HMC
f.registers.reg_cntrl.write(wr_en = False)
f.registers.reg_cntrl.write(rd_en = False)

#arm the snap shots - just for initial debugging
print 'arming snapshot blocks...'
f.snapshots.hmc_wr_snap_link3_ss.arm()
print 'done'

#start the write snap shot triggering and reset the counters
print 'triggering the write snapshots and reset the counters...'
f.registers.reg_cntrl.write(rst_wr = 'pulse')
f.registers.reg_cntrl.write(rst_rd = 'pulse')
print 'done'

#start the read snap shot triggering and reset the counters
#print 'triggering the read snapshots and reset the counters...'
#f.registers.reg_cntrl.write(rst_rd = 'pulse')
#print 'done'

#enable the HMC write process
print 'enabling the HMC write Link3 process...'
f.registers.reg_cntrl.write(wr_en= True)
print 'done'

#wait a few seconds for snap shots to fill and wr enable signals to propogate fully - needs to be more than 1 second or > 1.12s
time.sleep(2)

#grab the snapshots
print 'reading the write snapshots...'
hmc_in_link3 = f.snapshots.hmc_wr_snap_link3_ss.read(arm=False)['data']
print 'done'

#disable the HMC write prcoess when complete
#check write address register = 2^27-1 to know when done
print 'disabling the HMC write link 3 process when done...'
#wait here until all the HMC data is written to the HMC at the last memory location
while (f.registers.hmc_wr_end.read_uint() == 0):
  print 'Busy writing to the HMC...'
else:
  print 'HMC data for Link3 is done being written to...prepare for reading and comparison testing'
  f.registers.reg_cntrl.write(wr_en = False)
  print 'The Maximum write adddress is:', f.registers.reg_hmc_wr_address.read_uint()
print 'done'

#read back the status registers for link3
print 'reading back the write status registers for Link3...'

print "hmc empty wr cnt link3:",f.registers.hmc_empty_wr_cnt_link3.read_uint()
print "hmc wr error link3 cnt:",f.registers.hmc_wr_err_link3.read_uint()
print "hmc status:",f.registers.hmc_status.read_uint()
print 'NUMBER OF READ or WRITE FAILURES (AFTER WRITE):', f.registers.hmc_fail_cnt.read_uint()

print 'done'
#read back the snapshot captured data for link 3
print 'Displaying the snapshot block data for Link3...'
print 'HMC SNAPSHOT CAPTURED INPUT LINK3'
print '-----------------------------'
print 'Num wr_en wr_addr wr_data wr_rdy'
for i in range(0, read_length):
  print '[%i] %i %i %i %i'% \
  (i, hmc_in_link3['wr_en'][i], hmc_in_link3['wr_addr'][i], \
  hmc_in_link3['data'][i], hmc_in_link3['wr_rdy'][i] )
print 'done'

#read back the values from the HMC Link 3
#all read addresses - see read_add_length parameter
#Disable write and enable read to the HMC
f.registers.reg_cntrl.write(rd_en = False)
#f.registers.reg_cntrl.write(rd_en = True)

#arm the snap shots - just for initial debugging
print 'arming snapshot blocks...'
f.snapshots.hmc_rd_snap_in_link3_ss.arm()
f.snapshots.hmc_rd_snap_out_link3_ss.arm()
f.snapshots.hmc_reorder_snap_ss.arm()
print 'done'

#start the read snap shot triggering and reset the counters
print 'triggering the read snapshots and reset the counters...'
f.registers.reg_cntrl.write(rst_rd = 'pulse')
print 'done'

print 'NUMBER OF READ or WRITE FAILURES (AFTER READ RESET):', f.registers.hmc_fail_cnt.read_uint()

#enable the HMC read process
print 'enabling the HMC read Link3 process...'
f.registers.reg_cntrl.write(rd_en= True)
print 'done'

#wait a few  seconds for snap shots to fill and rd enable signals to propogate - needs to be greater than 0.55seconds 
time.sleep(2)

print 'NUMBER OF READ or WRITE FAILURES (AFTER READ ENABLED):', f.registers.hmc_fail_cnt.read_uint()

#grab the snapshots
print 'reading the read snapshots...'
hmc_read_in_link3 = f.snapshots.hmc_rd_snap_in_link3_ss.read(arm=False)['data']
hmc_read_out_link3 = f.snapshots.hmc_rd_snap_out_link3_ss.read(arm=False)['data']
hmc_read_out_reorder_link3 = f.snapshots.hmc_reorder_snap_ss.read(arm=False)['data']
print 'done'

#disable the HMC read prcoess when complete
#check read address register = 2^27-1 to know when done
print 'disabling the HMC read link 3 process when done...'
#wait here until all the HMC data is read from the HMC at the last memory location.
#check read address register = 2^27-1 to know when done. NB: There are more read cycles to ensure all the data is compared
while (f.registers.hmc_rd_end.read_uint() == 0):
  print 'Busy reading from the HMC...'
else:
  print 'HMC data for Link3 is done being read from...prepare for comparison testing'
  f.registers.reg_cntrl.write(rd_en = False)
  f.registers.reg_cntrl.write(wr_en = False)
  #This will be greater than 2^27-1 to ensure all read data is compared. There is a delay due to the reorder BRAM storage
  print 'The Maximum read adddress is:', f.registers.reg_hmc_rd_address.read_uint()
print 'NUMBER OF READ or WRITE FAILURES (AFTER READING):', f.registers.hmc_fail_cnt.read_uint()
#Disable Read

print 'NUMBER OF READ or WRITE FAILURES (AFTER WRITE DISABLED AND READ ENABLED):', f.registers.hmc_fail_cnt.read_uint()

#Read back the snap shot read input data
print 'Displaying the snapshot read input block data for Link3...'
print 'HMC SNAPSHOT CAPTURED READ INPUT LINK3'
print '--------------------------------------'
print 'Num rd_en rd_tag rd_address'

for i in range(0, read_length):

  #hmc_read_data_link3 = (f.registers.hmc_data_out_link3_255_224.read_uint()<<224) \
  #+ (f.registers.hmc_data_out_link3_223_192.read_uint()<<192) \
  #+ (f.registers.hmc_data_out_link3_191_160.read_uint()<<160) \
  #+ (f.registers.hmc_data_out_link3_159_128.read_uint()<<128) \
  #+ (f.registers.hmc_data_out_link3_127_96.read_uint()<<96) \
  #+ (f.registers.hmc_data_out_link3_95_64.read_uint()<<64) \
  #+ (f.registers.hmc_data_out_link3_63_32.read_uint()<<32) \
  #+ (f.registers.hmc_data_out_link3_31_0.read_uint());
  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 3
  print '[%i] %i %i %i'% \
  (i, hmc_read_in_link3['rd_en'][i], hmc_read_in_link3['rd_tag'][i], \
  hmc_read_in_link3['rd_address'][i])
print 'done'

#Read back the snap shot read input data
  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 3
print 'Displaying the snapshot read output block data for Link3...'
print 'HMC SNAPSHOT CAPTURED READ OUTPUT LINK3'
print '--------------------------------------'
print 'Num rd_exp_data rd_data rd_rdy rd_tag rd_data_valid hmc_reorder_rd_en_cnt hmc_fail_cnt'

for i in range(0, read_length):

  #Only print out the read address length - do not want to print out the full memory
  #read back the snapshot captured data for link 3
  print '[%i] %i %i %i %i %i %i %i' % \
  (i, hmc_read_out_link3['rd_expected_data'][i], hmc_read_out_link3['data'][i], \
  hmc_read_out_link3['rd_rdy'][i], hmc_read_out_link3['rd_tag'][i], hmc_read_out_link3['rd_data_valid'][i], \
  hmc_read_out_link3['hmc_reorder_rd_en_cnt'][i], hmc_read_out_link3['hmc_fail_cnt'][i])
print 'done'

#read back the snapshot captured reorder data for link 3
print 'Displaying the snapshot read output reorder block data for Link3...'
print 'HMC SNAPSHOT CAPTURED READ REORDER OUTPUT LINK3'
print '----------------------------------------------'
print 'Num data rd_en rd_addr expected_data'

for i in range(0, read_reorder_length):

  #read back the snapshot captured data for link 3
  print '[%i] %i %i %i %i' % \
  (i, hmc_read_out_reorder_link3['data'][i], hmc_read_out_reorder_link3['rd_en'][i], \
  hmc_read_out_reorder_link3['rd_addr'][i], hmc_read_out_reorder_link3['expected_data'][i])
print 'done'

#Read back read status
print 'reading back the read status registers for Link3...'
print "hmc empty rd cnt link3:",f.registers.hmc_empty_rd_cnt_link3.read_uint()
print "hmc rd error link3 cnt:",f.registers.hmc_rd_err_link3.read_uint()
print "hmc status:",f.registers.hmc_status.read_uint()

print 'done'

#Memory Test Pass Check for Link3
if(f.registers.hmc_fail_cnt.read_uint() >0):
  print 'HMC LINK 3 READ -  FAIL'
  hmc_link3_pass = 0
else:
  print 'HMC LINK3 WRITE AND READ - PASS'
  hmc_link3_pass = 1
print 'NUMBER OF READ HMC REORDER READ ENABLE COUNTS',f.registers.hmc_reorder_rd_en_cnt.read_uint()+1
print 'NUMBER OF READ or WRITE FAILURES:', f.registers.hmc_fail_cnt.read_uint()
link3_hmc_reorder_rd_en_cnt = f.registers.hmc_reorder_rd_en_cnt.read_uint()
link3_hmc_fail_cnt = f.registers.hmc_fail_cnt.read_uint()

#############################################################
#HMC LINK 3 TESTING END
#############################################################

#############################################################

#TOTAL LINK2 AND LINK3 HMC TEST RESULTS
print '######################################################'
#program the SKARAB
print 'programming the SKARAB...'
if opts.mezz == 0:
  print 'MEZZ 0 HMC TESTING STATUS'
elif opts.mezz == 1:
  print 'MEZZ 1 HMC TESTING STATUS'
elif opts.mezz == 2:
  print 'MEZZ 2 HMC TESTING STATUS'
else:
  print 'MEZZ 0 HMC TESTING STATUS'

#Link2 Test Results
if(hmc_link2_pass == True):

  print 'HMC WRITE/READ WALKING ONES TEST STATUS (LINK 2): PASS'
else:
  print 'HMC WRITE/READ WALKING ONES TEST STATUS (LINK 2): FAIL'
#Link 3 Test Results
if(hmc_link3_pass == True):

  print 'HMC WRITE/READ WALKING ONES TEST STATUS (LINK 3): PASS'
else:
  print 'HMC WRITE/READ WALKING ONES TEST STATUS (LINK 3): FAIL'
print 'NUMBER OF READ LINK2 HMC REORDER READ ENABLE COUNTS:', link2_hmc_reorder_rd_en_cnt+1
print 'NUMBER OF READ LINK3 HMC REORDER READ ENABLE COUNTS:', link3_hmc_reorder_rd_en_cnt+1
print 'NUMBER OF READ AND WRITE FAILURES FOR LINK2:', link2_hmc_fail_cnt
print 'NUMBER OF READ AND WRITE FAILURES FOR LINK3:', link3_hmc_fail_cnt
    
print '######################################################'










