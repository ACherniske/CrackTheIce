; --- Send 'G' ---
wait_G:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_G
    LDI  r1, #'G'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'o' ---
wait_o1:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_o1
    LDI  r1, #'o'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'o' ---
wait_o2:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_o2
    LDI  r1, #'o'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'd' ---
wait_d:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_d
    LDI  r1, #'d'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'b' ---
wait_b:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_b
    LDI  r1, #'b'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'y' ---
wait_y:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_y
    LDI  r1, #'y'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'e' ---
wait_e:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_e
    LDI  r1, #'e'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send ' ' ---
wait_sp:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_sp
    LDI  r1, #' '
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'F' ---
wait_F:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_F
    LDI  r1, #'F'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'P' ---
wait_P:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_P
    LDI  r1, #'P'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'G' ---
wait_G2:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_G2
    LDI  r1, #'G'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'A' ---
wait_A:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_A
    LDI  r1, #'A'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send '!' ---
wait_exc:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_exc
    LDI  r1, #'!'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- '\r' ---
wait_cr:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_cr
    LDI  r1, #0x0D
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- '\n' ---
wait_lf:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_lf
    LDI  r1, #0x0A
    LDI  r3, #UART_DATA
    ST   r3, r1

wait_done:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_done

    HALT