/* 
 * output.s - Contains functions for printing values in different formats.
 * Copyright (C) 2025 Stephen Bonar
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

    /* Include the shared macros for use in this source file. */
    .include "macros.s"

    /* 
     * We need to mark these functions as global so they are available to
     * other parts of the program.
     */
    .global print_program_info
    .global print_number_prompt
    .global print_menu
    .global print_result
    .global print_binary
    .global print_error

    /* We store our string constants in the read-only data section. */
    .section .rodata

    programName: .asciz "ACPCalc"
    programVersion: .asciz "v0.03"
    programCopyright: .asciz "Copyright (C) 2025 Stephen Bonar"
    programFormat: .asciz "%s %s\n%s\n\n"
    menuFormat: .asciz "\n\nMenu:\n\n%s\n%s\n%s\n%s\n\n%s"
    prompt: .asciz "< "
    enterNumberChoice: .asciz "1) Enter number"
    addNumberChoice: .asciz "2) Add number"
    subtractNumberChoice: .asciz "3) Subtract number" 
    exitChoice: .asciz "0) Exit"
    enterNumberFormat: .asciz "\n\nEnter a number\n\n%s"
    resultHeader: .asciz "Result:\n"
    resultBinFormat: .asciz "\nBIN: "
    resultHexFormat: .asciz "\nHEX: 0x%08X"
    resultDecFormat: .asciz "\nDEC: %i"
    zero: .asciz "0"
    one: .asciz "1"
    space: .asciz " "
    errorMessage: .asciz "\nERROR: %s\nPress any key to continue...\n"

    /* Switch to the text section for the code. */
    .text

    /*
     * Prints the program's information, including name, version, and 
     * copyright.
     *
     * void print_program_info();
     */
    .func print_program_info
print_program_info:
    init_stack_frame

    /*
     * We will call the printf function in libc to print the program info.
     *
     * int printf(const char* format, ...);
     * 
     * The first argument in libc is the format string, which is programFormat
     * in our case, followed by any arguments we want to substitute into the
     * format string. By calling convention, register r0 is the first function
     * argument, followed by r1, r2, and r3. Any additional args must be on the
     * stack.
     *
     * LDR <dest>, <address> loads the contents of memory at address into the
     * destination register. In this case, =<label> tells the assembler to 
     * add a pointer to the label in the literal pool, which is at the bottom
     * of the .text section. This puts a .word containing the address of the
     * string in the .text section, which is essentially a pointer to the 
     * string characters. This allows the load instruction to use an address 
     * relative to the program counter. This is necessary because a "far" 
     * addresses like the strings stored in the .rodata section can't fit as
     * an immediate value in ldr, but an offset relative to the program counter
     * can. 
     *
     * BL <address> tells the CPU to jump to the instructions at the specified
     * address and store the current program counter address in the link 
     * register (LR) as a return address. This calls the function.
     */
    ldr r0, =programFormat
    ldr r1, =programName
    ldr r2, =programVersion
    ldr r3, =programCopyright
    bl printf

    return
    .endfunc

    /*
     * Prints the program's main menu.
     *
     * void print_menu();
     */
    .func print_menu
print_menu:
    init_stack_frame

    /* 
     * There are more printf function arguments than we can place in registers,
     * so the rest have to be pushed on the stack. 
     */
    ldr r0, =exitChoice
    ldr r1, =prompt
    push {r0, r1}

    /* The first 4 printf arguments can be stored in r0 - r3 */
    ldr r0, =menuFormat
    ldr r1, =enterNumberChoice
    ldr r2, =addNumberChoice
    ldr r3, =subtractNumberChoice
    bl printf

    /* Deallocate the additional arguments we had to push on the stack. */
    add sp, #8

    return
    .endfunc

    /*
     * Prints a prompt for the user to enter a number:
     *
     * void print_number_prompt();
     */
    .func print_number_prompt
print_number_prompt:
    init_stack_frame
    ldr r0, =enterNumberFormat
    ldr r1, =prompt
    bl printf
    return
    .endfunc
 
    /*
     * Prints the result of calculation in various formats.
     *
     * This function prints the result in binary, hexadecimal, and decimal
     * formats.
     *
     * void print_result(int result);
     *
     * Parameters:
     *
     * r0 = result.
     */
    .func print_result
