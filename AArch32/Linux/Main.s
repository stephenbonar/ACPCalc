/* 
 * Main.s - Main program source file.
 * Copyright (C) 2024 Stephen Bonar
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at

 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,1
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

    /* 
     * The global directive makes the _start label available to the entire
     * program as the entry point needs to be global.
     */
    .global _start

/*
 * Main application entry point.
 */
_start:
    /* bl <des> is branch and link, which jumps to <dest> address, preserving
     * the return address in the link register lr (alias for r14).
     */
    bl _print_program_info @ Branch and link to _print_program_info subroutine.

    /* bal <dest> is branch always, which jumps to <dest> address wihtout
     * storing the return address in the link register. 
     */
    bal _print_menu        @ Branch Always to the _print_menu label.

/*
 * Prints the program info to the screen.
 */
_print_program_info:
    /*
     * Preserve the link register in r8 as subsequent calls to bl will replace
     * the return address with its own return address.
     * 
     * mov <dest>, <source> copies the value in <source> to <dest>, where
     * <dest> can either be another register or an immediate value (prefixed
     * with #).
     */
    mov r8, lr

    /*
     * ldr <dest>, <source> loads <source> into <dest>, where <source> is the 
     * label address when you use the = prefix. <source> can also be a 
     * register. If <source> is a register surrounded by [] brackets, it will
     * load the value pointed to by the address contained within <source>.  
     */                 
    ldr r0, =program_name      @ Load the address of the string for printing.

    mov r1, #7                 @ Set the character length for printing.
    bl _print                  @ Print program_name.
    ldr r0, =program_version
    mov r1, #7
    bl _print
    ldr r0, =program_copyright
    mov r1, #33
    bl _print

    /* 
     * The way you return to a return address in ARM assembly is to copy the
     * return address into the program counter (pc or r15) register. Normally
     * you would move the link register lr into pc, but in this case we
     * preserved the return address in r8.
     */
    mov pc, r8                 @ Use the original link address to return.

/*
 * Prints the program menu to the screen.
 */
_print_menu:
    ldr r0, =menu_header       @ Load the address of the string for printing.
    mov r1, #32                @ Set the character length for printing.
    bl _print                  @ Print menu_header.
    ldr r0, =option_1
    mov r1, #12
    bl _print
    ldr r0, =option_0
    mov r1, #8
    bl _print
    ldr r0, =prompt
    mov r1, #3
    bl _print
    ldr r0, =choice            @ Load the address of the string for input.
    mov r1, #1                 @ Set the character length for input.
    bl _read                   @ Read choice string from keyboard.
    ldr r0, =choice            @ Reload address of choice into r0.
    ldr r1, [r0]               @ Now load the value of choice into r1.

    /* 
     * bic <dest>, <source>, <mask> clears the bits specified in the mask. 
     * We need to do this because although we only read 1 byte from the
     * keyboard into choice, ldr loads an entire 32-bit word, so we need
     * to clear everything except the least significant byte as the rest
     * is garbage.
     */
    bic r1, r1, #0xFFFFFF00

    mov r2, #'0'               @ Copy ASCII '0' character into r2.

    /* 
     * cmp <op1>, <op2> Compares <op1> to <op2> by subtracting <op2> from 
     * <op1>. If the result is 0, updates the status register by setting the 
     * zero flag, which also indicates the two values are equal.
     */
    cmp r1, r2                @ See if choice is ASCII '0' character.

    /* 
     * beq <dest> is branch if equal, which jumps to <dest> address if the
     * zero flag is set, indicating a comparison was equal.
     */
    beq _exit                 @ If choice was 0, goto _exit.

    mov r2, #'1'              @ Copy ASCII '1' character into r2.
    cmp r1, r2                @ See if choice is ASCII '1' character.
    beq _add                  @ If choice was 1, goto _add.
    
    /* 
     * If this code is reached, an invalid choice was entered. Display an
     * error and go back to the beginning of _print_menu.
     */
    ldr r0, =selection_error
    mov r1, #33
    bl _print
    bal _print_menu

/*
 * Adds two numbers together.
 *
 * TODO: Document the parameters here.
 */
_add:
    /* TODO: Add logic for adding two numbers together. */
    
    /* 
     * Display an error that this function is not yet implemented. Replace
     * this code once we have a working implementation.
     */
    ldr r0, =not_imp_error
    mov r1, #30
    bl _print

    /* 
     * Pause the program so the user can see the output, then return to the
     * main menu when the user presses <enter>.
     */
    bl _pause
    bal _print_menu

/*
 * Pauses the program until the user types <enter>.
 */
_pause:
    mov r8, lr             @ Preserve the return address in r8.
    ldr r0, =pause_message @ Load the string address for printing.
    mov r1, #29            @ Set the number of characters to print.
    bl _print              @ Print the pause message.
    ldr r0, =choice        @ Load the choice address for input.
    mov r1, #1             @ Set the number of characters to read.
    bl _read               @ Read the character into choice.
    bl _read               @ Do another read to capture the newline in buffer.
    mov pc, r8             @ Return. 

/*
 * Exits with a success return code.
 */
_exit_success:
    mov r0, #0             @ Set the return code to 0 = success.
    bal _exit              @ Jump to the routine for invoking the exit syscall.

/*
 * Prints the specified string to standard output via syscall.
 *
 * r0 - A pointer to the string to print.
 * r1 - The number of characters to print. 
 */
_print:
    mov r2, r1 @ Move character count into the register the syscall expects.
    mov r1, r0 @ Move string into the register the syscall expects.
    mov r0, #1 @ Set file descriptor to stdout.
    mov r7, #4 @ Set syscall 4 - write.

    /* swi <parameter> or svc <parameter> triggers a supervisor call exception,
     * which puts the CPU in supervisor mode and jumps to the svc handler.
     * This allows your program to make a syscall to the operating system.
     *
     * NOTE: earlier version of ARM used swi, but swi is now an alias to svc,
     * and the code will compile to use svc instead.
     *
     * NOTE: On Linux, parameter should typically be 0, which indicates "Unix
     * style calling convention".
     */
    swi 0      @ Make syscall via software interrupt.

    mov pc, lr @ Return by copying the link register to program counter.

/*
 * Reads input from the keyboard into the specified string via syscall.
 *
 * r0 - A pointer to the string to read into.
 * r1 - The number of characters to read.
 */
_read:
    mov r2, r1 @ Move character count into the register the syscall expects.
    mov r1, r0 @ Move string into the register the syscall expects.
    mov r0, #0 @ Set file descriptor to stdin.
    mov r7, #3 @ Set syscall 3 - read.
    swi 0      @ Make syscall via software interrupt.
    mov pc, lr @ Return by copying the link register to program counter.

/*
 * Exits the program via syscall.
 *
 * r0 - The return code to exit with.
 */
_exit:
    mov r7, #1 @ Set syscall 1 - exit.
    swi 0      @ Make syscall via software interrupt.

    /*
     * The .data directive indicates the following should be placed in the
     * data section of the program. 
     */
    .data
program_name:      .ascii "ACPCalc"
program_version:   .ascii " v0.10\n"
program_copyright: .ascii "Copyright (C) 2024 Stephen Bonar\n"
menu_header:       .ascii "\nMenu\n------------------------\n\n"
option_1:          .ascii "1) Addition\n"
option_0:          .ascii "0) Exit\n"
prompt:            .ascii "\n< "
choice:            .ascii " "
selection_error:   .ascii "\nPlease enter a valid selection!\n"
not_imp_error:     .ascii "\nFeature not yet implemented!\n"
pause_message:     .ascii "Press <enter> to continue...\n"

