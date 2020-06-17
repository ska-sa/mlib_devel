module alveo_u280_infrastructure(
    input  sys_clk_buf_n,
    input  sys_clk_buf_p,

    output sys_clk0,
    output sys_clk180,
    output sys_clk270,

    output clk_200,

    output sys_rst,
    output sys_clk_rst_sync,
    output idelay_rdy
  );

  // Sys clk is 100MHz on the Aleo_U280
  wire sys_clk_ds;
  IBUFDS #(
    .IOSTANDARD("LVDS"),
    .DIFF_TERM("TRUE")
  ) ibufgds_sys_clk (
    .I (sys_clk_buf_p),
    .IB(sys_clk_buf_n),
    .O (sys_clk_ds)
  );

  wire fb_clk;

  wire sys_clk0_dcm;
  wire sys_clk180_dcm;
  wire sys_clk270_dcm;
  wire clk_200_dcm;

  wire clk_fb;

  wire pll_lock;

//   Alveo U280 Clock Trees (from alveo-u280-xdc.xdc)
//
//    1) AB-557-03 - ABRACON AB-557-03-HCHC-F-L-C-T @ 100.000Mhz Dual Output PCIe MEMs Oscillator
//
//      - OUT0--> SYS_CLK5_P/SYS_CLK5_N @ 100.000Mhz - PCIe REFCLK1 for x16 and Bifrucated x8 Lanes 8-15 Asynchronous Clocking
//                PINS: MGTREFCLK1P_225_AP13/MGTREFCLK1N_225_AP12
//
//      - OUT1--> SYSCLK_P/SYSCLK_P @ 100.000Mhz 1-to-4 Clock buffer
//           |
//           |--> SI53340-B-GM --> OUT0  SYSCLK0_P/SYSCLK0_N 100.000Mhz - System Clock for first DDR4 MIG interface and HBM Interfaces.
//                             |   PINS: IO_L12P_T1U_N10_GC_A08_D24_65/IO_L12N_T1U_N11_GC_A09_D25_65
//                             |
//                             |-> OUT1  SYSCLK1_P/SYSCLK1_N 100.000Mhz - System Clock for second DDR4 MIG interface.
//                             |   PINS: IO_L13P_T2L_N0_GC_QBC_69/IO_L13N_T2L_N1_GC_QBC_69
//                             |
//                             |-> OUT2  SYSCLK2_P/SYSCLK2_N 100.000Mhz - PCIe REFCLK1 for Bifrucated x8 Lanes 0-7 Asynchronous Clocking
//                             |   PINS: MGTREFCLK1P_227_AK13/MGTREFCLK1N_227_AK12
//                             |
//                             |-> OUT3  SYSCLK3_P/SYSCLK3_N 100.000Mhz - BANK 75 100Mhz Input clock
//                                 PINS: IO_L11P_T1U_N8_GC_75/IO_L11N_T1U_N9_GC_75

