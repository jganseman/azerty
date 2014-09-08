;       Azerty Keyboard driver for 16-bit DOS programs run in NTVDM
;                   Joachim Ganseman, 7 september 2014
;
;   This project was made because the AltGr key is dead after running "kb16 be"
;   in the NTVDM in recent 32-bit Windows operating systems. 
;
;       To assemble, first install masm32 and a good hex editor (HxD, IDA, ...)
;       From command line (Win 7, masm32-ml version 6.14), run:
;           path-to-masm\bin\ml /AT /c KEYBAZ.ASM
;           path-to-masm\bin\link16 KEYBAZ.obj,KEYBAZ.COM
;
;       Since exe2bin is not included in masm32, perform these steps manually:
;           In a hex editor, remove the first 300h bits such that it starts with E9 6C
;           Also, find bytes "02 0C 01", and replace 3 bytes following that string: 
;           "83 E0 07" should become "25 07 00".
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
Primary MACRO
;Key 29h,'^'
;Key 0Ch,'·'
;Key 0Dh,"'"
;Key 2Bh,'#'
;Key 1Bh,'+'
;Key 35h,'-'
;Key 56h,'<'
Key 29h,0B2h     ; Superscript 2
Key 02h,'&'
Key 03h,0E9h     ; e acute
Key 04h,'"'
Key 05h,"'"
Key 06h,'('
Key 07h,0A7h     ; Section sign
Key 08h,0E8h     ; e grave
Key 09h,'!'
Key 0Ah,0E7h     ; c cedilla
Key 0Bh,0E0h     ; a grave
Key 0Ch,')' 
Key 0Dh,'-'
Key 1Ah,088h     ; modifier (!) circumflex
Key 1Bh,'$'
Key 28h,0F9h     ; u grave
Key 2Bh,0B5h     ; mu - micro sign . On keycode for 102-key keyboards.
Key 56h,'<'
Key 32h,','
Key 33h,';'
Key 34h,':'
Key 35h,'='
ENDM


    ; Now tabulate the same keys when the shift key is pressed
Shift MACRO
;Key 29h,'¯'
;Key 03h,'"'
;Key 04h,15h ;Paragraph - hier kann man auch '@' hinsetzen
;Key 07h,'&'
;Key 08h,'/'
;Key 09h,'('
;Key 0Ah,')'
;Key 0Bh,'='
;Key 0Ch,'?'
;Key 0Dh,'`'
;Key 2Bh,'`'
;Key 1Bh,'*'
;Key 33h,';'
;Key 34h,':'
;Key 35h,'_'
;Key 56h,'>'  ;Spalten/Seitumbruch 249/250
Key 29h,0B3h     ; Superscript 3
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
Key 0Ch,0B0h     ; Degree sign 
Key 0Dh,'_'
Key 1Ah,0A8h     ; trema - umlaut
Key 1Bh,'*'
Key 28h,'%'
Key 2Bh,0A3h     ; Pound sign
Key 56h,'>'
Key 32h,'?'
Key 33h,'.'
Key 34h,'/'
Key 35h,'+'
ENDM

Ctrl MACRO      ; These map to ASCII Control Codes. No idea why they remain active here. Leaving them in for now.
;Key 2Ch,19H    
;Key 15h,1Ah    
Key 15h,019H     ; Ctrl-Y
Key 11h,01Ah     ; Ctrl-Z
ENDM

Alt MACRO       ; Avoid using the ALT-key alone. In many DOS-programs, these activate shortcuts in the GUI or menu. 
;Key 08h,'+'
ENDM

; For the next bit, we add some additional characters as found on many recent keyboards, as in:
; http://upload.wikimedia.org/wikipedia/commons/thumb/4/49/Belgian_Linux_keyboard.svg/1280px-Belgian_Linux_keyboard.svg.png

