;-------------------------------------------------
; Timer Driver 
; Anuj Vaishnav
; Version 1.0
; Created on 07/03/2016
;
; Timer driver, deals with timer interrupts.
; It makes sure, it updates the system time and scans the keyboard if requested
; by user (Handled by keyboardListener). After which it calls the scheduler,
; to switch between the process if necessary.
;
; N.b. The system time updates by the granuality of timer interrupt delays.
; Which in this is case is 5ms. Hence, a user program might see the time jump
; by 5 ms and in case it expects to reach e.g. 3ms it wouldn't be able to see 
; it. This design choice was made in order to make the user program less 
; dependent on time delay between 2 interrupts. Hence, now we can change timer
; delay wihout changing the user program. Expect it to behave in the same way.
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------

timer_span            EQU  5
                      
                      ; It expects R0 and R1 as scratch reg, as it is called
                      ; after ISR which saves them onto stack.
                      
                      ; set next Interrupt
                      MOVX  R0, #timer_Int_time;
                      LDRB  R1, [R0]           ;
                      ADD   R1, R1, #timer_span;
                      STRB  R1, [R0]           ;
                      
                      ; update system timer
                      LDR   R1, systemTime     ;
                      ; update time in jumps of timer delay aka time_span
                      ADD   R1, R1, #timer_span;
                      STR   R1, systemTime     ;
                      
                      ; Acknowledge the interrupt
                      MOVX  R0, #interrupt_bits;
                      LDRB  R1, [R0]           ; Read the current interrupts
                      BIC   R1, R1, #int_timer ; acknowledge timer interrupt
                      STRB  R1, [R0]           ;
                      
                      ; Handle keyboard IO
                      MOV   R0, LR             ;
                      BL    keyboardListener   ;
                      MOV   LR, R0             ;
                      
                      ; scheduler takes care of setting the right mode and
                      ; returning to user program.
                      B     scheduler          ;
                      
systemTime            DEFW  0                  ;
