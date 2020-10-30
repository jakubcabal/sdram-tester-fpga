#!/usr/bin/python
#-------------------------------------------------------------------------------
# PROJECT: SDRAM TESTER FPGA
#-------------------------------------------------------------------------------
# AUTHORS: Jakub Cabal <jakubcabal@gmail.com>
# LICENSE: The MIT License, please read LICENSE file
#-------------------------------------------------------------------------------

from wishbone import wishbone
from tester import tester
from sys_module import sys_module

print("SDRAM TESTER FPGA:")
print("========================================")

wb = wishbone("COM4")
sm = sys_module(wb)
test = tester(wb,0x4000)

#sm.report()
test.run_test(True,False)
#test.show_stats()
test.run_test(False,False)
#test.show_stats()
test.run_test(True,True)
#test.show_stats()
test.run_test(False,True)
#test.show_stats()

wb.close()
