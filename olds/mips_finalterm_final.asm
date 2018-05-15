# Special register
# s7: command buffer
# s6: current command: 0: stop; 1: go; 2:right; 3: left; 4: return
# s5: address of commandList[0]
# s4: using command item in CommandList[]
# s3: current command in command list
# t7: switch case variable to save case value
# t6: direction of marsbot by angle (0->355) : init value: 0

.eqv MASK_CAUSE_KEYMATRIX 0x00000800 # Bit 11: Key matrix 

# Data Lab Sim keyboard
.eqv IN_ADRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADRESS_HEXA_KEYBOARD 0xFFFF0014

# Keyboard from  Keyboard & Display MMIO Simulator
.eqv KEY_CODE 0xFFFF0004 # ASCII code from keyboard, 1 byte
.eqv KEY_READY 0xFFFF0000 # =1 if has a new keycode

# Mars bot
.eqv HEADING 0xffff8010 # Integer: An angle between 0 and 359
 # 0 : North (up)
 # 90: East (right)
# 180: South (down)
# 270: West (left)
.eqv MOVING 0xffff8050 # Boolean: whether or not to move
.eqv LEAVETRACK 0xffff8020 # Boolean (0 or non-0):
 # whether or not to leave a track
.eqv WHEREX 0xffff8030 # Integer: Current x-location of
.eqv WHEREY 0xffff8040 # Integer: Current y-location of

.data
    commandList: .space 3200
    welcome_message: .asciiz "Mars Bot Controller\n"
    user_pressed_enter: .asciiz "Pressed: Enter\n"
    user_pressed_del: .asciiz "Pressed: Del\n"
    wrong_interupt_cause: .asciiz "Wrong interupt cause\n"
    message_wrong_command: .asciiz "Command not supported!\n"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAIN Procedure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.text
