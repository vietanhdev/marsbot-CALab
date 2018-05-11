# This program use s5, s6, s7 to store current command

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
MarsBot
.eqv WHEREY 0xffff8040 # Integer: Current y-location of
MarsBot


.data
    welcome_message: .asciiz "Mars Bot Controller\n"
    user_pressed_enter: .asciiz "Pressed: Enter\n"
    user_pressed_del: .asciiz "Pressed: Del\n"

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# MAIN Procedure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.text
main:
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

    loop:

    WaitForKey: lw $t1, 0($k1) # $t1 = [$k1] = KEY_READY
    beq $t1, $zero, WaitForKey # if $t1 == 0 then Polling
    nop

    # Readkey
    lw $s2, 0($k0) # $s2 = [$k0] = KEY_CODE
    
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
    jal MarsBot_exec_command
    nop
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

    jr $ra

# end of MarsBot_exec_command()

# Delete the command
MarsBot_del_command:
    addi $v0, $zero, 4
    la $a0, user_pressed_del
    syscall

    jr $ra

# end of MarsBot_del_command()


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GENERAL INTERRUPT SERVED ROUTINE for all interrupts
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.ktext 0x80000180

#-------------------------------------------------------
# SAVE the current REG FILE to stack
#-------------------------------------------------------
IntSR: addi $sp,$sp,4 # Save $ra because we may change it later
    sw $ra,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
    sw $at,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
    sw $v0,0($sp)
    addi $sp,$sp,4 # Save $a0, because we may change it later
    sw $a0,0($sp)
    addi $sp,$sp,4 # Save $t1, because we may change it later
    sw $t1,0($sp)
    addi $sp,$sp,4 # Save $t3, because we may change it later
    sw $t3,0($sp)


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

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x82 # check row 2 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x84 # check row 3 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod

    li $t1, IN_ADRESS_HEXA_KEYBOARD
    li $t3, 0x88 # check row 4 and re-enable bit 7
    sb $t3, 0($t1) # must reassign expected row
    li $t1, OUT_ADRESS_HEXA_KEYBOARD
    lb $a0, 0($t1)
    bne $a0, $zero, end_LabSim_get_cod

end_LabSim_get_cod:


# Decode and process keycode
LabSim_process_cod:
    sw $ra,0($sp)
    addi $sp,$sp,4 # Save $ra because we may change it later
    sw $t7,0($sp)
    addi $sp,$sp,4 # Save $t7 because we may change it later

    jal LabSim_decode_keycode
    nop

    # Push keycode into keycode chain
    addi $s5, $s6, 0
    addi $s6, $s7, 0
    addi $s7, $a0, 0

    lw $t7, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4

    li  $v0, 11           # service 11 is print char
    syscall

    li $v0,11
    li $a0,'\n' # print endofline
    syscall

j next_pc
nop


# Function decode keycode
# Change: $a0, $t7
LabSim_decode_keycode:
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
        li $a0, 'a'
        b end_LabSim_decode_keycode
        nop
    case_b:
        li $a0, 'b'
        b end_LabSim_decode_keycode
        nop
    case_c:
        li $a0, 'c'
        b end_LabSim_decode_keycode
        nop
    case_d:
        li $a0, 'd'
        b end_LabSim_decode_keycode
        nop
    case_1:
        li $a0, '1'
        b end_LabSim_decode_keycode
        nop
    case_4:
        li $a0, '4'
        b end_LabSim_decode_keycode
        nop
    case_6:
        li $a0, '6'
        b end_LabSim_decode_keycode
        nop
    case_8:
        li $a0, '8'
        b end_LabSim_decode_keycode
        nop
    case_9:
        li $a0, '9'
        b end_LabSim_decode_keycode
        nop
    default:
        li $a0, '-'

end_LabSim_decode_keycode:

jr $ra
nop

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
    lw $ra, 0($sp) # Restore the registers from stack
    addi $sp,$sp,-4
    return: eret # Return from exception


#-----------------------------------------------------------
# MARSBOT CONTROLLING
#-----------------------------------------------------------

#-----------------------------------------------------------
# GO procedure, to start running
# param[in] none
#-----------------------------------------------------------
GO: li $at, MOVING # change MOVING port
 addi $k0, $zero,1 # to logic 1,
 sb $k0, 0($at) # to start running
 jr $ra
#-----------------------------------------------------------
# STOP procedure, to stop running
# param[in] none
#-----------------------------------------------------------
STOP: li $at, MOVING # change MOVING port to 0
 sb $zero, 0($at) # to stop
 jr $ra
#-----------------------------------------------------------
# TRACK procedure, to start drawing line
# param[in] none
#-----------------------------------------------------------
TRACK: li $at, LEAVETRACK # change LEAVETRACK port
 addi $k0, $zero,1 # to logic 1,
 sb $k0, 0($at) # to start tracking
 jr $ra

#-----------------------------------------------------------
# UNTRACK procedure, to stop drawing line
# param[in] none
#-----------------------------------------------------------
UNTRACK:li $at, LEAVETRACK # change LEAVETRACK port to 0
 sb $zero, 0($at) # to stop drawing tail
 jr $ra
#-----------------------------------------------------------
# ROTATE procedure, to rotate the robot
# param[in] $a0, An angle between 0 and 359
# 0 : North (up)