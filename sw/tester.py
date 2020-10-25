#!/usr/bin/python
#-------------------------------------------------------------------------------
# PROJECT: SDRAM TESTER FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
#-------------------------------------------------------------------------------

import time

class tester:
    def __init__(self, wishbone, base_addr):
        self.wb = wishbone
        self.ba = base_addr

    def show_stats(self):
        len_reg     = self.wb.read(self.ba+0x08)
        tick_cnt    = self.wb.read(self.ba+0x10)
        req_cnt     = self.wb.read(self.ba+0x14)
        rdresp_cnt  = self.wb.read(self.ba+0x18)

        period = 1.0/0.166
        time = (tick_cnt*period)/1000000000
        bits = req_cnt*32
        thr = (bits/time)/1000000

        print("========================================")
        print("TESTER STATS:")
        print("========================================")
        print("Troughput:           %f Mbps" % thr)
        print("Total bits:          %d b" % bits)
        print("Total time:          %f s" % time)
        print("One period:          %f ns" % period)
        print("----------------------------------------")
        print("Length reg:          %d" % len_reg)
        print("Tick cnt:            %d" % tick_cnt)
        print("Reuest cnt:          %d" % req_cnt)
        print("RD Response cnt:     %d" % rdresp_cnt)
        print("----------------------------------------\n")

    def run_test(self,write):
        print("========================================")
        if write:
            test_mode = 0x10
            print("WRITE TEST:")
        else:
            test_mode = 0x00
            print("READ TEST:")
        print("========================================")
        self.wb.write(self.ba+0x00,0x2) # clear test
        self.wb.write(self.ba+0x00,0x0) # clear test done
        #self.wb.write(self.ba+0x08,0x4fffffff) # run test
        self.wb.write(self.ba+0x00,0x1+test_mode) # run test
        print("Test Run...")
        status = self.wb.read(self.ba+0x04)
        status_cnt = 0
        while status == 0:
            status_cnt = status_cnt + 1
            time.sleep(1)
            status = self.wb.read(self.ba+0x04)
            #print("status:     %d" % status)
            if (status_cnt > 10):
                self.wb.write(self.ba+0x00,0x0) # stop test
                print("Test failed.")
                return

        self.wb.write(self.ba+0x00,0x0) # stop test
        print("Test completed.")
        print("----------------------------------------\n")
