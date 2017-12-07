;-------------------------------------------------
; Buzzer process
; Anuj Vaishnav
; Version 1.0
; Created on 14/04/2016
;
; A buzzer thread, which infinitely plays a siren using buzzer on board.
; The siren effect is achieved by changing between 2 frequency at almost
; every 1 sec. 
;
; N.b. this program doesn't have a main so OS cannot execute it as the first 
; thread. It must be either be launched by other process (via SVC) or be set
; at compile time as secondary process.
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------
                   ; time difference between change in frequency
delay              EQU    1000;
freq1              EQU    0xFF;
freq2              EQU    0xCC;

                   
                   ; N.b. system time is update in leaps of the time difference
                   ; between 2 timer interrupts. This is to avoid rewriting
                   ; the programs for same time delays, after changing timer
                   ; interrupts.
                   ; It is not very accurate form of timing resource.
                   ; This is because of OS switiching between 2 processes.
                   ; Despite 1 sec time being past, this process might not 
                   ; be able to access CPU at that very time. It will need to 
                   ; wait for its time slice. 
                   ; This problem is neglible as the time slice is of 5ms only.
                   ; And the check for timing reference is using LT
                   ; or GT only, allowing for some lateness.
                   SVC    _getSystemTime;
                   ADD    R1, R0, #delay; Identify next time for next frequency
                                        ; toggle, throughout the program
                   MOV    R2, #0        ; Frequency identifier. 0 indicates
                                        ; first frequency and 1 indicates second
                   
wait_1             ; busy polling for right time
                   SVC    _getSystemTime; returns time in R0
                   CMP    R0, R1        ; 
                   BLT    wait_1        ; 
                   ; Right time to change the frequency
                   ADD    R1, R0, #delay; set delay for next change                   
                   CMP    R2, #0        ; Check which tone needs to be played
                   BNE    skip          ;
                   MOV    R2, #1        ; Set freq1 for buzzer to play
                   MOV    R0, #freq1    ;
                   B      play          ;
skip               MOV    R2, #0        ; Set freq2 for buzzer to play
                   MOV    R0, #freq2    ;               
play               SVC    _playBuzzer   ; play the frequency given in R0
                   B      wait_1        ; repeat

                   ; This part isn't used at the moment.
                   ; It was used to test if the process terminates
                   ; cleanely or not.                   
exit               MOV    R0, #0        ; set the buzzer to off (inaudible freq) 
                   SVC    _playBuzzer   ;
                   SVC    _stop         ;         
