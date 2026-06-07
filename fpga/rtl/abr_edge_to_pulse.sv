// abr_edge_to_pulse.sv - Converts rising edge on input to output pulse
// ToDo: Make it configurable to select edge and pulse polarity

module abr_edge_to_pulse (
  input  logic  clk_i,
  input  logic  rstn_i,
  input  logic  edge_i,

  output logic pulse_o
);

  logic edge_q;
  logic edge_detect, edge_detect_q;

  assign edge_detect = edge_i & ~edge_q;
  assign pulse_o     = edge_detect_q;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (~rstn_i) begin
      edge_q        <= '0;
      edge_detect_q <= '0;
    end else begin
      edge_q        <= edge_i;
      edge_detect_q <= edge_detect;
    end
  end

endmodule : abr_edge_to_pulse