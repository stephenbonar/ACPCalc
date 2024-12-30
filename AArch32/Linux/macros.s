/* 
 * macros.s - Provides shared macros for use within the program.
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

    /* .equ assigns a name to a literal value */
    .equ word_size_bytes, 4
    .equ word_size_bits, 32
    .equ bits_per_byte, 8

    /* 
     * This macro is used to set up the stack frame at the beginning of a
     * function. 
     *
     * Due to calling conventions, we need to initialize the stack frame by 
     * preserving the frame pointer and the link register by pushing them on 
     * the stack.
     *
     * PUSH accepts a list of registers and pushes them onto the stack,
     * decrementing the stack pointer register SP (R13) by 4 bytes for
     * each register. The stack is full descending, so it grows downward
     * towards lower memory addresses.
     *
     * We now have a stack frame of two 4-byte items (8-bytes total) created
     * for the main function when we pushed fp and lr onto the stack. The
     * frame pointer should point to the first item that was pushed onto the
     * stack, but the stack pointer is on the second item. So, we simply add
     * 4 to it to point to the first item.
     *
     * ADD <dest>, <operand1>, <operand2> or fp = sp + 4
     */
    .macro init_stack_frame
    push {fp, lr}
    add fp, sp, #word_size_bytes
    .endm

    /* 
     * This macro is used to properly return from a function.
     *
     * This is done by restoring FP to its value prior to the function being
     * called, and restoring the return address in LR to the PC (program 
     * counter).
     *
     * POP accepts a list of registers to retrieve off the stack. Each register
     * retrieved increments the stack pointer by 4 bytes as the value is 
     * "popped off the stack".
     */
    .macro return
    pop {fp, pc}
    .endm
