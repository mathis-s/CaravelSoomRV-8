module LoadStoreUnit (
	clk,
	rst,
	IN_branch,
	IN_uopLd,
	IN_uopSt,
	OUT_MEM_re,
	OUT_MEM_readAddr,
	IN_MEM_readData,
	OUT_MEM_we,
	OUT_MEM_writeAddr,
	OUT_MEM_writeData,
	OUT_MEM_wm,
	IN_SQ_lookupMask,
	IN_SQ_lookupData,
	IN_CSR_data,
	OUT_CSR_we,
	OUT_uopLd,
	OUT_loadFwdValid,
	OUT_loadFwdTag
);
	input wire clk;
	input wire rst;
	input wire [75:0] IN_branch;
	input wire [162:0] IN_uopLd;
	input wire [68:0] IN_uopSt;
	output reg OUT_MEM_re;
	output reg [29:0] OUT_MEM_readAddr;
	input wire [31:0] IN_MEM_readData;
	output reg OUT_MEM_we;
	output reg [29:0] OUT_MEM_writeAddr;
	output reg [31:0] OUT_MEM_writeData;
	output reg [3:0] OUT_MEM_wm;
	input wire [3:0] IN_SQ_lookupMask;
	input wire [31:0] IN_SQ_lookupData;
	input wire [31:0] IN_CSR_data;
	output reg OUT_CSR_we;
	output reg [87:0] OUT_uopLd;
	output wire OUT_loadFwdValid;
	output wire [6:0] OUT_loadFwdTag;
	integer i;
	integer j;
	reg [162:0] uopLd_0;
	reg [162:0] uopLd_1;
	assign OUT_loadFwdValid = uopLd_0[0] || (IN_uopLd[0] && (IN_SQ_lookupMask == 4'b1111));
	assign OUT_loadFwdTag = (uopLd_0[0] ? uopLd_0[56-:7] : IN_uopLd[56-:7]);
	reg isCSRread_1;
	always @(*) begin
		OUT_MEM_readAddr = IN_uopLd[162:133];
		OUT_MEM_writeAddr = IN_uopSt[68:39];
		OUT_MEM_writeData = IN_uopSt[36-:32];
		OUT_MEM_wm = IN_uopSt[4-:4];
		if ((IN_uopLd[0] && (!IN_branch[0] || ($signed(IN_uopLd[44-:7] - IN_branch[43-:7]) <= 0))) && (IN_SQ_lookupMask != 4'b1111))
			OUT_MEM_re = 0;
		else
			OUT_MEM_re = 1;
		if (IN_uopSt[0]) begin
			if (IN_uopSt[68:61] == 8'hff) begin
				OUT_MEM_we = 1;
				OUT_CSR_we = 0;
			end
			else begin
				OUT_MEM_we = 0;
				OUT_CSR_we = 1;
			end
		end
		else begin
			OUT_MEM_we = 1;
			OUT_CSR_we = 1;
		end
	end
	always @(*) begin : sv2v_autoblock_1
		reg [31:0] result;
		reg [31:0] data;
		result = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		data[31:24] = (uopLd_1[98] ? uopLd_1[130:123] : (isCSRread_1 ? IN_CSR_data[31:24] : IN_MEM_readData[31:24]));
		data[23:16] = (uopLd_1[97] ? uopLd_1[122:115] : (isCSRread_1 ? IN_CSR_data[23:16] : IN_MEM_readData[23:16]));
		data[15:8] = (uopLd_1[96] ? uopLd_1[114:107] : (isCSRread_1 ? IN_CSR_data[15:8] : IN_MEM_readData[15:8]));
		data[7:0] = (uopLd_1[95] ? uopLd_1[106:99] : (isCSRread_1 ? IN_CSR_data[7:0] : IN_MEM_readData[7:0]));
		case (uopLd_1[91-:2])
			0: begin
				case (uopLd_1[93-:2])
					0: result[7:0] = data[7:0];
					1: result[7:0] = data[15:8];
					2: result[7:0] = data[23:16];
					3: result[7:0] = data[31:24];
				endcase
				result[31:8] = {24 {(uopLd_1[94] ? result[7] : 1'b0)}};
			end
			1: begin
				case (uopLd_1[93-:2])
					default: result[15:0] = data[15:0];
					2: result[15:0] = data[31:16];
				endcase
				result[31:16] = {16 {(uopLd_1[94] ? result[15] : 1'b0)}};
			end
			default: result = data;
		endcase
		OUT_uopLd[87-:32] = result;
		OUT_uopLd[55-:7] = uopLd_1[56-:7];
		OUT_uopLd[48-:5] = uopLd_1[49-:5];
		OUT_uopLd[43-:7] = uopLd_1[44-:7];
		OUT_uopLd[36-:32] = uopLd_1[88-:32];
		OUT_uopLd[0] = uopLd_1[0];
		OUT_uopLd[4-:3] = (uopLd_1[2] ? 3'd5 : 3'd0);
		OUT_uopLd[1] = uopLd_1[1];
	end
	always @(posedge clk)
		if (rst) begin
			uopLd_0[0] <= 0;
			uopLd_1[0] <= 0;
		end
		else begin
			uopLd_0[0] <= 0;
			uopLd_1[0] <= 0;
			if (uopLd_0[0] && (!IN_branch[0] || ($signed(uopLd_0[44-:7] - IN_branch[43-:7]) <= 0))) begin
				uopLd_1 <= uopLd_0;
				isCSRread_1 <= uopLd_0[162:155] == 8'hff;
			end
			if (IN_uopLd[0] && (!IN_branch[0] || ($signed(IN_uopLd[44-:7] - IN_branch[43-:7]) <= 0)))
				if ((IN_SQ_lookupMask == 4'b1111) && !(uopLd_0[0] && (!IN_branch[0] || ($signed(uopLd_0[44-:7] - IN_branch[43-:7]) <= 0)))) begin
					uopLd_1 <= IN_uopLd;
					uopLd_1[98-:4] <= IN_SQ_lookupMask;
					uopLd_1[130-:32] <= IN_SQ_lookupData;
				end
				else begin
					uopLd_0 <= IN_uopLd;
					uopLd_0[98-:4] <= IN_SQ_lookupMask;
					uopLd_0[130-:32] <= IN_SQ_lookupData;
				end
		end
endmodule
