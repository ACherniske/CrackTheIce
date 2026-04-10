; =============================================================================
; hello.s - PISC-8 "Hello World" firmware
; Sends "Hello, World!\r\n" over UART, then halts.
;
; Register usage:
;   r1 (acc) - current character to send / loop scratch
;   r2 (tmp) - loop counter / UART busy poll value
;   r3 (t0)  - holds port address constants during I/O
;   r6 (cnt) - string index counter
;
; Algorithm:
;   1. Load the string into a lookup table (LDI sequence)
;   2. For each character:
;        a. Wait until UART is not busy  (poll UART_BUSY port)
;        b. Write the character to UART_DATA port
;   3. HALT
;
; I/O port constants (can be used directly as LDI immediates):
;   UART_DATA = 0x00  (write-only: byte to transmit)
;   UART_BUSY = 0x01  (read-only:  1=busy, 0=ready)
;
; Note: PISC-8 has no indirect addressing, so we unroll the string
;       transmission explicitly. This keeps the ISA minimal while
;       still showing the full UART handshake pattern.
;       See hello_loop.s for a pointer-based version once you add
;       data RAM and indirect load instructions.
; =============================================================================

; ---------------------------------------------------------------------------
; Macro-style subroutine to send a single character.
; Pattern used for each character:
;
;   LDI  r3, #UART_BUSY   ; load port address into r3
; wait_N:
;   LD   r2, r3           ; r2 <- IO[r3] = UART_BUSY status
;   BNZ  wait_N           ; if busy (non-zero), keep polling
;   LDI  r1, #'X'         ; load character into r1
;   LDI  r3, #UART_DATA   ; port address for UART_DATA
;   ST   r3, r1           ; IO[r3] <- r1  (transmit byte)
;
; ---------------------------------------------------------------------------

; ============================================================
; ENTRY POINT - execution begins at address 0x00
; ============================================================

; --- Send 'H' ---
wait_H:
    LDI  r3, #UART_BUSY       ; r3 = address of UART_BUSY port (0x01)
    LD   r2, r3               ; r2 <- IO[UART_BUSY]
    BNZ  wait_H               ; if busy, loop
    LDI  r1, #'H'             ; 0x48
    LDI  r3, #UART_DATA       ; r3 = address of UART_DATA port (0x00)
    ST   r3, r1               ; transmit 'H'

; --- Send 'e' ---
wait_e:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_e
    LDI  r1, #'e'             ; 0x65
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'l' (first) ---
wait_l1:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_l1
    LDI  r1, #'l'             ; 0x6C
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'l' (second) ---
wait_l2:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_l2
    LDI  r1, #'l'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'o' ---
wait_o:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_o
    LDI  r1, #'o'             ; 0x6F
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send ',' ---
wait_comma:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_comma
    LDI  r1, #','             ; 0x2C
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send ' ' ---
wait_sp:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_sp
    LDI  r1, #' '             ; 0x20
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'W' ---
wait_W:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_W
    LDI  r1, #'W'             ; 0x57
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

; --- Send 'r' ---
wait_r:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_r
    LDI  r1, #'r'             ; 0x72
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'l' ---
wait_l3:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_l3
    LDI  r1, #'l'
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send 'd' ---
wait_d:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_d
    LDI  r1, #'d'             ; 0x64
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send '!' ---
wait_exc:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_exc
    LDI  r1, #'!'             ; 0x21
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send '\r' (carriage return, 0x0D) ---
wait_cr:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_cr
    LDI  r1, #0x0D
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Send '\n' (newline, 0x0A) ---
wait_lf:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_lf
    LDI  r1, #0x0A
    LDI  r3, #UART_DATA
    ST   r3, r1

; --- Wait for last byte to finish, then light LED and halt ---
wait_done:
    LDI  r3, #UART_BUSY
    LD   r2, r3
    BNZ  wait_done

; Light up LED (GPIO_OUT port = 0x02, value 0x01 = LED0 on)
    LDI  r1, #0x01            ; LED pattern: bit 0 on
    LDI  r3, #GPIO_OUT        ; port 0x02
    ST   r3, r1               ; drive LED

    HALT