.data
    pr_filName: .asciiz "Enter a wave file name:\n"
    pr_filSize: .asciiz "Enter the file size (in bytes):\n"
    fileName: .space 100

    out_info: .asciiz "Information about the wave file:\n================================\n"

    out_max: .asciiz "Maximum amplitude: "
    out_min: .asciiz "\nMinimum amplitude: "

    #############################
    # file size - $t0
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

remove_newline:
#
    jr $ra