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

CapsLockBit EQU 40h

;=============================================================================
;                        Makros der Uebersetzungstabellen
;=============================================================================


Primary MACRO
Key 29h,'^'
Key 0Ch,'·'
Key 0Dh,"'"
Key 2Bh,'#'
Key 1Bh,'+'
Key 35h,'-'
Key 56h,'<'
ENDM



Shift MACRO
Key 29h,'¯'
Key 03h,'"'
Key 04h,15h ;Paragraph - hier kann man auch '@' hinsetzen
Key 07h,'&'
Key 08h,'/'
Key 09h,'('
Key 0Ah,')'
Key 0Bh,'='
Key 0Ch,'?'
Key 0Dh,'`'
Key 2Bh,'`'
Key 1Bh,'*'
Key 33h,';'
Key 34h,':'
Key 35h,'_'
Key 56h,'>'  ;Spalten/Seitumbruch 249/250
ENDM

Ctrl MACRO
Key 2Ch,19H
Key 15h,1Ah
ENDM

Alt MACRO
Key 08h,'+'
ENDM


CtrlAlt MACRO
Key 1Eh,'†'
Key 12h,'Ç'
Key 17h,'°'
Key 18h,'¢'
Key 16h,'£'
Key 03h,'2'
Key 04h,'§'
Key 10h,'@'
Key 08h,'{'
Key 09h,'['
Key 0Ah,']'
Key 0Bh,'}'
Key 0Ch,'\'
Key 1Bh,'~'
Key 56h,'|'
ENDM

ShiftAlt MACRO
Key 1Eh,'Ö'
Key 12h,'ä'
Key 17h,'ç'
Key 18h,'ï'
Key 16h,'ó'
Key 03h,'˘' ;ShiftAlt2
Key 05h,'˘' ;ShiftAlt4
ENDM

CtrlShift MACRO
Key 2ch,19h  ;Ctrl-Shift-Y wie Ctrl Y
Key 15h,1AH  ;Ctrl-Shift-Z wie Ctrl Z
Key 1Eh,'a'  
Key 30h,'·'
Key 2Eh,'r'
Key 22h,'G'
Key 20h,'Â'
Key 19h,'„'
Key 1Fh,'s'
Key 32h,'Ê'
Key 18h,'Í'
Key 21h,'Ë'
Key 12h,'E'
Key 14h,'Ì'
Key 10h,'˚'
ENDM

CtrlShiftAlt MACRO
Key 1Eh,'É'
Key 12h,'à'
Key 17h,'å'
Key 18h,'ì'
Key 16h,'ñ'
ENDM


LowerCase MACRO
Key 28h,'Ñ'
Key 27h,'î'
Key 1Ah,'Å'
Key 2Ch,'y'
Key 15h,'z'
ENDM


UpperCase MACRO
Key 28h,'é'
Key 27h,'ô'
Key 1Ah,'ö'
Key 2Ch,'Y'
Key 15h,'Z'
ENDM

ScanXchg MACRO
Key 2Ch,15h
Key 15h,2Ch
Key 79h,03h
ENDM

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

OkMsg                 DB 13,10,'Tastaturtreiber geladen...'
                      DB 13,10,'$'

CODE                  ENDS
END                   EntryLabel ; Return nicht vergessen!
