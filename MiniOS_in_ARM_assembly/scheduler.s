;-------------------------------------------------
; Scheduler
; Anuj Vaishnav
; Version 1.0
; Created on 14/04/2016
;
; It is a simple scheudler which is launched every timer interrupt. It will 
; first push the context of running process onto its stack. Then pick a next 
; process to get the CPU, by using round robin on potential process spaces.
; After which it extracts the context of the next process to run from its stack
; and sets its respective regs and launches it.
;
; There is a mechanism to identify if there are no active processes at the time 
; of picking the next process to run. Once it is detected it launches a default
; idle process which is just an infinte loop doing nothing. This can be later
; swapped with logic to make CPU go to sleep, leaving the interrupts on, to save
; power.
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------
                   ; maximum process/threads allowed on system
maxThreads         EQU    2             ; starts numbering from zero
R0PositiononStack  EQU    2*4           ; used by keyboard listener program

;-------------------------------------------------
; Save User Context onto its stack
;-------------------------------------------------
                   
                   PUSH   {SP}^         ; get user SP
                   POP    {R0}
                   
                   STMFD  R0!, {LR}     ; push return addr on user stack
                   MOV    R14, R0       ; make R0 a scratch reg
                   POP    {R0, R1}      ; restore the R0-R1 saved by ISR
                   STMFD  R14!, {R0-R12}; Push R0-R12 reg onto user stack
                   
                   PUSH   {LR}^         ; retrieve user's LR for storing
                   POP    {R1}          ;
                   MRS    R0, SPSR      ; Get user flags
                   ; push flags and lr, n.b. lr is stored first and then flags
                   STMFD  R14!, {R0, R1}
                   
;-------------------------------------------------
; Pick next process to run.
; Currently it simply does round robin on potential available entries in PCB.
; In the case if the process is not active, it skips it.
; As new process is installed on first free available slot. It might happen a 
; newly created process gets an earlier time slot (in case an even earlier 
; process terminated).  
;-------------------------------------------------
enterPickProcess   
                   ; R1 will throughout hold pcb index
                   LDR    R1, active_process   ;
                   ADR    R0, pcb              ; R0 will throughout be pcb
                   STR    R14, [R0, R1, LSL #2]; Save final user SP in PCB
                   ADR    R2, active_threads   ;
                   
                   ; Create counter of threads being checked, to identify
                   ; if everything is blocked and avoid deadlock
                   ; N.b. it is +2 because firstly the numbering of maxThreads
                   ; starts from 0, leading to +1. And another +1 exists 
                   ; so that we run back into where we started to be on safe 
                   ; side.
                   MOV    R4, #maxThreads + 2  ;
pickProcess
                   ; If everything is blocked launch default idle state program
                   SUBS   R4, R4, #1           ;
                   BEQ    launchIdleState      ;

                   ADD    R1, R1, #1           ; try next process
                   CMP    R1, #maxThreads      ; mod maxThreads
                   MOVGT  R1, #0               ; 

                   LDRB   R3, [R2, R1]         ;
                   CMP    R3, #1               ; check if thread is active
                   BNE    pickProcess          ; if not check another process
                   STR    R1, active_process   ;
  
;-------------------------------------------------
; Load User Context onto its stack
;-------------------------------------------------
loadContext
                   LDR   R0, [R0, R1, LSL #2]; get USER SP in R0
                   LDMFD R0!, {R1}        ; get flags
                   MSR   SPSR, R1         ;
                   
                   LDMFD R0!, {LR}^       ; get user LR
                   MOV   LR, R0           ;
                   ADD   R0, R0, #14*4    ; calculate final address of user SP
                   PUSH  {R0}             ; 
                   POP   {SP}^            ; set SP for user process
                    
                   ; set flags, mode and most of the user regs
                   LDMFD LR, {R0-R12, PC}^; 
                    
;-------------------------------------------------
; PCB
; It constitues of 3 parts. Process_ID currently running, Flags for each process
; and their respective stack pointers. We save the state of process in their
; respective stacks in order to reduce the size of PCB, as we extend it to have
; more processes. This make saving and restoring context a bit more complicated
; but the scalaiblity acheieve is more desireable and hence justifyable. 
;-------------------------------------------------

active_process      DEFW  0         ; Start with first process being active

pcb                 DEFW  sp_thread1;
                    DEFW  sp_thread2;
                    DEFW  sp_thread3;
                    DEFW  sp_idle   ; isn't used other than idle state

active_threads      DEFB  1,0,0,0   ;  set first process as active by default
                    ALIGN                   

;-------------------------------------------------
; Idle state
; This logic is specific to situation when we don't have any user processes
; running. Currently we just have B . in order to exit from Scheduler which
; is running in higher privilege and cannot be interrupted. This avoids the 
; deadlock formed, when all processes are blocked. 
; In theory with some more advance hardware support we can switch on sleep mode
; leaving only interrupts on, to save power.
;-------------------------------------------------
launchIdleState    MOV  R1, #maxThreads+1 ; set idle as running
                   STR  R1, active_process;
                   B    loadContext       ; get context of idle thread

sp_idle            ; Default state w
                   DEFW  user_mode_int_setting ; flags
                   DEFW  0,0,0,0
                   DEFW  0,0,0,0
                   DEFW  0,0,0,0
                   DEFW  0,0,idle              ; PC

idle               B     .       ; default user program to launch in idle state
