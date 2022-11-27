module ControlRegs (
	clk,
	rst,
	IN_mispredFlush,
	IN_we,
	IN_wm,
	IN_writeAddr,
	IN_data,
	IN_re,
	IN_readAddr,
	OUT_data,
	IN_comValid,
	IN_branchMispred,
	IN_wbValid,
	IN_ifValid,
	IN_comBranch,
	OUT_irqAddr,
	IN_irqTaken,
	IN_irqSrc,
	IN_irqFlags,
	IN_irqMemAddr,
	OUT_SPI_cs,
	OUT_SPI_clk,
	OUT_SPI_mosi,
	IN_SPI_miso,
	OUT_mode,
	OUT_wmask,
	OUT_rmask,
	OUT_tmrIRQ,
	OUT_IO_busy
);
	parameter NUM_UOPS = 4;
	parameter NUM_WBS = 4;
	input wire clk;
	input wire rst;
	input wire IN_mispredFlush;
	input wire IN_we;
	input wire [3:0] IN_wm;
	input wire [6:0] IN_writeAddr;
	input wire [31:0] IN_data;
	input wire IN_re;
	input wire [6:0] IN_readAddr;
	output reg [31:0] OUT_data;
	input wire [NUM_UOPS - 1:0] IN_comValid;
	input wire IN_branchMispred;
	input wire [NUM_WBS - 1:0] IN_wbValid;
	input wire [NUM_UOPS - 1:0] IN_ifValid;
	input wire [NUM_UOPS - 1:0] IN_comBranch;
	output wire [31:0] OUT_irqAddr;
	input wire IN_irqTaken;
	input wire [31:0] IN_irqSrc;
	input wire [2:0] IN_irqFlags;
	input wire [31:0] IN_irqMemAddr;
	output reg OUT_SPI_cs;
	output reg OUT_SPI_clk;
	output reg OUT_SPI_mosi;
	input wire IN_SPI_miso;
	output wire [7:0] OUT_mode;
	output wire [63:0] OUT_wmask;
	output wire [63:0] OUT_rmask;
	output reg OUT_tmrIRQ;
	output wire OUT_IO_busy;
	integer i;
	reg reReg;
	reg weReg;
	reg [3:0] wmReg;
	reg [6:0] writeAddrReg;
	reg [6:0] readAddrReg;
	reg [31:0] dataReg;
	reg [63:0] cRegs64 [5:0];
	reg [31:0] cRegs [15:0];
	assign OUT_irqAddr = cRegs[1];
	reg [5:0] spiCnt;
	reg [25:0] tmrCnt;
	assign OUT_IO_busy = ((spiCnt > 0) || !IN_we) || !weReg;
	reg [3:0] ifetchValidReg;
	assign OUT_rmask = {cRegs[5], cRegs[4]};
	assign OUT_wmask = {cRegs[7], cRegs[6]};
	assign OUT_mode = cRegs[3][31:24];
	always @(posedge clk) begin
		OUT_tmrIRQ <= 0;
		ifetchValidReg <= IN_ifValid;
		if (rst) begin
			weReg <= 1;
			for (i = 0; i < 6; i = i + 1)
				cRegs64[i] <= 0;
			for (i = 0; i < 8; i = i + 1)
				cRegs[i] <= 0;
			OUT_SPI_clk <= 0;
			spiCnt <= 0;
			OUT_SPI_cs <= 1;
			OUT_SPI_mosi <= 0;
		end
		else begin
			if (OUT_SPI_clk == 1) begin
				OUT_SPI_clk <= 0;
				OUT_SPI_mosi <= cRegs[0][31];
			end
			else if (spiCnt != 0) begin
				OUT_SPI_clk <= 1;
				spiCnt <= spiCnt - 1;
				cRegs[0] <= {cRegs[0][30:0], IN_SPI_miso};
			end
			if (spiCnt == 0)
				OUT_SPI_cs <= 1;
			if (!weReg)
				if (writeAddrReg[5])
					;
				else begin
					if (wmReg[0])
						cRegs[writeAddrReg[3:0]][7:0] <= dataReg[7:0];
					if (wmReg[1])
						cRegs[writeAddrReg[3:0]][15:8] <= dataReg[15:8];
					if (wmReg[2])
						cRegs[writeAddrReg[3:0]][23:16] <= dataReg[23:16];
					if (wmReg[3])
						cRegs[writeAddrReg[3:0]][31:24] <= dataReg[31:24];
					if ((writeAddrReg[3:0] == 4'd3) && |wmReg[1:0])
						tmrCnt <= 0;
					if (writeAddrReg[4:0] == 0) begin
						case (wmReg)
							4'b1111: spiCnt <= 32;
							4'b1100: spiCnt <= 16;
							4'b1000: spiCnt <= 8;
							default:
								;
						endcase
						OUT_SPI_mosi <= dataReg[31];
						OUT_SPI_cs <= 0;
					end
				end
			if (!reReg)
				if (readAddrReg[5]) begin
					if (readAddrReg[0])
						OUT_data <= cRegs64[readAddrReg[3:1]][63:32];
					else
						OUT_data <= cRegs64[readAddrReg[3:1]][31:0];
				end
				else
					OUT_data <= cRegs[readAddrReg[3:0]];
			if (OUT_mode[0])
				if ((cRegs[3][15:0] != 0) && (cRegs[3][15:0] == tmrCnt[25:10])) begin
					OUT_tmrIRQ <= 1;
					tmrCnt <= 0;
				end
				else
					tmrCnt <= tmrCnt + 1;
			if (IN_irqTaken) begin
				cRegs[2] <= IN_irqSrc;
				cRegs[3][23:16] <= {6'b000000, IN_irqFlags[1:0]};
				cRegs[3][31:24] <= 0;
				tmrCnt <= 0;
			end
			reReg <= IN_re;
			weReg <= IN_we;
			wmReg <= IN_wm;
			readAddrReg <= IN_readAddr;
			writeAddrReg <= IN_writeAddr;
			dataReg <= IN_data;
			cRegs64[0] <= cRegs64[0] + 1;
			cRegs64[1] = cRegs64[1] + 1;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				begin
					if (ifetchValidReg[i])
						cRegs64[1] = cRegs64[1] + 1;
					if (IN_comValid[i] && !IN_mispredFlush)
						cRegs64[3] = cRegs64[3] + 1;
					if ((IN_comValid[i] && !IN_mispredFlush) && IN_comBranch[i])
						cRegs64[5] = cRegs64[5] + 1;
				end
			for (i = 0; i < NUM_WBS; i = i + 1)
				if (IN_wbValid[i])
					cRegs64[2] = cRegs64[2] + 1;
			if (IN_branchMispred)
				cRegs64[4] <= cRegs64[4] + 1;
		end
	end
endmodule
