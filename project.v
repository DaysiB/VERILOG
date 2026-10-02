/*
 * "DAYSI" ASIC audio/visual demo.
 * Modificado con decodificador de fuentes directo para "DAYSI",
 * flores, caritas felices y paleta rosa/amarillo.
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // Always 1
  input  wire       clk,      // Clock
  input  wire       rst_n     // Reset_n - low to reset
);

  // VGA Signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;

  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uio_out = 0;
  assign uio_oe  = 0;

  wire _unused_ok = &{ena, ui_in, uio_in};

  // VGA Coordinates Generator
  wire [9:0] x;
  wire [9:0] y;
  wire video_active;  
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );

  // Frame timing
  wire signed [9:0] frame = frame_counter[6:0];
  wire signed [9:0] offset_x = frame/2; 
  wire signed [9:0] offset_y = frame; 
  wire signed [9:0] center_x = 320 + offset_x;
  wire signed [9:0] center_y = 240 + offset_y;
  wire signed [9:0] p_x = x - center_x;
  wire signed [9:0] p_y = y - center_y;

  // Math for background dynamics
  reg signed [17:0] r1;
  reg signed [18:0] r2;
  wire signed [19:0] r = 2*(r1 - center_y*2) + r2 - center_x*2 + 2;

  always @(posedge clk) begin
    if (~rst_n) begin
      r1 <= 0;
      r2 <= 0;
    end else begin
      if (~vsync) begin
        r1 <= 0;
        r2 <= 0;
      end
      if (video_active & y == 0) begin
        if (x < center_y) r1 <= r1 + center_y;
      end else if (x == 640) begin
        r2 <= 320*320;
      end else if (x > 640) begin
        if (x-640 <= offset_x) r2 <= r2 + 2*320 + offset_x;
      end else if (video_active & x == 0) begin
        r1 <= r1 + 2*p_y + 1;
      end else if (video_active) begin
        r2 <= r2 + 2*p_x + 1;
      end
    end
  end

  // Visual Effects: Petals & Stripes
  wire signed [22:0] dot = (r * (128-frame)) >> (9+((frame[6:4]+1)>>1));
  wire [15:0] dot_sq = dot[7:0] * dot[7:0];
  wire zoom_mode = part == 5 | part == 6;
  wire signed [22:0] dot2 = (dot_sq * frame) >> (15 - 2*zoom_mode);

  wire [7:0] flower_petals = (p_x[5:0] ^ p_y[5:0]) + (r[11:4]);
  wire mode_a = part == 0 | part == 1 | part == 2 | part == 5;
  wire mode_b = part == 0 | part == 4;
  wire [7:0] stripes = (flower_petals & 8'h3F) + p_y*mode_a + p_x*mode_b;

  wire fractal_mode = part == 1 | part == 6;
  wire [7:0] out = fractal_mode ? -(y & 8'h7f & p_x) + (r>>11) : dot2 + stripes;

  // Caritas felices (Smiley Faces)
  wire signed [9:0] sm_x = p_x[7:0];
  wire signed [9:0] sm_y = p_y[7:0];
  wire face_circle = (sm_x*sm_x + sm_y*sm_y < 2500);
  wire left_eye   = ((sm_x + 18)*(sm_x + 18) + (sm_y + 12)*(sm_y + 12) < 36);
  wire right_eye  = ((sm_x - 18)*(sm_x - 18) + (sm_y + 12)*(sm_y + 12) < 36);
  wire mouth      = (sm_y > 5) && (sm_y < 25) && ((sm_x*sm_x)/2 + (sm_y-10)*(sm_y-10) > 100) && ((sm_x*sm_x)/2 + (sm_y-10)*(sm_y-10) < 220);
  wire smiley_face = face_circle && !left_eye && !right_eye && !mouth;

  // =========================================================================
  // MATRIZ DE TEXTO DIRECTA: D-A-Y-S-I
  // =========================================================================
  // Posicionamiento en pantalla: Y entre 180 y 244 (64 px alto)
  // X repartido en 5 letras de 48px con espacio entre ellas
  wire in_text_y = (y >= 180 && y < 244);
  wire [5:0] char_x = x[5:0];       // X local (0..63)
  wire [5:0] char_y = y[5:0] - 180; // Y local (0..63)
  wire [2:0] char_idx = x[8:6];     // Índice de la letra según posición X (150px..450px)

  reg char_pixel;
  always @(*) begin
    char_pixel = 1'b0;
    if (in_text_y) begin
      case (char_idx)
        3'd2: // Letra 'D'
          char_pixel = (char_x < 12) || 
                       (char_y < 12 && char_x < 40) || 
                       (char_y > 52 && char_x < 40) || 
                       (char_x >= 36 && char_x < 48 && char_y >= 8 && char_y <= 56);
        3'd3: // Letra 'A'
          char_pixel = (char_x < 12) || (char_x >= 36 && char_x < 48) || 
                       (char_y < 12) || 
                       (char_y >= 28 && char_y <= 40);
        3'd4: // Letra 'Y'
          char_pixel = (char_y <= 32 && ((char_x >= char_y && char_x < char_y + 12) || 
                       (char_x + char_y >= 36 && char_x + char_y < 48))) ||
                       (char_y > 32 && char_x >= 18 && char_x < 30);
        3'd5: // Letra 'S'
          char_pixel = (char_y < 12) || 
                       (char_y > 52) || 
                       (char_y >= 26 && char_y <= 38) ||
                       (char_y < 32 && char_x < 12) || 
                       (char_y > 32 && char_x >= 36 && char_x < 48);
        3'd6: // Letra 'I'
          char_pixel = (char_x >= 18 && char_x < 30) || 
                       (char_y < 12) || 
                       (char_y > 52);
        default: char_pixel = 1'b0;
      endcase
    end
  end

  wire title = char_pixel;

  // =========================================================================
  // PALETA Y COLORACIÓN (ROSA Y AMARILLO)
  // =========================================================================
  wire [2:0] part = frame_counter[9-:3];

  wire [5:0] PINK_BRIGHT = 6'b11_01_10; // Rosa brillante
  wire [5:0] PINK_PASTEL = 6'b11_10_11; // Rosa pastel
  wire [5:0] YELLOW_GOLD = 6'b11_11_00; // Amarillo intenso
  wire [5:0] MAGENTA     = 6'b11_00_01; // Magenta acento

  assign {R,G,B} =
    (~video_active) ? 6'b00_00_00 :
    (title) ? YELLOW_GOLD :                                                     // El texto DAYSI siempre destaca en amarillo
    (smiley_face & (part == 2 | part == 5)) ? YELLOW_GOLD :                     // Caritas amarillas
    (part == 0) ? { &out[5:3] ? PINK_BRIGHT : 6'b00_00_00 } :
    (part == 1) ? { &out[5:2] ? PINK_PASTEL : YELLOW_GOLD } :
    (part == 3) ? { |out[7:6] ? YELLOW_GOLD : PINK_BRIGHT } :
    (part == 4) ? { &out[6:4] ? PINK_BRIGHT : (&out[6:3] ? YELLOW_GOLD : MAGENTA) } :
    (part == 6) ? { out[7:6] ? PINK_PASTEL : YELLOW_GOLD } :
                  { out[7:6], out[7:6], 2'b00 };

  reg [11:0] frame_counter;
  reg frame_counter_frac;
  always @(posedge clk) begin
    if (~rst_n) begin
      frame_counter <= 0;
      frame_counter_frac <= 0;
    end else begin
      if (x == 0 && y == 0) begin
        frame_counter <= frame_counter + 1;
      end
    end
  end

endmodule