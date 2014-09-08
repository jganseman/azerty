;       Azerty Keyboard driver for 16-bit DOS programs run in NTVDM
;                   Joachim Ganseman, 7 september 2014
;
;   This project was made because the AltGr key is dead after running "kb16 be"
;   in the NTVDM in recent 32-bit Windows operating systems. 
;
;       To assemble, first install masm32 and a good hex editor (HxD, IDA, ...)
;       From command line (Win 7, masm32-ml version 6.14), run:
;           path-to-masm\bin\ml /AT /c KEYBAZ.ASM
;			rm KEYBAZ.COM
;           path-to-masm\bin\link16 KEYBAZ.obj,KEYBAZ.COM
;
;       Since exe2bin is not included in masm32, perform these steps manually:
;           In a hex editor, remove the first 300h bits such that the file starts with E9
;           (? Also, find bytes "02 0C 01", and replace 3 bytes following that string: 
;           "83 E0 07" should become "25 07 00". ?)
;
;   This code was adapted from a German QWERTZ-keyboard driver published in 1990 on 
;   http://www.heise.de/ct/hotline/Deutsche-Tastatur-im-Vista-DOS-Fenster-322534.html
;   , with German comments (! did not make it easier as my German is very rusty).
;   Credit to whom credit is due: I include here the heading of the original file:
;
;=============================================================================
;
;       Mini-tastaturtreiber, J. Tucht, 31.10.1990
;
;	Assemblierung fÅr aufruf von der COMMAND-ebene:
;
;		masm keyboard;
;		link keyboard;
;		exe2bin keyboard.com
;
;       Assemblierung fÅr einbindung in config.sys (wird noch kleiner)
;
;		masm keyboard /dConfigSys;
;		link keyboard;
;		exe2bin keyboard
;
;	MASM 3.0 schluckt den /D-switch nicht (ich habe MASM 4.0).
;       Ggf. am anfang des quelltextes 'ConfigSys EQU 1' einfÅgen!
;
;=============================================================================

CapsLockBit EQU 40h

;=============================================================================
;                        Makros der Uebersetzungstabellen
;=============================================================================


    ; First, tabulate all normal (lowercase) non-alphanumeric characters
    ; Note: avoid using HEX codes for characters, since they differ depending on codepage
	; Make sure this file is edited and saved in the codepage that you want!
Primary MACRO
Key 29h,'˝'     ; Superscript 2
Key 02h,'&'
Key 03h,'Ç'     ; e acute
Key 04h,'"'
Key 05h,"'"
Key 06h,'('
Key 07h,'ı'     ; Section sign
Key 08h,'ä'     ; e grave
Key 09h,'!'
Key 0Ah,'á'     ; c cedilla
Key 0Bh,'Ö'     ; a grave
Key 0Ch,')' 
Key 0Dh,'-'
Key 1Ah,'^'     ; (modifier?) circumflex
Key 1Bh,'$'
Key 28h,'ó'     ; u grave
Key 2Bh,'Ê'     ; mu - micro sign . On keycode for 102-key keyboards.
Key 56h,'<'
Key 32h,','
Key 33h,';'
Key 34h,':'
Key 35h,'='
ENDM


    ; Now tabulate the same keys when the shift key is pressed
Shift MACRO
Key 29h,'¸'     ; Superscript 3
Key 02h,'1'
Key 03h,'2'     
Key 04h,'3'
Key 05h,'4'
Key 06h,'5'
Key 07h,'6' 
Key 08h,'7' 
Key 09h,'8'
Key 0Ah,'9' 
Key 0Bh,'0'
Key 0Ch,'¯'     ; Degree sign 
Key 0Dh,'_'
Key 1Ah,'˘'     ; trema - umlaut
Key 1Bh,'*'
Key 28h,'%'
Key 2Bh,'ú'     ; Pound sign
Key 56h,'>'
Key 32h,'?'
Key 33h,'.'
Key 34h,'/'
Key 35h,'+'
ENDM

