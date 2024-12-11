; Luke Cutter Morse Code Generator in MASM
; This program converts text messages to Morse Code and writes the output to a file
; IMPORTANT: To avoid errors, place a breakpoint at _main and in Properties >> Linker >> System >> set Enable Large Addresses to NO (/LARGEADDRESSAWARE: NO)

; Declarations for Windows API functions
extrn ExitProcess : proc    ; Function to terminate the program
extrn CreateFileA : proc    ; Function to create/open a file
extrn WriteFile : proc      ; Function to write data to a file
extrn CloseHandle : proc    ; Function to close file handles
extrn GetStdHandle : proc   ; Function to get standard I/O handles
extrn Beep : proc           ; Function for audio output

.DATA
; Output file name, null terminated
outFile BYTE "morse.txt", 0
; Input message to convert
message BYTE "Thank you for teaching me Assembly Professor Hall!", 0


; File handling variables
wHandle QWORD ?           ; Stores the file handle after creation
bytesWrite QWORD ?        ; Stores the number of bytes written

; Windows API Constants
GENERIC_WRITE EQU 40000000h           ; File access mode for writing
CREATE_ALWAYS EQU 2                   ; File creation mode (always creates a new file)
FILE_ATTRIBUTE_NORMAL EQU 80h         ; Normal file attributes
STD_OUTPUT_HANDLE EQU -11             ; Standard output handle constant

; Morse Code timing constants
DOT_FREQ EQU 700                      ; Frequency for dots in Hz
DASH_FREQ EQU 700                     ; Frequency for dashes in Hz
DOT_DUR EQU 110                       ; Duration for dots in ms
DASH_DUR EQU 330                      ; Duration for dashes in ms
PAUSE_DUR EQU 110                    ; Pause between elements in ms

; Output buffer for morse Code
ALIGN 16                              ; Aligns the buffer on 16-byte boundary for efficiency
outBuffer   BYTE 1024 DUP(?)          ; 1024-byte buffer for output

; Complete Morse Code lookup table
; Each entry includes dots (.), dashes (-), and a space, terminated by null (0)
morse_a     BYTE ".- ", 0                ; A in Morse Code
morse_b     BYTE "-... ", 0              ; B in Morse Code
morse_c     BYTE "-.-. ", 0              ; C in Morse Code
morse_d     BYTE "-.. ", 0               ; D in Morse Code
morse_e     BYTE ". ", 0                 ; E in Morse Code
morse_f     BYTE "..-. ", 0              ; F in Morse Code
morse_g     BYTE "--. ", 0               ; G in Morse Code
morse_h     BYTE ".... ", 0              ; H in Morse Code
morse_i     BYTE ".. ", 0                ; I in Morse Code
morse_j     BYTE ".--- ", 0              ; J in Morse Code
morse_k     BYTE "-.- ", 0               ; K in Morse Code
morse_l     BYTE ".-.. ", 0              ; L in Morse Code
morse_m     BYTE "-- ", 0                ; M in Morse Code
morse_n     BYTE "-. ", 0                ; N in Morse Code
morse_o     BYTE "--- ", 0               ; O in Morse Code
morse_p     BYTE ".--. ", 0              ; P in Morse Code
morse_q     BYTE "--.- ", 0              ; Q in Morse Code
morse_r     BYTE ".-. ", 0               ; R in Morse Code
morse_s     BYTE "... ", 0               ; S in Morse Code
morse_t     BYTE "- ", 0                 ; T in Morse Code
morse_u     BYTE "..- ", 0               ; U in Morse Code
morse_v     BYTE "...- ", 0              ; V in Morse Code
morse_w     BYTE ".-- ", 0               ; W in Morse Code
morse_x     BYTE "-..- ", 0              ; X in Morse Code
morse_y     BYTE "-.-- ", 0              ; Y in Morse Code
morse_z     BYTE "--.. ", 0              ; Z in Morse Code
morse_0     BYTE "----- ", 0             ; 0 in Morse Code
morse_1     BYTE ".---- ", 0             ; 1 in Morse Code
morse_2     BYTE "..--- ", 0             ; 2 in Morse Code
morse_3     BYTE "...-- ", 0             ; 3 in Morse Code
morse_4     BYTE "....- ", 0             ; 4 in Morse Code
morse_5     BYTE "..... ", 0             ; 5 in Morse Code
morse_6     BYTE "-.... ", 0             ; 6 in Morse Code
morse_7     BYTE "--... ", 0             ; 7 in Morse Code
morse_8     BYTE "---.. ", 0             ; 8 in Morse Code
morse_9     BYTE "----. ", 0             ; 9 in Morse Code
morse_period BYTE ".-.-.- ", 0           ; Period (.) in Morse Code
morse_comma  BYTE "--..-- ", 0           ; Comma (,) in Morse Code
morse_qmark  BYTE "..--.. ", 0           ; ? in Morse Code
morse_exclam BYTE "-.-.-- ", 0           ; ! in Morse Code
morse_space  BYTE "/ ", 0                ; Space in Morse Code
morse_fslash BYTE "-..-. ", 0            ; / in Morse Code
morse_colon BYTE "---... ", 0            ; : in Morse Code
morse_at BYTE ".--.-. ", 0               ; @ in Morse Code
morse_equal BYTE "-...- ", 0             ; = in Morse Code

