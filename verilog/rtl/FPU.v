module FPU (
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
	wire lessThan;
	wire equal;
	wire greaterThan;
	wire [4:0] compareFlags;
	compareRecFN #(
		8,
		24
	) compare(
		.a(srcArec),
		.b(srcBrec),
		.signaling(1'b1),
		.lt(lessThan),
		.eq(equal),
		.gt(greaterThan),
		.unordered(),
		.exceptionFlags(compareFlags)
	);
	wire [31:0] toInt;
	wire [2:0] intFlags;
	recFNToIN #(
		8,
		24,
		32
	) toIntRec(
		.control(0),
		.in(srcArec),
		.roundingMode(rm),
		.signedOut(IN_uop[70-:6] == 6'd12),
		.out(toInt),
		.intExceptionFlags(intFlags)
	);
	wire [32:0] fromInt;
	wire [4:0] fromIntFlags;
	iNToRecFN #(
		32,
		8,
		24
	) intToRec(
		.control(0),
		.signedIn(IN_uop[70-:6] == 6'd19),
		.in(IN_uop[198-:32]),
		.roundingMode(rm),
		.out(fromInt),
		.exceptionFlags(fromIntFlags)
	);
	wire [32:0] addSub;
	wire [4:0] addSubFlags;
	addRecFN #(
		8,
		24
	) addRec(
		.control(0),
		.subOp(IN_uop[70-:6] == 6'd5),
		.a(srcArec),
		.b(srcBrec),
		.roundingMode(rm),
		.out(addSub),
		.exceptionFlags(addSubFlags)
	);
	reg [32:0] recResult;
	always @(*)
		case (IN_uop[70-:6])
			6'd20, 6'd19: recResult = fromInt;
			default: recResult = addSub;
		endcase
	wire [31:0] fpResult;
	recFNToFN #(
		8,
		24
	) recode(
		.in(recResult),
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
			case (IN_uop[70-:6])
				6'd4, 6'd5, 6'd20, 6'd19: OUT_uop[87-:32] <= fpResult;
				6'd15: OUT_uop[87-:32] <= {31'b0000000000000000000000000000000, equal};
				6'd16: OUT_uop[87-:32] <= {31'b0000000000000000000000000000000, equal || lessThan};
				6'd17: OUT_uop[87-:32] <= {31'b0000000000000000000000000000000, lessThan};
				6'd7: OUT_uop[87-:32] <= {IN_uop[166], IN_uop[197:167]};
				6'd8: OUT_uop[87-:32] <= {!IN_uop[166], IN_uop[197:167]};
				6'd9: OUT_uop[87-:32] <= {IN_uop[198] ^ IN_uop[166], IN_uop[197:167]};
				6'd12, 6'd13: OUT_uop[87-:32] <= toInt;
				6'd10: OUT_uop[87-:32] <= (lessThan ? IN_uop[198-:32] : IN_uop[166-:32]);
				6'd11: OUT_uop[87-:32] <= (lessThan ? IN_uop[166-:32] : IN_uop[198-:32]);
				default:
					;
			endcase
		end
		else
			OUT_uop[0] <= 0;
endmodule
