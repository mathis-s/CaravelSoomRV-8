
module rf
#(parameter LENGTH=64, parameter WIDTH=32)
(
    input wire clk,
    
    input wire[5:0] waddr0,
    input wire[WIDTH-1:0] wdata0,
    input wire wen0,
    
    input wire[5:0] waddr1,
    input wire[WIDTH-1:0] wdata1,
    input wire wen1,
    
    input wire[5:0] waddr2,
    input wire[WIDTH-1:0] wdata2,
    input wire wen2,
    
    input wire[5:0] raddr0,
    output wire[WIDTH-1:0] rdata0,
    
    input wire[5:0] raddr1,
    output wire[WIDTH-1:0] rdata1,
    
    input wire[5:0] raddr2,
    output wire[WIDTH-1:0] rdata2,
    
    input wire[5:0] raddr3,
    output wire[WIDTH-1:0] rdata3
);

wire[LENGTH-1:0] wsel_bus0;
wire[LENGTH-1:0] wsel_bus1;
wire[LENGTH-1:0] wsel_bus2;

wire[LENGTH-1:0] rsel_bus0;
wire[LENGTH-1:0] rsel_bus1;
wire[LENGTH-1:0] rsel_bus2;
wire[LENGTH-1:0] rsel_bus3;

DEC6x64 wdec0
(
    .en(wen0),
    .in(waddr0),
    .out(wsel_bus0)
);
DEC6x64 wdec1
(
    .en(wen1),
    .in(waddr1),
    .out(wsel_bus1)
);
DEC6x64 wdec2
(
    .en(wen1),
    .in(waddr1),
    .out(wsel_bus1)
);

