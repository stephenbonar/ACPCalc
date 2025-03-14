/* 
 * main.s - Main program source file.
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

    /* 
     * The include directive copies and pastes the content of "macros.s" into
     * this source file. Other source files will simply be assembled and linked
     * to this one. In this case, we're including common macros that can be
     * shared across the various source files in our program.
     */
    .include "macros.s"

    /* 
     * Here we define the main function as a global as it needs to be
     * global to work properly.
     */
    .global main

    /* The .rodata section contains string constants */
    .section .rodata

/* We create labeled zero-terminated string constants with .asciz directive */
invalidChoiceError: .asciz "Invalid Choice!"

    /* 
     * Since we specified the .rodata section first, we need to indicate we're
     * back in the .text section where the code lives.
     */
    .text

    /* 
    * Main application entry point
    *
    * .func main tells the assembler that the code pointed to by the main label is
    * a function. This helps the debugger recognize main as a function.
    *
    * main: is a label. Labels like this get replaced by the assembler with a
    * memory address in the application's virtual address space. Named labels like
    * this also become symbols when assembled. Labels point to the first
    * instruction or data that immidately follows. The assembler automatically
    * picks an appropriate memory address in relation to the rest of the program.
    * Labels are a convinient way of referring to memory locations without having
    * to hand pick memory appropriate memory addresses.
    */
    .func main
main:
    /* 
     * Inserts code to initialize main's stack frame using a macro. See 
     * macros.s for more details.
     */
    init_stack_frame

    /* 
     * Here we're allocating a single .word local variable on the stack for
     * the result and initializing it. We can create a new variable on the
     * stack without push or pop by simply moving the stack pointer to the
     * next available position. We do this by subtracting the size of a word
     * (4 bytes) from the stack pointer (the system stack grows downward
     * towards lower memory addresses. This is what happens in C when you
     * create a local variable in a function.
     *
     * SUB <dest>, <operand1>, <operand2> subtracts operand2 from operand1
     * and stores the result in <dest>.
     *
     * .equ assigns a name to an immediate value. Here result_offset will
     * keep track of the offset from the frame pointer of the result local
     * variable we allocated.
     *
     * MOV <dest>, <source> copies the source value into the destination 
     * register.
     *
     * STR <source>, <dest> stores the value in the source register in the
     * specified memory location. In this case, we're storing 0 in the
     * variable we created on the stack, which we can reference as an
     * offset of the frame pointer, since the frame pointer points to the
     * bottom of the stack frame allocated for this function. 
     */
    sub sp, sp, #word_size_bytes
    .equ result_offset, -8
    mov r0, #0
    str r0, [fp, #result_offset]

    /*
     * Print information about the program (version, copyright, etc.)
     *
     * We print the program information to the screen by calling the function
     * print_program_info(). The print_program_info function is defined in the
     * output.s source file.
     *
     * BL <address> tells the CPU to jump to the instructions at the specified
     * address and store the current program counter address in the link 
     * register (LR) as a return address. This calls the function.
     */
    bl print_program_info

    /* 
     * Main menu loop.
     *
     * 10: is a local label. These numbered labels (0 - 99) are used for branching
     * to different parts of a function or macro rather than an entirely new 
     * subroutine. This is useful for loops and conditionals where you're still
     * within a subroutine but need to jump to different parts of that routine.
     * Unlike named labels, local labels do not get symbols in the executable. 
     * Local labels must always start with a number but can be optionally followed
     * by a name.
     */
10:
    /* Load the result from the local variable on the stack so we can print. */
    ldr r0, [fp, #result_offset]

    /* Print the current result in binary, hexadecimal, and decimal formats. */
    bl print_result

    /* Display the menu choices and the choice prompt. */
    bl print_menu

    /* 
     * We will call the getchar function in libc to read in a single character
     * from the keyboard to get the user's choice.
     *
     * int getchar(void);
     *
     * The return value is stored in r0 by convention, so that's where the char
     * will be stored.
     */
    bl getchar

    /*
     * Use the compare instruction to determine which menu entry to jump to. 
     *
     * CMP operand1, operand2 compares the two operands by subtracting operand2
     * from operand1, discarding the result. CMP updates the status register 
     * based on the result. If subtraction results in 0, then the zero flag is
     * set, which many conditional instructions will honor as EQ or equal.
     * Otherwise, the zero flag will be cleared, which conditional instructions
     * will honor as NE or not equal. Also, depending on the result, the
     * negative flag will be set or cleared, which LE, GT, etc.
     *
     * beq adds a conditional suffix to the b (branch) instruction to tell the
     * program to jump to the local label 2 only if r0 was equal. The 'f'
     * suffix tells the assembler to branch to the local label 2 that 
     * immediately follows this instruction. This is needed in case there are
     * multiple local labels in the program named 2. 
     */
    cmp r0, #'0'
    beq 0f
    cmp r0, #'1'
    beq 1f
    cmp r0, #'2'
    beq 2f
    cmp r0, #'3'
    beq 3f

    /* 
     * If we reach this point, we've entered an invalid menu choice. 11: prints
     * an error for invalid choice and returns to the main menu.
     */
    bal 11f

    /* 
     * Menu Selection 1.
     *
     * Prompts the user to enter a number and store it in the result. Returns
     * to the main menu by branching to 10b.
     *
     * BAL adds the conditional suffix AL (always) to the b (branch) 
     * instruciton. This is the default suffix so it isn't strictly necessary,
     * (we could have just written 'b'), but it makes it clear we want an
     * unconditional branch here. In this case we are jumping to local label 1,
     * which returns from the function. We use the 'b' suffix on the local
     * label to indicate we want to jump to the local label 1 that comes 
     * immediately before this instruction. 
     */
1:
    bl enter_number
    str r0, [fp, #result_offset]
    bal 10b

    /*
     * Menu Selection 2.
     *
     * Promps the user to enter a number to add to the result. Returns to the
     * main menu by branching to 10b.
     */
2:
    bl enter_number
    mov r1, r0
    ldr r0, [fp, #result_offset]
    add r0, r0, r1
    str r0, [fp, #result_offset]
    bal 10b

    /*
     * Menu Selection 3.
     *
     * Promps the user to enter a number to subtract from the result. Returns
     * to the main menu by branching to 10b.
     */
3:
    bl enter_number
    mov r1, r0
    ldr r0, [fp, #result_offset]
    sub r0, r0, r1
    str r0, [fp, #result_offset]
    bal 10b

11:
    /* 
     * Prints the invalid choice error.
     */
    ldr r0, =invalidChoiceError
    bl print_error
    bal 10b

    /* 
     * Local label for exiting / returning from the function.
     *
     * We want to return 0 for success. R0 contains the return value by
     * convention, so we first store 0 in R0.
     *
     * We then add 4 to the stack pointer to deallocate the
     * local result variable so the stack pointer is once again pointing
     * to the link register preserved at the top of the stack frame.
     *
     * We then call the return macro defined in macros.s to pop the 
     * frame pointer and link register off the stack, unwinding the stack
     * frame. 
     */
0:
    mov r0, #0
    add sp, sp, #word_size_bytes
    return
    .endfunc