// Use SLR2 region: SYSCLK_P/SYSCLK_P @ 100.000Mhz 1-to-4 Clock buffer OUT3  SYSCLK3_P/SYSCLK3_N 100.000Mhz - BANK 75 100Mhz Input clock

  MMCM_BASE #(
   .BANDWIDTH          ("OPTIMIZED"), // Jitter programming ("HIGH","LOW","OPTIMIZED")
   .CLKFBOUT_MULT_F    (10), // Multiply value for all CLKOUT (5.0-64.0).
   .CLKFBOUT_PHASE     (0.0),
   .CLKIN1_PERIOD      (10.0), // Clock is 100 MHz
   .CLKOUT0_DIVIDE_F   (1.0), // Divide amount for CLKOUT0 (1.000-128.000).
   .CLKOUT0_DUTY_CYCLE (0.5),
   .CLKOUT1_DUTY_CYCLE (0.5),
   .CLKOUT2_DUTY_CYCLE (0.5),
   .CLKOUT3_DUTY_CYCLE (0.5),
   .CLKOUT4_DUTY_CYCLE (0.5),
   .CLKOUT5_DUTY_CYCLE (0.5),
   .CLKOUT6_DUTY_CYCLE (0.5),
   .CLKOUT0_PHASE      (0.0),
   .CLKOUT1_PHASE      (0.0),
   .CLKOUT2_PHASE      (270),
   .CLKOUT3_PHASE      (0.0),
   .CLKOUT4_PHASE      (0.0),
   .CLKOUT5_PHASE      (0.0),
   .CLKOUT6_PHASE      (0.0),
   .CLKOUT1_DIVIDE     (4),// 4=> 100MHz * 10 / 4 = 250MHz sys_clk used in simulink
   .CLKOUT2_DIVIDE     (4),// 4=> 100MHz * 10 / 4 = 250MHz sys_clk used in simulink
   .CLKOUT3_DIVIDE     (5),// 5=> 100MHz * 10 / 5 = 200MHz for clk200
   .CLKOUT4_DIVIDE     (10),// 10=> 100MHz * 10 / 10 = 100MHz for clk100
   .CLKOUT5_DIVIDE     (1),
   .CLKOUT6_DIVIDE     (1),
   .CLKOUT4_CASCADE    ("FALSE"),
   .CLOCK_HOLD         ("FALSE"),
   .DIVCLK_DIVIDE      (1), // Master division value (1-80)
   .REF_JITTER1        (0.0),
   .STARTUP_WAIT       ("FALSE")
  ) MMCM_BASE_inst (
   .CLKIN1   (sys_clk_ds),
   .CLKFBIN  (clk_fb),

   .CLKFBOUT  (clk_fb),
   .CLKFBOUTB (),

   .CLKOUT0  (),
   .CLKOUT0B (),
   .CLKOUT1  (sys_clk0_dcm),
   .CLKOUT1B (sys_clk180_dcm),
   .CLKOUT2  (sys_clk270_dcm),
   .CLKOUT2B (),
   .CLKOUT3  (clk_200_dcm),
   .CLKOUT3B (),
   .CLKOUT4  (),
   .CLKOUT5  (),
   .CLKOUT6  (),
   .LOCKED   (pll_lock),

   .PWRDWN   (1'b0),
   .RST      (1'b0)

  );


  BUFG bufg_sysclk[3:0](
    .I({sys_clk0_dcm, sys_clk180_dcm, sys_clk270_dcm, clk_200_dcm}),
    .O({sys_clk0,     sys_clk180,     sys_clk270,     clk_200})
  );
  
  /* reset gen */
  reg sys_rst_reg_z;
  reg sys_rst_reg;
  reg [15:0] sys_rst_counter;
  always @(posedge sys_clk0) begin
    sys_rst_reg_z <= sys_rst_reg;
    if (!pll_lock) begin
      sys_rst_reg     <= 1'b0;
      sys_rst_counter <= {16{1'b0}};
    end else begin
      if (sys_rst_counter == {16{1'b1}}) begin
        sys_rst_reg <= 1'b0;
        sys_rst_counter <= {16{1'b1}};
      end else begin
        sys_rst_reg <= 1'b1;
        sys_rst_counter <= sys_rst_counter + 16'd1;
      end
    end

  end
  assign sys_rst = sys_rst_reg_z & pll_lock;

  /* io delay reset */

  IDELAYCTRL #(
    .SIM_DEVICE("ULTRASCALE")
  ) idelayctrl_inst(
    .REFCLK(clk_200),
    .RST(sys_rst),
    .RDY(idelay_rdy)
  );
  
  reg rstR1 = 1'b1;
  reg rstR2 = 1'b1;
  reg rstR3 = 1'b1;
  reg rstR4 = 1'b1;
  assign sys_clk_rst_sync = rstR4;
 
  always @(posedge sys_clk0 or negedge pll_lock) begin
      if (~pll_lock) begin
          rstR1 <= 1'b1;
          rstR2 <= 1'b1;
          rstR3 <= 1'b1;
          rstR4 <= 1'b1;
      end else begin
          rstR1 <= 1'b0;
          rstR2 <= rstR1;
          rstR3 <= rstR2;
          rstR4 <= rstR3;
      end
  end

endmodule
