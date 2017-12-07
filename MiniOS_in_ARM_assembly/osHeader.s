;-------------------------------------------------
; OS Header file
; Anuj Vaishnav
; Version 1.0
; Created on 08/02/2016
;
; This file contains all the necessary addresses, sizes and bit patterns for OS 
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------

;-------------------------------------------------
; Button bit patterns and aliases
;-------------------------------------------------
lowerbuttonBit            EQU &80      ;
upperbuttonBit            EQU &40      ;
bothButtonBits            EQU &C0      ;
buttonMask                EQU &C       ;

;-------------------------------------------------
; Execution mode realted aliases
;-------------------------------------------------
user_mode_setting         EQU &D0      ;
user_mode_int_setting     EQU &50      ;
svc_mask                  EQU &FF000000;
clear_mode                EQU &1F      ;
user_mode                 EQU &10      ;
system_mode               EQU &1F      ;
supervisor_mode           EQU &13      ;
abort_mode                EQU &17      ;
undefined_mode            EQU &1B      ;
irq_mode                  EQU &12      ;
fiq_mode                  EQU &11      ;

;-------------------------------------------------
; Stack related aliases
;-------------------------------------------------
RAMlimit                  EQU &27C00   ; limit of RAM

threadStackLimit          EQU &300

thread1StackLimit         EQU &500     ; stack space for user thread 1
thread2StackLimit         EQU &500     ; stack for user thread 2
userStackLimit            EQU &1000    ; stack for all users

supervisorStackLimit      EQU &1000    ; stack space for supervisor
abortStackLimit           EQU &1000    ; stack space for abort
irqStackLimit             EQU &1000    ; stack space for irq
fiqStackLimit             EQU &1000    ; stack space for fiq
                          ; Total stack space
totalStackSpace           EQU (userStackLimit + supervisorStackLimit + irqStackLimit + abortStackLimit + fiqStackLimit)

;-------------------------------------------------
; Interrupt aliases
;-------------------------------------------------
interrupt_bits            EQU &10000018;
interruptEnableBits       EQU &1000001C;
interrupt_timer_bit       EQU &1       ;
timer_Int_time            EQU &1000000C;

int_timer                    EQU &01;
int_spartanDriver            EQU &02;
int_virtexFPGADriver         EQU &04;
int_ethernetInterfaceDriver  EQU &08;
int_SerialRxDReadyDriver     EQU &10;
int_SerialRxDAvailDriver     EQU &20;
int_upperButtonDriver        EQU &40;
int_lowerbuttonDriver        EQU &80;

;-------------------------------------------------
; All other aliases
;-------------------------------------------------
maskOffUpperNibble        EQU &FFFFFFF0;
timerLocation             EQU &10000008;
keyboard_loc              EQU &20000002;
buzzer_loc                EQU &20000000;

threadLimit               EQU 3;
