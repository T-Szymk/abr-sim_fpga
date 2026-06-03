
//  Xilinx True Dual Port RAM Byte Write, Write First Dual Clock RAM
//  This code implements a parameterizable true dual port memory (both ports can read and write).
//  The behavior of this RAM is when data is written, the new memory contents at the write
//  address are presented on the output port.

  parameter NB_COL = <col>;                       // Specify number of columns (number of bytes)
  parameter COL_WIDTH = <width>;                  // Specify column width (byte width, typically 8 or 9)
  parameter RAM_DEPTH = <depth>;                  // Specify RAM depth (number of entries)
  parameter RAM_PERFORMANCE = "HIGH_PERFORMANCE"; // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  parameter INIT_FILE = "";                       // Specify name/location of RAM initialization file if using one (leave blank if not)

  <wire_or_reg> [clogb2(RAM_DEPTH-1)-1:0] <addra>;  // Port A address bus, width determined from RAM_DEPTH
  <wire_or_reg> [clogb2(RAM_DEPTH-1)-1:0] <addrb>;  // Port B address bus, width determined from RAM_DEPTH
  <wire_or_reg> [(NB_COL*COL_WIDTH)-1:0] <dina>;  // Port A RAM input data
  <wire_or_reg> [(NB_COL*COL_WIDTH)-1:0] <dinb>;  // Port B RAM input data
  <wire_or_reg> <clka>;                           // Port A clock
  <wire_or_reg> <clkb>;                           // Port B clock
  <wire_or_reg> [NB_COL-1:0] <wea>;               // Port A write enable
  <wire_or_reg> [NB_COL-1:0] <web>;		  // Port B write enable
  <wire_or_reg> <ena>;                            // Port A RAM Enable, for additional power savings, disable BRAM when not in use
  <wire_or_reg> <enb>;                            // Port B RAM Enable, for additional power savings, disable BRAM when not in use
  <wire_or_reg> <rsta>;                           // Port A output reset (does not affect memory contents)
  <wire_or_reg> <rstb>;                           // Port B output reset (does not affect memory contents)
  <wire_or_reg> <regcea>;                         // Port A output register enable
  <wire_or_reg> <regceb>;                         // Port B output register enable
  wire [(NB_COL*COL_WIDTH)-1:0] <douta>; // Port A RAM output data
  wire [(NB_COL*COL_WIDTH)-1:0] <doutb>; // Port B RAM output data

  reg [(NB_COL*COL_WIDTH)-1:0] <ram_name> [RAM_DEPTH-1:0];
  reg [(NB_COL*COL_WIDTH)-1:0] <ram_data_a> = {(NB_COL*COL_WIDTH){1'b0}};
  reg [(NB_COL*COL_WIDTH)-1:0] <ram_data_b> = {(NB_COL*COL_WIDTH){1'b0}};

  // The following code either initializes the memory values to a specified file or to all zeros to match hardware
  generate
    if (INIT_FILE != "") begin: use_init_file
      initial
        $readmemh(INIT_FILE, <ram_name>, 0, RAM_DEPTH-1);
    end else begin: init_bram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < RAM_DEPTH; ram_index = ram_index + 1)
          <ram_name>[ram_index] = {(NB_COL*COL_WIDTH){1'b0}};
    end
  endgenerate

  generate
  genvar i;
     for (i = 0; i < NB_COL; i = i+1) begin: byte_write
       always @(posedge <clka>)
         if (<ena>)
           if (<wea>[i]) begin
             <ram_name>[<addra>][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <dina>[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
             <ram_data_a>[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <dina>[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end else begin
             <ram_data_a>[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <ram_name>[<addra>][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end

       always @(posedge <clkb>)
         if (<enb>)
           if (<web>[i]) begin
             <ram_name>[<addrb>][(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <dinb>[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
             <ram_data_b>[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <dinb>[(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end else begin
             <ram_data_b>[(i+1)*COL_WIDTH-1:i*COL_WIDTH] <= <ram_name>[addrb][(i+1)*COL_WIDTH-1:i*COL_WIDTH];
           end
     end
  endgenerate

  //  The following code generates HIGH_PERFORMANCE (use output register) or LOW_LATENCY (no output register)
  generate
    if (RAM_PERFORMANCE == "LOW_LATENCY") begin: no_output_register

      // The following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
       assign <douta> = <ram_data_a>;
       assign <doutb> = <ram_data_b>;

    end else begin: output_register

      // The following is a 2 clock cycle read latency with improve clock-to-out timing

      reg [(NB_COL*COL_WIDTH)-1:0] douta_reg = {(NB_COL*COL_WIDTH){1'b0}};
      reg [(NB_COL*COL_WIDTH)-1:0] doutb_reg = {(NB_COL*COL_WIDTH){1'b0}};

      always @(posedge <clka>)
        if (<rsta>)
          douta_reg <= {(NB_COL*COL_WIDTH){1'b0}};
        else if (regcea)
          douta_reg <= <ram_data_a>;

      always @(posedge <clkb>)
        if (<rstb>)
          doutb_reg <= {(NB_COL*COL_WIDTH){1'b0}};
        else if (<regceb>)
          doutb_reg <= <ram_data_b>;

      assign <douta> = douta_reg;
      assign <doutb> = doutb_reg;

    end
  endgenerate

  //  The following function calculates the address width based on specified RAM depth
  function integer clogb2;
    input integer depth;
      for (clogb2=0; depth>0; clogb2=clogb2+1)
        depth = depth >> 1;
  endfunction
							
						