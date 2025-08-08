;-MODULE DECLARATION
EnableExplicit
DeclareModule datasec
Declare create(filename.s)  
EndDeclareModule

;-MODULE START
Module datasec
  #MAXDATA_IN_A_ROW = 35
  ;--PUBLIC PROCEDURES
  Procedure create(filename.s)
    If Not #PB_Compiler_Debugger : End : EndIf
    Protected fileh.i,counter.i=0,mybyte.a,outputstring.s = "DataSection"+#CRLF$+"mydata_start:"+#CRLF$
    fileh = ReadFile(#PB_Any,filename.s)
    If Not IsFile(fileh) : Debug "Could not open file "+filename.s : End : EndIf
    Repeat
      If counter = 0 : outputstring + "Data.a ": EndIf
      mybyte = ReadAsciiCharacter(fileh)
      outputstring+"$"+RSet(Hex(mybyte.a,#PB_Ascii),2,"0")
      If counter<>#MAXDATA_IN_A_ROW And Not Eof(fileh) :outputstring+"," : Else :outputstring+#CRLF$ : counter = -1 : EndIf
      counter+1
    Until Eof(fileh)
    CloseFile(fileh)
    outputstring+"mydata_end:"+#CRLF$+"EndDataSection"
    Debug outputstring
  EndProcedure
EndModule

;-EXAMPLE USAGE
datasec::create("mysprite.png")


; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 31
; Folding = --
; EnableXP
; DPIAware