.align 2
lockedVal:
    .byte 0

.align 2
unlockedVal:
    .byte 1

.macro WAIT_FOR_UPDATE
    WFE
.endmacro

.macro SIGNAL_UPDATE
    DSB
    SEV
.endmacro

@ Declare extern void _most_freq_char_lock_mutex(void * mutex);
.global _most_freq_char_lock_mutex
.arm
.align 2
_most_freq_char_lock_mutex:
    LDR     r1, lockedVal
1:  LDREX   r2, [r0]
    CMP     r2, r1        @ Test if mutex is locked or unlocked
	BEQ     2f            @ If locked - wait for it to be released, from 2
    STREXNE r2, r1, [r0]  @ Not locked, attempt to lock it
    CMPNE   r2, #1        @ Check if Store-Exclusive failed
    BEQ     1b            @ Failed - retry from 1
    @ Lock acquired
    DMB                   @ Required before accessing protected resource
    BX      lr

2:  @ Take appropriate action while waiting for mutex to become unlocked
    WAIT_FOR_UPDATE
    B       1b            @ Retry from 1

@ Declare extern void _most_freq_char_unlock_mutex(void * mutex);
.global _most_freq_char_unlock_mutex
.arm
.align 2
_most_freq_char_unlock_mutex:
    LDR     r1, unlockedVal
    DMB                   @ Required before releasing protected resource
    STR     r1, [r0]      @ Unlock mutex
    SIGNAL_UPDATE	
    BX      lr