; Symbol Morse Code translations gotten from: http://www.moratech.com/aviation/morsecode.html

.CODE
_main PROC
    ; Allocates shadow space for function calls
    sub rsp, 40

    ; Creates an output file using CreateFileA
    mov rcx, OFFSET outFile             ; First step: filename
    mov rdx, GENERIC_WRITE              ; Second step: access mode
    xor r8, r8                          ; Third step: no sharing
    xor r9, r9                          ; Fourth step: no security
    mov QWORD PTR [rsp+32], CREATE_ALWAYS  ; Fifth step: create new file
    mov QWORD PTR [rsp+40], FILE_ATTRIBUTE_NORMAL  ; Sixth step: normal file
    xor rax, rax
    mov QWORD PTR [rsp+48], rax         ; Seventh step: no template
    call CreateFileA
    mov wHandle, rax                    ; Store file handle

    ; Initialize message processing
    lea rsi, message
    xor rdi, rdi

process_loop:
    ; Get next character from message
    movzx rax, byte ptr [rsi]           ; Load character into RAX
    test al, al                         ; Check if the character is null (end of string)
    jz write_file                       ; If null, finish processing
    inc rsi                             ; Move to next character

    ; Convert lowercase to uppercase
    cmp al, 'a'                         ; Check if character is lowercase
    jb check_char                       ; If below 'a', skip conversion
    cmp al, 'z'                         ; Check if character is in lowercase range
    ja check_char                       ; If above 'z', skip conversion
    sub al, 32                          ; Convert to uppercase (subtract 32)

check_char:
    ; Compare character against all possible inputs
    cmp al, 'A'
    je do_a
    cmp al, 'B'
    je do_b
    cmp al, 'C'
    je do_c
    cmp al, 'D'
    je do_d
    cmp al, 'E'
    je do_e
    cmp al, 'F'
    je do_f
    cmp al, 'G'
    je do_g
    cmp al, 'H'
    je do_h
    cmp al, 'I'
    je do_i
    cmp al, 'J'
    je do_j
    cmp al, 'K'
    je do_k
    cmp al, 'L'
    je do_l
    cmp al, 'M'
    je do_m
    cmp al, 'N'
    je do_n
    cmp al, 'O'
    je do_o
    cmp al, 'P'
    je do_p
    cmp al, 'Q'
    je do_q
    cmp al, 'R'
    je do_r
    cmp al, 'S'
    je do_s
    cmp al, 'T'
    je do_t
    cmp al, 'U'
    je do_u
    cmp al, 'V'
    je do_v
    cmp al, 'W'
    je do_w
    cmp al, 'X'
    je do_x
    cmp al, 'Y'
    je do_y
    cmp al, 'Z'
    je do_z
    cmp al, '0'
    je do_0
    cmp al, '1'
    je do_1
    cmp al, '2'
    je do_2
    cmp al, '3'
    je do_3
    cmp al, '4'
    je do_4
    cmp al, '5'
    je do_5
    cmp al, '6'
    je do_6
    cmp al, '7'
    je do_7
    cmp al, '8'
    je do_8
    cmp al, '9'
    je do_9
    cmp al, '.'
    je do_period
    cmp al, ','
    je do_comma
    cmp al, '?'
    je do_qmark
    cmp al, '!'
    je do_exclam
    cmp al, '/'
    je do_fslash
    cmp al, ':'
    je do_colon
    cmp al, '@'
    je do_at
    cmp al, '='
    je do_equal
    cmp al, ' '
    je do_space
    jmp process_loop                    ; Skips any unknown characters

