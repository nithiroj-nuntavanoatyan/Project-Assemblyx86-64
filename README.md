# Project-Assemblyx86-64

## Overview
This project is an x86-64 assembly program that provides encryption and decryption functionality.

## Files
- `Encryptorx64.s` - Assembly source file for encryption.
- `Decryptor.s` - Assembly source file for decryption.

## How to Run
1. Assemble the source file:
   ```sh
   yasm -f elf64 -g dwarf2 -o filename.o filename.s
   ```
2. Link the object file:
   ```sh
   ld -o filename filename.o
   ```
3. Execute the program:
   ```sh
   ./filename
   ```
4. Enter the required input when prompted.

