;; NOTE: stolen from https://lists.nongnu.org/archive/html/gcl-devel/2012-10/pdfkieTlklRzN.pdf
BITS 64

%define SYS_EXIT 60
%define SYS_WRITE 1
%define STDOUT 1
%define PRINT_FRAC_N 10

segment .text

;; xmm0 - input
;; xmm0 - output
frac:
    ;; frac(x) = x - trunc(x)
    movsd xmm1, xmm0
    cvttsd2si rax, xmm1
    cvtsi2sd xmm1, rax
    subsd xmm0, xmm1
    ret

;; xmm0 - input
;; xmm0 - output
floor:
    cvttsd2si rax, xmm0
    cvtsi2sd xmm1, rax
    subsd xmm0, xmm1

    pxor xmm1, xmm1
    comisd xmm0, xmm1
    jae .skipdec
    dec rax
.skipdec:
    cvtsi2sd xmm0, rax
    ret

print_int:
    ;; rax contains the value we need to print
    ;; rdi is the counter of chars
    mov rdi, 0
.loop:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add rdx, '0'
    dec rsp
    inc rdi
    mov [rsp], dl
    cmp rax, 0
    jne .loop
    ;; rsp - points at the beginning of the buf
    ;; rdi - contains the size of the buf
    ;; printing the buffer
    mov rbx, rdi
    ;; write(STDOUT, buf, buf_size)
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, rsp
    mov rdx, rbx
    syscall
    add rsp, rbx
    ret

;; xmm0 - f - fraction to print, must be < 1.0
print_frac:
    ;; dot of the fraction
    mov BYTE [x], '.'
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, x
    mov rdx, 1
    syscall

    ;; Allocate stack variables
%define M    0
%define R    (M + 8)
%define U    (R + 8)
%define Size (U + 8)
    sub rsp, Size
    ;; ------------------------------

    ;; Initialize R -----------------
    movsd QWORD [rsp + R], xmm0
    ;; ------------------------------

    ;; Initialize M -----------------
    movsd xmm0, QWORD [one]
    mov rax, PRINT_FRAC_N
.loop:
    test rax, rax
    jz .end

    movsd xmm1, QWORD [tenth]
    mulsd xmm0, xmm1
    dec rax
    jmp .loop
.end:
    movsd xmm1, QWORD [half]
    mulsd xmm0, xmm1
    movsd [rsp + M], xmm0
    ;; ------------------------------

.loop1:
    ;; U = floor(R * 10.0);
    movsd xmm0, QWORD [rsp + R]
    movsd xmm1, QWORD [ten]
    mulsd xmm0, xmm1
    call floor
    movsd QWORD [rsp + U], xmm0

    ;; R = frac(R * 10.0);
    movsd xmm0, QWORD [rsp + R]
    movsd xmm1, QWORD [ten]
    mulsd xmm0, xmm1
    call frac
    movsd QWORD [rsp + R], xmm0

    ;; M = M * 10.0;
    movsd xmm0, QWORD [rsp + M]
    movsd xmm1, QWORD [ten]
    mulsd xmm0, xmm1
    movsd QWORD [rsp + M], xmm0

    ;; if (R < M) break;
    movsd xmm0, QWORD [rsp + R]
    movsd xmm1, QWORD [rsp + M]
    comisd xmm0, xmm1
    jb .loop1_end

    ;; if (R > 1 - M) break;
    movsd xmm0, QWORD [one]
    movsd xmm1, QWORD [rsp + M]
    subsd xmm0, xmm1
    movsd xmm1, xmm0
    movsd xmm0, QWORD [rsp + R]
    comisd xmm0, xmm1
    ja .loop1_end

    ; printf("%d", (int) U);
    movsd xmm0, QWORD [rsp + U]
    cvttsd2si rax, xmm0
    add al, '0'
    mov BYTE [x], al
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, x
    mov rdx, 1
    syscall

    jmp .loop1
.loop1_end:

    ;; if (R > 0.5) {
    ;;     U += 1.0;
    ;; }
    movsd xmm0, QWORD [rsp + R]
    movsd xmm1, QWORD [half]
    comisd xmm0, xmm1

    jbe .skip_increment
    movsd xmm0, QWORD [rsp + U]
    movsd xmm1, QWORD [one]
    addsd xmm0, xmm1
    movsd QWORD [rsp + U], xmm0
.skip_increment:

    ;; printf("%d", (int) U);
    movsd xmm0, QWORD [rsp + U]
    cvttsd2si rax, xmm0
    add al, '0'
    mov BYTE [x], al
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, x
    mov rdx, 1
    syscall

    ;; Deallocate stack variable
    add rsp, Size
%undef Size
%undef U
%undef R
%undef M
    ;; ------------------------------
    ret

;; xmm0
;; TODO: print_f64 does not support negative numbers
print_f64:
    cvttsd2si rax, xmm0
    call print_int

    call frac
    call print_frac

    mov BYTE [x], 10
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, x
    mov rdx, 1
    syscall

    ret

global _start
_start:
    movsd xmm0, QWORD [pi]
    call print_f64

    mov rax, SYS_EXIT
    mov rdi, 0
    syscall

segment .data
one:   dq 1.0
half:  dq 0.5
ten:   dq 10.0
tenth: dq 0.1
pi:    dq 3.141592653589

segment .bss
x: resb 1
