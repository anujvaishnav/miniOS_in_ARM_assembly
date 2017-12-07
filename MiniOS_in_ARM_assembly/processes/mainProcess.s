;-------------------------------------------------
; Main process
; Anuj Vaishnav
; Version 1.0
; Created on 18/04/2016
;
; This is the start process. It creates a child keyboard process and then 
; child buzzer process. After which it terminates
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------

failure           EQU  0;

main
                  ADR  R0, firstProcess; get location of child process
                  ; Attempt to create a process, it will fail if there is no
                  ; space for new process (OS limit), returning 0 in R0.
                  SVC _createProcess   ;
                  CMP R0, #failure     ; Check if the process creation succeeded
                  BEQ main             ; In case of failure attempt again
                  
trySecondProcess  ADR  R0, secondProcess; get location of child process
                  SVC  _createProcess   ;
                  CMP  R0, #failure     ;
                  BEQ  trySecondProcess ;
                  
                  ; Process termination
                  SVC  _stop            ;

firstProcess      INCLUDE ./keyboardProcess.s
secondProcess     INCLUDE ./buzzerProcess.s
