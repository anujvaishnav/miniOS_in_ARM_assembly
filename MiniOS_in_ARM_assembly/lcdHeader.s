;-------------------------------------------------
; LCD HD44780 settings Header file
; Anuj Vaishnav
; Version 1.0
; Created on 08/02/2016
;
; This file contains all the necessary port addresses, peculiar bit patterns
; and commands for interfacing with LCD.
;
; Last modified: 15/02/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------
portB               EQU &10000004; Portb address of lcd screen (control reg)
portA               EQU &10000000; PortA address of lcd screen (data reg)
RW                  EQU &00000004; Read not write bit
RS                  EQU &00000002; Register select bit
E                   EQU &00000001; Enable interface signal bit
backlight           EQU &20      ; Backlight of lcd screen

; The follwing are the commands which can be used with issueCommand routine
cls                 EQU &01      ; Clear screen Command
CGRAMaddress        EQU &40      ; CGRAM address used for new characters

; The following are commands to change cursor position
bottomRow           EQU &C0      ; Command for jumping to bottom row on lcd
topRow              EQU &80      ; Command for jumping to top row on lcd
baseCharPositon     EQU &80      ; Address of first cursor position of lcd

;The following are commands to move the cursor and shift the display
shiftCursorLeft 	  EQU &10      ; Command for move the cursor to left
shiftCursorRight 	  EQU &14      ; Command for move the cursor to right
shiftDisplayLeft 	  EQU &18      ; Command for move the display to left 
shiftDisplayRight   EQU &1C      ; Command for move the display to right

;The follwing are commands to change cursor behaviour
cursorOff  	        EQU &0C      ; Command for display on, cursor off
steadyCursor 	      EQU &0E      ; Command for display on, cursor on, 
                                 ; steady cursor
blinkingCursor 	    EQU &0F      ; Command for display on, cursor on, 
                                 ; blinking cursor