main:

	li $t6, 0

	li $a0, 180
	jal ROTATE
	nop
	

    #---------------------------------------------------------
    # Welcome message
    #---------------------------------------------------------
    addi $v0, $zero, 4
    la $a0, welcome_message
    syscall

    #---------------------------------------------------------
    # Enable interrupts you expect
    #---------------------------------------------------------
    # Enable the interrupt of Keyboard matrix 4x4 of Digital Lab Sim
    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x80 # bit 7 = 1 to enable
    sb $t3, 0($t1)

    #---------------------------------------------------------
    # Main loop
    #---------------------------------------------------------
    li $k0, KEY_CODE
    li $k1, KEY_READY
    
    # Load address of commandList
    la $s5, commandList
    addi $s4, $s5, 0
    
    # Assign the first command to stop
    li $t2, 0 # Command
   	sw $t2, 0($s5)
   	li $t2, 1 # Count
   	sw $t2, 4($s5)

    loop:

    WaitForKey:
    
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
    beq $s6, $t7, case_exe_return
	nop
    b case_exe_default
    nop
    case_exe_stop:
    	nop
    	# === STOP() ===
    	li $at, MOVING # change MOVING port to 0
 		sb $zero, 0($at) # to stop
    	# === end of STOP() ===
    	nop
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 100
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    case_exe_go:
    	# === GO() ===
        li $at, MOVING # change MOVING port
 		addi $k0, $zero,1 # to logic 1,
 		sb $k0, 0($at) # to start running
        # === End of GO() ===
        
        nop
        addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 100
 		syscall
        nop
        nop
        b write_to_cmdlist
        nop
    case_exe_right:
    	jal TURNRIGHT
    	nop
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 100
 		syscall
        nop
        nop
        
        # After rotate, set next command to GO
        li $s6, 1
        
        b write_to_cmdlist
        nop
    case_exe_left:
    	jal TURNLEFT
    	nop
    	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 		li $a0, 100
 		syscall
        nop
        nop
        
        # After rotate, set next command to GO
        li $s6, 1
        
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
    
   	j end_of_exe
    nop
    
    
    ## ======= RETURN TO ORIGIN POSITION =========
    case_exe_return:
    
    	# === UNTRACK() ===
    	li $at, LEAVETRACK # change LEAVETRACK port to 0
 		sb $zero, 0($at) # to stop drawing tail
 		# === End of UNTRACK() ===
    
    
    	# === RETURN() ===
    	# Return to original position using commandList
    	
    	loop_return:
    	beq $s4, $s5, end_of_return # Loop from the last position to the top of list
    	nop
    	
    	li $a0, 180 # Rotate to opposite direction
    	jal ROTATE
    	nop

    	jal UNTRACK
    	nop
    	
    	li $t7, 0
    	beq $s6, $t7, case_exe_revert_stop
    	nop
    	li $t7, 1
    	beq $s6, $t7, case_exe_revert_go
    	nop
    	li $t7, 2
    	beq $s6, $t7, case_exe_revert_right
    	nop
    	li $t7, 3
    	beq $s6, $t7, case_exe_revert_left
		nop
    	
    	case_exe_revert_go:
        	# === GO() ===
        	li $at, MOVING # change MOVING port
 			addi $k0, $zero,1 # to logic 1,
 			sb $k0, 0($at) # to start running
       		# === End of GO() ===
        	nop
        	addi $v0,$zero,32 # Keep running by sleeping in 100 ms
 			li $a0, 100
 			syscall
        	nop
        	nop
        	b end_of_revert_exe
        	nop
        case_exe_revert_stop:
        	# === STOP() ===
    		li $at, MOVING # change MOVING port to 0
 			sb $zero, 0($at) # to stop
    		# === end of STOP() ===
        	nop
        	b end_of_revert_exe
        	nop
        case_exe_revert_right:
        	jal TURNLEFT
    		nop
        	b end_of_revert_exe
        	nop
        case_exe_revert_left:
        	jal TURNRIGHT
    		nop
        	b end_of_revert_exe
        	nop
    	
    	end_of_revert_exe:
    	
    	
    	# Decrease the count variable if count > 1
    	#  or go to the previous command if count = 1
    	sw $t2, 4($s4)
    	
    	addi $t2, $t2, -1
    	beq $t2, $zero, decrease_count_of_current_command
    	nop
    	go_to_previous_command:
    	addi $s4, $s4, -8
    	
    	decrease_count_of_current_command:
    	sw $t2, 4($s4)
    	
    	j loop_return
    	nop

    	end_of_return:
    	
    	# === End of RETURN() ===
    	
    	
    	
    	# === STOP() ===
    	li $at, MOVING # change MOVING port to 0
 		sb $zero, 0($at) # to stop
    	# === end of STOP() ===
    	
    	
    	li $a0, 180 # Rotate to opposite direction
    	jal ROTATE
    	
    case_exe_default:
    end_of_exe:
    
    
    lw $t1, 0($k1) # $t1 = [$k1] = KEY_READY
    beq $t1, $zero, WaitForKey # if $t1 == 0 then Polling
    nop

    # Readkey
    #---------------------------------------------------------
    # Disable interrupts to fixbug
    #---------------------------------------------------------
    li $t1, IN_ADRESS_HEXA_KEYBOARD
    sb $zero, 0($t1)
    #---------------------------------------------------------
    
    lw $s2, 0($k0) # $s2 = [$k0] = KEY_CODE
   

    #---------------------------------------------------------
    # Enable interrupts you expect
    #---------------------------------------------------------
    # Enable the interrupt of Keyboard matrix 4x4 of Digital Lab Sim
    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x80 # bit 7 = 1 to enable
    sb $t3, 0($t1)
    #---------------------------------------------------------

    
    # Handle Enter key
    li $t1, 0x0000000a # Enter
    bne $s2, $t1, not_a_enter_key
    nop
    jal MarsBot_exec_command
    nop
    not_a_enter_key:

    # Handle Delele key
    li $t1, 0x0000007f # Delele
    bne $s2, $t1, not_a_delete_key
    nop
    li $s7, 0 # Reset command chain
    not_a_delete_key:
    
    
    j loop
    nop


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MARS BOT EXCUTION
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Excution the command
MarsBot_exec_command:
    
    addi $v0, $zero, 4
    la $a0, user_pressed_enter
    syscall
   

    # Print 1st character of command
    and $a0, $s7, 0xF00
    srl $a0, $a0, 8
    
    sw $ra,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
   	nop
   	jal show_character
   	nop
   	nop
   	lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
   	nop
   	
   	# Print 2nd character of command
    and $a0, $s7, 0x0F0
    srl $a0, $a0, 4
   	
   	sw $ra,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
   	nop
   	jal show_character
   	nop
   	nop
   	lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
   	nop
   	
   	# Print 2rd character of command
    and $a0, $s7, 0x00F
   	
   	sw $ra,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
   	nop
   	jal show_character
   	nop
   	nop
   	lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
   	nop
    
    # Print '\n'
    li $a0, '\n'
    li $v0, 11    # print_character
    syscall
    
    
    # IMPORTANT: SPLIT ALL PREVIOUS CHARACTER FROM $t7 EXCEPT THE CURRENT COMMAND
    # $s7 can save 8 characters of a command at maximum
    # => split 3 last characters (lower bits) to receive only current command
    and $t4, $s7, 0xFFF
    
    # Process the command
    process_command:
    li $t7, 0x1b4
    beq $t4, $t7, case_start
    li $t7, 0xc68
    beq $t4, $t7, case_stop
    li $t7, 0x444
    beq $t4, $t7, case_turnleft
    li $t7, 0x666
    beq $t4, $t7, case_turnright
    li $t7, 0xdad
    beq $t4, $t7, case_track
    li $t7, 0xcbc
    beq $t4, $t7, case_untrack
    li $t7, 0x999
    beq $t4, $t7, case_return
    nop
    b default_move
    nop
    case_start:
    	li $s6, 1
        b end_of_process
        nop
    case_stop:
    	li $s6, 0
        b end_of_process
        nop
    case_turnleft:
        li $s6, 3
        b end_of_process
        nop
    case_turnright:
    	li $s6, 2
        b end_of_process
        nop
    case_track:
    
    	# === TRACK () ===
    	li $at, LEAVETRACK # change LEAVETRACK port
 		addi $k0, $zero,1 # to logic 1,
 		sb $k0, 0($at) # to start tracking
 		# === End of TRACK() ===
    	
        b end_of_process
        nop
    case_untrack:
    	
    	# === UNTRACK () ===
    	li $at, LEAVETRACK # change LEAVETRACK port to 0
 		sb $zero, 0($at) # to stop drawing tail
 		# === End of UNTRACK() ===
    	
        b end_of_process
        nop
    case_return:
        li $s6, 4
        b end_of_process
        nop
    default_move:
        addi $v0, $zero, 4
    	la $a0, message_wrong_command
    	syscall
	
	end_of_process:
	

    jr $ra
    nop
