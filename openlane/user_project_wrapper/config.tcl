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

# Base Configurations. Don't Touch
# section begin

set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"
set ::env(ROUTING_CORES) 14

# YOU ARE NOT ALLOWED TO CHANGE ANY VARIABLES DEFINED IN THE FIXED WRAPPER CFGS 
source $::env(DESIGN_DIR)/fixed_dont_change/fixed_wrapper_cfgs.tcl

# YOU CAN CHANGE ANY VARIABLES DEFINED IN THE DEFAULT WRAPPER CFGS BY OVERRIDING THEM IN THIS CONFIG.TCL
source $::env(DESIGN_DIR)/fixed_dont_change/default_wrapper_cfgs.tcl

set script_dir [file dirname [file normalize [info script]]]

set ::env(DESIGN_NAME) user_project_wrapper
#section end

# User Configurations

## Source Verilog Files
set ::env(VERILOG_FILES) "\
	$::env(CARAVEL_ROOT)/verilog/rtl/defines.v \
	$script_dir/../../../../verilog/rtl/user_project_wrapper.v \
    $script_dir/../../../../verilog/rtl/soomrv.v \
	$script_dir/../../../../verilog/rtl/Core.v \
	$script_dir/../../../../verilog/rtl/InstrDecoder.v \
	$script_dir/../../../../verilog/rtl/IntALU.v \
	$script_dir/../../../../verilog/rtl/Load.v \
	$script_dir/../../../../verilog/rtl/AGU.v \
	$script_dir/../../../../verilog/rtl/StoreAGU.v \
	$script_dir/../../../../verilog/rtl/ProgramCounter.v \
	$script_dir/../../../../verilog/rtl/Rename.v \
	$script_dir/../../../../verilog/rtl/ROB.v \
	$script_dir/../../../../verilog/rtl/BranchPredictor.v \
	$script_dir/../../../../verilog/rtl/IndirectBranchPredictor.v \
	$script_dir/../../../../verilog/rtl/LoadBuffer.v \
	$script_dir/../../../../verilog/rtl/StoreQueue.v \
	$script_dir/../../../../verilog/rtl/Multiply.v \
	$script_dir/../../../../verilog/rtl/Divide.v \
	$script_dir/../../../../verilog/rtl/ControlRegs.v \
	$script_dir/../../../../verilog/rtl/PopCnt.v \
	$script_dir/../../../../verilog/rtl/BranchSelector.v \
	$script_dir/../../../../verilog/rtl/Fuse.v \
	$script_dir/../../../../verilog/rtl/PreDecode.v \
	$script_dir/../../../../verilog/rtl/RenameTable.v \
	$script_dir/../../../../verilog/rtl/TagBuffer.v \
	$script_dir/../../../../verilog/rtl/IssueQueue.v \
	$script_dir/../../../../verilog/rtl/CacheController.v \
	$script_dir/../../../../verilog/rtl/MemoryController.v \
	$script_dir/../../../../verilog/rtl/SRAMWrapperDC.v \
	$script_dir/../../../../verilog/rtl/SRAMWrapperIC.v \
	$script_dir/../../../../verilog/rtl/PCFile.v \
	$script_dir/../../../../verilog/rtl/LoadStoreUnit.v \
	$script_dir/../../../../verilog/rtl/TageTable.v \
	$script_dir/../../../../verilog/rtl/TagePredictor.v \
	$script_dir/../../../../verilog/rtl/BranchTargetBuffer.v \
	$script_dir/../../../../verilog/rtl/ICacheTable.v \
	$script_dir/../../../../verilog/rtl/BranchPredictionTable.v \
	$script_dir/../../../../verilog/rtl/ReturnStack.v \
	$script_dir/../../../../verilog/rtl/FPU.v \
	$script_dir/../../../../verilog/rtl/FMul.v \
	$script_dir/../../../../verilog/rtl/FDiv.v \
    $script_dir/../../../../verilog/rtl/hardfloat/addRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/compareRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/fNToRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/HardFloat_primitives.v \
    $script_dir/../../../../verilog/rtl/hardfloat/HardFloat_specialize.v \
    $script_dir/../../../../verilog/rtl/hardfloat/recFNToIN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/recFNToFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/mulRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/HardFloat_rawFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/isSigNaNRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/iNToRecFN.v \
    $script_dir/../../../../verilog/rtl/hardfloat/divSqrtRecFN_small.v \
	$script_dir/../../../../verilog/rtl/LZCnt.v"

## Clock configurations
set ::env(CLOCK_PORT) "user_clock2"
set ::env(CLOCK_NET) "user_clock2"

set ::env(CLOCK_PERIOD) "20"

