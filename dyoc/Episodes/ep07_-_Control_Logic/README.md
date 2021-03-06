# Design Your Own Computer
# Episode 7 : "Expanding Control Logic"

Welcome to the seventh episode of "Design Your Own Computer". In this episode
we will completely rewrite the Control Logic in a manner that is more readable
and more suited for future expansion.

Instructions implemented in total : 4/151.

## Control Logic
Since the control signals are functions of the Instruction Register and of the
Instruction Cycle Counter, it makes sense to implement the generation of the
control signals as a lookup-table, essentially a ROM.

Since an instruction never takes more than eight clock cycles, the instruction
cycle counter can fit in three bits. By combining the 8-bit instruction
register with the 3-bit instruction cycle counter we can generate an 11-bit
address into the lookup table. The data read from this lookup table will then
contain all the control signals for the CPU.  This lookup happens in line 2668.

Line 2667 is necessary, because during the first clock cycle of the
instruction, the Instruction Register has not yet been updated.  Since the
first cycle is always an instruction fetch consisting of "read from program
counter" and "increment program counter", we just hard code this value here.

It is useful to define symbols for the values of the different multiplexers in
the datapath. This is done in lines 29-47. The corresponding decoding of the
ROM data into the individual control signals is done in lines 49-58. It is
important that these two sections of the source code are kept in sync. Any
changes to one section will likely need corresponding changes to the other
section. For this reason the two sections are placed next to each other in the
source file.

Using these constants it becomes much easier to write the individual
instructions.  For instance, the "LDA #" instruction is defined in lines
1752-1760. Each line represents one clock cycle.

Of course, typing in this table of over two thousand lines is very tedious
and repetetive, but the benefit is well worth it.

From now on, implementing a new instruction is just a matter of deciding the
control signals necessary in each of the up to eight clock cycles.
Occasionally, we'll need to add more control signals, and this entails
modifying lines 26-58. There will be modifications to the datapath as well
in the coming episodes.

## Datapath reorganization
The datapath of the CPU consists of several different registers. It is helpful
to split these registers to their own files. This leads to the new files
pc.vhd, ar.vhd, hi.vhd, and lo.vhd.

## VGA modification
We've added yet another line of debug output showing the current value of the 
control signals.

Furthermore, looking at the top debug line "Inst Cnt" gives the hexadecimal
value of the current instruction. However, it would be much more useful
to display the assembly mnemonic. This is fairly easy to add.

Each mnemonic is a string of eight characters, and therefore we need a memory
with 256\*8 entries, each consisting of 8 bits (for the ASCII character value).
The address is calculated in lines 141-147 of vga/digits.vhd, and the
ASCII code is read from a memory in lines 150-161. Line 171 has been added to
override the text "Inst Cnt" with the current assembly mnemonic. And that is it!

## LED output
It is likely that at some point the CPU will attempt to execute an instruction
that is not yet implemented. To help debugging these situations the LEDs are
now connected up to display the OpCode of the invalid instruction.
The control of the LEDs takes place in lines 2653-2664 of cpu/ctl.vhd.
If ever the LEDs light up then the CPU has encountered an invalid instruction, and
the LEDs show the OpCode encountered.

