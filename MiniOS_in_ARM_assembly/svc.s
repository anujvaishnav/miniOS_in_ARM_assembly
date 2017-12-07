;-------------------------------------------------
; SVC Handler
; Anuj Vaishnav
; Version 1.0
; Created on 13/03/2016
;
; System call implementation for ARM processor
;
; Last modified: 01/05/2016 (AV) marked with small sub heading
;
; New additions: Create process, support for buzzer, modification in stop_2
; to relinquish CPU to other process and finally made getChar_9 a process  
; blocking SVC call. 
;
; Known bugs: None
;-------------------------------------------------

;-------------------------------------------------
; SVC call aliases 
;-------------------------------------------------
_printChar                EQU 0       ;
_printString              EQU 1       ;
_stop                     EQU 2       ;
_waitTime                 EQU 3       ;
_checkbuttons             EQU 4       ;
_printHexNumber           EQU 5       ;
_clearScrn                EQU 6       ;
_setCursorPosition        EQU 7       ;
_getSystemTime            EQU 8       ;
_getChar                  EQU 9       ;
_playBuzzer               EQU 10      ;
_createProcess            EQU 11      ; 

;-------------------------------------------------
; keyboard debouncing alises
;-------------------------------------------------
keyboardThreshold         EQU 8       ;
firstRow                  EQU 1       ;
secondRow                 EQU 2       ;
thirdRow                  EQU 4       ;
fourthRow                 EQU 8       ;
;-------------------------------------------------
; process related aliases
;-------------------------------------------------
free                      EQU 0       ;
active                    EQU 1       ;
blocked                   EQU 2       ;
noOfRegs                  EQU 15      ;
;-------------------------------------------------
                          ; SVC execption handler
                          ; from the svc argument in instruction, identify
                          ; the routine called by indexing into the jump table
                          ; and transfer controller to the dedicated routine.
                          ; Note it passes R1 & LR as scratch reg, which will 
                          ; be restored to original values before returning to
                          ; user, by routines
