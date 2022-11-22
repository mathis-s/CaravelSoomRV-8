module LoadBuffer (
	clk,
	rst,
	commitSqN,
	IN_stall,
	IN_uop,
	IN_branch,
	OUT_branch,
	OUT_maxLoadSqN
);
	parameter NUM_PORTS = 2;
	parameter NUM_ENTRIES = 16;
	input wire clk;
	input wire rst;
	input wire [6:0] commitSqN;
	input wire [1:0] IN_stall;
	input wire [(NUM_PORTS * 163) - 1:0] IN_uop;
	input wire [75:0] IN_branch;
	output reg [75:0] OUT_branch;
	output reg [6:0] OUT_maxLoadSqN;
	integer i;
	integer j;
	reg [37:0] entries [NUM_ENTRIES - 1:0];
	reg [6:0] baseIndex;
	wire [6:0] indexIn;
	reg mispredict [NUM_PORTS - 1:0];
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				entries[i][37] <= 0;
			baseIndex = 0;
			OUT_branch[0] <= 0;
			OUT_maxLoadSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
		else begin
			OUT_branch[0] <= 0;
			if (IN_branch[0]) begin
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if ($signed(entries[i][36-:7] - IN_branch[43-:7]) > 0)
						entries[i][37] <= 0;
				if (IN_branch[22])
					baseIndex = IN_branch[29-:7];
			end
			else if (entries[0][37] && ($signed(commitSqN - entries[0][36-:7]) > 0)) begin
				for (i = 0; i < (NUM_ENTRIES - 1); i = i + 1)
					entries[i] <= entries[i + 1];
				entries[NUM_ENTRIES - 1][37] <= 0;
				baseIndex = baseIndex + 1;
			end
			for (i = 0; i < NUM_PORTS; i = i + 1)
				if ((!IN_stall[i] && IN_uop[i * 163]) && (!IN_branch[0] || ($signed(IN_uop[(i * 163) + 44-:7] - IN_branch[43-:7]) <= 0)))
					if (i == 0) begin : sv2v_autoblock_1
						reg [$clog2(NUM_ENTRIES) - 1:0] index;
						index = IN_uop[(i * 163) + ((23 + $clog2(NUM_ENTRIES)) >= 24 ? 23 + $clog2(NUM_ENTRIES) : ((23 + $clog2(NUM_ENTRIES)) + ((23 + $clog2(NUM_ENTRIES)) >= 24 ? (23 + $clog2(NUM_ENTRIES)) - 23 : 25 - (23 + $clog2(NUM_ENTRIES)))) - 1)-:((23 + $clog2(NUM_ENTRIES)) >= 24 ? (23 + $clog2(NUM_ENTRIES)) - 23 : 25 - (23 + $clog2(NUM_ENTRIES)))] - baseIndex[$clog2(NUM_ENTRIES) - 1:0];
						entries[index][36-:7] <= IN_uop[(i * 163) + 44-:7];
						entries[index][29-:30] <= IN_uop[(i * 163) + 162-:30];
						entries[index][37] <= 1;
					end
					else if ((i == 1) && (IN_uop[261-:4] != 0)) begin : sv2v_autoblock_2
						reg temp;
						temp = 0;
						for (j = 0; j < NUM_ENTRIES; j = j + 1)
							if ((entries[j][37] && (entries[j][29-:30] == IN_uop[(i * 163) + 162-:30])) && ($signed(IN_uop[(i * 163) + 44-:7] - entries[j][36-:7]) <= 0))
								temp = 1;
						if (((IN_uop[0] && !IN_stall[0]) && ($signed(IN_uop[207-:7] - IN_uop[44-:7]) <= 0)) && (IN_uop[162-:30] == IN_uop[325-:30]))
							temp = 1;
						if (temp) begin
							OUT_branch[0] <= 1;
							OUT_branch[75-:32] <= IN_uop[(i * 163) + 88-:32] + (IN_uop[(i * 163) + 1] ? 2 : 4);
							OUT_branch[43-:7] <= IN_uop[(i * 163) + 44-:7];
							OUT_branch[29-:7] <= IN_uop[(i * 163) + 30-:7];
							OUT_branch[36-:7] <= IN_uop[(i * 163) + 37-:7];
							OUT_branch[21-:5] <= IN_uop[(i * 163) + 23-:5];
							OUT_branch[16-:16] <= IN_uop[(i * 163) + 18-:16];
							OUT_branch[22] <= 0;
						end
					end
			OUT_maxLoadSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
endmodule
