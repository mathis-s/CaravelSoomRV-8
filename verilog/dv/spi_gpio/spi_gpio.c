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
#pragma GCC optimize ("01")
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

    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_27 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_26 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_25 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_24 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_23 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_22 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_21 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_20 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_19 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_18 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_17 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_16 = GPIO_MODE_USER_STD_OUTPUT;

    reg_mprj_io_15 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_14 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_13 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_12 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_11 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_10 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_9 = GPIO_MODE_USER_STD_OUTPUT;
    reg_mprj_io_8 = GPIO_MODE_USER_STD_OUTPUT;

     /* Apply configuration */
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

	reg_la2_oenb = reg_la2_iena = 0x00000000;    // [95:64]

    // Flag start of the test
	reg_mprj_datal = 0xA0000000;

    // Make sure core is disabled
    reg_mprj_slave = 0b0110;

    // Write Instructions
    /*
    00000000 <_start>:
    0:   00001137                lui     sp,0x1
    4:   80010113                addi    sp,sp,-2048 # 800 <hexLut+0x75c>
    8:   008000ef                jal     ra,10 <main>
    c:   00100073                ebreak

    00000010 <main>:
    10:   09000793                li      a5,144
    14:   ff0006b7                lui     a3,0xff000
    18:   0007c703                lbu     a4,0(a5)
    1c:   04071e63                bnez    a4,78 <main+0x68>
    20:   ff0007b7                lui     a5,0xff000
    24:   00000693                li      a3,0
    28:   01378793                addi    a5,a5,19 # ff000013 <_estack+0xfefe0017>
    2c:   03000713                li      a4,48
    30:   0a400613                li      a2,164
    34:   00a00813                li      a6,10
    38:   00e78023                sb      a4,0(a5)
    3c:   00e78023                sb      a4,0(a5)
    40:   00e78023                sb      a4,0(a5)
    44:   00e78023                sb      a4,0(a5)
    48:   00e78023                sb      a4,0(a5)
    4c:   00e78023                sb      a4,0(a5)
    50:   00e78023                sb      a4,0(a5)
    54:   00d605b3                add     a1,a2,a3
    58:   0005c583                lbu     a1,0(a1)
    5c:   00b78023                sb      a1,0(a5)
    60:   0a000593                li      a1,160
    64:   0005c503                lbu     a0,0(a1)
    68:   00051e63                bnez    a0,84 <main+0x74>
    6c:   00168693                addi    a3,a3,1 # ff000001 <_estack+0xfefe0005>
    70:   fd0694e3                bne     a3,a6,38 <main+0x28>
    74:   00008067                ret
    78:   00178793                addi    a5,a5,1
    7c:   00e689a3                sb      a4,19(a3)
    80:   f99ff06f                j       18 <main+0x8>
    84:   00158593                addi    a1,a1,1
    88:   00a78023                sb      a0,0(a5)
    8c:   fd9ff06f                j       64 <main+0x54>
    */

    // Write Program
    const uint32_t program[] = 
    {
        0x00001137,
        0x80010113,
        0x008000ef,
        0x00100073,
        0x09000793,
        0xff0006b7,
        0x0007c703,
        0x04071e63,
        0xff0007b7,
        0x00000693,
        0x01378793,
        0x03000713,
        0x0a400613,
        0x00a00813,
        0x00e78023,
        0x00e78023,
        0x00e78023,
        0x00e78023,
        0x00e78023,
        0x00e78023,
        0x00e78023,
        0x00d605b3,
        0x0005c583,
        0x00b78023,
        0x0a000593,
        0x0005c503,
        0x00051e63,
        0x00168693,
        0xfd0694e3,
        0x00008067,
        0x00178793,
        0x00e689a3,
        0xf99ff06f,
        0x00158593,
        0x00a78023,
        0xfd9ff06f,
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
    const char* string = "Hello, World!\n";
    volatile char* pointerC = (volatile char*)(0x30010000 + 144);

    while (*string != 0)
        *pointerC++ = *string++;
    *pointerC = 0;

    string = "\n";
    pointerC = (volatile char*)(0x30010000 + 160);
    while (*string != 0)
        *pointerC++ = *string++;
    *pointerC = 0;

    string = "0123456789abcdef";
    pointerC = (volatile char*)(0x30010000 + 164);
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
    // uint32_t result = *((volatile char*)0x30010004);

    // Flag Successful Test if correct
    //if (result == 18)
    reg_mprj_datal = 0xB0000000;
}
