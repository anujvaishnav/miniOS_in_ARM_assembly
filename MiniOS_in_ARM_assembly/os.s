;-------------------------------------------------
; OS
; Anuj Vaishnav
; Version 2.0
; Created on 15/02/2016
;
; The OS initalises itself including the stacks and anything else
; application might need before dispatching the control to user code.
; The user then interacts with hardware using the SVC calls (set up by OS) and
; can also launch a new process and terminate itself.
;
; Last modified: 01/05/2016 (AV) (Changes are marked with small header)
;
; Known bugs: None
;
;-------------------------------------------------
                          ; import the settings of OS
                          INCLUDE ./osHeader.s;
;================================================
; ARM Vector table. Note it must start from address 0 for correct operation of 
; the processor.
;================================================
                          ORG 0
vector_table              B   reset     ; reset
                          B   .         ; undefined_instruction
                          B   svc_entry ; svc_call 
                          B   .         ; prefetch_abort
                          B   .         ; data_abort  
                          B   .         ; empty_exception
                          B   ISR_entry ; IRQ
                          B   .         ; FIQ
                            
;=================================================
reset                     ; initalize stack pointers
                          ; initalize peripherals
                          ; enter user mode
;================================================
                          ; initalize stack pointers
;-------------------------------------------------                          
                          ; initalize supervisor_stack
                          ADRL SP, supervisor_stack;
                          
                          ; initalize user stack
                          MSR  CPSR_c, # system_mode; Change to System mode
setupUserStack            ADRL  SP, sp_thread1     ;
                          
                          ; initalize abort stack
                          MSR  CPSR_c, # abort_mode ; Change to Abort mode
setupAbortStack           ADRL  SP, abort_stack    ;
                          
                          ; initalize irq stack                
                          MSR  CPSR_c, # irq_mode ;
setupIRQStack             ADRL  SP, irq_stack     ; Change to IRQ mode
                          
                          ; initalize fiq stack
                          MSR  CPSR_c, # fiq_mode ;
setupFIQStack             ADRL  SP, fiq_stack     ; Change to FIQ mode
                          
;-------------------------------------------------                          
; Initalize peripherals
; set up the lcd in defined state i.e. clear display for our lab env.
;-------------------------------------------------
                          BL   clrScrn            ;                          
;-------------------------------------------------
; Initalize interrupts
;-------------------------------------------------                          
                          MOV  R1, #interrupt_timer_bit
                          MOVX R14, #interruptEnableBits
                          STRB R1, [R14]         ;
                          
                          MOVX  R1, #keyboard_loc;
                          MOV   R14, #&0F        ; set reading mode on
                          STRB  R14, [R1, #1]    ; control reg
                          ; set it to read all keys
                          ; Beware one cannot identify which key is pressed
                          ; as a result, but only the fact of key being pressed
                          MOV   R14, #&E0        ;
                          STRB  R14, [R1]        ; data reg
                          
;-------------------------------------------------
; Handing over the control to user program by changing to user mode
;-------------------------------------------------                          
                          ; enter user mode
                          MSR       SPSR, #user_mode_int_setting; User mode
                          ; jump to main method of user code
                          ADRL      R14, main      ;
                          MOVS      PC, R14        ; "Return" to user 
                          
;-------------------------------------------------
changeMode                ; Changes execution mode
                          ; It expects the target mode pattern in R1
                          ; and return address in R2.
                          ; Usage of LR and stack is avoided as all modes have 
                          ; their private LR and stack. Also it allows
                          ; routine to be called before initalizing stacks. 
;-------------------------------------------------
                          MSR  CPSR_c, R1          ; Update CPSR
                          MOV  PC, R2              ; return

;================================================
;================================================
; New code added from here on.
;================================================
;================================================     
    
;=================================================
lcd_library               INCLUDE ./lcd.s      
interrupt                 INCLUDE ./isr.s
svc_entry                 INCLUDE ./svc.s
scheduler                 INCLUDE ./scheduler.s
keyboardListener          INCLUDE ./keyboardListener.s    
;=================================================

user_code_start           

process1                  INCLUDE ./ex9/mainProcess.s
                          
                          ; set up user stack below user code
                          ; in order to keep OS safe from stack overflow
                          
;-------------------------------------------------
; stack space for user mode
;-------------------------------------------------
                          ; allocate memory to user stacks (For all possible
                          ; processes, at any point in time.)
                          ; the default process stack with main method
                          DEFS  threadStackLimit;    
user_stack
sp_thread1
                          ; Set memory for process 2
                          DEFS  threadStackLimit;
sp_thread2                
                          ; Set memory for process 3
                          DEFS  threadStackLimit;
sp_thread3                
                                                    
                          
;-------------------------------------------------
; stack space for supervisor mode
;-------------------------------------------------
                          ; allocate bytes to supervisor stack
                          DEFS  supervisorStackLimit;
supervisor_stack          
;-------------------------------------------------
; stack space for irq mode
;-------------------------------------------------
                          ; allocate bytes to irq stack
                          DEFS  irqStackLimit
irq_stack                 
;-------------------------------------------------
; stack space for abort mode
;-------------------------------------------------
                          ; allocate bytes to abort stack
                          DEFS  abortStackLimit
abort_stack               
;-------------------------------------------------
; stack space for fiq mode
;-------------------------------------------------
                          ; allocate bytes to fiq stack
                          DEFS  fiqStackLimit
fiq_stack                 
;=================================================       
