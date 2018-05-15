    # Move using command from $s6 register
    li $t7, 0
    beq $s6, $t7, case_exe_stop
    li $t7, 1
    beq $s6, $t7, case_exe_go
    li $t7, 2
    beq $s6, $t7, case_exe_right
    li $t7, 3
    beq $s6, $t7, case_exe_left
    li $t7, 4
	nop
    b case_exe_default
    nop
    case_exe_stop:
    	jal STOP
    	nop
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 1000
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    case_exe_go:
        jal GO
        
        addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 1000
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    case_exe_right:
    	li $a0, 90
    	jal ROTATE
    
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 1000
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    case_exe_left:
    	li $a0, 270
		jal ROTATE
    
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 1000
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    	
   	
   	write_to_cmdlist:
   	lw $s3, 0($s4)

    nop
    beq $s3, $s6, already_in_list
    nop
    
    # If cmd not in list, write it to list
    add $s4, $s4, 8
    sw $s6, 0($s4)
    li $t2, 1
    sw $t2, 4($s4)
    
    nop
    b  end_of_exe
    nop
    already_in_list:
    	# load and increase cmd count
    	lw $t2, 4($s4)
    	addi $t2, $t2, 1
    	sw $t2, 4($s4)
    
   	
    case_exe_default:
    end_of_exe:
