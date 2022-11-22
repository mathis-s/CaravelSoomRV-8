module CacheTable (
	IN_addr,
	OUT_valid,
	OUT_paddr
);
	parameter SIZE = 16;
	parameter ASSOC = 4;
	parameter NUM_LOOKUPS = 2;
	input wire [(NUM_LOOKUPS * 26) - 1:0] IN_addr;
	output wire [NUM_LOOKUPS - 1:0] OUT_valid;
	output wire [(NUM_LOOKUPS * 6) - 1:0] OUT_paddr;
endmodule
