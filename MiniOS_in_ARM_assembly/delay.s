; Assumes it will get its delay in R0
             PUSH   {R0};
delayloop    SUBS   R0, R0, #1;
             BNE    delayloop;
             POP    {R0};
             MOV    PC, LR;
