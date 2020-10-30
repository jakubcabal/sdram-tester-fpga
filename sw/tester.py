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
        error_cnt   = self.wb.read(self.ba+0x1c)

        period = 1.0/0.100
        time = (tick_cnt*period)/1000000000
        bits = req_cnt*32
        thr = (bits/time)/1000000

        print("========================================")
        print("TESTER STATS:")
        print("========================================")
        print("Throughput:          %.2f Mbps" % thr)
        print("Total bits:          %d b" % bits)
        print("Total time:          %.2f s" % time)
        print("One period:          %.2f ns" % period)
        print("----------------------------------------")
        print("Length reg:          %d" % len_reg)
        print("Tick cnt:            %d" % tick_cnt)
        print("Reuest cnt:          %d" % req_cnt)
        print("RD Response cnt:     %d" % rdresp_cnt)
        print("Error cnt:           %d" % error_cnt)
        print("----------------------------------------\n")

    def run_test(self,write,rand):
        print("========================================")
        if (write and not rand):
            test_mode = 0x10
            print("WRITE SEQ TEST:")
        if (write and rand):
            test_mode = 0x30
            print("WRITE RAND TEST:")
        if (not write and not rand):
            test_mode = 0x00
            print("READ SEQ TEST:")
        if (not write and rand):
            test_mode = 0x20
            print("READ RAND TEST:")
        print("========================================")
        self.wb.write(self.ba+0x00,0x2) # clear test
        self.wb.write(self.ba+0x00,0x0) # clear test done
        if (write):
            self.wb.write(self.ba+0x08,0x04ffffff)
        else:
            self.wb.write(self.ba+0x08,0x03ffffff)
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

        tick_cnt   = self.wb.read(self.ba+0x10)
        req_cnt    = self.wb.read(self.ba+0x14)
        error_cnt  = self.wb.read(self.ba+0x1c)

        period = 1.0/0.100
        test_time = (tick_cnt*period)/1000000000
        bits = req_cnt*32
        thr = (bits/test_time)/1000000
        print("Test Throughput: %.2f Mbps" % thr)
        if (error_cnt > 0):
                print("Read data check failed.")

        print("----------------------------------------\n")
