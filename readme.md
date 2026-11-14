# NIOS V/m Embedded SoC with Custom PWM & Sigma-Delta (PPM) DACs

## Overview

This repository contains the complete hardware-software co-design, RTL implementation, and physical validation of a **RISC-V (Intel Nios V/m) System-on-Chip** deployed on an **Intel Cyclone V (DE1-SoC) FPGA**. The system integrates two custom 8-bit Digital-to-Analog Converter (DAC) peripherals written in VHDL—one based on **Pulse Width Modulation (PWM)** and the other on **Pulse Proportion / Sigma-Delta Modulation (PPM/PDM)**—interfaced via Avalon Memory-Mapped PIOs and driven by bare-metal C firmware.

Both converters translate 8-bit unsigned digital codes $D \in [0, 255]$ into analog voltages via external 2-stage passive RC low-pass reconstruction filters according to:

$$
V_{out} = V_{dd} \cdot \frac{D}{256}, \quad V_{dd} = 3.3\text{ V}
$$

## Repository Structure

```
NIOSV-Dual-DAC-PWM-SigmaDelta-FPGA/
├── Core-Architecture/
│   ├── Nios system/
│   │   ├── nios_system.vhd               # Top-level structural VHDL entity connecting Nios V & DACs
│   │   └── platformdesigner.qsys         # Platform Designer SoC configuration (Nios V/m, Timer, PIOs, UART)
│   └── Peripherals/
│       ├── DAC PPM/
│       │   ├── ppm_top.vhd               # Top-level 1st-order digital Sigma-Delta (PPM/PDM) modulator
│       │   ├── ppm_freq_generator.vhd    # Programmable sampling clock enable generator (50–400 kHz)
│       │   ├── ppm_sigma_delta_adder.vhd # 10-bit signed accumulator & 1-bit feedback subtractor
│       │   ├── ppm_register.vhd          # 10-bit synchronous accumulator state register
│       │   ├── ppm_comparator.vhd        # 1-bit MSB quantizer (output bitstream generator)
│       │   └── tb_ppm_top.vhd            # VHDL testbench for PPM/PDM DAC verification
│       └── DAC PWM/
│           ├── DAC_PWM.vhd               # 8-bit PWM modulator with prescaler, dual down-counters & 3-state output
│           ├── ncounter.vhd              # Generic N-bit synchronous loadable down-counter
│           └── tb_DAC_PWM.vhd            # VHDL testbench for PWM DAC verification
├── Core-Firmware/
│   ├── keyboard.c                        # Interactive JTAG-UART firmware for static DC voltage & frequency control
│   └── sine.c                            # Timer-IRQ driven firmware for real-time sinusoidal waveform synthesis
├── Immagini/
│   ├── Complete system.png               # Top-level block diagram of Nios V/m and dual DAC peripherals
│   ├── ppm_block_diagram.png             # Conceptual block diagram of the 1st-order Sigma-Delta (PPM) loop
│   └── RTL_viewer_ppm_dac.png            # Quartus Prime RTL Viewer schematic of the synthesized PPM DAC
└── README.md
```

## Hardware Architecture & Engineering Trade-offs

### 1. Platform Designer SoC Architecture (`Core-Architecture/Nios system/`)

* **Processor & Memory (`platformdesigner.qsys`):** A 50 MHz **Intel Nios V/m** (`intel_niosv_m_0`) RISC-V soft-core connected via AXI4-Lite / Avalon-MM interconnects to a 256 KB dual-ported on-chip RAM (`onchip_memory2_0`, base address `0x00000000`).
* **Peripherals & Interrupts:**
  * `timer_0` (`0x00050040`, IRQ 5): 32-bit interval timer generating periodic interrupts ($100\text{ Hz}$ to $1\text{ kHz}$) for deterministic waveform sampling.
  * `jtag_uart_0` (`0x000500B0`, IRQ 1): Bidirectional serial console for runtime user input.
  * Memory-mapped PIOs: `pio_val_out` (8-bit DAC data), `pio_freq_sel` (2-bit clock prescaler selector), `LEDS` (2-bit status indicator), and `HEX0`/`HEX1` (7-segment hex display drivers).
* **Top-Level Integration (`nios_system.vhd`):** Structurally binds the Nios V/m subsystem to both `DAC_PWM` and `ppm_top`, routing the modulated digital outputs to `GPIO_0(0)` and `GPIO_0(1)` respectively.

### 2. PWM DAC Peripheral (`Core-Architecture/Peripherals/DAC PWM/`)

* **Architecture:** Uses a programmable prescaler (`PSC`) driven by the 50 MHz system clock to select four operating base frequencies $f_0 \in \{400, 200, 100, 50\}\text{ kHz}$, yielding PWM repetition frequencies $f_{PWM} = f_0 / 256 \in \{1560, 781, 391, 195\}\text{ Hz}$. Two 8-bit synchronous down-counters (`ncounter.vhd`: `CNT0` initialized to `255`, `CNT1` loaded with `DAC_IN`) control pulse width per cycle, gated by a tri-state output buffer (`ENABLE`).
* **Trade-off:** Simple, deterministic counter logic, but spectral energy concentrates at the low fundamental switching frequency $f_0 / 256$ with first-harmonic amplitude $V_1 = \frac{V_{dd}}{\pi}\sin(\frac{\pi D}{256})$. Achieving $< 1\text{ LSB}$ ripple requires aggressive low-pass filtering ($A > 2N/\pi$).

