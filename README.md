# The9660Boot

The9660Boot is a simple bootloader designed for the x86 architecture and packaged in an ISO 9660 file system. This project serves as an educational example of how to create a bootable ISO image with a custom bootloader.

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Installation](#installation)

## Introduction

This project demonstrates how to create a bootable ISO image containing a custom bootloader for the x86 architecture. The bootloader is written in assembly language and designed to be compatible with the BIOS boot process, adhering to the ISO 9660 file system standard.

## Prerequisites

To build and run this project, you will need the following tools installed on your system:

- `nasm` (Netwide Assembler) - for assembling the bootloader
- `mkisofs` - for creating the ISO 9660 image
- `qemu` - for testing the bootable ISO image

## Installation

### Step 1: Clone the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/The-Jat/The9660Boot.git
cd The9660Boot
```

### Step 2: Build the Bootloader and ISO image
Use the provided Makefile to assemble the bootloader and create the bootable ISO image:

```bash
make
```

### Step 3: Testing the Bootable ISO Image
You can test the bootable ISO image using `qemu`:
```bash
make run
```

Alternatively, you can use `VirtualBox` to test the ISO image by createing a new virtual machine and attaching the `image.iso` as the optical drive. Remeber to uncheck the `Enable EFI` checkbox from the Setting of the newly created virtual machine.
