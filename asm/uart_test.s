; =============================================================================
; uart_test.s
; Clean UART test pattern generator
; Sends "UART_TEST\r\n" forever
; =============================================================================

; r1 = char
; r2 = temp (UART busy)
; r3 = IO addr

loop:

; --- U ---
wait_U:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_U
    LDI r1, #'U'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- A ---
wait_A:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_A
    LDI r1, #'A'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- R ---
wait_R:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_R
    LDI r1, #'R'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- T ---
wait_T:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_T
    LDI r1, #'T'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- _ ---
wait_us:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_us
    LDI r1, #'_'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- T ---
wait_T2:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_T2
    LDI r1, #'T'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- E ---
wait_E:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_E
    LDI r1, #'E'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- S ---
wait_S:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_S
    LDI r1, #'S'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- T ---
wait_T3:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_T3
    LDI r1, #'T'
    LDI r3, #UART_DATA
    ST  r3, r1

; --- \r ---
wait_cr:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_cr
    LDI r1, #0x0D
    LDI r3, #UART_DATA
    ST  r3, r1

; --- \n ---
wait_lf:
    LDI r3, #UART_BUSY
    LD  r2, r3
    BNZ wait_lf
    LDI r1, #0x0A
    LDI r3, #UART_DATA
    ST  r3, r1

    JMP loop