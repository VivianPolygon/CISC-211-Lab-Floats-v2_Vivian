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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    /* because the variables we need to initialize are consecutive in memory, we can loop over them similar to an array for initialization */
    LDR r11, =0 /* initialization value */
    LDR r10, =14 /* consecutive words to initialize - 1, PL condition code that checks this includes 0 */
    LDR r9, =f0 /* starting address */
    
    initLoop:
    STR r11, [r9], 4 /* store value '0' at current address, post-increment by 4 to hit next address (all data are alligned words) */
    SUBS r10, r10, 1 /* subtract 1 from the initialization count and update flags */
    BPL initLoop /* if the count is greater than or equal to 0, continue the loop. PL includes 0 */

    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    MOV PC, LR /* move the link register into the program counter to jump back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    LDR r0, [r0] /* load from input */
    LSR r0, r0, 31 /* shift the register to the right, moving the sign bit into the LSB, and zeroing out the rest */
    STR r0, [r1] /* store the shifted registed to the specified memory location */
    
    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    BX LR /* branch with exchange to use whats in the link register to move back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    LDR r0, [r0] /* load from input */
    /* The exponent is stored in bits 23 - 30 */
    LSR r0, r0, 23 /* shift the exponent (and sign bit) to bottom of register */
    AND r0, r0, 0xFF /* excludes sign bit */
    SUB r1, r0, 127 /* unbiased exponent */
    
    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    BX LR /* branch with exchange to use whats in the link register to move back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    LDR r0, [r0] /* load from input */
    /* mantissa is in bits 0 - 22 */
    LDR r1, =0x7FFFFF /* mask removes non-mantissa bits */
    AND r0, r0, r1 /* apply mask */
    LDR r1, =0x800000 /* implied bit */
    ADD r1, r0, r1 /* adds implied bit */
    
    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    MOV PC, LR /* move the link register into the program counter to jump back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    LDR r11, [r0] /* load from input */
    /* for a float to be zero, all bits except the sign bit must be cleared. */
    /* the sign bit tells us if it is "positive" zero or "negative" zero */
    LSLS r10, r11, 1 /* shift out the sign bit, if the remaining value is not zero, the float is not 0 */
    MOVNE r0, 0 /* exponent and mantissa is not 0 */
    MOVEQ r0, 1 /* exponent and mantissa is 0 */
    LSRS r10, r11, 31 /* isolate the sign bit from initial load's value, and update flags. Could use getSignBit, however this is more compact */ 
    NEGNE r0, r0 /* if the shift that isolates the sign bit is not 0 (negative) negate. will change r0 from 1 to -1, but not affect 0 */
    
    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    BX LR /* branch with exchange to use whats in the link register to move back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */
    
    MOV r11, r0 /* functions are used that overwrite r0, store input in a register thats perserved by calling convention */
    LDR r10, [r0] /* load from input */
    
    /* for a float to be infinity, all bits in the exponent must be set, while all bits in the mantissa must be cleared */
    /* the sign bit may or may not be set. If the sign is positive, its positive infinity. If the sign is negative, its negative infinity */
    
    BL getMantissa /* function call to get the mantissa, stores it in r0, r1 is the mantissa with the implied bit, which we do not need here*/
    MOVS r9, r0 /* mantissa */ 
    MOVNE r0, 0 /* the mantissa has some bits set, so the value is not infinity, therefore the output will be 0 */
    BNE asmIsInfComplete /* we already know the output due to the mantissa */
    /* mantissa was 0, so we need to look at the exponent */
    MOV r0, r11 /* assign float memory location to r0 for function */
    BL getExponent /* function call to get the exponent, r0 contains the bits as they are stored (biased), and is what we care about */
    CMP r0, 0xFF /* checks if all bits in the exponent are set */
    MOVNE r0, 0 /* the exponent is not all set, so we know the value is not infinity */
    BNE asmIsInfComplete /* we already know the output due to the exponent */
    /* at this point we know that the float is infinity, we now need to determine it's sign */
    LSRS r0, r10, 31 /* isolates the sign bit at the bottom of the register and updates flags. We could use getSignBit, but this is more compact */
    MOVEQ r0, 1  /* if the signbit is positive, return  1, as specified */
    MOVNE r0, -1 /* if the signbit is negative, return -1, as specified */
    
    asmIsInfComplete:
    pop {r4-r11,LR} /* restore upper registers, and link register (calling convention 2) */
    BX LR /* branch with exchange to use whats in the link register to move back to the caller (calling convention 3) */
    
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
    push {r4-r11,LR} /* perserve upper registers, and link register (calling convention 1) */ 
    BL initVariables /* initialize all variables to 0. function dosen't interact completly with f0 and f1 blocks after init */
    /* f0, sb0, f1, and sb1 are written to, other memoru addresses for f0 and f1 blocks are not */
    
    /* input processing */
    LDR r2, =f0 /* assign the designated location in memory the inputted first floating-point operand */
    STR r0, [r2]
    LDR r3, =f1 /* assign the designated location in memory the inputted second floating-point operand*/
    STR r1, [r3]
     
    /* check sign difference. Individual signs stored in r10 and r11. sign comparison is stored in r9 */
    
    /* compute the sign of the first input */
    MOV r0, r2 /* move the address of f0 to r0, for getSignBit input */
    LDR r1, =sb0 /* r1 needs to be the writing address, for getSignBit */
    BL getSignBit /* INPUTS: r0 - [float input], r1 - address of output, OUTPUT: r1, address of output (unchanged) */
    LDR r10, [r1] /* get sign for later, store in specified address */
    /* compute the sign of the second input */
    MOV r0, r3 /* move the address of f1 to r0, for getSignBit input */
    LDR r1, =sb1 /* r1 needs to be the writing address, for getSignBit */
    BL getSignBit /* INPUTS: r0 - [float input], r1 - address of output, OUTPUT: r1, address of output (unchanged) */
    LDR r11, [r1] /* get sign for later, store in specified address */
    
    /* we need to check the signs against eachother. there are four distinct cases we need to consider */
    /* to get 4 cases from two bits, we can weight one (double it), and add them together. Then we can read this value */
    ADD r8, r10, r10 /* double the sign value for f0, allows for sorting into four cases from signs, can reconize sign order */
    ADD r8, r8, r11 /* add to the doubled f0 sign the sign of f1 */
    /* below a pattern reminiscent of an enum and case statement is used to sort out which is which if one is positve and one is negative,
    or if they share a sign. in the former case, we can immediatly return, in the latter more steps are required, but we also
    need to remember what the sign that was shared is */
    TEQ r8, 1       /* case: 1  */
    LDREQ r0, =f0   /* Load to r0 address of f0; */ 
    BEQ assignFloat /* break; */  /* if our sign comparison results in a 1, f0 is positive, and f1 is negative. f0 is larger */
    TEQ r8, 2       /* case: 2  */
    LDREQ r0, =f1   /* load to r0 address of f1; */
    BEQ assignFloat /* break;   */  /* if our sign comparison results in a 2, f0 is negative, and f1 is positive. f1 is larger */   
    MOV r9, 0  /* after this point, we know the signs match, we need to note what they are though. line defaults the shared sign to positive */
    TEQ r8, 3       /* case: 3  */
    MOVEQ r9, 1     /* load 1 into r9, indicates that the sign is negative. Note that r9 is the previously specified register for the sign comparison */
     
    /* signs match, exponent and mantissa need to be directly checked (jumping to assignFloat skips this section)*/
    
    /* compare exponent and mantissa (r10 - f0, r1 - f11, r10 and r11 no longer need the individual signs, as r9 holds the relevant information on their shared sign) */
    LDR r10, =f0 /* get float address for f0 */
    LDR r11, =f1 /* get float address for f1 */
	
    /* pseudo-delegates! */
    LDR r6, =getExponent /* get the instruction address of getExponent into a register (we can swap this out with getMantissa later and reuse subsequent code!) */
    MOV r8, PC /* stores the line after the next into the Program Counter. Confirmed that like 318 is what gets stored through debugging techniques*/
    MOV r7, 0 /* this is used to prevent infinite loops, lets us know what pass we are on */
    
    /* get f0 exponent (1st pass), get f0 mantissa (2nd pass) */
    MOV r0, r10 /* move f0's address into r0, both getExponent and getMantissa use this as their input */
    BLX r6 /* on the first pass, this is getExponent, on the second, getMantissa */
    MOV r4, r0 /* move into perserved register */
    /* get f1 exponent (1st pass), get f1 mantissa (2nd pass) */
    MOV r0, r11 /* move f1's address into r0, both getExponent and getMantissa use this as their input */
    BLX r6 /* on the first pass, this is getExponent, on the second, getMantissa */

    /* compare the values of the exponents to eachother (first pass), and mantissas (second pass) */
    CMP r4, r0 /* compare function outputs to see which is larger, r0 has f1's exponent or mantissa from function call */
    MOVPL r2, 0 /* indicates that f0 is larger (absolute value), or they are identical */
    MOVMI r2, 1 /* indicates that f1 is larger (absolute value) */
    BNE sharedSignApply /* if there is a disparity, we know one is larger, branch out. Will exit after first pass if exponent is larger */
	
    CMP r7, 1 /* r7 will be 1 at the end of the second pass. If this is hit, the floats are identical. */
    BEQ sharedSignApply /* exit, if this wasn't here, we would run the second pass over and over again if the floats are identical */
	
    LDR r6, =getMantissa /* for our second pass, we want to use getMantissa instead of getExponent, so assign it to r6 */
    MOV r7, 1 /* allows us to exit in the edgecase of identical floats */
    MOV PC, r8 /* moves us back to the top of this section */
	
    /* apply shared sign flip to comparison, then sets */
    /* f0's address should be in r10, f1's address should be in r11 */
    /* r2 should contain a 0 if f0 has a greater abs, and a 1 if it has a smaller abs */
    /* r9 should contain a 0 if the shared sign is positive, and a 1 if the shared sign is negative */
    sharedSignApply:
        /* position float addresses for assignFloat */
	MOV r0, r10 /* r0 becomes f0 */
	MOV r1, r11 /* f1 becomes f1 */
	/* swap float positions before compare to invert result to map abs comparison to actual value comparison */
	EORS r9, r2 /* by default, point to f0 *//* if both are negative, flip to f1 */ /* if f1 is larger, flip to f1 */ /* if both, no change (f0) */ 
	MOVNE r2, r1 /* swap r0 and r1 */
	MOVNE r1, r0
	MOVNE r0, r2
	B assignFloat /* whatever float's address is in r0 will be assigned */
	
	/* put address of float in r0 */
    assignFloat:
	MOV r11, r0 /* store float address out of way */
	/* sign bit */
	LDR r7, [r0, 4] /* gets sign bit of float into r7 for setOutput. We always stored this, it is always the float address + 4, due to order of data up top */
	/* exponent */
	BL getExponent /* exponent address is still in r0 */
	MOV r8, r0 /* gets stored exponent into r8, for setOutput */
	MOV r9, r1 /* gets unbiased exponent into r9, for setOutput */	
	/* mantissa */
	MOV r0, r11 /* recall float address */
	BL getMantissa
	MOV r10, r1 /* gets mantissa (with implied bit) and stores into r10, for setOutput */
	/* if our exponent is all cleared (subnormal), or all set (infintity, or NaN), then we need the mantissa without the implied bit */
	CMP r8, 0 /* stored exponent is all cleared */
	MOVEQ r10, r0 /* overwrite with mantissa with no implied bit from earlier function return */
	CMP r8, 0xFF /* stored exponent is all set */
	MOVEQ r10, r0 /* overwrite with mantissa with no implied bit from earlier function return */
	/* float */
	LDR r6, [r11] /* puts float into r6, for setOutput */
	
    setOutput: /* set the memory locations for the functions output, see below for what should be stored where */
	LDR r0, =fMax /* r0 must be pointer to fmax for C call */
	STR r6, [r0] /* the maximum float, in r6 */
	LDR r11, =sbMax
	STR r7, [r11] /* the maximum float's sign bit, in r7 */
	LDR r11, =storedExpMax
	STR r8, [r11] /* the maximum float's stored exponent (biased), in r8 */
	LDR r11, =realExpMax
	STR r9, [r11] /* the maximum float's stored exponent (unbiased), in r9 */
	LDR r11, =mantMax
	STR r10, [r11] /* the maximum float's mantissa in r10 */
	
    pop {r4-r11,PC} /* restore upper registers, and set program counter to caller's link (calling convention 2, 3) */ /* spite! */

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



