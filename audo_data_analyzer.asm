.data
    pr_filName: .asciiz "Enter a wave file name:\n"
    pr_filSize: .asciiz "Enter the file size (in bytes):\n"
    fileName: .space 100

    out_info: .asciiz "Information about the wave file:\n================================\n"

    out_max: .asciiz "Maximum amplitude: "
    out_min: .asciiz "\nMinimum amplitude: "

    error_msg: .asciiz "Error: Could not open file.\n"
    read_err_msg: .asciiz "Error: Could not read the file.\n"

#############################
# file size - $s0
# file address - $s1 (heap memory where file content is)
# max - $t2
# min - $t0
#############################

.text
main:
    # Get file name from user
    li $v0, 4
    la $a0, pr_filName
    syscall

    li $v0, 8
    la $a0, fileName
    li $a1, 100
    syscall

    jal remove_newline      # Remove newline from file name

    # Get file size from user
    li $v0, 4
    la $a0, pr_filSize
    syscall

    li $v0, 5
    syscall
    move $s0, $v0       # Store file size in $s0

    # Dynamic memory allocation
    move $a0, $v0       # File size in $a0
    li $v0, 9           # sbrk syscall for dynamic memory allocation
    syscall
    move $s1, $v0       # Store heap memory address in $s1

open_file:
    li $v0, 13          # syscall to open the file
    la $a0, fileName    # File name from user
    li $a1, 0           # Read-only mode
    li $a2, 0           # No additional flags
    syscall
    move $t2, $v0       # Store file descriptor in $t2

    # Check if file opened successfully
if_succesful:
    bgez $t2, read_file # If file descriptor >= 0, go to read_file
else_print_error:       # Otherwise, print error and exit
    li $v0, 4
    la $a0, error_msg
    syscall
    j exit

read_file:
    # Read file into dynamically allocated memory
    move $a0, $t2       # File descriptor
    move $a1, $s1       # Heap memory address from $s1
    move $a2, $s0       # File size from $s0
    li $v0, 14          # syscall for reading a file
    syscall
    
    # Check if the file was read successfully
    bltz $v0, read_error  # If return value < 0, print error and exit
    j find_min_max

read_error:
    li $v0, 4
    la $a0, read_err_msg
    syscall
    j exit

find_min_max:
    addi $t7, $s1, 44       # skip the header-first 44 bytes, $t7 new address
    add $t8, $s0, $zero     # copy file size (boundary checking)
    sub $t8, $t8, 44        # subtract 44 bytes (header) reamin with size of audo data

    lb $t0, 0($t7)
    lb $t1, 1($t7)
    sll $t1, $t1, 8
    or $t0, $t0, $t1    #$t0 = min  -- just an assumption

    lb $t2, 2($t7)
    lb $t3, 3($t7)
    sll $t3, $t3, 8
    or $t2, $t2, $t3    #$t3 = max  -- just an assumption

    #check if assumption correct
    bgt $t0, $t2 change_max

    addi $t7, $t7, 4    #done with first 4 bytes

find_min_mac_loop:       #load next 4 bytes (2 vals, possible min and/or max), increment address and index until same as size
    addi $t7, $t7, 2    #move to next 2 bytes
    sub $t8, $t8, 2     # decrement my index -- (remaining size)

best_case:
    blez $t8, done_min_max      # my track/index has reached zero, exit loop

    #load next 4 bytes - 2 values
    lb $t3, 0($t7)
    lb $t4, 1($t7)
    sll $t4, $t4, 8
    or $t3, $t3, $t4

    #check if the new value is less than current min
    blt $t3, $t0 update_min

    #or check if greater that our current max
    bgt $t3, $t2 update_max

    j find_min_mac_loop

done_min_max:
    li $v0, 4
    la $a0, out_max
    syscall

    li $v0, 1
    move $a0, $t2
    syscall

    #output minimum amplitude
    li $v0, 4
    la $a0, out_min
    syscall

    li $v0, 1
    move $a0, $t0
    syscall

    j exit


change_max:
    move $t3, $t2   #copy new min
    move $t2, $t0   #new max
    move $t0, $t3   #update new min

    j find_min_mac_loop     # Continue the loop

update_min:
    move $t0, $t3   # update min val
    j find_min_mac_loop
update_max:
    move $t2, $t3   # update max val
    j find_min_mac_loop # continue the loop

remove_newline:
    la $t0, fileName

find_newline:
    lb $t1, 0($t0)
base_case:
    beqz $t1, done
else_found_replace:         # If we're at the newline, replace it
    beq $t1, 0x0A, remove_it
else:                       # We haven't reached the newline, keep looking
    addi $t0, $t0, 1
    j find_newline

remove_it:
    sb $zero, 0($t0)

done:
    jr $ra

exit:
    li $v0, 10
    syscall