Ctrl MACRO      ; These map to ASCII Control Codes. No idea why they remain active here. Leaving them in for now.
; Key 15h,019H     ; Ctrl-Y
; Key 11h,01Ah     ; Ctrl-Z
ENDM

Alt MACRO       ; Avoid using the ALT-key alone. In many DOS-programs, these activate shortcuts in the GUI or menu. 
; Key 08h,'+'
ENDM

; For the next bit, we add some additional characters as found on many recent keyboards, as in:
; http://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Belgian_Linux_keyboard.svg/1280px-Belgian_Linux_keyboard.svg.png

CtrlAlt MACRO       ; Ctrl+Alt equals the Alt-GR combination!
Key 29h,'™'     ; Logical not-sign
Key 02h,'|'
Key 03h,'@'     
Key 04h,'#'
Key 05h,'¨'     ; Fraction 1/4
Key 06h,'´'     ; Fraction 1/2
Key 07h,'^'     ; Non-modifier (?) caret sign 
;Key 08h,'{' 
;Key 09h,'['
Key 0Ah,'{' 
Key 0Bh,'}'
Key 0Ch,'\'     
Key 1Ah,'['     
Key 1Bh,']'
Key 28h,'Ô'     ; acute accent (modifier?)
Key 2Bh,'`'     ; grave accent (modifier?)
Key 56h,'\'
Key 34h,'˙'     ; middle dot - gregorian comma
Key 35h,'~'     ; tilde (modifier?)
Key 10h,'@'
;Key 12h,'Ä'     ; Euro sign
;Key 18h,09Ch     ; lowercase oe-ligature
Key 19h,'Ë'     ; lowercase Nordic thorn
Key 1Eh,'ë'     ; lowercase ae-ligature
Key 1Fh,'·'     ; German double-sz
;Key 20h,0F0h     ; lowercase Nordic eth
Key 2Ch,'Æ'     ; left double angle brackets
Key 2Dh,'Ø'     ; right double angle brackets
Key 2Eh,'Ω'     ; cent sign
ENDM

ShiftAlt MACRO          ; TODO: figure out response of AZERTY keyboard to shift-alt
ENDM

CtrlShift MACRO         ; TODO: figure out response of AZERTY keyboard to ctrl-shift
; Key 15h,019h  ;Ctrl-Shift-Y wie Ctrl Y
; Key 11h,01AH  ;Ctrl-Shift-Z wie Ctrl Z
ENDM

CtrlShiftAlt MACRO      ; This equals AltGR-Shift.
Key 02h,'≠'     ; Inverted exclamation mark
Key 04h,'ú'     ; Pound sign
Key 05h,'$'     
;Key 09h,099h     ; TM-trademark sign
Key 0Ah,'Ò'     ; plus-minus sign 
Key 0Bh,'¯'     ; Degree sign
Key 0Ch,'®'     ; Inverted question mark     
Key 33h,'û'     ; Multiplication sign
Key 34h,'ˆ'     ; Division sign
Key 12h,'Ω'     ; Cent sign
Key 13h,'©'     ; R-registered trademark sign
Key 15h,'æ'     ; Yen sign
;Key 18h,08Ch     ; uppercase oe-ligature
Key 19h,'Á'     ; uppercase Nordic thorn
Key 1Eh,'í'     ; uppercase ae-ligature
;Key 20h,0D0h     ; uppercase Nordic eth
Key 2Eh,'∏'     ; C-copyright sign
ENDM


LowerCase MACRO         ; Define alphanumerics which are different from qwerty
Key 10h,'a'
Key 11h,'z'
Key 1Eh,'q'
Key 27h,'m'
Key 2Ch,'w'
ENDM


UpperCase MACRO
Key 10h,'A'
Key 11h,'Z'
Key 1Eh,'Q'
Key 27h,'M'
Key 2Ch,'W'
ENDM


ScanXchg MACRO          ; TODO figure out what these are for. Leave it in for now...
;Key 2Ch,15h         ; Y-key on QWERTZ
;Key 15h,2Ch         ; Z-key on QWERTZ
;Key 79h,03h         ; This key seems to be an uncommon one found next to spacebar on some keyboards (like japanses ones)
ENDM                     ; They also map to ASCII Control Codes, but it probably has some other use.

