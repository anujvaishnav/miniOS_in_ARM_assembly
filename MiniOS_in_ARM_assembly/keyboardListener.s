;-------------------------------------------------
; Keyboard Listner
; Anuj Vaishnav
; Version 1.0
; Created on 14/04/2016
;
; The program scans the keyboard by performing keyboard debouncing, when the
; user requests. Otherwise, it simply returns back.
; In the case where user is waiting for keyboard input, it performance 
; debouncing over successive timer interrupts and when key press is identifed
; it sets the user thread as active. It also resets the waitingThread to none.
; N.b. waitingThread will be changed by a SVC call, setting it to user's SP.
;
; Last modified: 01/05/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------
                         PUSH {LR, R0-R2}
                         LDR  R1, waitingThread; get user's SP
                         CMP  R1, #0           ; if no one is waiting
                         BEQ  end              ; 
                         BL   scanKeyboard     ; returns result in R0
                         CMP  R0, #0           ; check if key is pressed
                         BEQ  end              ; Still waiting for key press
                         
                         ; otherwise store at R0 in user stack
                         STR  R0, [R1, #R0PositiononStack]; 
                         
                         ; set it as ready
                         MOV  R0, #1                      ;
                         LDRB R1, waitingThread + 4       ; get process number
                         STRB R0, [R1, #active_threads]   ;
                         
                         ; reset waiting thread
                         MOV  R0, #0               ; 
                         STR  R0, waitingThread    ; reset user SP to none
                         STR  R0, waitingThread + 4; reset process number
                         
end                      POP  {PC, R0-R2}          ; return

waitingThread            DEFW 0,0                  ; SP and process number

;-------------------------------------------------
                         ; It scans the keyboard and if the key is pressed
                         ; it returns the ASCII value of it in R0
                         ; otherwise a null char i.e. 0
                         ; It uses software debouncing technique.
                         ; Debouncing by incrementing & decrementing counter 
;-------------------------------------------------
; The code below is same as earlier exercise(inside SVC) other than return from 
; SVC is changed to normal function return.
;-------------------------------------------------
scanKeyboard
                         PUSH {R1-R6, LR}       ;
                         MOVX  R1, #keyboard_loc;
                         MOVX  R2, #column_codes;
                         MOV   R3, #3           ; number of columns 
                         MOV   R5, #0           ;
                         
columnLoop               LDRB  R0, [R2], #1    ;
                         STRB  R0, [R1]        ; set the relevant column
                         
                         ; expecting key press 
                         
                         LDRB  R4, [R1]        ; check data
                         BIC   R0, R4, R0      ; remove the column mask
                         
                         ; identify the row(key in column, using loop unrolling)
                         ; And handle it accordingly
                         LDRB  R4, [R5, #keyboard_table]  
                         CMP   R0, #firstRow   ;
                         BLEQ  keyPressed      ; if pressed increment
                         BL    keyNotPressed   ; else decrement
                         ADD   R5, R5, #1      ;
                         
                         LDRB  R4, [R5, #keyboard_table]; used by BLs
                         CMP   R0, #secondRow  ;
                         BLEQ  keyPressed      ; if pressed increment
                         BL    keyNotPressed   ; else decrement
                         ADD   R5, R5, #1      ;
                         
                         LDRB  R4, [R5, #keyboard_table]   
                         CMP   R0, #thirdRow   ;
                         BLEQ  keyPressed      ; if pressed increment
                         BL    keyNotPressed   ; else decrement
                         ADD   R5, R5, #1      ;

                         LDRB  R4, [R5, #keyboard_table]   
                         CMP   R0, #fourthRow  ;
                         BLEQ  keyPressed      ; if pressed increment
                         BL    keyNotPressed   ; else decrement
                         ADD   R5, R5, #1      ;

                         SUBS  R3, R3, #1      ;
                         BNE   columnLoop      ; Try other column
                         ; no key has been pressed
                         MOV   R0, #0          ; return null
                         POP   {R1-R6, PC}     ;

column_codes             DEFB  &80,&40,&20     ; (1,4,7,*), (2,5,8,0),(3,6,9,#)
                         ALIGN  4
                         
                         ; counters for each key
keyboard_table           DEFB   0,0,0,0        ; (1,4,7,*)
                         DEFB   0,0,0,0        ; (2,5,8,0)
                         DEFB   0,0,0,0        ; (3,6,9,#)
                         
keyboard_ASCII           DEFB   '147*2580369#' ;

lastKeyPressed           DEFB   0              ; stored in ASCII (0 means null)
                         ALIGN  4              ;

keyNotPressed            SUBNES R4, R4, #1     ; decrement the counter
                         MOVMI  R4, #0         ; satutrate coounter at 0
                         STRB   R4, [R5, #keyboard_table];
                         MOVPL  PC, LR         ; debouncing yet (counter +ve)
                         
                         LDRB   R6, lastKeyPressed; 
                         CMP    R6, #0            ; Check if the key was pressed
                         MOVEQ  PC, LR            ; else go back
                         
                         LDRB   R4, [R5, #keyboard_ASCII]; check if same key
                         CMP    R4, R6            ;
                         MOVNE  PC, LR            ;
                         MOV    R4, #0            ;
                         
                         ; Key has been pressed and released again
                         STRB   R4, lastKeyPressed; reset last key pressed
                         MOV    R0, R6            ; prepare a return argument
                         POP   {R1-R6, PC}        ;

keyPressed               ; increment the counter and 
                         ; Saturate counter to threshold
                         ADD   R4, R4, #1             ;
                         CMP   R4, #keyboardThreshold ;
                         MOVGT R4, #keyboardThreshold ;
                         
                         STRB  R4, [R5, #keyboard_table];
                         ADDLT PC, LR, #4               ; skip keyNotPressed
                         
                         ; At this stage we identifed, the key has been pressed
                         LDRB  R0, [R5, #keyboard_ASCII];
                         STR   R0, lastKeyPressed; 
                         ADD   PC, LR, #4               ;