# end of MarsBot_exec_command()

#-----------------------------------------------------------
# MARSBOT CONTROLLING
#-----------------------------------------------------------


j fixbug
#-----------------------------------------------------------
# GO procedure, to start running
# param[in] none
#-----------------------------------------------------------
GO: li $at, MOVING # change MOVING port
 addi $k0, $zero,1 # to logic 1,
 sb $k0, 0($at) # to start running
 jr $ra
 nop
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in] none
#-----------------------------------------------------------
STOP: li $at, MOVING # change MOVING port to 0
 sb $zero, 0($at) # to stop
 jr $ra
 nop
#-----------------------------------------------------------
# TRACK procedure, to start drawing line
# param[in] none
#-----------------------------------------------------------
TRACK: li $at, LEAVETRACK # change LEAVETRACK port
 addi $k0, $zero,1 # to logic 1,
 sb $k0, 0($at) # to start tracking
 jr $ra
 nop

#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in] none
#-----------------------------------------------------------
UNTRACK:li $at, LEAVETRACK # change LEAVETRACK port to 0
 sb $zero, 0($at) # to stop drawing tail
 jr $ra
 nop
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in] $a0, An angle between 0 and 359
# 0 : North (up)
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in] $a0, An angle between 0 and 359
# 0 : North (up)
# 90: East (right)
# 180: South (down)
# 270: West (left)
#-----------------------------------------------------------
ROTATE: li $at, HEADING # change HEADING port
 sw $a0, 0($at) # to rotate robot
 jr $ra
 nop
 
#-------------------------------------------------------------
# Turn right procedure, turn 90* right from current direction
# param: 
#-------------------------------------------------------------
TURNRIGHT:
	subi	$t6,$t6,90
	addi	$t6,$t6,360
	li		$t4,360
	div		$t6,$t4
	mfhi	$t6
	
	# Rotate procedure
	li	$at, HEADING	# change HEADING port
	sw	$t6, 0($at)		# to rotate robot
	jr	$ra

#-------------------------------------------------------------
# Turn left procedure, turn 90* left from current direction
# param: 
#-------------------------------------------------------------
TURNLEFT:
	subi	$t6,$t6,-90
	addi	$t6,$t6,360
	li		$t4,360
	div		$t6,$t4
	mfhi	$t6
	# Rotate procedure
	li	$at, HEADING	# change HEADING port
	sw	$t6, 0($at)		# to rotate robot
	jr	$ra
	

fixbug:

# In: $a0
# Change: $a0, $7
show_character:
    
    li $t7, 10
    beq $a0, $t7, case_print_a
    li $t7, 11
    beq $a0, $t7, case_print_b
    li $t7, 12
    beq $a0, $t7, case_print_c
    li $t7, 13
    beq $a0, $t7, case_print_d
    li $t7, 1
    beq $a0, $t7, case_print_1 
    li $t7, 4
    beq $a0, $t7, case_print_4 
    li $t7, 6
    beq $a0, $t7, case_print_6 
    li $t7, 8
    beq $a0, $t7, case_print_8
    li $t7, 9
    beq $a0, $t7, case_print_9
    nop
    b default_print
    nop
    case_print_a:
        li $a0, 'a'
        b print_char
        nop
    case_print_b:
        li $a0, 'b'
        b print_char
        nop
    case_print_c:
        li $a0, 'c'
        b print_char
        nop
    case_print_d:
        li $a0, 'd'
        b print_char
        nop
    case_print_1:
        li $a0, '1'
        b print_char
        nop
    case_print_4:
        li $a0, '4'
        b print_char
        nop
    case_print_6:
        li $a0, '6'
        b print_char
        nop
    case_print_8:
        li $a0, '8'
        b print_char
        nop
    case_print_9:
        li $a0, '9'
        b print_char
        nop
    default_print:
       li $a0, '-' # 15 is a default code determine a wrong command

	print_char:
    	li $v0, 11    # print_character
    	syscall
    	
   
    
    jr $ra
    nop
    
   