### 3. Sigma-Delta / PPM DAC Peripheral (`Core-Architecture/Peripherals/DAC PPM/`)

* **Architecture:** Implements a 1st-order digital **Sigma-Delta modulator** operating at oversampling rates $f_0 \in \{400, 200, 100, 50\}\text{ kHz}$. A 10-bit signed feedback loop (`ppm_sigma_delta_adder.vhd` + `ppm_register.vhd`) integrates the quantization error between the 8-bit input and the 1-bit feedback DAC ($0$ or $2^8 - 1$), while `ppm_comparator.vhd` extracts $\overline{\text{MSB}}$ as the high-frequency output bitstream.
* **Trade-off:** Widening the internal accumulator to **10 bits** prevents arithmetic overflow during transient error accumulation. Unlike PWM, Sigma-Delta modulation shapes quantization noise toward higher frequencies, significantly relaxing analog RC filter requirements and reducing output ripple across all operating frequencies.

## Embedded Firmware (`Core-Firmware/`)

1. **Static Conversion Mode (`keyboard.c`):** Polls user input over `stdin` (JTAG UART) to set the 8-bit conversion code (`0–255`) and clock frequency index (`0–3`), updating the DAC PIO registers, onboard LEDs, and dual 7-segment displays (`HEX1:HEX0`) in real time.
2. **Interrupt-Driven Waveform Generator (`sine.c`):** Configures `timer_0` in continuous interrupt mode (`CONT_MSK | ITO_MSK`). At each timer overflow, `timer_isr` streams the next sample from a 20-point lookup table to `PIO_VAL_OUT_BASE` ($f_{sine} = f_{IRQ} / 20$), allowing glitch-free runtime frequency switching via JTAG UART without blocking the main loop.

## Experimental Validation on DE1-SoC

### 1. Static DC Linearity & Ripple Comparison (2-Stage RC Filter, $f_{c1} \approx 3.4\text{ Hz}, f_{c2} \approx 2.3\text{ Hz}$)

Across all 12 test configurations ($D \in \{20, 128, 160\}$ and $f_0 \in \{400, 200, 100, 50\}\text{ kHz}$), both converters achieved DC linearity within $\pm 10\text{ mV}$ of theoretical values:

| $f_0$ (kHz) | Digital Input $D$ | Theoretical $V_{out}$ (V) | PWM Measured $V_{out}$ (V) | PWM Ripple ($\text{mV}_{pp}$) | PPM Measured $V_{out}$ (V) | PPM Ripple ($\text{mV}_{pp}$) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **400** | 20 / 128 / 160 | 0.26 / 1.65 / 2.06 | 0.266 / 1.65 / 2.05 | 320 / 380 / 380 | 0.263 / 1.65 / 2.07 | 205 / 200 / 200 |
| **200** | 20 / 128 / 160 | 0.26 / 1.65 / 2.06 | 0.265 / 1.65 / 2.05 | 344 / 380 / 380 | 0.263 / 1.65 / 2.07 | 205 / 200 / 190 |
| **100** | 20 / 128 / 160 | 0.26 / 1.65 / 2.06 | 0.265 / 1.65 / 2.05 | 355 / 400 / 380 | 0.263 / 1.65 / 2.07 | 210 / 200 / 210 |
| **50** | 20 / 128 / 160 | 0.26 / 1.65 / 2.06 | 0.264 / 1.65 / 2.06 | 370 / 400 / 400 | 0.264 / 1.65 / 2.07 | 170 / 210 / 210 |

* **Key Finding:** The Sigma-Delta (PPM/PDM) architecture cuts peak-to-peak output ripple nearly in half ($170\text{–}210\text{ mV}_{pp}$ vs. $320\text{–}400\text{ mV}_{pp}$ for PWM) and remains immune to ripple degradation at lower $f_0$ settings.

### 2. Dynamic Sinusoidal Synthesis ($f_c \approx 50\text{–}72\text{ Hz}$ Reconstruction Filter)

* **25 Hz Sine Wave ($f_{IRQ} = 500\text{ Hz}$, $f_0 = 100\text{ kHz}$):** Well inside the filter passband; PPM achieves $2.68\text{ V}_{pp}$ with lower switching noise compared to PWM ($2.56\text{ V}_{pp}$).
* **50 Hz Sine Wave ($f_{IRQ} = 1000\text{ Hz}$, $f_0 = 400\text{ kHz}$):** Approaching the RC cutoff frequency causes expected passband roll-off ($1.80\text{ V}_{pp}$ for PPM, $1.68\text{ V}_{pp}$ for PWM), with PPM preserving superior waveform fidelity even at low oversampling clocks ($50\text{ kHz}$).
