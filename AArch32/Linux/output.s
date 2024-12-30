/* 
 * output.s - Contains functions for printing values in different formats.
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

    /* Include the shared macros for use in this source file. */
    .include "macros.s"

    /* 
     * We need to mark these functions as global so they are available to
     * other parts of the program.
     */
    .global print_result
    .global print_binary
    .global print_error

    /* We store our string constants in the read-only data section. */
    .section .rodata

    resultHeader: .asciz "Result:\n"
    resultBinFormat: .asciz "\nBIN: "
    resultHexFormat: .asciz "\nHEX: 0x%#08X"
    resultDecFormat: .asciz "\nDEC: %i"
    zero: .asciz "0"
    one: .asciz "1"
    space: .asciz " "
    errorMessage: .asciz "\nERROR: %s\nPress any key to continue...\n"

    /* Switch to the text section for the code. */
    .text
 
    /*
     * Prints the result of calculation in various formats.
     *
     * This function prints the result in binary, hexadecimal, and decimal
     * formats.
     *
     * void print_result(int result);
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
     * We first shift the result right by the number left in the loop
     * counter. This will put the next bit in register r7. We use the 'S'
     * suffix on the MOV instruction to tell this operation to update the
     * status register.
     */
    movs r7, r4, lsr r5

    ldreq r0, =zero     @ If the bit was a zero, load the '0' character.
    ldrne r0, =one      @ If the bit was a one, load the '1' character.
    bleq printf         @ Print the individual bit.

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
