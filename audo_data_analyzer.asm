.data
    pr_filName: .asciiz "Enter a wave file name:\n"
    pr_filSize: .asciiz "Enter the file size (in bytes):\n"
    fileName: .space 100

    out_info: .asciiz "Information about the wave file:\n================================\n"

    out_max: .asciiz "Maximum amplitude: "
    out_min: .asciiz "\nMinimum amplitude: "

     error_msg: .asciiz "Error: Could not open file.\n"

    #############################
    # file size - $t0
    # file address - $t1
    # 
    #############################

.text
main:
# get file nume from user
    li $v0, 4
    la $a0, pr_filName
    syscall

    li $v0, 8
    la $a0, fileName
    li $a1, 100
    syscall

    jal remove_newline      #plan is to know If was able to read the file before ask for the file size

# get file size from user
    li $v0, 4
    la $a0, pr_filSize
    syscall

    li $v0, 5
    syscall
    move $t0, $v0       # keep copy of file size

    # dynamic memory allocation
    move $a0, $v0       # $v0 & $t0 currently has the file size
    li $v0, 9
    syscall
    move $t1, $v0       # heap memory address location

open_file:
    li $v0, 13
    la $a0, fileName
    li $a1, 0
    li $a2, 0
    syscall
    move $t2, $v0       # file discriptor

    #check if open file succesful
if_succesful: #then read the file
    bgez $t2, read_file
else_print_error:
    li $v0, 4
    la $a0, error_msg
    syscall

    j exit

read_file:
    li $v0, 1
    move $a0, $t2
    syscall

    j exit


# find_min_max:
#     lb 

remove_newline:
    la $t0, fileName

find_newline:
    lb $t1, 0($t0)
base_case:
    beqz $t1, done
else_found_replace:                       # if we're at the newline -> replace it
    beq $t1, 0x0A, remove_it
else:                       # we haven't reached the newline position, then keep looking
    addi $t0, $t0, 1
    j find_newline

remove_it:
    sb $zero, 0($t0)

done:
    jr $ra

exit:
    li $v0, 10
    syscall