    .data
    pr_filName: .asciiz "Enter a wave file name:\n"
    pr_filSize: .asciiz "Enter the file size (in bytes):\n"
    fileName: .space 100
    
    out_info: .asciiz "Information about the wave file:\n================================\n"
    out_max: .asciiz "Maximum amplitude: "
    out_min: .asciiz "\nMinimum amplitude: "
    
    error_msg: .asciiz "Error: Could not open file.\n"
    read_err_msg: .asciiz "Error: Could not read the file.\n"
    
    .text
    main:
        # Prompt the user to enter the file name
        li $v0, 4
        la $a0, pr_filName
        syscall
    
        # Read file name input
        li $v0, 8
        la $a0, fileName
        li $a1, 100
        syscall
    
        # Remove newline from the file name
        jal remove_newline
    
        # Prompt the user to enter the file size
        li $v0, 4
        la $a0, pr_filSize
        syscall
    
        # Read file size input
        li $v0, 5
        syscall
        move $s0, $v0           # Store file size in $s0
    
        # Allocate dynamic memory to hold the file contents
        move $a0, $s0
        li $v0, 9               # sbrk syscall for dynamic memory allocation
        syscall
        move $s1, $v0           # Store the address of the allocated memory in $s1
    
    open_file:
        # Open the file
        li $v0, 13              # syscall to open the file
        la $a0, fileName        # File name from user
        li $a1, 0               # Read-only mode
        li $a2, 0               # No additional flags
        syscall
        move $t2, $v0           # Store the file descriptor in $t2
    
        # Check if file opened successfully
        bgez $t2, read_file     # If file descriptor >= 0, go to read_file
    
    else_print_error:
        li $v0, 4
        la $a0, error_msg
        syscall
        j exit
    
    read_file:
        # Read file contents into memory
        move $a0, $t2           # File descriptor
        move $a1, $s1           # Address in memory where the file will be read
        move $a2, $s0           # File size
        li $v0, 14              # syscall for reading a file
        syscall
    
        # Check if the file was read successfully
        bltz $v0, read_error    # If return value < 0, print error and exit
        j find_min_max
    
    read_error:
        li $v0, 4
        la $a0, read_err_msg
        syscall
        j exit
    
    find_min_max:
        addi $t7, $s1, 44       # Skip the header (first 44 bytes)
        sub $t8, $s0, 44        # Remaining file size (subtract header)
    
        # Initialize min and max with the first sample (16-bit)
        lh $t0, 0($t7)          # Load the first 16-bit sample as min
        move $t2, $t0           # Set max equal to the first sample
    
        addi $t7, $t7, 2        # Move to the next sample
        sub $t8, $t8, 2         # Decrease the remaining size
    
    find_min_mac_loop:
        blez $t8, done_min_max  # If remaining size <= 0, exit loop
    
        lh $t3, 0($t7)          # Load the next 16-bit sample
    
        # Check if the new sample is less than the current min
        blt $t3, $t0 update_min
    
        # Check if the new sample is greater than the current max
        bgt $t3, $t2 update_max
    
        addi $t7, $t7, 2        # Move to the next sample
        sub $t8, $t8, 2         # Decrease remaining size
        j find_min_mac_loop
    
    done_min_max:
        # Output the maximum amplitude
        li $v0, 4
        la $a0, out_max
        syscall
    
        li $v0, 1
        move $a0, $t2           # Output max value
        syscall
    
        # Output the minimum amplitude
        li $v0, 4
        la $a0, out_min
        syscall
    
        li $v0, 1
        move $a0, $t0           # Output min value
        syscall
    
        j exit
    
    update_min:
        move $t0, $t3           # Update min value
        j find_min_mac_loop
    
    update_max:
        move $t2, $t3           # Update max value
        j find_min_mac_loop
    
    remove_newline:
        la $t0, fileName
    
    find_newline:
        lb $t1, 0($t0)
        beqz $t1, done_remove_newline
        beq $t1, 0x0A, remove_it
        addi $t0, $t0, 1
        j find_newline
    
    remove_it:
        sb $zero, 0($t0)
    
    done_remove_newline:
        jr $ra
    
    exit:
        li $v0, 10              # Exit syscall
        syscall
