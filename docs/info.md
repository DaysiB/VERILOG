<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project is a hardware-only (no CPU, no RAM, no GPU) VGA demoscene generator designed for Tiny Tapeout that renders a 640x480 @ 60Hz video stream directly on-the-fly by "racing the beam" using purely digital logic gates: the hvsync_generator module tracks horizontal (x) and vertical (y) pixel coordinates alongside standard timing signals, while the letters D-A-Y-S-I are decoded on-the-fly through spatial combinational logic without a font ROM, procedural radial functions generate flower petal geometries and smiley face coordinates, and a 6-bit TinyVGA color signal (R[1:0], G[1:0], B[1:0]) outputs a vibrant pink and golden yellow palette.

## How to test

Connect the Tiny Tapeout board to a 25.175 MHz clock source, pull the rst_n pin low briefly to reset the frame counter, hook up a standard VGA monitor to the output, and watch the visual demo automatically cycle through sequential scene parts featuring the "DAYSI" banner, procedural flowers, tunnel zooms, and smiley faces.

## External hardware


