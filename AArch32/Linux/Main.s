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

    .global _start

/*
 * Main application entry point.
 */
_start:
    ldr r0, =hello @ Load the address of hello into r0.
    mov r1, #14    @ Set the character length to 14.

/*
 * Prints the specified string to standard output.
 *
 * r0 - A pointer to the string to print.
 * r1 - The number of characters to print. 
 */
_print:
    mov r2, r1 @ Move character count into the register the syscall expects.
    mov r1, r0 @ Move string into the register the syscall expects.
    mov r0, #1 @ Set file descriptor to stdout.
    mov r7, #4 @ Set syscall 4 - write.
    swi 0      @ Make syscall via software interrupt.

/*
 * Exits the program via syscall.
 *
 * r0 - The return code to exit with.
 */
_exit:
    mov r7, #1 @ Set syscall 1 - exit.
    swi 0      @ Make syscall via software interrupt.

    .data
hello: .ascii "Hello, world!\n"

