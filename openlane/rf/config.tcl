# SPDX-FileCopyrightText: 2020 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0

set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"
#set ::env(STD_CELL_LIBRARY_OPT) "sky130_fd_sc_hs"
#set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hs"
set ::env(LIB_SYNTH_OPT) [list ]

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) RF

set ::env(VERILOG_FILES) "\
	$::env(CARAVEL_ROOT)/verilog/rtl/defines.v \
	$script_dir/../../../../verilog/rtl/RF.v"


set ::env(VERILOG_FILES_BLACKBOX) "\
    $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"

set ::env(SYNTH_READ_BLACKBOX_LIB) 1
set ::env(DESIGN_IS_CORE) 0

set ::env(ROUTING_CORES) 14
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_NET) "clk"
set ::env(CLOCK_PERIOD) "20"

set ::env(FP_SIZING) absolute
#set ::env(DIE_AREA) "0 0 1050 430"
set ::env(DIE_AREA) "0 0 590 820"

set ::env(FP_PIN_ORDER_CFG) $script_dir/../../pin_order.cfg

set ::env(PL_BASIC_PLACEMENT) 0
set ::env(FP_CORE_UTIL) 45
set ::env(PL_TARGET_DENSITY) 0.55
# Delay 1 had best results for now
set ::env(SYNTH_STRATEGY) "AREA 0"

set ::env(PL_TIME_DRIVEN) 1
set ::env(PL_ROUTABILITY_DRIVEN) 1
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0

set ::env(GRT_OVERFLOW_ITERS) 400
# Maximum layer used for routing is metal 4.
# This is because this macro will be inserted in a top level (user_project_wrapper) 
# where the PDN is planned on metal 5. So, to avoid having shorts between routes
# in this macro and the top level metal 5 stripes, we have to restrict routes to metal4.  
# 
set ::env(RT_MAX_LAYER) {met4}

# You can draw more power domains if you need to 
set ::env(VDD_NETS) [list {vccd1}]
set ::env(GND_NETS) [list {vssd1}]

set ::env(DIODE_INSERTION_STRATEGY) 3
# If you're going to use multiple power domains, then disable cvc run.
set ::env(RUN_CVC) 1
set ::env(QUIT_ON_MAGIC_DRC) 0
set ::env(QUIT_ON_TIMING_VIOLATIONS) 0
set ::env(QUIT_ON_HOLD_VIOLATIONS) 0
set ::env(QUIT_ON_SETUP_VIOLATIONS) 0

set ::env(SYNTH_BUFFERING) 0
set ::env(SYNTH_SIZING) 0

set ::env(GRT_ALLOW_CONGESTION) 1
set ::env(ROUTING_OPT_ITERS) 200
set ::env(CELL_PAD) 0
set ::env(DPL_CELL_PADDING) 0
#set ::env(FP_PDN_HORIZONTAL_HALO) 0
#set ::env(TAP_DECAP_INSERTION) 0

#set ::env(PL_MAX_DISPLACEMENT_X) 1000
#set ::env(PL_MAX_DISPLACEMENT_Y) 200


set ::env(global_verbose_level) 0
set ::env(GLOBAL_VERBOSE_LEVEL) 0
