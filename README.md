# encrypted-messaging-uart-fpga

VHDL system for encrypted point-to-point communication between two FPGA boards over UART, using the PRESENT lightweight block cipher — extended with remote control of an 8x8 RGB LED matrix. Designed, simulated and implemented on Xilinx Vivado for the Basys3 board.

## Overview

This project was built in two stages, as part of a Digital Design course, and is presented here as a single system.

**Stage 1 — Secure messaging link.**
A transmitter (`emisor_cifr`) builds a message containing a source address, a destination address and a random nonce, encrypts the payload with the **PRESENT** lightweight block cipher, and sends the frame over a **UART** link. The base receiver logic decrypts the frame, validates the addresses, and outputs the decoded command.

**Stage 2 — Remote-controlled RGB LED matrix.**
That receiver logic was extended into `receptor_cifr_rgb`, the receiver actually used in the final system, so that once a message is validated, the decoded command drives an 8x8 **WS2812 RGB LED matrix**: it selects one of several predefined figures and displays it either as a static image or as an animation that shifts it across the matrix (`dibuja_rgb_xx`).

Both designs were verified through functional simulation and synthesized for the **Basys3** FPGA board (Xilinx Vivado). The full system was also validated experimentally with **two physical Basys3 boards**: one running the transmitter and sending commands over UART, and the other decrypting them and drawing the corresponding figure on the LED matrix in real time.

## Message format

Each message is 10 bytes long:

| Field | Size |
|---|---|
| Destination address (plaintext) | 8 bits |
| Source address (plaintext) | 8 bits |
| Encrypted body (destination + source + command + nonce, PRESENT-encrypted) | 64 bits |

The destination and source addresses are sent both in clear and inside the encrypted body, so the receiver can check that the message was encrypted with the expected key before trusting it. The decrypted **command** field selects which figure to draw and whether it should stay static or animate.

## Architecture

- `emisor_cifr.vhd` — builds the plaintext, encrypts it with PRESENT and transmits it over UART.
- `receptor_cifr_rgb.vhd` — the receiver actually used in the final system: receives the UART frame, decrypts it with PRESENT, validates the message and drives the RGB LED matrix from the decoded command.
- `dibuja_rgb_xx.vhd` — draws a predefined figure on the 8x8 WS2812 matrix, static or animated (shifting).
- `ws2812_controller.vhd` — low-level driver generating the WS2812 serial timing for the LED matrix.
- `present/` — PRESENT block cipher core (see [Credits](#credits)).
- `uart_limon.vhd` — UART transmitter/receiver core.
- Testbenches for each design, plus a combined testbench connecting transmitter and receiver (`emisor_receptor_cifr_rgb_tb`).

## How to simulate

1. Open the project in Xilinx Vivado.
2. Add all sources under `src/` and the matching testbench.
3. Run behavioral simulation and check the waveform: transmitted/received bytes, `ready`/`tx_busy` handshakes, the PRESENT plaintext/ciphertext at both ends, and (for stage 2) the `rgb_out` serial stream and matrix state.

## How to synthesize / implement

1. Run synthesis and implementation in Vivado for the Basys3 board (`xc7a35tcpg236-1`).
2. Generate the bitstream and program the board(s).
3. For the hardware demo, connect two Basys3 boards through their UART pins (Pmod JB/JC, see the constraints file for the exact pin mapping): one running `emisor_cifr` (or the combined `emisor_receptor_rgb` design), the other running `receptor_cifr_rgb` connected to the WS2812 8x8 matrix.

## Credits

The PRESENT cipher core is based on the implementation by [Charilaos Memeletzoglou](https://github.com/CMemeletzoglou/PRESENT) (MIT License). See `present/LICENSE` for the original license terms.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
