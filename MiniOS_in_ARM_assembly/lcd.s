;-------------------------------------------------
; Library for LCD HD44780 
; Anuj Vaishnav
; Version 1.0
; Created on 4/2/2016
;
; This library contains functions for interacting with lcd display HD44780, 
; which is used along with the lcdHeader.s file 
; (consisting of the required settings such as addresses of ports).
;
; It assumes the stack is already initalized and is allocated abundant amount
; of memory.
;
; Mostly all the function assumes the argument in R4 unless stated otherwise.
; 
; Read lcdHeader.s to see what possible command codes can be used with 
; issueCommand routine.
;
; Last modified: 15/2/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------

              ; import the settings of lcd HD44780
              INCLUDE ./lcdHeader.s;
                            
;=================================================
;-------------------------------------------------          
printString   ; The function takes a pointer to string and prints it on 
              ; lcd screen HD44780
              ; The expected string is terminated by a '\t'
              ; R0 holds the pointer to string to print
              ; it relies on another routine printChar for proper functioning
;-------------------------------------------------

              PUSH  {LR, R4}; save the previous state
printNextChar LDRB  R4, [R0], #1;
              CMP   R4, #'\t'; 
              POPEQ   {R4,PC}; return from function        
              BL    printChar; 
              B     printNextChar;
          
;=================================================
;-------------------------------------------------        
printChar     ; Prints a given char on screen. 
              ; R4 holds the char to be printed on screen
              ; it relies on the wait4free routine to function correctly
;-------------------------------------------------

              PUSH   {LR, R0-R2}
              MOV    R1, #portB;
              MOV    R2, #portA;
              
              ; set to read 'control' with data bus direction as input
              ; R0 will hold the status of portB throught the function 
              LDRB   R0, [R1]; read current status
              BL     wait4free; Wait for lcd controller to get free
              
              ; set to read 'data' with data bus direction as output
              BIC    R0, R0, #RW; set RW = 0
              ; set RS = 1 and backlight on of lcd
              ORR    R0, R0, #(RS OR backlight);
              STRB   R0, [R1]; change portB
              
              ; output desired byte onto data bus
              STRB   R4, [R2]; write on portA
              
              ; enable bus;
              ORR    R0, R0, #E; enable bus
              STRB   R0, [R1]; change portB
              
              ; disable bus;
              BIC    R0, R0, #E; disable bus
              STRB   R0, [R1]; change portB
              POP {R0-R2, PC};  return from function

;========================================
;-------------------------------------------------
wait4free     ; wait for lcd to get free by polling
              ; 7th bit in control reg of lcd
              ; expects portB's status in R0
              ; expects portB & portA address in R1 and R2 respectively
              ; link regiester is saved in case in future, a routine is called
;-------------------------------------------------
              PUSH   {LR, R0, R3}
              ; set RW = 1 and backlight on of lcd
              ORR    R0, R0, #(RW OR backlight); 
              BIC    R0, R0, #RS; set RS = 0
              STRB   R0, [R1]; change portB
              
step2         ; enable bus;
              ORR    R0, R0, #E; enable bus
              STRB   R0, [R1]; change portB
              
              ;read lcd status byte;
              LDRB   R3, [R2]; read port A
              
              ; disable bus;
              BIC    R0, R0, #E; disable bus
              STRB   R0, [R1]; change portB
              
              ; if bit 7 of status byte was high repeat from step 2
              TST    R3, #0x80; bit 7 is high or not
              BNE    step2;
              POP    {R3, R0, PC}; return from the function

;=================================================
;-------------------------------------------------          
issueCommand  ; It issues a command to controller present in lcd.
              ; By writing to control register of lcdHeader.
              ; R4 is expected to hold the command to be written to 
              ; control reg.
              ; It can be invoked with various commands listed in lcdHeader.s
;-------------------------------------------------

              PUSH   {LR, R0-R2}
              MOV    R1, #portB;
              MOV    R2, #portA;
              LDRB   R0, [R1]; read current status
              BL     wait4free; Wait for lcd controller to get free
              
              ; change to control mode with write permission
              ; set RW = 0 and RS = 0
              BIC    R0, R0, #(RW OR RS);
              STRB   R0, [R1]; change portB
              
              ; output desired byte onto data bus
              STRB   R4, [R2]; write on portA
              
              ; enable bus;
              ORR    R0, R0, #E; enable bus
              STRB   R0, [R1]; change portB
              
              ; disable bus;
              BIC    R0, R0, #E; disable bus
              STRB   R0, [R1]; change portB
              POP    {R0-R2, PC}; return from the routine
          
;=================================================
;-------------------------------------------------          
clrScrn       ; This function clears the lcd screen by issuing a clear
              ; command to lcd controller.
              ; It relies on issueCommand routine to work properly. 
;-------------------------------------------------

               PUSH {LR, R4}
               MOV  R4, #cls;
               BL   issueCommand; issue command for clearing the screen
               POP  {R4, PC} ; return from the routine

;=================================================
;-------------------------------------------------          
topLine        ; This function moves the cursor to top line of lcd.
               ; It relies on issueCommand routine to work properly.
;-------------------------------------------------
               
               PUSH {LR, R4}
               MOV  R4, #topRow;
               BL   issueCommand; issue command for going to bottom line
               POP  {R4, PC} ; return from the routine    
          
;=================================================
;-------------------------------------------------          
bottomLine     ; This function moves the cursor to bottom line of lcd.
               ; It relies on issueCommand routine to work properly.
;-------------------------------------------------
               
               PUSH {LR, R4}
               MOV  R4, #bottomRow;
               BL   issueCommand; issue command for going to bottom line
               POP  {R4, PC} ; return from the routine
               
;=================================================
;-------------------------------------------------          
mvCursorTo     ; This function moves the cursor to the given char position.
               ; It relies on issueCommand routine to work properly.
               ; It expects the char position in R4.
               ; Note the char position starts from 0 to 40 spread 
               ; over 4 lines in sequence and only making the 
               ; first 16 characters of the top two lines visible on screen.
;-------------------------------------------------
               
               PUSH {LR, R4}
               ADD  R4, R4, #baseCharPositon;
               BL   issueCommand; issue command for going to bottom line
               POP  {R4, PC} ; return from the routine

;=================================================
;-------------------------------------------------          
setNewChar     ; This function adds a new char to lcd display
               ; It relies on issueCommand and printString 
               ; routine to work properly.
               ; R0 is expected to hold a pointer new character
               ; which has terminating symbol '\t'
               ; R4 is expected to hold the index from CGRAM address 
               ; where newChar is to be placed in CGRAM
               ; Note The fucntion would set the cursor position to
               ; first char by default
;-------------------------------------------------
               
               PUSH {LR}
               ADD  R4, R4, #&40; set CGRAM address
               BL issueCommand;
                  
               ; write sequence of new char bytes
               ; Note R0 already holds the pointer for printString to use
               BL printString;
                                
               MOV R4, #baseCharPositon;
               BL issueCommand; set DD RAM address
               POP  {PC} ; return from the routine
               
;=================================================
;-------------------------------------------------          
_delayTime     ; This function is used to casue a delay by executing 
               ; unproductive instructions to keep the processor busy.
               ; It expects the delay argument (no. of instructions) in R4.
               ; Note it does not call any other routine nor it uses
               ; any other register except R4 (argument).
               ; This structure exempts the routine from usage of stack.
               ; If it is changed in future, please make sure stack exemption
               ; is appropriately for new design
;-------------------------------------------------
               
delayloop      SUBS   R4, R4, #1;
               BNE    delayloop; 
               MOV    PC, LR; return from the routine