# end of show_character()




#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENERAL INTERRUPT SERVED ROUTINE for all interrupts
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ktext 0x80000180

#-------------------------------------------------------
# SAVE the current REG FILE to stack
#-------------------------------------------------------
IntSR:
	
	addi $sp,$sp,4 # Save $ra because we may change it later
    sw $ra,0($sp)
    addi $sp,$sp,4 # Save $at because we may change it later
    sw $at,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
    sw $v0,0($sp)
    addi $sp,$sp,4 # Save $a0, because we may change it later
    sw $a0,0($sp)
    addi $sp,$sp,4 # Save $t1, because we may change it later
    sw $t1,0($sp)
    addi $sp,$sp,4 # Save $t3, because we may change it later
    sw $t3,0($sp)
    
    
    get_caus:
	mfc0 $t1, $13 # $t1 = Coproc0.cause
	
	IsKeyMa:li $t2, MASK_CAUSE_KEYMATRIX # if Cause value confirm Key..
 	and $at, $t1,$t2
	beq $at,$t2, Keymatrix_Intr
	nop
	others: 
	
	addi $v0, $zero, 4
    la $a0, wrong_interupt_cause
    syscall
	
	nop
	
	j next_pc
	nop
	
	Keymatrix_Intr:


#--------------------------------------------------------
# Processing
#--------------------------------------------------------


# Get button digital lab sim
LabSim_get_cod:

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x81 # check row 1 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod
	nop


    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x82 # check row 2 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod
    nop

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x84 # check row 3 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod
    nop

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x88 # check row 4 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod
    nop

end_LabSim_get_cod:


# Decode and process keycode
LabSim_process_cod:

	# === DECODE() ===
    li $t7, 0x00000044
    beq $a0, $t7, case_a
    li $t7, 0xffffff84
    beq $a0, $t7, case_b
    li $t7, 0x00000018
    beq $a0, $t7, case_c
    li $t7, 0x00000028
    beq $a0, $t7, case_d
    li $t7, 0x00000021
    beq $a0, $t7, case_1 
    li $t7, 0x00000012
    beq $a0, $t7, case_4 
    li $t7, 0x00000042
    beq $a0, $t7, case_6 
    li $t7, 0x00000014
    beq $a0, $t7, case_8
    li $t7, 0x00000024
    beq $a0, $t7, case_9
    nop
    b default
    case_a:
        li $a0, 10
        b push_code_to_keychain
        nop
    case_b:
        li $a0, 11
        b push_code_to_keychain
        nop
    case_c:
        li $a0, 12
        b push_code_to_keychain
        nop
    case_d:
        li $a0, 13
        b push_code_to_keychain
        nop
    case_1:
        li $a0, 1
        b push_code_to_keychain
        nop
    case_4:
        li $a0, 4
        b push_code_to_keychain
        nop
    case_6:
        li $a0, 6
        b push_code_to_keychain
        nop
    case_8:
        li $a0, 8
        b push_code_to_keychain
        nop
    case_9:
        li $a0, 9
        b push_code_to_keychain
        nop
    default:
    	j next_pc
		nop
        #b push_code_to_keychain
       #li $a0, 15 # 15 is a default code determine a wrong command
       
	# Push keycode into keycode chain
	push_code_to_keychain:
	sll $s7, $s7, 4
	or $s7, $s7, $a0
	
	# === END OF DECODE() ===

j next_pc
nop

# End of LabSim_process_cod()

#--------------------------------------------------------
# Evaluate the return address of main routine
# epc <= epc + 4
#--------------------------------------------------------
next_pc:
    mfc0 $at, $14 # $at <= Coproc0.$14 = Coproc0.epc
    addi $at, $at, 4 # $at = $at + 4 (next instruction)
    mtc0 $at, $14 # Coproc0.$14 = Coproc0.epc <= $at


#--------------------------------------------------------
# RESTORE the REG FILE from STACK
#-------------------------------------------------------- 
restore:
    lw $t3, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    lw $t1, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    lw $a0, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    lw $v0, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
   	lw $at,0($sp) # Restore the registers from stack
    addi $sp,$sp,-4 
    lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    
    eret # Return from exception
