;-------------------------------------------------
; Interrupt Service Routine
; Anuj Vaishnav
; Version 1.0
; Created on 07/03/2016
;
; It identifies the interrupt type and calls the appropriate driver for it.
; N.b. Use of TST leads to priority in terms of sequence of how interrupts
; are served. 
;
; Last modified: 25/04/2016 (AV)
;
; Known bugs: None
;
;-------------------------------------------------
ISR_entry           SUB   LR, LR, #4; save return address
                    PUSH  {R0, R1}  ; Will need to be restored by driver  
                    
                    ; MOVX is not a standard ARM instruction, but our lab
                    ; tools do work with it. This is used because relative
                    ; addressing seems to fail here.
                    MOVX  R1, #interrupt_bits             ;
                    LDRB  R0, [R1]                        ;
                    TST   R0, #int_timer                  ;
                    BNE   timerDriver                     ;
                    TST   R0, #int_spartanDriver          ;
                    BNE   spartanDriver                   ;
                    TST   R0, #int_virtexFPGADriver       ;
                    BNE   virtexFPGADriver                ;
                    TST   R0, #int_ethernetInterfaceDriver;
                    BNE   ethernetInterfaceDriver         ;
                    TST   R0, #int_SerialRxDReadyDriver   ;
                    BNE   SerialRxDReadyDriver            ;
                    TST   R0, #int_SerialRxDAvailDriver   ;
                    BNE   SerialRxDAvailDriver            ;
                    TST   R0, #int_upperButtonDriver      ;
                    BNE   upperButtonDriver               ;
                    TST   R0, #int_lowerbuttonDriver      ;
                    BNE   lowerbuttonDriver               ;
                    
timerDriver               INCLUDE  ./timerDriver.s
spartanDriver             B        .
virtexFPGADriver          B        .
ethernetInterfaceDriver   B        .
SerialRxDReadyDriver      B        .
SerialRxDAvailDriver      B        .
upperButtonDriver         B        .
lowerbuttonDriver         B        .
