module ExternalMemorySim (
	clk,
	en,
	bus
);
	parameter SIZE = 1048576;
	input wire clk;
	input wire en;
	inout wire [31:0] bus;
	integer i;
	reg oen = 0;
	reg [31:0] outBus;
	assign bus = (oen ? outBus : 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz);
	reg [31:0] mem [SIZE - 1:0];
	reg [31:0] addr;
	reg [1:0] state = 0;
	reg [2:0] waitCycles;

    initial begin
        for (i = 0; i < SIZE; i=i+1)
            mem[i] = 0;
        $readmemh("program.hex", mem);
        $display("First instruction: %x", mem[0]);
    end

	always @(posedge clk)
		case (state)
			0: begin
				if (en) begin
					addr <= bus;
					waitCycles <= 3;
					state <= 1;
				end
				oen <= 0;
			end
			1: begin
				if (waitCycles == 0)
					state <= (addr[31] ? 2 : 3);
				waitCycles <= waitCycles - 1;
			end
			2:
				if (en) begin
					mem[addr[19:0]] <= bus;
					addr[29:0] <= addr[29:0] + 1;
				end
				else
					state <= 0;
			3:
				if (en) begin
					outBus <= mem[addr[19:0]];
					addr[29:0] <= addr[29:0] + 1;
					oen <= 1;
				end
				else begin
					state <= 0;
					oen <= 0;
				end
		endcase
	wire [31:0] retAddr = mem[20'h3ffff];
endmodule