## Internal Macros
### Macro PDN Connections
set ::env(FP_PDN_MACRO_HOOKS) {dcache.sram0 vccd1 vssd1 vccd1 vssd1,dcache.sram1 vccd1 vssd1 vccd1 vssd1,icache.sram0 vccd1 vssd1 vccd1 vssd1,icache.sram1 vccd1 vssd1 vccd1 vssd1,core.rf vccd1 vssd1 vccd1 vssd1}

# set ::env(SYNTH_DEFINES) "USE_POWER_PINS"

puts $::env(FP_PDN_MACRO_HOOKS)
### Macro Placement
set ::env(MACRO_PLACEMENT_CFG) "$script_dir/../../macro.cfg"
set ::env(PL_MACRO_HALO) {20 20}
set ::env(PL_MACRO_CHANNEL) {20 20}
#set ::env(FP_PDN_HORIZONTAL_HALO) {20}
#set ::env(FP_PDN_VERTICAL_HALO) {20}
#set ::env(FP_TAP_HORIZONTAL_HALO) {30}
#set ::env(FP_TAP_VERTICAL_HALO) {30}

### Black-box verilog and views
set ::env(VERILOG_FILES_BLACKBOX) "\
	$::env(CARAVEL_ROOT)/verilog/rtl/defines.v \
    $::env(PDK_ROOT)/sky130B/libs.ref/sky130_sram_macros/verilog/sky130_sram_2kbyte_1rw1r_32x512_8.v \
    $script_dir/../../../../verilog/gl/RF.v"

set ::env(EXTRA_LEFS) "\
    $::env(PDK_ROOT)/sky130B/libs.ref/sky130_sram_macros/lef/sky130_sram_2kbyte_1rw1r_32x512_8.lef \
    $script_dir/../../../../lef/RF.lef"

set ::env(EXTRA_GDS_FILES) "\
    $::env(PDK_ROOT)/sky130B/libs.ref/sky130_sram_macros/gds/sky130_sram_2kbyte_1rw1r_32x512_8.gds \
    $script_dir/../../../../gds/RF.gds"

set ::env(GRT_OVERFLOW_ITERS) 60
set ::env(GRT_ALLOW_CONGESTION) 1

set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(GRT_RESIZER_TIMING_OPTIMIZATIONS) 0 

# set ::env(GLB_RT_MAXLAYER) 5
set ::env(RT_MAX_LAYER) {met4}

# disable pdn check nodes becuase it hangs with multiple power domains.
# any issue with pdn connections will be flagged with LVS so it is not a critical check.
set ::env(FP_PDN_CHECK_NODES) 0

set ::env(FP_CORE_UTIL) 40
set ::env(PL_BASIC_PLACEMENT) 0
set ::env(PL_TARGET_DENSITY) 0.28
set ::env(SYNTH_STRATEGY) "DELAY 4"

set ::env(PL_TIME_DRIVEN) 1
set ::env(PL_ROUTABILITY_DRIVEN) 1
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 1
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0

# Reduce routing on L2 for Metal Minimum Clear Area check
set ::env(GLB_RT_L2_ADJUSTMENT) 0.2
set ::env(GRT_ADJUSTMENT) {0.3}
set ::env(GRT_LAYER_ADJUSTMENTS) {0.99,0,0,0,0.2,0}

# 2 works, 4 kinda works but often fails detailed placement
set ::env(DIODE_INSERTION_STRATEGY) 4

set ::env(ROUTING_OPT_ITERS) 200


# The following is because there are no std cells in the example wrapper project.
#set ::env(SYNTH_TOP_LEVEL) 1
#set ::env(PL_RANDOM_GLB_PLACEMENT) 1
#
#set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
#set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
#set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
#set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0
#
#set ::env(FP_PDN_ENABLE_RAILS) 0
#
#set ::env(DIODE_INSERTION_STRATEGY) 0
#set ::env(FILL_INSERTION) 0
#set ::env(TAP_DECAP_INSERTION) 0
#set ::env(CLOCK_TREE_SYNTH) 0

set ::env(RUN_MAGIC) 1
set ::env(RUN_MAGIC_DRC) 0
set ::env(MAGIC_CONVERT_DRC_TO_RDB) 0
set ::env(QUIT_ON_MAGIC_DRC) 0
set ::env(QUIT_ON_TIMING_VIOLATIONS) 0
set ::env(QUIT_ON_HOLD_VIOLATIONS) 0
set ::env(QUIT_ON_SETUP_VIOLATIONS) 0

#set ::env(DPL_CELL_PADDING) 4
#set ::env(CELL_PAD) 4

#ram 300 3050 N
#mprj 60 500 N
#pram1 2000 50 S
#pram0 300 50 S


#ram0 100 2737 E
#ram1 880 2737 E
#ram2 1560 2737 E
#ram3 2240 2737 E
#pram0 100 100 E
#pram1 880 100 E
#pram2 1560 100 E
#pram3 2240 100 E
