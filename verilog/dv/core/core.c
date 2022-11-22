/*
 * SPDX-FileCopyrightText: 2020 Efabless Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: Apache-2.0
 */

// This include is relative to $CARAVEL_PATH (see Makefile)
#include <defs.h>
#include <stub.c>

/*
	Wishbone Test:
		- Configures MPRJ lower 8-IO pins as outputs
		- Checks counter value through the wishbone port
*/

void main()
{

	/* 
	IO Control Registers
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 3-bits | 1-bit | 1-bit | 1-bit  | 1-bit  | 1-bit | 1-bit   | 1-bit   | 1-bit | 1-bit | 1-bit   |
	Output: 0000_0110_0000_1110  (0x1808) = GPIO_MODE_USER_STD_OUTPUT
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 110    | 0     | 0     | 0      | 0      | 0     | 0       | 1       | 0     | 0     | 0       |
	
	 
	Input: 0000_0001_0000_1111 (0x0402) = GPIO_MODE_USER_STD_INPUT_NOPULL
	| DM     | VTRIP | SLOW  | AN_POL | AN_SEL | AN_EN | MOD_SEL | INP_DIS | HOLDH | OEB_N | MGMT_EN |
	| 001    | 0     | 0     | 0      | 0      | 0     | 0       | 0       | 0     | 1     | 0       |
	*/

	/* Set up the housekeeping SPI to be connected internally so	*/
	/* that external pin changes don't affect it.			*/

    reg_spi_enable = 1;
    reg_wb_enable = 1;
	// reg_spimaster_config = 0xa002;	// Enable, prescaler = 2,
                                        // connect to housekeeping SPI

	// Connect the housekeeping SPI to the SPI master
	// so that the CSB line is not left floating.  This allows
	// all of the GPIO pins to be used for user functions.

    reg_mprj_io_37 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_36 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_35 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_34 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_33 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_32 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_31 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_30 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_29 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_28 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_27 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_26 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_25 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_24 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_23 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_22 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_20 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_16 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_15 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_9 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_8 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_7 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_6 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_5 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    //reg_mprj_io_4 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    //reg_mprj_io_3 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    //reg_mprj_io_2 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    //reg_mprj_io_1 = GPIO_MODE_USER_STD_BIDIRECTIONAL;
    reg_mprj_io_0 = GPIO_MODE_USER_STD_BIDIRECTIONAL;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

	reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]

    // Flag start of the test
	reg_mprj_datal = 0xAB600000;

    // Make sure core is disabled
    reg_mprj_slave = 0b0110;

    // Write Instructions
    /*
    00000000 <_start>:
    0:   00001137                lui     sp,0x1
    4:   80010113                addi    sp,sp,-2048 # 800 <.end+0x7dc>
    8:   008000ef                jal     ra,10 <main>
    c:   00100073                ebreak

    00000010 <main>:
    10:   00400293                li      t0,4
    14:   00128393                addi    t2,t0,1

    00000018 <.loop>:
    18:   00028303                lb      t1,0(t0)
    1c:   00128293                addi    t0,t0,1
    20:   fe031ce3                bnez    t1,18 <.loop>

    00000024 <.end>:
    24:   40728533                sub     a0,t0,t2
    28:   00a02223                sw      a0,4(zero) # 4 <_start+0x4>
    2c:   00100073                ebreak
    */

    // Write Program
    const uint32_t program[] = 
    {
        0x00001137,     
        0x80010113,     
        0x008000ef,     
        0x00100073,     
        0x00400293,    
        0x00128393,    
        0x00028303,    
        0x00128293,    
        0xfe031ce3,    
        0x40728533,    
        0x00a02223,    
        0x00100073,    
    };

    volatile uint32_t* pointer = (volatile uint32_t*)0x30020000;
    for (uint32_t i = 0; i < (sizeof(program) / sizeof(uint32_t)); i++)
    {
        *pointer++ = program[i];
    }
        /**((volatile uint32_t*)0x30020000) = 0x01000513;
    *((volatile uint32_t*)0x30020004) = 0xfff50513;
    *((volatile uint32_t*)0x30020008) = 0xfe051ee3;
    *((volatile uint32_t*)0x3002000c) = 0x00100073;*/

    // Write test string
    const char* string = "string with len 20  ";
    volatile char* pointerC = (volatile char*)0x30010004;

    while (*string != 0)
        *pointerC++ = *string++;
    *pointerC = 0;
    
    // Enable core
    reg_mprj_slave = 0b0001;

    // Wait until core has disabled itself with ebreak
    while ((reg_mprj_slave & (1))) ;
    
    // Enable access core sram
    reg_mprj_slave = 0b0110;

    // Get Result from 0x4
    uint32_t result = *((volatile char*)0x30010004);

    // Flag Successful Test if correct
    if (result == 20)
        reg_mprj_datal = 0xAB610000;
}
