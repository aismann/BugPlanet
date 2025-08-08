;-MODULE DECLARATION
EnableExplicit
DeclareModule QuadData
  Declare Create(filename.s)
EndDeclareModule
;-MODULE START
Module QuadData
  #MAXDATA_IN_A_ROW = 8
  ;--PUBLIC PROCEDURES
  ;***************************************
  ;Reads a file and creates datasection
  ;code from it using quads to be small.
  ;Output result goes to the debug window.
  ;***************************************
  Procedure Create(filename.s)
    Protected fileh.i , quads.i, remainder.i, output.s, counter.i , i.i , j.i
    Protected Dim Values.a(7)  
    If Not #PB_Compiler_Debugger : End: EndIf
    If FileSize(filename.s)<1 : Debug "File not found or empty." : End : EndIf
    quads = FileSize(filename)/8
    remainder = Mod(FileSize(filename),8)
    fileh = ReadFile(#PB_Any,filename)
    output + "DataSection"+#CRLF$
    For i = 1 To quads
      If counter = 0 : output+"Data.q " : EndIf
      For j = 0 To 7
          values(j) = ReadAsciiCharacter(fileh)
      Next j
      output + "$"
        For j = 7 To 0 Step - 1
          output + RSet(Hex(values(j),#PB_Ascii),2,"0")
        Next j
      If counter <> #MAXDATA_IN_A_ROW And i <> quads: output + "," : Else : output + #CRLF$ : counter = -1 : EndIf
      counter + 1
    Next i
    If Not Eof(fileh) : output + "Data.a ": EndIf
    While Not Eof(fileh)
      output + "$" + RSet(Hex(ReadAsciiCharacter(fileh),#PB_Ascii),2,"0")
      If Not Eof(fileh)
        output + ","
      EndIf
    Wend
    output + #CRLF$ + "EndDataSection"
    Debug output
  EndProcedure
EndModule

;-EXAMPLE USAGE (obviously a valid filename is needed)
quaddata::create("myzip.zip")
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 48
; FirstLine = 3
; Folding = --
; EnableXP
; DPIAware