; Character handlers - each loads the appropriate Morse code pattern
do_a:
    mov rbx, OFFSET morse_a             ; Loads the address of Morse code for 'A'
    jmp process_morse
do_b:
    mov rbx, OFFSET morse_b             ; Loads the address of Morse code for 'B'
    jmp process_morse
do_c:
    mov rbx, OFFSET morse_c             ; Loads the address of Morse code for 'C'
    jmp process_morse
do_d:
    mov rbx, OFFSET morse_d             ; Loads the address of Morse code for 'D'
    jmp process_morse
do_e:
    mov rbx, OFFSET morse_e             ; Loads the address of Morse code for 'E'
    jmp process_morse
do_f:
    mov rbx, OFFSET morse_f             ; Loads the address of Morse code for 'F'
    jmp process_morse
do_g:
    mov rbx, OFFSET morse_g             ; Loads the address of Morse code for 'G'
    jmp process_morse
do_h:
    mov rbx, OFFSET morse_h             ; Loads the address of Morse code for 'H'
    jmp process_morse
do_i:
    mov rbx, OFFSET morse_i             ; Loads the address of Morse code for 'I'
    jmp process_morse
do_j:
    mov rbx, OFFSET morse_j             ; Loads the address of Morse code for 'J'
    jmp process_morse
do_k:
    mov rbx, OFFSET morse_k             ; Loads the address of Morse code for 'K'
    jmp process_morse
do_l:
    mov rbx, OFFSET morse_l             ; Loads the address of Morse code for 'L'
    jmp process_morse
do_m:
    mov rbx, OFFSET morse_m             ; Loads the address of Morse code for 'M'
    jmp process_morse
do_n:
    mov rbx, OFFSET morse_n             ; Loads the address of Morse code for 'N'
    jmp process_morse
do_o:
    mov rbx, OFFSET morse_o             ; Loads the address of Morse code for 'O'
    jmp process_morse
do_p:
    mov rbx, OFFSET morse_p             ; Loads the address of Morse code for 'P'
    jmp process_morse
do_q:
    mov rbx, OFFSET morse_q             ; Loads the address of Morse code for 'Q'
    jmp process_morse
do_r:
    mov rbx, OFFSET morse_r             ; Loads the address of Morse code for 'R'
    jmp process_morse
do_s:
    mov rbx, OFFSET morse_s             ; Loads the address of Morse code for 'S'
    jmp process_morse
do_t:
    mov rbx, OFFSET morse_t             ; Loads the address of Morse code for 'T'
    jmp process_morse
do_u:
    mov rbx, OFFSET morse_u             ; Loads the address of Morse code for 'U'
    jmp process_morse
do_v:
    mov rbx, OFFSET morse_v             ; Loads the address of Morse code for 'V'
    jmp process_morse
do_w:
    mov rbx, OFFSET morse_w             ; Loads the address of Morse code for 'W'
    jmp process_morse
do_x:
    mov rbx, OFFSET morse_x             ; Loads the address of Morse code for 'X'
    jmp process_morse
do_y:
    mov rbx, OFFSET morse_y             ; Loads the address of Morse code for 'Y'
    jmp process_morse
do_z:
    mov rbx, OFFSET morse_z             ; Loads the address of Morse code for 'Z'
    jmp process_morse
do_0:
    mov rbx, OFFSET morse_0             ; Loads the address of Morse code for '0'
    jmp process_morse
do_1:
    mov rbx, OFFSET morse_1             ; Loads the address of Morse code for '1'
    jmp process_morse
do_2:
    mov rbx, OFFSET morse_2             ; Loads the address of Morse code for '2'
    jmp process_morse
do_3:
    mov rbx, OFFSET morse_3             ; Loads the address of Morse code for '3'
    jmp process_morse
do_4:
    mov rbx, OFFSET morse_4             ; Loads the address of Morse code for '4'
    jmp process_morse
do_5:
    mov rbx, OFFSET morse_5             ; Loads the address of Morse code for '5'
    jmp process_morse
do_6:
    mov rbx, OFFSET morse_6             ; Loads the address of Morse code for '6'
    jmp process_morse