;-------------------------------------------------  
                          PUSH  {R1, LR}           ; push scratch register
                          LDR   R14, [LR, #-4]     ; Read SVC instructions
                          BIC   R14, R14, #svc_mask; Mask off the opcode
                          
                          ; compare with table max 
                          CMP   R14, #((end_jump_table - jump_table)/4);
                          BHI   out_of_range      ;
                          ADRL  R1, jump_table    ;
                          LDR   PC, [R1, R14, LSL #2];

jump_table                DEFW  printChar_0       ;
                          DEFW  printString_1     ;
                          DEFW  stop_2            ;
                          DEFW  waitTime_3        ;
                          DEFW  checkbuttons_4    ;
                          DEFW  printHex32Number_5;
                          DEFW  clearScreen_6     ;
                          DEFW  moveCursor_7      ;
                          DEFW  getSystemTime_8   ;
                          DEFW  getChar_9         ;
                          DEFW  buzzer_10         ;
                          DEFW  createProcess_11  ;
end_jump_table

out_of_range              B     .                 ;

;=================================================

;-------------------------------------------------    
printChar_0               ; print char routine, expects the arugment in R0
                          ; for consistency reason. Hence, it saves
                          ; argument reg of printChar(R4), passes the char to 
                          ; print and then recovers it later
;-------------------------------------------------
                          PUSH  {R4}           ;
                          MOV   R4, R0         ;
                          BL    printChar      ;
                          POP   {R4}           ;
                          POP   {R1,PC}^       ; return from the routine

;-------------------------------------------------   
printString_1             ; print string routine, expects the aurgement in R0
                          ; with 0 as string terminator
;------------------------------------------------- 
                          BL    printString    ;
                          POP   {R1, PC}^      ; return from the routine
                          
;-------------------------------------------------   
waitTime_3                ; wait time routine, expects the arugement in R2
                          ; R2 is the number of milliseconds SVC should wait
                          ; for before returning to program
;------------------------------------------------- 
                          
                          PUSH   {R0,R2-R4}  ;
                          MOV    R4, #timerLocation;
                          LDR    R1, [R4]    ; R1 will hold old value throughout
_timer                    LDR    R0, [R4]    ; R0 will hold new value throughout
                          CMP    R1, R0      ;
                          ; if(oldValue > newValue)
                          ; a = (255 - old value) [because wrap back happened]
                          BLE    OV_LE_NV
                          RSB    R3, R1, #255; 
                          ADD    R3, R3, R0  ; a = a + newValue
                          SUB    R2, R2, R3  ; timeLeft -= a
                          ; if(oldValue <= newValue)
OV_LE_NV                  SUBLE  R3, R0, R1  ; 
                          SUBLES R2, R2, R3  ; timeLeft -= (newValue-oldValue)
                          ; if timeLeft = 0
                          POPEQ  {R0,R2-R4}  ;
                          POPEQ  {R1, PC}^   ; 
                          ;MOVEQS PC, LR     ; return from the routine
                          MOV    R1, R0      ; update oldValue
                          B      _timer      ;
                          
;-------------------------------------------------   
checkbuttons_4            ; check buttons routine, returns pattern back 
                          ; if buttons asked by User are pressed else 
                          ; a garbage value is returned in R0
                          ; It expects bit pattern for buttons in R0
                          ; Possible bit patterns are defined in osHeader.s
                          ; for users to use
;------------------------------------------------- 
                          ADRL  R1, portB      ;
                          LDRB  R1, [R1]       ;
                          ; Clear all bits other than buttons
                          BIC   R0, R0, #buttonMask;
                          AND   R0, R1, R0     ; check status
                          POP   {R1, PC}^      ; return from the routine

;-------------------------------------------------    
printHex32Number_5        ; print hex number routine, expects the arugment in R0
;-------------------------------------------------
                          ROR   R0, R0, #(7*4) ; ROR by 1 hexDigit to restore it
                          MOV   R1, #8         ;
_nextDigit                BL    printHex4      ;
                          ROR   R0, R0, #(32-4); 
                          SUBS  R1, R1, #1     ;
                          BNE   _nextDigit     ;
                          POP   {R1,PC}^       ; return from the routine
                          
printHex4                 PUSH  {R0,R4, LR}    ;
                          MOV   R4, #maskOffUpperNibble
                          BIC   R0, R0, R4     ;
                          CMP   R0, #9         ;
                          ADDGT R0, R0, #('A' - 10)
                          ADDLE R4, R0, #('0') ;
                          BL    printChar      ;
                          POP   {R0,R4, PC}    ;

;-------------------------------------------------   
clearScreen_6             ; clear screen routine, clears the lcd screen
;------------------------------------------------- 
                          BL    clrScrn        ;
                          POP   {R1, PC}^      ; return from the routine

;-------------------------------------------------   
moveCursor_7   ; This function moves the cursor to the given char position.
               ; It expects the char position in R0 (Consistency reasons).
               ; Note the char position starts from 0 to 40 and spread 
               ; over 2 lines in sequence and only making the 
               ; first 16 characters of the top two lines visible on screen.
;------------------------------------------------- 
                          PUSH {R4}            ; 
                          MOV  R4, R0          ; Prepare argument for mvCursorTo
                          BL   mvCursorTo      ;
                          POP  {R4}            ; Restore original R4
                          POP  {R1, PC}^       ; return from the routine

;-------------------------------------------------   
getSystemTime_8           ; Returns system Time in R0
;------------------------------------------------- 
                          ADRL  R1, systemTime  ;
                          LDR   R0, [R1]        ;
                          POP   {R1, PC}^       ;

;================================================
;============== The new addition ================
;================================================

;------------------------------------------------- 
stop_2                    ; Stops the execution of user program by setting it
                          ; inactive and then calls the scheduler's pick process
                          ; N.b. We are not restoring R1 & LR as user process
                          ; to which they belonged to, is terminated.
                          ; LR earlier stored the return address to user program
;-------------------------------------------------
                          LDR   R1, active_process ; get process number
                          MOV   R14, #0            ; set the process inactive
                          STRB  R14, [R1, #active_threads];
                          
                          ADD   SP, SP, #8; forget return address and R1
                          ; R14 is user SP as argument for enterPickProcess 
                          B     enterPickProcess;
                          
;-------------------------------------------------
getChar_9                ; This SVC call blocks the user process until user
                         ; presses a key. After which keyboardListener sets the
                         ; process active again, and the process continues
                         ; its execution from the instruction after SVC _getChar
                         ; call. The R0 at this point in time will hold the 
                         ; key, user pressed.
                         ; Return argument form user process's perspective
                         ; is in R0.
                         ; N.b. we do not call scheduler directly
                         ; as we need to set SP and process number for 
                         ; keyboardListener
;-------------------------------------------------
                         ; get R1 and return address
                         POP  {R1, R14}     ;
                         
                         ; Save context
                         PUSH {R2}          ; save scratch regs
                         PUSH {SP}^         ; get user SP
                         POP  {R2}          ;
                         
                         ; n.b. PC(R14) is stored first
                         STMFD r2!, {R14}   ;
                         MOV   R14, R2      ;
                         POP   {R2}         ; recover user R2
                         
                         STMFD R14!, {R0-R12}; save most of the user regs
                         PUSH  {LR}^         ;
                         POP   {R2}          ; get user LR
                         MRS   R1, SPSR      ;
                         ;N.B. Higher reg is pushed first
                         STMFD R14!, {R1, R2}; push LR and flags on user stack
                         
                         ; save user SP for keyboardListener
                         STR   R14, waitingThread       ;
                         
                         ; Set active Thread as blocked
                         MOV   R0, #blocked             ;
                         LDR   R1, active_process       ; 
                         STRB  R0, [R1, #active_threads];
                         
                         ; set process number for keyboardListener
                         STR   R1, waitingThread + 4    ;
                         
                         ; Giving user SP in R14 as argument
                         B     enterPickProcess         ;

;-------------------------------------------------   
buzzer_10                ; Plays the buzzer with a frequency given in R0
                         ; Note it relies heavily on hardware to identify
                         ; what the frequency is.
;------------------------------------------------- 
                         ADRL  R1, buzzer_loc  ; get buzzer location
                         STRB  R0, [R1]        ; set buzzer frequency
                         POP   {R1, PC}^       ; return to user program
                          
;-------------------------------------------------
createProcess_11        ; Creates a new process, who's starting memory location 
                        ; is expected in R0. It return 0 in R0 if it cannot be
                        ; created else a 1.
                        ; This call fails to create a process when OS is already
                        ; operating at max number of process, and doesn't have
                        ; memory for new one.
;-------------------------------------------------                          
                        ; save scratch regs
                        PUSH {R2, R3}          ;
                        ; maxThreads starts numbering from 0 hence to get
                        ; total max threads we do +1.
                        ; It will serve as thread remaining to check counter.
                        MOV R1, #maxThreads + 1;
                        
                        ; scan for free process space
scanForProcess          SUBS  R1, R1, #1 ; Decrement remaining to check counter 
                        ; if no process slot is free return back to user 
                        MOVEQ R0, #0                   ;
                        BEQ   exit_create_process      ;          
                        ; check if the process slot is empty
                        LDRB  R2, [R1, #active_threads];
                        CMP   R2, #free                ;
                        ; if free slot is not found try another
                        BNE   scanForProcess           ; 

                        ; set the process slot as active
setProcessActive        MOV   R3, #active;
                        STRB  R3, [R1, #active_threads];
                        
                        ; get stack space for new process
setupStack              MOV  R2, #threadStackLimit;
                        ADRL R3, user_stack       ; get initial user_stack SP
                        ; calculate SP for new process. 
                        MLA  R2, R1, R2, R3       ; (processNo*stackSize + base)
                        
                        ; we will set up the stack with default reg values
                        ; for scheduler to be restored, so that it doesn't
                        ; have to differenciate between already running and new
                        ; process 
                        ; Set PC of new process in its initial stack
                        STMFD R2!, {R0}              ;
                        MOV   R3, #noOfRegs          ;
                        ADR   R14,initialStackState-4;
                        
                        ; push all default regs to new process's stack
stackSetupLoop          LDR   R0, [R14, R3, LSL #2]  ;
                        STMFD R2!, {R0}              ; 
                        SUBS  R3, R3, #1             ;
                        BNE   stackSetupLoop         ;
                        
setSPForScheudler       ; Update PCB entry with resulting SP of new process
                        ; This will be then used by scheduler when it tries to
                        ; run the process on its turn.
                        ADR  R0, pcb                 ;
                        STR  R2, [R0, R1, LSL #2]    ;
                        MOV  R0, #1                  ; return success
exit_create_process                        
                        POP   {R2, R3}               ;
                        POP   {R1, PC}^              ; return to user program

initialStackState       
                        ; Define default reg values with which the process
                        ; will start. (They are set by the scheudler, as it
                        ; simply loads the reg values from stacks for next
                        ; proces to run. Defining the from the start on stack
                        ; enabels the scheudler to make no distinguisment from
                        ; new and old process. Making it simpler.)                 
                        DEFW  user_mode_int_setting ; flags
                        DEFW  0,0,0,0
                        DEFW  0,0,0,0
                        DEFW  0,0,0,0
                        DEFW  0,0    ; Need to be followed by PC
