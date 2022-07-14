#!/usr/bin/env python

'''
This script continually configures the FPGA, performs the walking ones HMC test for a particular HMC (mezz 0, 1, 2) and continues to perform the test until the loop_iteration count is complete. This just tests stability of the HMC.
\n\n 
Author: Adam Isaacson, June 2022.
'''
import casperfpga
import time
import sys
import logging
import os


# How many times to exectute the FPGA programming
loop_iteration = 1

# SKARAB BOARD
skarab_host = "skarab02080A-01"        
        
for i in range(0,loop_iteration):
  print ('loop iteration count %d out of %d\n' %(i, loop_iteration))
  print '###################################'
  print 'HMC TESTING MEZ0 START'
  print '##################################'
  os.system('python skarab_hmc_data_test_fc.py %s -m 0' %(skarab_host))
  print 'HMC TESTING MEZ0 END'
  print '###################################'
  print 'HMC TESTING MEZ1 START'
  print '##################################'
  os.system('python skarab_hmc_data_test_fc.py %s -m 1' %(skarab_host))       
  print 'HMC TESTING MEZ1 END'
  print '###################################'
  print 'HMC TESTING MEZ2 START'
  print '##################################'
  os.system('python skarab_hmc_data_test_fc.py %s -m 2' %(skarab_host))       
  print 'HMC TESTING MEZ2 END'
  print 'HMC TESTING COMPLETE'
 	    