do_7:
    mov rbx, OFFSET morse_7             ; Loads the address of Morse code for '7'
    jmp process_morse
do_8:
    mov rbx, OFFSET morse_8             ; Loads the address of Morse code for '8'
    jmp process_morse
do_9:
    mov rbx, OFFSET morse_9             ; Loads the address of Morse code for '9'
    jmp process_morse
do_period:
    mov rbx, OFFSET morse_period        ; Loads the address of Morse code for period
    jmp process_morse
do_comma:
    mov rbx, OFFSET morse_comma         ; Loads the address of Morse code for comma
    jmp process_morse
do_qmark:
    mov rbx, OFFSET morse_qmark         ; Loads the address of Morse code for ?
    jmp process_morse
do_exclam:
    mov rbx, OFFSET morse_exclam        ; Loads the address of Morse code for !
    jmp process_morse
do_fslash:
    mov rbx, OFFSET morse_fslash        ; Loads the address of Morse code for /
    jmp process_morse
do_colon:
    mov rbx, OFFSET morse_colon         ; Loads the address of Morse code for :
    jmp process_morse
do_at:
    mov rbx, OFFSET morse_at            ; Loads the address of Morse code for @
    jmp process_morse
do_equal:
    mov rbx, OFFSET morse_equal         ; Loads the address of Morse code for =
    jmp process_morse
do_space:
    mov rbx, OFFSET morse_space         ; Loads the address of Morse code for space
    jmp process_morse




process_morse:
    ; Get next character from morse pattern
    mov al, [rbx]                       ; Gets the character from pattern
    test al, al                         ; Checks if there is a null terminator
    jz process_loop                     ; If null, goes to next input character
    
    ; Copy to buffer
    mov [outBuffer + rdi], al           ; Stores in the output buffer
    inc rdi                             ; Increments the buffer position
    
    ; Play sound based on character
    cmp al, '.'                         ; Check if dot
    je play_dot
    cmp al, '-'                         ; Check if dash
    je play_dash
    jmp next_morse_char                 ; Skips the spaces and other characters

play_dot:
    push rbx                            ; Save registers
    push rdi
    
    ; Play dot sound
    mov rcx, DOT_FREQ
    mov rdx, DOT_DUR
    sub rsp, 32                         ; Shadow space reservation for Beep
    call Beep
    add rsp, 32                         ; Reverts shadow space reservation for Beep
    
    ; Add pause
    mov rcx, DOT_FREQ
    mov rdx, PAUSE_DUR
    sub rsp, 32                         ; Shadow space reservation for Beep
    call Beep
    add rsp, 32                         ; Reverts shadow space reservation for Beep
    
    pop rdi                             ; Restore registers
    pop rbx
    jmp next_morse_char

play_dash:
    push rbx                            ; Save registers
    push rdi
    
    ; Play dash sound
    mov rcx, DASH_FREQ
    mov rdx, DASH_DUR
    sub rsp, 32                         ; Shadow space for Beep
    call Beep
    add rsp, 32                         ; Shadow space reversion for Beep
    
    ; Add pause
    mov rcx, DASH_FREQ
    mov rdx, PAUSE_DUR
    sub rsp, 32                         ; Shadow space for Beep
    call Beep
    add rsp, 32                         ; Shadow space reversion for Beep
    
    pop rdi                             ; Restores the registers
    pop rbx

next_morse_char:
    inc rbx                             ; Moves to the next character in morse pattern
    jmp process_morse                   ; Continues processing the current morse pattern

write_file:
    ; Write complete morse code to file using WriteFile
    mov rcx, wHandle                    ; First parameter: file handle
    mov rdx, OFFSET outBuffer           ; Second parameter: buffer address
    mov r8, rdi                         ; Third parameter: number of bytes to write
    mov r9, OFFSET bytesWrite           ; Fourth parameter: bytes written variable
    xor rax, rax
    mov QWORD PTR [rsp+32], rax         ; Fifth parameter: no overlapped structure
    call WriteFile                      ; Writes to the file

    ; Close the output file
    mov rcx, wHandle                    ; File handle
    call CloseHandle                    ; Closes the file

    ; Get handle to console for output
    mov rcx, STD_OUTPUT_HANDLE          ; Standard output constant
    call GetStdHandle

    ; Exit program with return code 0
    xor rcx, rcx                        ; Return code (0) and exit
    call ExitProcess
_main ENDP

END