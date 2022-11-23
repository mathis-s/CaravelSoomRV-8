module FMul (
	clk,
	rst,
	en,
	IN_branch,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire [75:0] IN_branch;
	input wire [198:0] IN_uop;
	output reg [87:0] OUT_uop;
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
	wire [2:0] rm = 0;
	wire [32:0] mul;
	wire [4:0] mulFlags;
	mulRecFN #(
		8,
		24
	) mulRec(
		.control(0),
		.a(srcArec),
		.b(srcBrec),
		.roundingMode(rm),
		.out(mul),
		.exceptionFlags(mulFlags)
	);
	wire [31:0] fpResult;
	recFNToFN #(
		8,
		24
	) recode(
		.in(mul),
		.out(fpResult)
	);
	always @(posedge clk)
		if (rst)
			OUT_uop[0] <= 0;
		else if ((en && IN_uop[0]) && (!IN_branch[0] || ($signed(IN_uop[52-:7] - IN_branch[43-:7]) <= 0))) begin
			OUT_uop[55-:7] <= IN_uop[64-:7];
			OUT_uop[48-:5] <= IN_uop[57-:5];
			OUT_uop[43-:7] <= IN_uop[52-:7];
			OUT_uop[4-:3] <= 0;
			OUT_uop[0] <= 1;
			OUT_uop[36-:32] <= IN_uop[134-:32];
			OUT_uop[1] <= 0;
			OUT_uop[87-:32] <= fpResult;
		end
		else
			OUT_uop[0] <= 0;
endmodule