;Sollen Scan-Codes unangetastet bleiben:
;PURGE ScanXchg

;---------------------------------------------------------------Spaltenumbruch


DezimalDings          EQU '.,' ;Liefere je nach CapsLock "." oder ","
RomDezimalDings       EQU '.'



;=============================================================================
;                                 Allgemeine Macros
;=============================================================================

SetInt                MACRO Num,Ofs
                      MOV AX,2500H+Num
                      MOV DX,OFFSET Ofs
                      INT 21H
                      ENDM

GetInt                MACRO Num,Vector
                      MOV AX,3500H+Num
                      INT 21H
                      MOV WORD PTR [Vector],BX
                      MOV WORD PTR [Vector+2],ES
                      ENDM

CODE                  SEGMENT
                      ASSUME CS:CODE,DS:CODE


;-----------------------------------------------------------------------------
                      IFDEF ConfigSys
;-----------------------------------------------------------------------------


EntryLabel            PROC FAR

;Device Header

                      DD -1
                      DW 8004h
StrategyTrap          DW Strategy
InstallTrap           DW Install
                      ;   12345678
                      DB "NUL     "   ;Geraetename
IGNORE:               RET
EntryLabel            ENDP

;-----------------------------------------------------------------------------
                      ELSE ;IFNDEF ConfigSys
;-----------------------------------------------------------------------------

                      ORG 100h
EntryLabel:           JMP Install

;-----------------------------------------------------------------------------
                      ENDIF
;-----------------------------------------------------------------------------


;=============================================================================
;residenter Datenbereich
;=============================================================================

                      EVEN  ;gerade Adresse erzwingen

Setup MACRO Table
Table&Size=0
Key MACRO Key,Symbol
DB LOW Symbol,Key
Table&Size=Table&Size+1
ENDM
Table&Addr:
ENDM


Setup Primary
LowerCase
Primary
Setup Shift
UpperCase
Shift
Setup Caps
LowerCase
IRP X,<Ctrl,Alt,CtrlShift,CtrlAlt,ShiftAlt,CtrlShiftAlt,ScanXchg>
Setup X
X
ENDM


AddrIndex             DW PrimaryAddr, ShiftAddr
                      DW CtrlAddr, CtrlShiftAddr
                      DW AltAddr,ShiftAltAddr
                      DW CtrlAltAddr, CtrlShiftAltAddr

SizeIndex             DB PrimarySize, ShiftSize
                      DB CtrlSize, CtrlShiftSize
                      DB AltSize,ShiftAltSize
                      DB CtrlAltSize, CtrlShiftAltSize

E0Flag                DB 0

;=============================================================================
;residenter CodeBereich
;=============================================================================



KbdEvent:             CLD
                      IRP  XX,<DS,BX,AX,CX,ES,DI>
                      PUSH XX
                      ENDM
                      PUSH CS
                      POP  ES
                      MOV  CX,40h
                      MOV  DS,CX


                      XOR  BX,BX

                      TEST BYTE PTR DS:[96h],8  ;RightAlt gedrueckt?
                      MOV  AL,4+8               ;CtrlAlt vortaeuschen
                      JNZ  $+5

                      MOV  AL,DS:[17h]          ;Flag fuerShift/Ctrl/Alt/Caps

                      MOV  DI,AX
                      SHR  AL,1
                      JNC  $+4
                      OR   AL,1
                      AND  AX,7

                      IF CapsSize
                      TEST AL,6                 ;setzt Z-Flag fuer Tabellen
                      ENDIF                     ;"Primary" nad "Shift"

                      XCHG DI,AX
                      MOV  CL,CS:[SizeIndex+DI]
                      ROL  DI,1                 ;ROL laesst Z-Flag unberuehrt
                      MOV  DI,CS:[AddrIndex+DI]

                      IF CapsSize
                      JNZ  Scan
                      TEST AL,CapsLockBit
                      JZ   Scan
                      ADD  DI,2*CapsSize
                      ENDIF