CtrlAlt MACRO       ; Ctrl+Alt equals the Alt-GR combination!
;Key 1Eh,'†'
;Key 12h,'Ç'
;Key 17h,'°'
;Key 18h,'¢'
;Key 16h,'£'
;Key 03h,'2'
;Key 04h,'§'
;Key 10h,'@'
;Key 08h,'{'
;Key 09h,'['
;Key 0Ah,']'
;Key 0Bh,'}'
;Key 0Ch,'\'
;Key 1Bh,'~'
;Key 56h,'|'
Key 29h,0ACh     ; Logical not-sign
Key 02h,'|'
Key 03h,'@'     
Key 04h,'#'
Key 05h,0BCh     ; Fraction 1/4
Key 06h,0BDh     ; Fraction 1/2
Key 07h,'^'     ; Non-modifier caret sign 
Key 08h,'{' 
Key 09h,'['
Key 0Ah,'{' 
Key 0Bh,'}'
Key 0Ch,'\'     
;Key 0Dh,'_'
Key 1Ah,'['     
Key 1Bh,']'
Key 28h,092h     ; acute accent
Key 2Bh,091h     ; grave accent
Key 56h,'\'
;Key 32h,'?'
;Key 33h,'.'
Key 34h,0B7h     ; middle dot - gregorian comma
Key 35h,098h     ; Small tilde (modifier?)
Key 10h,'@'
Key 12h,080h     ; Euro sign
Key 18h,09Ch     ; lowercase oe-ligature
Key 19h,0FEh     ; lowercase Nordic thorn
Key 1Eh,0E6h     ; lowercase ae-ligature
Key 1Fh,0DFh     ; German double-sz
Key 20h,0F0h     ; lowercase Nordic eth
Key 2Ch,0ABh     ; left double angle brackets
Key 2Dh,0BBh     ; right double angle brackets
Key 2Eh,0A2h     ; cent sign
ENDM

ShiftAlt MACRO          ; TODO: figure out response of AZERTY keyboard to shift-alt
;Key 1Eh,'Ö'
;Key 12h,'ä'
;Key 17h,'ç'
;Key 18h,'ï'
;Key 16h,'ó'
;Key 03h,'˘' ;ShiftAlt2
;Key 05h,'˘' ;ShiftAlt4
ENDM

CtrlShift MACRO         ; TODO: figure out response of AZERTY keyboard to ctrl-shift
Key 15h,019h  ;Ctrl-Shift-Y wie Ctrl Y
Key 11h,01AH  ;Ctrl-Shift-Z wie Ctrl Z
;Key 2ch,19h  ;Ctrl-Shift-Y wie Ctrl Y
;Key 15h,1AH  ;Ctrl-Shift-Z wie Ctrl Z
;Key 1Eh,'a'  
;Key 30h,'·'
;Key 2Eh,'r'
;Key 22h,'G'
;Key 20h,'Â'
;Key 19h,'„'
;Key 1Fh,'s'
;Key 32h,'Ê'
;Key 18h,'Í'
;Key 21h,'Ë'
;Key 12h,'E'
;Key 14h,'Ì'
;Key 10h,'˚'
ENDM

CtrlShiftAlt MACRO      ; This equals AltGR-Shift.
;Key 1Eh,'É'
;Key 12h,'à'
;Key 17h,'å'
;Key 18h,'ì'
;Key 16h,'ñ'
Key 02h,0A1h     ; Inverted exclamation mark
Key 04h,0A3h     ; Pound sign
Key 05h,'$'     
Key 09h,099h     ; TM-trademark sign
Key 0Ah,0B1h     ; plus-minus sign 
Key 0Bh,0B0h     ; Degree sign
Key 0Ch,0BFh     ; Inverted question mark     
Key 33h,0D7h     ; Multiplication sign
Key 34h,0F7h     ; Division sign
;Key 10h,'@'
Key 12h,0A2h     ; Cent sign
Key 13h,0AEh     ; R-registered trademark sign
Key 15h,0A5h     ; Yen sign
Key 18h,08Ch     ; uppercase oe-ligature
Key 19h,0DEh     ; uppercase Nordic thorn
Key 1Eh,0C6h     ; uppercase ae-ligature
;Key 1Fh,DFh     ; German double-sz
Key 20h,0D0h     ; uppercase Nordic eth
Key 2Eh,0A9h     ; C-copyright sign
ENDM


LowerCase MACRO         ; Define alphanumerics which are different from qwerty
;Key 28h,'Ñ'
;Key 27h,'î'
;Key 1Ah,'Å'
;Key 2Ch,'y'
;Key 15h,'z'
Key 10h,'a'
Key 11h,'z'
Key 1Eh,'q'
Key 27h,'m'
Key 2Ch,'w'
ENDM


UpperCase MACRO
;Key 28h,'é'
;Key 27h,'ô'
;Key 1Ah,'ö'
;Key 2Ch,'Y'
;Key 15h,'Z'
Key 10h,'A'
Key 11h,'Z'
Key 1Eh,'Q'
Key 27h,'M'
Key 2Ch,'W'
ENDM

ScanXchg MACRO          ; TODO figure out what these are for. Leave it in for now...
Key 2Ch,15h         ; Y-key on QWERTZ
Key 15h,2Ch         ; Z-key on QWERTZ
Key 79h,03h         ; This key seems to be an uncommon one found next to spacebar on some keyboards (like japanses ones)
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

OkMsg                 DB 13,10,'AZERTY driver Loaded, (c) Joachim Ganseman'
                      DB 13,10,'$'

CODE                  ENDS
END                   EntryLabel ; Return nicht vergessen!
