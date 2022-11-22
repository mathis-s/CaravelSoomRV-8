module ReservationStation (
	clk,
	rst,
	frontEn,
	IN_DIV_doNotIssue,
	IN_MUL_doNotIssue,
	IN_stall,
	IN_uopValid,
	IN_uop,
	IN_loadFwdUOp,
	IN_resultValid,
	IN_resultUOp,
	IN_invalidate,
	IN_invalidateSqN,
	IN_nextCommitSqN,
	OUT_valid,
	OUT_uop,
	OUT_free
);
	parameter NUM_UOPS = 3;
	parameter QUEUE_SIZE = 8;
	parameter RESULT_BUS_COUNT = 3;
	parameter STORE_QUEUE_SIZE = 8;
	input wire clk;
	input wire rst;
	input wire frontEn;
	input wire IN_DIV_doNotIssue;
	input wire IN_MUL_doNotIssue;
	input wire [NUM_UOPS - 1:0] IN_stall;
	input wire [NUM_UOPS - 1:0] IN_uopValid;
	input wire [(NUM_UOPS * 140) - 1:0] IN_uop;
	input wire [138:0] IN_loadFwdUOp;
	input wire [RESULT_BUS_COUNT - 1:0] IN_resultValid;
	input wire [(RESULT_BUS_COUNT * 97) - 1:0] IN_resultUOp;
	input wire IN_invalidate;
	input wire [5:0] IN_invalidateSqN;
	input wire [5:0] IN_nextCommitSqN;
	output reg [NUM_UOPS - 1:0] OUT_valid;
	output reg [(NUM_UOPS * 140) - 1:0] OUT_uop;
	output reg [4:0] OUT_free;
	integer i;
	integer j;
	integer k;
	reg [4:0] freeEntries;
	reg [139:0] queue [QUEUE_SIZE - 1:0];
	reg [0:0] queueInfo [QUEUE_SIZE - 1:0];
	reg enqValid;
	reg [2:0] deqIndex [NUM_UOPS - 1:0];
	reg deqValid [NUM_UOPS - 1:0];
	reg [32:0] reservedWBs [NUM_UOPS - 1:0];
	always @(*) begin
		for (i = 0; i < NUM_UOPS; i = i + 1)
			deqValid[i] = 0;
		for (i = NUM_UOPS - 1; i >= 0; i = i - 1)
			begin : sv2v_autoblock_1
				reg [2:0] ids0 [7:0];
				reg [5:0] sqns0 [7:0];
				reg valid0 [7:0];
				reg [2:0] ids1 [3:0];
				reg [5:0] sqns1 [3:0];
				reg valid1 [3:0];
				reg [2:0] ids2 [1:0];
				reg [5:0] sqns2 [1:0];
				reg valid2 [1:0];
				deqValid[i] = 1'b0;
				deqIndex[i] = 3'bxxx;
				for (j = 0; j < QUEUE_SIZE; j = j + 1)
					begin
						ids0[j] = j[2:0];
						sqns0[j] = queue[j][49-:6];
						valid0[j] = 0;
						if (queueInfo[j][0] && (!deqValid[1] || (deqIndex[1] != j[2:0])))
							if ((((((((((((((queue[j][75] || (IN_resultValid[0] && (IN_resultUOp[64-:7] == queue[j][74-:7]))) || (IN_resultValid[1] && (IN_resultUOp[161-:7] == queue[j][74-:7]))) || (IN_resultValid[2] && (IN_resultUOp[258-:7] == queue[j][74-:7]))) || (((OUT_valid[0] && (OUT_uop[36-:6] != 0)) && (OUT_uop[43-:7] == queue[j][74-:7])) && (OUT_uop[3-:3] == 3'd0))) || (((OUT_valid[1] && (OUT_uop[176-:6] != 0)) && (OUT_uop[183-:7] == queue[j][74-:7])) && (OUT_uop[143-:3] == 3'd0))) && (((((queue[j][66] || (IN_resultValid[0] && (IN_resultUOp[64-:7] == queue[j][65-:7]))) || (IN_resultValid[1] && (IN_resultUOp[161-:7] == queue[j][65-:7]))) || (IN_resultValid[2] && (IN_resultUOp[258-:7] == queue[j][65-:7]))) || (((OUT_valid[0] && (OUT_uop[36-:6] != 0)) && (OUT_uop[43-:7] == queue[j][65-:7])) && (OUT_uop[3-:3] == 3'd0))) || (((OUT_valid[1] && (OUT_uop[176-:6] != 0)) && (OUT_uop[183-:7] == queue[j][65-:7])) && (OUT_uop[143-:3] == 3'd0)))) && ((i == 0) || (queue[j][3-:3] != 3'd3))) && ((i == 0) || (queue[j][3-:3] != 3'd4))) && ((i == 1) || (queue[j][3-:3] != 3'd2))) && ((i == 2) || (queue[j][3-:3] != 3'd1))) && ((i != 2) || (queue[j][3-:3] != 3'd0))) && (!IN_DIV_doNotIssue || (queue[j][3-:3] != 3'd3))) && (!IN_MUL_doNotIssue || (queue[j][3-:3] != 3'd2))) && (((queue[j][3-:3] != 3'd0) && (queue[j][3-:3] != 3'd4)) || !reservedWBs[i][0]))
								valid0[j] = 1;
					end
				for (j = 0; j < 4; j = j + 1)
					if (valid0[2 * j] && (!valid0[(2 * j) + 1] || ($signed(sqns0[2 * j] - sqns0[(2 * j) + 1]) < 0))) begin
						valid1[j] = 1;
						ids1[j] = ids0[2 * j];
						sqns1[j] = sqns0[2 * j];
					end
					else if (valid0[(2 * j) + 1]) begin
						valid1[j] = 1;
						ids1[j] = ids0[(2 * j) + 1];
						sqns1[j] = sqns0[(2 * j) + 1];
					end
					else begin
						valid1[j] = 0;
						ids1[j] = 3'bxxx;
						sqns1[j] = 6'bxxxxxx;
					end
				for (j = 0; j < 2; j = j + 1)
					if (valid1[2 * j] && (!valid1[(2 * j) + 1] || ($signed(sqns1[2 * j] - sqns1[(2 * j) + 1]) < 0))) begin
						valid2[j] = 1;
						ids2[j] = ids1[2 * j];
						sqns2[j] = sqns1[2 * j];
					end
					else if (valid1[(2 * j) + 1]) begin
						valid2[j] = 1;
						ids2[j] = ids1[(2 * j) + 1];
						sqns2[j] = sqns1[(2 * j) + 1];
					end
					else begin
						valid2[j] = 0;
						ids2[j] = 3'bxxx;
						sqns2[j] = 6'bxxxxxx;
					end
				for (j = 0; j < 1; j = j + 1)
					if (valid2[2 * j] && (!valid2[(2 * j) + 1] || ($signed(sqns2[2 * j] - sqns2[(2 * j) + 1]) < 0))) begin
						deqValid[i] = 1;
						deqIndex[i] = ids2[2 * j];
					end
					else if (valid2[(2 * j) + 1]) begin
						deqValid[i] = 1;
						deqIndex[i] = ids2[(2 * j) + 1];
					end
			end
	end
	reg [2:0] insertIndex [NUM_UOPS - 1:0];
	reg insertAvail [NUM_UOPS - 1:0];
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				insertAvail[i] = 0;
				insertIndex[i] = 3'bxxx;
				if (IN_uopValid[i])
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						if ((!queueInfo[j][0] && (((i == 0) || !insertAvail[0]) || (insertIndex[0] != j[2:0]))) && (((i <= 1) || !insertAvail[1]) || (insertIndex[1] != j[2:0]))) begin
							insertAvail[i] = 1;
							insertIndex[i] = j[2:0];
						end
			end
	always @(posedge clk) begin
		for (i = 0; i < NUM_UOPS; i = i + 1)
			reservedWBs[i] <= {1'b0, reservedWBs[i][32:1]};
		if (!rst) begin
			for (i = 0; i < RESULT_BUS_COUNT; i = i + 1)
				if (IN_resultValid[i])
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						begin
							if ((queue[j][75] == 0) && (queue[j][74-:7] == IN_resultUOp[(i * 97) + 64-:7]))
								queue[j][75] <= 1;
							if ((queue[j][66] == 0) && (queue[j][65-:7] == IN_resultUOp[(i * 97) + 64-:7]))
								queue[j][66] <= 1;
						end
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if ((OUT_valid[i] && (OUT_uop[(i * 140) + 36-:6] != 0)) && (OUT_uop[(i * 140) + 3-:3] == 3'd0))
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						begin
							if ((queue[j][75] == 0) && (queue[j][74-:7] == OUT_uop[(i * 140) + 43-:7]))
								queue[j][75] <= 1;
							if ((queue[j][66] == 0) && (queue[j][65-:7] == OUT_uop[(i * 140) + 43-:7]))
								queue[j][66] <= 1;
						end
		end
		if (rst) begin
			for (i = 0; i < QUEUE_SIZE; i = i + 1)
				queueInfo[i][0] <= 0;
			freeEntries = 8;
			OUT_free <= 8;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				reservedWBs[i] <= 0;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				OUT_valid[i] <= 0;
		end
		else if (IN_invalidate) begin
			for (i = 0; i < QUEUE_SIZE; i = i + 1)
				if ($signed(queue[i][49-:6] - IN_invalidateSqN) > 0) begin
					queueInfo[i][0] <= 0;
					if (queueInfo[i][0])
						freeEntries = freeEntries + 1;
				end
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (!IN_stall[i] || ($signed(OUT_uop[(i * 140) + 49-:6] - IN_invalidateSqN) > 0))
					OUT_valid[i] <= 0;
		end
		else begin
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (!IN_stall[i])
					if (deqValid[i]) begin
						OUT_uop[i * 140+:140] <= queue[deqIndex[i]];
						freeEntries = freeEntries + 1;
						OUT_valid[i] <= 1;
						queueInfo[deqIndex[i]][0] <= 0;
						reservedWBs[i] <= {queue[deqIndex[i]][3-:3] == 3'd3, reservedWBs[i][32:10], (queue[deqIndex[i]][3-:3] == 3'd2) | reservedWBs[i][9], reservedWBs[i][8:1]};
					end
					else
						OUT_valid[i] <= 0;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (frontEn && IN_uopValid[i]) begin : sv2v_autoblock_2
					reg [139:0] temp;
					temp = IN_uop[i * 140+:140];
					for (k = 0; k < RESULT_BUS_COUNT; k = k + 1)
						if (IN_resultValid[k]) begin
							if (!temp[75] && (temp[74-:7] == IN_resultUOp[(k * 97) + 64-:7]))
								temp[75] = 1;
							if (!temp[66] && (temp[65-:7] == IN_resultUOp[(k * 97) + 64-:7]))
								temp[66] = 1;
						end
					queue[insertIndex[i]] <= temp;
					queueInfo[insertIndex[i]][0] <= 1;
					freeEntries = freeEntries - 1;
				end
		end
		OUT_free <= freeEntries;
	end
endmodule
