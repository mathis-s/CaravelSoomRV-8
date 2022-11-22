module SRAMWrapper#
(
    parameter SIZE_IN_WORDS=1024,
    parameter WORD_SIZE=32,
    parameter ADDR_LEN=$clog2(SIZE_IN_WORDS)
)
(

    input wire clk,
    
    input wire nce0,
    input wire nwe0,
    input wire[ADDR_LEN-1:0] addr0,
    input wire[WORD_SIZE-1:0] wdata0,
    input wire[(WORD_SIZE/8)-1:0] wmask0,
    output reg[WORD_SIZE-1:0] rdata0,

    input wire nce1,
    input wire[ADDR_LEN-1:0] addr1,
    output reg[WORD_SIZE-1:0] rdata1
);
localparam LENGTH = (SIZE_IN_WORDS / 512);
localparam WIDTH = (WORD_SIZE / 32);

genvar i;
genvar j;

wire[WORD_SIZE-1:0] readData0[LENGTH-1:0];
wire[WORD_SIZE-1:0] readData1[LENGTH-1:0];

reg[ADDR_LEN-1:0] lastAddr0;
reg[ADDR_LEN-1:0] lastAddr1;

reg lastRe0;
reg lastRe1;

generate if (LENGTH > 1)
    always@(posedge clk) begin
        lastAddr0 <= addr0;
        lastAddr1 <= addr1;

        lastRe0 <= !nce0 && nwe0;
        lastRe1 <= !nce1;

        if (lastRe0) begin
            rdata0 <= readData0[lastAddr0[ADDR_LEN-1:9]];
        end

        if (lastRe1) begin
            rdata1 <= readData1[lastAddr1[ADDR_LEN-1:9]];
        end
    end
endgenerate

generate if (LENGTH == 1)
    always@(posedge clk) begin
        lastRe0 <= !nce0 && nwe0;
        lastRe1 <= !nce1;

        if (lastRe0) begin
            rdata0 <= readData0[0];
        end

        if (lastRe1) begin
            rdata1 <= readData1[0];
        end
    end
endgenerate

generate
    for (i = 0; i < LENGTH; i=i+1) begin
        for (j = 0; j < WIDTH; j=j+1) begin
            
            if (LENGTH == 1)
                sky130_sram_2kbyte_1rw1r_32x512_8 sram
                (
                    .clk0(clk),
                    .csb0(!(!nce0)),
                    .web0(nwe0),
                    .wmask0(wmask0[j*4+:4]),
                    .addr0(addr0[8:0]),
                    .din0(wdata0[j*32+:32]),
                    .dout0(readData0[i][j*32+:32]),

                    .clk1(clk),
                    .csb1(!(!nce1)),
                    .addr1(addr1[8:0]),
                    .dout1(readData1[i][j*32+:32])
                );
            else
                sky130_sram_2kbyte_1rw1r_32x512_8 sram
                (
                    .clk0(clk),
                    .csb0(!(!nce0 && addr0[ADDR_LEN-1:9] == i)),
                    .web0(nwe0),
                    .wmask0(wmask0[j*4+:4]),
                    .addr0(addr0[8:0]),
                    .din0(wdata0[j*32+:32]),
                    .dout0(readData0[i][j*32+:32]),

                    .clk1(clk),
                    .csb1(!(!nce1 && addr1[ADDR_LEN-1:9] == i)),
                    .addr1(addr1[8:0]),
                    .dout1(readData1[i][j*32+:32])
                );
        end
    end
endgenerate

endmodule