print_result:
    init_stack_frame

    /* 
     * We push r4 onto the stack because we need to restore it to what it was
     * before print_result was called. Registers r4 - r11 need to be preserved
     * according to calling convention, so any registers we use in this
     * function need to be preserved on the stack.
     */
    push {r4}

    /* 
     * Register r0 has the argument 'int result', but we'll need to reuse r0
     * multiple times when calling other functions, so let's save the value in
     * r4 instead.
     */
    mov r4, r0

    /* Print the header we decorate the result with. */
    ldr r0, =resultHeader
    bl printf
    
    /* Print the result in binary format first. */
    ldr r0, =resultBinFormat
    bl printf
    mov r0, r4
    bl print_binary

    /* Then, print the result in hex format. */
    ldr r0, =resultHexFormat
    mov r1, r4
    bl printf

    /* Last, print it in decimal format. */
    ldr r0, =resultDecFormat
    mov r1, r4
    bl printf

    /* Restore register r4 to what it was before print_result was called. */
    pop {r4}

    return
    .endfunc

    /*
     * Prints the specified number as a formatted binary value.
     *
     * void print_binary(int number);
     *
     * Parameters:
     *
     * r0 = int number.
     */
    .func print_binary
print_binary:
    init_stack_frame

    /* 
     * Preserve r4 - r7 as we need to use these in our function, but return
     * them to what they were when the function was called.
     */
    push {r4, r5, r6, r7}

    /* 
     * Copy the argument r0 into r4 as we will need to repurpose r0 as an
     * argument for additional function calls.
     */
    mov r4, r0

    /* Initalize r5 and r6 as counters for our loop. */
    mov r5, #word_size_bits     @ Counter to decrement, also # bits to shift.
    mov r6, #bits_per_byte + 1  @ Octet counter.

    /* Local label that marks the start of bit printing loop. */
1:
    sub r5, r5, #1          @ Decrement the loop counter / bits to shift.
    subs r6, r6, #1         @ Derement the octet counter.

    /* 
     * Skip printing a space if we haven't finished printing an entire octet
     * yet by jumping to local label 2, which prints an individual bit.
     * We want to separate each octet with a space to make the binary easier
     * to read.
     *
     * The NE suffix tells the instruction to only execute if the zero flag
     * is not set (not equal). While we aren't really testing for equality
     * here, EQ vs NE is tied to the zero flag so that's still how we check
     * if the octet counter is zero. We use the SUB instruction with the 'S'
     * suffix to tell the SUB instruction to update the status register.
     */
    bne 2f

    /* Print a space as we've completed an entire octet. */
    mov r6, #bits_per_byte  @ Reset the octet counter.
    ldr r0, =space
    bl printf

    /* Local label for printing an individual bit. */
2:
    /* 
     * First, we need to select the bit we want to examine by setting r7 to 1
     * and then shifting that bit left to the desired bit.
     *
     * LSL <dest>, <source>, <amount> shifts the bits in source left by the 
     * specified amount of bits and stores the result in dest.
     */
    mov r7, #1
    lsl r7, r7, r5

    /*
     * Then, we need to do do a bitwise AND against the number we're printing
     * (r4) and the selected bit in r7 to clear all of the bits except the one
     * we want to check. We then shift the result of AND in r7 back to the
     * right the same amount to see if it is a 1 or a 0.
     *
     * AND <dest>, <operand1>, <operand2> performs a bitwise AND on operand1
     * and operand2 and stores it in dest.
     *
     * LSR <dest>, <source>, <amount> shifts the bits in source right by the 
     * specified amount of bits and stores the result in dest. Here we use the
     * S suffix to update the status registers based on the result of the LSR
     * instruction.
     */
    and r7, r4, r7    
    lsrs r7, r7, r5

    /*
     * If shifting the bits right resulted in the zero flag being set, we know
     * the bit was a zero so we load the zero string in r0 (the EQ suffix tells
     * the first load instruction only to execute if the zero flag is set).
     * Otherwise, if the zero flag is not set, we know the bit was a 1 so we
     * load the one string into r0 (the NE suffix tells the second load 
     * instruction to only load the one string if the zero flag was not set).
     */
    ldreq r0, =zero     @ If the bit was a zero, load the '0' character.
    ldrne r0, =one      @ If the bit was a one, load the '1' character.
    bl printf           @ Print the individual bit.

    /*
     * Check if the loop counter has reached zero, otherwise start the loop
     * again.
     */
    cmp r5, #0
    bne 1b

    /* 
     * Pop the previous register values off the stack to restore the registers
     * to the state they were in before print_binary was called.
     */
    pop {r4, r5, r6, r7}

    return
.endfunc

/* 
 * Prints the specified error message.
 *
 * void print_error(const char* message);
 *
 * Parameters:
 *
 * r0 = message
 */
.func print_error
print_error:
    init_stack_frame
    mov r1, r0
    ldr r0, =errorMessage
    bl printf
    bl getchar             @ We use 2 calls to getchar to capture \n
    bl getchar            
    return
.endfunc