Scan:                 IN   AL,60h
                      MOV  AH,AL
                      CMP  CS:E0Flag,0E0h
                      MOV  CS:E0Flag,AL
                      JZ   ChainOld

                      JCXZ ChainOld             ;Schleife evtl ueberspringen
                      MOV  AL,ES:[DI]
                      SCASW
                      LOOPNZ $-4
                      JNZ  ChainOld
                      MOV  BX,AX

ChainOld:
                      IF ScanXchgSize
                      MOV  DI,OFFSET ScanXchgAddr
                      MOV  CL,ScanXchgSize
                      MOV  AL,ES:[DI]
                      SCASW
                      LOOPNZ $-4
                      JNZ  $+4
                      MOV  BH,AL
                      ENDIF

                      MOV  AX,DS:[1Ch]
                      PUSHF
                      DB   9Ah
OldKbdEvent           DD ?
                      XCHG BX,AX

                      IF DezimalDings NE RomDezimalDings
                      CMP  WORD PTR [BX],5300h+RomDezimalDings
                      JNZ  Skip5
                      MOV  BYTE PTR [BX],LOW DezimalDings
                      IF DezimalDings/100h
                      TEST BYTE PTR DS:[17H],CapsLockBit
                      JZ   Skip5
                      MOV BYTE PTR [BX],HIGH DezimalDings
                      ENDIF
Skip5:
                      ENDIF

                      OR   AX,AX                ;Scan-Code oder Zeichen aendern?
                      JZ   Exit                 ;Nein:Exit
                      MOV  [BX],AX              ; Ja: Zeichenim Puffer ablegen
                      LEA  AX,[BX+2]
                      CMP  AL,3Eh
                      JNZ  $+4
                      MOV  AL,1Eh
                      CMP  AX,DS:[1Ah]
                      JZ   Exit
                      MOV  DS:[1Ch],AX

Exit:
                      IRP  XX,<DI,ES,CX,AX,BX,DS>
                      POP  XX
                      ENDM

                      IRET

;=============================================================================
                      IFDEF ConfigSys
;=============================================================================


Install               PROC FAR
                      PUSH AX
                      PUSH BX
                      PUSH DX
                      PUSH DS
                      PUSH ES

                      PUSH CS
                      POP  DS

                      GetInt 9h,OldKbdEvent
                      SetInt 9h,KbdEvent

;Regulaeren Eintrittspunkt im Device-Header vermerken

                      MOV  AX,OFFSET Ignore
                      MOV  StrategyTrap,AX
                      MOV  InstallTrap,AX
                      MOV  DX,OFFSET OkMsg
                      MOV  AH,9
                      INT  21h

;Treiber/Ende und Status im Request Header vermerken

                      LDS  BX,RequestPtr
                      MOV  WORD PTR[BX+14], OFFSET Install
                      MOV  [BX+16],CS
                      MOV  WORD PTR [BX+3],300h
                      POP  ES
                      POP  DS
                      POP  DX
                      POP  BX
                      POP  AX
                      RET

Strategy:             MOV  WORD PTR CS:RequestPtr, BX
                      MOV  WORD PTR CS:RequestPtr+2,ES
                      RET

RequestPtr            DD   ?                    ;Zeiger auf Request-Header

Install               ENDP

;-----------------------------------------------------------------------------
                      ELSE ;IFNDEF ConfigSys
;-----------------------------------------------------------------------------


Install:              MOV  DX,OFFSET OkMsg
                      MOV  AH,9
                      INT  21h

                      GetInt 9h,OldKbdEvent
                      SetInt 9h,KbdEvent

                      MOV DX,OFFSET Install
                      INT 27h                   ;resident beleiben

;-----------------------------------------------------------------------------
                      ENDIF
;-----------------------------------------------------------------------------

OkMsg                 DB 13,10,'AZERTY driver loaded, ∏ Joachim Ganseman'
                      DB 13,10,'$'

CODE                  ENDS
END                   EntryLabel ; Return nicht vergessen!
