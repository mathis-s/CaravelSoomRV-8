module PreDecode (
	clk,
	rst,
	ifetchValid,
	outEn,
	mispred,
	OUT_full,
	IN_instrs,
	OUT_instrs
);
	parameter NUM_INSTRS_IN = 8;
	parameter NUM_INSTRS_OUT = 4;
	parameter BUF_SIZE = 4;
	input wire clk;
	input wire rst;
	input wire ifetchValid;
	input wire outEn;
	input wire mispred;
	output reg OUT_full;
	input wire [(NUM_INSTRS_IN * 54) - 1:0] IN_instrs;
	output reg [(NUM_INSTRS_OUT * 70) - 1:0] OUT_instrs;
	integer i;
	reg [170:0] buffer [BUF_SIZE - 1:0];
	reg [$clog2(BUF_SIZE) - 1:0] bufIndexIn;
	reg [$clog2(BUF_SIZE) - 1:0] bufIndexOut;
	reg [$clog2(NUM_INSTRS_IN) - 1:0] subIndexOut;
	reg [$clog2(BUF_SIZE):0] freeEntries;
	always @(posedge clk) begin
		if (rst) begin
			bufIndexIn = 0;
			bufIndexOut = 0;
			for (i = 0; i < NUM_INSTRS_OUT; i = i + 1)
				OUT_instrs[i * 70] <= 0;
			freeEntries = BUF_SIZE;
		end
		else if (!mispred) begin
			if (outEn)
				for (i = 0; i < NUM_INSTRS_OUT; i = i + 1)
					if ((bufIndexOut != bufIndexIn) || (freeEntries == 0)) begin : sv2v_autoblock_1
						reg [170:0] cur;
						reg [15:0] instr;
						cur = buffer[bufIndexOut];
						instr = cur[0 + (subIndexOut * 16)+:16];
						if ((instr[1:0] == 2'b11) && (((bufIndexOut + 2'b01) != bufIndexIn) || (subIndexOut != cur[134-:3]))) begin
							OUT_instrs[(i * 70) + 37-:31] <= {buffer[bufIndexOut][170-:28], subIndexOut};
							OUT_instrs[i * 70] <= 1;
							if (subIndexOut == cur[134-:3]) begin
								bufIndexOut = bufIndexOut + 1;
								freeEntries = freeEntries + 1;
								subIndexOut = buffer[bufIndexOut][137-:3];
							end
							else
								subIndexOut = subIndexOut + 1;
							OUT_instrs[(i * 70) + 69-:32] <= {buffer[bufIndexOut][0 + (subIndexOut * 16)+:16], instr};
							OUT_instrs[(i * 70) + 6-:5] <= buffer[bufIndexOut][142-:5];
							OUT_instrs[(i * 70) + 1] <= buffer[bufIndexOut][128] && (buffer[bufIndexOut][131-:3] == subIndexOut);
							if (subIndexOut == buffer[bufIndexOut][134-:3]) begin
								bufIndexOut = bufIndexOut + 1;
								freeEntries = freeEntries + 1;
								subIndexOut = buffer[bufIndexOut][137-:3];
							end
							else
								subIndexOut = subIndexOut + 1;
						end
						else if (instr[1:0] != 2'b11) begin
							OUT_instrs[(i * 70) + 37-:31] <= {buffer[bufIndexOut][170-:28], subIndexOut};
							OUT_instrs[(i * 70) + 69-:32] <= {16'bxxxxxxxxxxxxxxxx, instr};
							OUT_instrs[(i * 70) + 6-:5] <= buffer[bufIndexOut][142-:5];
							OUT_instrs[(i * 70) + 1] <= buffer[bufIndexOut][128] && (buffer[bufIndexOut][131-:3] == subIndexOut);
							OUT_instrs[i * 70] <= 1;
							if (subIndexOut == cur[134-:3]) begin
								bufIndexOut = bufIndexOut + 1;
								freeEntries = freeEntries + 1;
								subIndexOut = buffer[bufIndexOut][137-:3];
							end
							else
								subIndexOut = subIndexOut + 1;
						end
						else
							OUT_instrs[i * 70] <= 0;
					end
					else
						OUT_instrs[i * 70] <= 0;
			if (ifetchValid && (((((((IN_instrs[0] || IN_instrs[54]) || IN_instrs[108]) || IN_instrs[162]) || IN_instrs[216]) || IN_instrs[270]) || IN_instrs[324]) || IN_instrs[378])) begin
				buffer[bufIndexIn][128] <= 0;
				for (i = 0; i < NUM_INSTRS_IN; i = i + 1)
					if (IN_instrs[i * 54]) begin
						buffer[bufIndexIn][0 + (i * 16)+:16] <= IN_instrs[(i * 54) + 53-:16];
						buffer[bufIndexIn][134-:3] <= i[2:0];
						if (IN_instrs[(i * 54) + 1]) begin
							buffer[bufIndexIn][128] <= 1;
							buffer[bufIndexIn][131-:3] <= i[2:0];
						end
					end
				for (i = NUM_INSTRS_IN - 1; i >= 0; i = i - 1)
					if (IN_instrs[i * 54]) begin
						buffer[bufIndexIn][137-:3] <= i[2:0];
						if (bufIndexIn == bufIndexOut)
							subIndexOut = i[2:0];
					end
				buffer[bufIndexIn][170-:28] <= IN_instrs[37-:28];
				buffer[bufIndexIn][142-:5] <= IN_instrs[6-:5];
				bufIndexIn = bufIndexIn + 1;
				freeEntries = freeEntries - 1;
			end
		end
		else begin
			bufIndexIn = 0;
			bufIndexOut = 0;
			for (i = 0; i < NUM_INSTRS_OUT; i = i + 1)
				OUT_instrs[i * 70] <= 0;
			freeEntries = BUF_SIZE;
		end
		OUT_full <= freeEntries == 0;
	end
endmodule