DEC6x64 rdec0
(
    .en(1'b1),
    .in(raddr0),
    .out(rsel_bus0)
);
DEC6x64 rdec1
(
    .en(1'b1),
    .in(raddr1),
    .out(rsel_bus1)
);
DEC6x64 rdec2
(
    .en(1'b1),
    .in(raddr2),
    .out(rsel_bus2)
);
DEC6x64 rdec3
(
    .en(1'b1),
    .in(raddr3),
    .out(rsel_bus3)
);

generate
    genvar i;
    for (i = 0; i < LENGTH; i=i+1) begin
        Register#(.WIDTH(WIDTH)) re
        (
            .clk(clk),
            .wen({wsel_bus2[i], wsel_bus1[i], wsel_bus0[i]}),
            .wdata0(wdata0),
            .wdata1(wdata1),
            .wdata2(wdata2),
            
            .nren({~rsel_bus3[i], ~rsel_bus2[i], ~rsel_bus1[i], ~rsel_bus0[i]}),
            .rdata0(rdata0),
            .rdata1(rdata1),
            .rdata2(rdata2),
            .rdata3(rdata3)
        );
    end
endgenerate
endmodule

module Register
#(parameter WIDTH=32)
(
    input wire clk,
    input wire[2:0] wen,
    
    input wire[WIDTH-1:0] wdata0,
    input wire[WIDTH-1:0] wdata1,
    input wire[WIDTH-1:0] wdata2,
    //input wire wdata3,
    
    input wire[3:0] nren,
    output wire[WIDTH-1:0] rdata0,
    output wire[WIDTH-1:0] rdata1,
    output wire[WIDTH-1:0] rdata2,
    output wire[WIDTH-1:0] rdata3
);

wire[WIDTH-1:0] in;
wire enclk;
wire[WIDTH-1:0] state;
wire write;

sky130_fd_sc_hd__or3_1 EN_OR
(
    .X(write),
    .A(wen[0]),
    .B(wen[1]),
    .C(wen[2])
);

sky130_fd_sc_hd__dlclkp_1 CLK_EN
(
    .GCLK(enclk),
    .GATE(write),
    .CLK(clk)
);

generate
    genvar i;
    for (i = 0; i < WIDTH; i=i+1) begin
        sky130_fd_sc_hd__a222oi_1 IN_MUX
        (
            .Y(in[i]),
            .A1(wen[0]),
            .A2(wdata0[i]),
            .B1(wen[1]),
            .B2(wdata1[i]),
            .C1(wen[2]),
            .C2(wdata2[i])
        );

        sky130_fd_sc_hd__dfxtp_1 FF
        (
            .D(in[i]),
            .Q(state[i]),
            .CLK(enclk)
        );

        sky130_fd_sc_hd__ebufn_2 OUT_BUF0
        (
            .Z(rdata0[i]),
            .A(state[i]),
            .TE_B(nren[0])
        );

        sky130_fd_sc_hd__ebufn_2 OUT_BUF1
        (
            .Z(rdata1[i]),
            .A(state[i]),
            .TE_B(nren[1])
        );

        sky130_fd_sc_hd__ebufn_2 OUT_BUF2
        (
            .Z(rdata2[i]),
            .A(state[i]),
            .TE_B(nren[2])
        );

        sky130_fd_sc_hd__ebufn_2 OUT_BUF3
        (
            .Z(rdata3[i]),
            .A(state[i]),
            .TE_B(nren[3])
        );
    end
endgenerate

endmodule


module DEC6x64 (
    input wire en,
    input wire[5:0] in,
    output wire[63:0] out
);

wire[7:0] sel;
DEC3x8 decRoot
(
    .EN(en),
    .A(in[5:3]),
    .SEL(sel)
);

generate
    genvar i;
    for (i = 0; i < 8; i=i+1) begin
        DEC3x8 decLeaf
        (
            .EN(sel[i]),
            .A(in[2:0]),
            .SEL(out[8*i+:8])
        );
    end
endgenerate

endmodule

// Following is copied from DFFRAM
/*Copyright ©2020-2021 The American University in Cairo and the Cloud V Project.

    This file is part of the DFFRAM Memory Compiler.
    See https://github.com/Cloud-V/DFFRAM for further info.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

module DEC3x8 (
    input           EN,
    input   [2:0]   A,
    output  [7:0]   SEL
);

    wire [2:0]      A_buf;
    wire            EN_buf;

    sky130_fd_sc_hd__clkbuf_2 ABUF[2:0] (.X(A_buf), .A(A));
    sky130_fd_sc_hd__clkbuf_2 ENBUF (.X(EN_buf), .A(EN));
    
    (* keep = "true" *) // AND0 tends to be optimized away on register files
    sky130_fd_sc_hd__nor4b_2   AND0 ( .Y(SEL[0])  , .A(A_buf[0]), .B(A_buf[1])  , .C(A_buf[2]), .D_N(EN_buf) ); // 000
    sky130_fd_sc_hd__and4bb_2   AND1 ( .X(SEL[1])  , .A_N(A_buf[2]), .B_N(A_buf[1]), .C(A_buf[0])  , .D(EN_buf) ); // 001
    sky130_fd_sc_hd__and4bb_2   AND2 ( .X(SEL[2])  , .A_N(A_buf[2]), .B_N(A_buf[0]), .C(A_buf[1])  , .D(EN_buf) ); // 010
    sky130_fd_sc_hd__and4b_2    AND3 ( .X(SEL[3])  , .A_N(A_buf[2]), .B(A_buf[1]), .C(A_buf[0])  , .D(EN_buf) );   // 011
    sky130_fd_sc_hd__and4bb_2   AND4 ( .X(SEL[4])  , .A_N(A_buf[0]), .B_N(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) ); // 100
    sky130_fd_sc_hd__and4b_2    AND5 ( .X(SEL[5])  , .A_N(A_buf[1]), .B(A_buf[0]), .C(A_buf[2])  , .D(EN_buf) );   // 101
    sky130_fd_sc_hd__and4b_2    AND6 ( .X(SEL[6])  , .A_N(A_buf[0]), .B(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) );   // 110
    sky130_fd_sc_hd__and4_2     AND7 ( .X(SEL[7])  , .A(A_buf[0]), .B(A_buf[1]), .C(A_buf[2])  , .D(EN_buf) ); // 111
endmodule
