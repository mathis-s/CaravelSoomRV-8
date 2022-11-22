module FDiv (
	clk,
	rst,
	en,
	IN_wbAvail,
	OUT_busy,
	IN_branch,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire IN_wbAvail;
	output wire OUT_busy;
	input wire [75:0] IN_branch;
	input wire [198:0] IN_uop;
	output reg [87:0] OUT_uop;
	wire [2:0] rm = 0;
	wire [32:0] srcArec;
	wire [32:0] srcBrec;
	fNToRecFN #(
		8,
		24
	) recA(
		.in(IN_uop[198-:32]),
		.out(srcArec)
	);
	fNToRecFN #(
		8,
		24
	) recB(
		.in(IN_uop[166-:32]),
		.out(srcBrec)
	);
	wire ready;
	assign OUT_busy = (!ready || (en && IN_uop[0])) || OUT_uop[0];
	wire outValid;
	wire [32:0] result;
	divSqrtRecFN_small #(
		8,
		24,
		0
	) fdiv(
		.nReset(!rst),
		.clock(clk),
		.control(1'b1),
		.inReady(ready),
		.inValid((en && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))),
		.sqrtOp(IN_uop[65]),
		.a(srcArec),
		.b(srcBrec),
		.roundingMode(rm),
		.outValid(outValid),
		.sqrtOpOut(),
		.out(result),
		.exceptionFlags()
	);
	wire [31:0] fpResult;
	recFNToFN #(
		8,
		24
	) recode(
		.in(result),
		.out(fpResult)
	);
	reg running;
	always @(posedge clk) begin
		if (rst)
			running <= 0;
		if (((!running && en) && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			OUT_uop[55-:7] <= IN_uop[64-:7];
			OUT_uop[48-:5] <= IN_uop[57-:5];
			OUT_uop[43-:7] <= IN_uop[52-:7];
			OUT_uop[4-:3] <= 0;
			OUT_uop[36-:32] <= IN_uop[134-:32];
			OUT_uop[1] <= 0;
			running <= 1;
		end
		else if ((running && outValid) && (!IN_branch[0] || ($signed(OUT_uop[43-:7] - IN_branch[43-:7]) <= 0))) begin
			OUT_uop[0] <= 1;
			OUT_uop[87-:32] <= fpResult;
			running <= 0;
		end
		else begin
			if (!(!IN_branch[0] || ($signed(OUT_uop[43-:7] - IN_branch[43-:7]) <= 0)) || IN_wbAvail)
				OUT_uop[0] <= 0;
			if (!(!IN_branch[0] || ($signed(OUT_uop[43-:7] - IN_branch[43-:7]) <= 0)))
				running <= 0;
		end
	end
endmodule
