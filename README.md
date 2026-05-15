# CPE 487 Final Project: Apple-I

## Project Overview

The goal of this project was to create a (somewhat) faithful recreation of the Apple I computer in
VHDL for use on the Nexys-A7 FPGA board. The project closely emulates the original hardware
of the Apple I, modeling its proprietary shift-register based display circuitry for output through
the VGA port as well the Motorola 6821 peripheral interface adapter that allows simultaneous
connection of a keyboard and a monitor to the 6502 CPU.

Apple I Overview:

- Simple MOS-6502 based machine with dedicated video circuitry
- Utilized 256 bytes of ROM to store a lightweight hex monitor / operating system (Wozmon)
- Shipped with 4K of user-accessible RAM
- Utilized the Motorola 6821 Peripheral Interface Adapter to bridge the gap between the keyboard + display circuitry
- Display circuitry consisted of 7 x 1024-bit shift registers

Our Implemntation:

- Built upon a premade 6502 CPU core from https://github.com/Steve-Teal/mx65
- Utilized vga_sync module from Lab 6 for display timing (along with associated clk_wiz modules)
- Utilized UART protocol to serially transfer ASCII data from computer to Nexys-A7 board along with custom UART receiver module
- Closely modeled behavior of the Apple I display circuitry + adjusted to interface with VGA protocol
- Closely modeled behavior of the 6821 Peripheral Interface Adapter
- Created a 4K RAM module to interface with the 6502 CPU

<img width="371" height="272" alt="image" src="https://github.com/user-attachments/assets/2f2074ae-2aa9-4346-8e09-630a412b5337" />

## Required Hardware

- **Digilent Nexys A7 FPGA Board**

  <img src="https://cdn11.bigcommerce.com/s-7gavg/images/stencil/1920w/products/629/5236/NexysA7-top-600__89503.1670980013.jpg?c=2" alt="Digilent Nexys A7 FPGA Board" width="300">

- **VGA Monitor** (800×600 @ 60 Hz)

    <img src="https://c1.neweggimages.com/productimage/nb640/24-276-208-Z01.jpg" alt="VGA Monitor (800×600 @ 60 Hz)" width="300">

- **VGA to HDMI Cable**

    <img src="https://img.fruugo.com/product/6/66/1682800666_max.jpg" alt="VGA to HDMI cable" width="200">

### Pin Mapping

## System Architecture

### System Block Diagram

### Memory Map

### Finite State Machines

## Vivado Setup & Programming Instructions

1. **Download all source files** (`.vhd`) and the constraint file (`.xdc`) from this repository.
2. **Create a new Vivado project** targeting the **Digilent Nexys A7‑100T FPGA board**.
3. **Add Source Files**  
   Include the following VHDL modules:
   - `apple_i_top.vhd` (top‑level design)
   - `clk_wiz_0.vhd` and `clk_wiz_0_clk_wiz.vhd` (clock generation)
   - `display_top.vhd`, `vga_sync.vhd`, `pixel_decode.vhd`, `line_buffer.vhd` (video pipeline)
   - `ram.vhd`, `rom.vhd`, `font_rom_pkg.vhd` (memory components)
   - `io_top.vhd`, `uart_protocol.vhd`, `shiftregister.vhd`, `6821_core.vhd`, `mx65.vhd` (I/O and peripheral logic)
4. **Add Constraints File**
   - Use `apple_i_top.xdc` for pin assignments and board‑specific mappings.
5. **Run Synthesis**
   - Verify that all modules compile successfully and resolve dependencies.
6. **Run Implementation**
   - Check timing reports and ensure all constraints are met.
7. **Generate Bitstream**
   - Wait for Vivado to complete bitstream generation (`.bit` file).
8. **Program the Device**
   - Open **Hardware Manager**, connect the Nexys A7 board via USB, and program it with the generated bitstream.
9. **Verify Operation**
   - Confirm VGA output and UART communication are functioning as expected.

## FPGA Inputs & Outputs

## Modifications & Implemntation

- show the starter code githubs

## Project Results (Images & Videos)

## Team Summary

### Responsibilities

## Summary of Process

### Timeline

### Difficulties

### Future Works

## File Structure
