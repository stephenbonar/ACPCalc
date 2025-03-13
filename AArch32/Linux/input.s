/* 
 * input.s - Provides functions for receiving input from the user.
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
    .global enter_number

    /* We store our string constants in the read-only data section. */
    .section .rodata

    entryString: .asciz "%d"

    /* Switch to the text section for the code. */
    .section .text

    .func enter_number
enter_number:
    init_stack_frame

    /* Allocate a local variable on the stack for the entered number. */
    sub sp, sp, #word_size_bytes
    .equ entry_offset, -8

    /* Print the prompt. */
    bl print_number_prompt

    /* Get the number from the keyboard. */
    ldr r0, =entryString
    add r1, fp, #entry_offset
    bl scanf
    bl getchar                   @ We need to capture the newline character.
    ldr r0, [fp, #entry_offset]  @ Load entry into r0 as the return value.

    /* Deallocate entry on the stack. */
    add sp, #word_size_bytes

    return
    .endfunc
