;-------------------------------------------------
; Keyboard process 
; Anuj Vaishnav
; Version 1.0
; Created on 14/04/2016
;
; This thread loops infinitely request for user input from keyboard
; and printing it on the screen.
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
keyboard           ; This SVC blocks the process execution. 
                   ; Execution will only be resumed in its respective time slice
                   ; after the user presses the key.
                   ; Ensuring the printChar has something to print.
                   SVC    _getChar     ; returns char in R0                         
                   SVC    _printChar   ; print the char present in R0.
                   B      keyboard     ; repeat
