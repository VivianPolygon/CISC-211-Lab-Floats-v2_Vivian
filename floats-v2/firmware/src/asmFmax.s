/*** asmFmax.s   ***/

.syntax unified

/* Declare the following to be in data memory */
.data  
.align

/* Define the globals so that the C code can access them */

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Vivian Overbey"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
/* use these locations to store f0 values */
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
/* use these locations to store f1 values */
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
/* use these locations to store fMax values */
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

/* Tell the assembler that what follows is in instruction memory     */
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    /* because the variables we need to initialize are consecutive in memory, we can loop over them similar to an array for initialization */
    LDR r11, =0 /* initialization value */
    LDR r10, =15 /* consecutive words to initialize */
    LDR r9, =f0 /* starting address */
    
    initLoop:
    STR r11, [r9] /* store value '0' at current address */
    ADD r9, r9, 4 /* add 4 to adress to move to next word (STR [r9], 4 does not seem to work) */
    SUBS r10, r10, 1 /* subtract 1 from the initialization count and update flags */
    BEQ initVariablesComplete /* if the count is at 0, we are done, branch to done */
    BPL initLoop /* if the count is greater than 0, continue the loop. PL includes 0, but EQ is checked first. If the count becomes negative somehow, should still fall through to done */

    initVariablesComplete:
    pop {r4-r11,LR}
    MOV PC, LR
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    LDR r0, [r0] /* load from input */
    LSR r0, r0, 31 /* shift the register to the right, moving the sign bit into the LSB, and zeroing out the rest */
    STR r0, [r1] /* store the shifted registed to the specified memory location */
    
    pop {r4-r11,LR}
    MOV PC, LR
    
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function does NOT
                check for +/-Inf or +/-0, so r1 ALWAYS contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    LDR r0, [r0] /* load from input */
    /* The exponent is stored in bits 23 - 30 */
    LSR r0, r0, 23 /* shift the exponent (and sign bit) to bottom of register */
    AND r0, r0, 0xFF /* excludes sign bit */
    SUB r1, r0, 127 /* unbiased exponent */
    
    pop {r4-r11,LR}
    BX LR
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    LDR r0, [r0] /* load from input */
    /* mantissa is in bits 0 - 22 */
    LDR r1, =0x7FFFFF /* mask removes non-mantissa bits */
    AND r0, r0, r1 /* apply mask */
    LDR r1, =0x800000 /* implied bit */
    ADD r1, r0, r1 /* adds implied bit */
    
    pop {r4-r11,LR}
    MOV PC, LR
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    LDR r11, [r0] /* load from input */
    /* for a float to be zero, all bits except the sign bit must be cleared. */
    /* the sign bit tells us if it is "positive" zero or "negative" zero */
    LSLS r10, r11, 1 /* shift out the sign bit, if the remaining value is not zero, the float is not 0 */
    MOVNE r0, 0 /* exponent and mantissa is not 0 */
    MOVEQ r0, 1 /* exponent and mantissa is 0 */
    LSRS r10, r11, 31 /* isolate the sign bit and update flags. Could use previous function, however this is more compact */ 
    NEGNE r0, r0 /* if the shift that isolates the sign bit is not 0 (negative) negate. will change r0 from 1 to -1, but not affect 0 */
    
    pop {r4-r11,LR}
    BX LR
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to follow the calling convention! */
    push {r4-r11,LR}
    
    MOV r11, r0 /* functions are used that overwrite r0, store input in a register thats perserved by calling convention */
    LDR r10, [r0] /* load from input */
    /* for a float to be infinity, all bits in the exponent must be set, while all bits in the mantissa must be cleared */
    /* the sign bit may or may not be set. If its set its positive infinity. If it is negative, its negative infinity */
    
    BL getMantissa /* function call to get the mantissa, stores it in r0, r1 is the mantissa with the implied bit, which we do not need here*/
    MOVS r9, r0 /* mantissa */ 
    MOVNE r0, 0 /* the mantissa has some bits set, so the value is not infinity, thefore the output will be 0 */
    BNE asmIsInfComplete /* we already know the output due to the mantissa */
    /* mantissa was 0, so we need to look at the exponent */
    MOV r0, r11 /* assign float memory location to r0 for function */
    BL getExponent /* function call to get the exponent, r0 contains the bits as they are stored (biased), and is what we care about */
    CMP r0, 0xFF /* checks if all bits in the exponent are set */
    MOVNE r0, 0 /* the exponent is not all set, so we know the value is not infinity */
    BNE asmIsInfComplete /* we already know the output due to the exponent */
    /* at this point we know that the float is infinity, we now need to determine it's sign */
    LSRS r0, r10, 31 /* isolates the sign bit at the bottom of the register and updates flags */
    MOVEQ r0, 1  /* if the signbit is positive, return  1, as specified */
    MOVNE r0, -1 /* if the signbit is negative, return -1, as specified */
    
    asmIsInfComplete:
    pop {r4-r11,LR}
    BX LR
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to follow the calling convention! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   
    /* r0 input is f0 (floating-point value) */
    /* r1 input is f1 (floating-point value) */
    /* r0 output is address of fmax */
    push {r4-r11,LR}   
    BL initVariables
    
    /* input processing */
    LDR r2, =f0 /* assign the designated location in memory the inputted first floating-point operand */
    STR r0, [r2]
    LDR r2, =f1 /* assign the designated location in memory the inputted second floating-point operand*/
    STR r1, [r2]
     
    /* check sign difference. Individual signs stored in r10 and r11. sign comparison is stored in r9 */
    
    /* compute the sign of the first input */
    LDR r0, =f0
    LDR r1, =sb0
    BL getSignBit /* INPUTS: r0 - [float input], r1 - address of output, OUTPUT: r1, address of output (unchanged) */
    LDR r10, [r1] /* get sign for later */
    /* compute the sign of the second input */
    LDR r0, =f1
    LDR r1, =sb1
    BL getSignBit /* INPUTS: r0 - [float input], r1 - address of output, OUTPUT: r1, address of output (unchanged) */
    LDR r11, [r1] /* get sign for later */
    
    /* we need to check the signs against eachother. there are four distinct cases we need to consider */
    ADD r8, r10, r10 /* double the sign value for f0, allows for sorting into four cases from signs, can reconize sign order */
    ADD r8, r8, r11 /* add to the doubled f0 sign the sign of f1 */
    /* below a pattern reminiscent of an enum and case statement is used to sort out if one is positve and one is negative,
    or if they share a sign. in the former case, we can immediatly return, in the latter more steps are required, but we also
    need to remember what the sign that was shared is */
    TEQ r8, 1       /* case: 1  */
    LDREQ r0, =f0   /* Load to r5 address of f0; */ 
    BEQ assignFloat /* break; */  /* if our sign comparison results in a 1, f0 is positive, and f1 is negative. f0 is larger */
    TEQ r8, 2       /* case: 2  */
    LDREQ r0, =f1   /* load to r5 address of f1; */
    BEQ assignFloat /* break;   */  /* if our sign comparison results in a 2, f0 is negative, and f1 is positive. f1 is larger */   
    MOV r9, 0  /* after this point, we know the signs match, we need to note what they are though. line defaults the shared sign to positive */
    TEQ r8, 3       /* case: 3  */
    MOVEQ r9, 1     /* load 1 into r9, indicates that the sign is negative */
    B quickEval     /* default case, matching signs */
     
    
    quickEval:
	LDR r6, =f0
	LDR r6, [r6]
	LSL r6, r6, 1 /* load float f0, and shift out sign bit */
	
	LDR r7, =f1
	LDR r7, [r7]
	LSL r7, r7, 1 /* load float f1, and shift out sign bit */
	
	/* swap float positions before compare to invert result to map abs comparison to actual value comparison */
	CMP r9, 0
	MOVNE r5, r6
	MOVNE r6, r7
	MOVNE r7, r5
	
	CMP r6, r7 /* without the sign bit, whichever value is higher when read as an unsigned integer has a higher absolute value */
	LDRHI r0, =f0 /* f0 has a higher value */
	LDRLS r0, =f1 /* f1 has higher value, or they are equal  */
	B assignFloat
	
	
	/* put address of float in r0 */
    assignFloat:
	MOV r11, r0 /* store float address out of way */
	BL getSignBit
	LDR r7, [r1] /* gets sign bit of float into r7 for setOutput */
	
	MOV r0, r11 /* recall float address */
	BL getExponent
	MOV r8, r0 /* gets stored exponent into r8, for setOutput */
	MOV r9, r1 /* gets unbiased exponent into r9, for setOutput */
	
	MOV r0, r11 /* recall float address */
	BL getMantissa
	MOV r10, r1 /* gets mantissa (with implied bit) and stores into r10, for setOutput */
	/* if our exponent is all cleared (subnormal), or all set (infintity, or NaN), then we need the mantissa without the implied bit */
	CMP r8, 0 /* stored exponent is all cleared */
	MOVEQ r10, r0 /* overwrite with mantissa with no implied bit from earlier function return */
	CMP r8, 0xFF /* stored exponent is all set */
	MOVEQ r10, r0 /* overwrite with mantissa with no implied bit from earlier function return */
	
	LDR r6, [r11] /* puts float into r6, for setOutput */
        B setOutput
	
	
    setOutput: /* set the memory locations for the functions output, see below for what should be stored where */
	LDR r11, =fMax
	STR r6, [r11] /* the maximum float, in r6 */
	LDR r11, =sbMax
	STR r7, [r11] /* the maximum float's sign bit, in r7 */
	LDR r11, =storedExpMax
	STR r8, [r11] /* the maximum float's stored exponent (biased), in r8 */
	LDR r11, =realExpMax
	STR r9, [r11] /* the maximum float's stored exponent (unbiased), in r9 */
	LDR r11, =mantMax
	STR r10, [r11] /* the maximum float's mantissa in r10 */

	
    LDR r0, =fMax /* address of fmax, required for C call  */
    pop {r4-r11,LR}
    BX LR

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



