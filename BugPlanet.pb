; VER PB 6.21 Beta 9 OpenGL prototyping, probably cross platform, tested on WIN7 64bit
; BugsPlanet initial version by @miso
; https://www.purebasic.fr/english/viewtopic.php?p=643758#p643758
; -----------------------------------------
; BugsPlanet v1.1 icesoft 20250806
;  Controls: W, A S, D, E, (Arrows), H,  Leftmouse, Rightmouse.
; * Bug fixes 
; * Source code redesign (clean code)  #part1
; * Own GitHup Repository:
; * And some improvements:
; - easier catching a box
; - Pressing 'H' shows the direction to the Helipad
; - more color
; - removed shadow
; - Debug mode is only a warning

; BugsPlanet v1.2 icesoft 20250831
; * Source code redesign (clean code) #part2
; - Empty egg (only one) can collect (armor+100+random(100))


;- 0 Compiler checks
#COMPILER_MINIMUM_VERSION = 621
If Int(#PB_Compiler_Version) < #COMPILER_MINIMUM_VERSION
  Debug "Please compile with 6.21 or higher. "
  Debug "This snippet uses features presented with that update."
  End
EndIf


;- 1 Inits
; UsePNGImageEncoder()
UsePNGImageDecoder()
InitEngine3D()
InitSprite()
InitKeyboard()
InitMouse()
InitSound()

;- 2 Constants
#MAINDESKTOP_H        = 0
#MAINWINDOW_H         = 0
#MAINWINDOW_NAME      = "Bug Planet"
#MAINWINDOW_FLAGS     = #PB_Window_ScreenCentered
#MAINWINDOW_RESIZE    = 1
#MAINWINDOW_TOPOFFSET = 0
#SCREEN_FLAGS         = #PB_Screen_WaitSynchronization
#SCREEN_FRAMERATE     = 60
#AUTOSTRETCH_ON       = 1
#AUTOSTRETCH_OFF      = 0
#MAINLOOP_DELAY       = 0
#MAINCAMERA = 1
#FINAL_RENDERCAMERA = 31
#MASK_GENERALPICKMASK = 1<<1
#MASK_NOPICKMASK = 1<<31
#MASK_MAINCAMERA = 1<<1
#MASK_FINAL_RENDERCAMERA = 1<<31
#RENDEROBJECT = 1
#RENDERWIDTH  = 640
#RENDERHEIGHT = 480

#GROUND = 2
#HULL = 3
#TURR = 4
#BOX = 5
#AIM = 6
#EGGEMPTY = 7
#EGG = 8
#AMMOPOD = 9
#NEST = 12 
#btex1 = 13
#btex2 = 14
#BUG = 15
#DEADBUG = 16
#REP = 20
#HELI = 21
#RESS = 100
#RESE = 500
#BGS = 800
#BGE = 999
#MAXDIST = 1000

; Ant behavior
#b_Idle = 0
#b_attack = 1
#b_wonder = 2
#b_guard = 3

#WALL = 30
#WALL_RIGHT = 226
#WALL_LEFT = 227
#WALL_BELOW = 228
#WALL_ABOVE = 229
#KILLED_NEST= 1
#COLLECT_ALL =2

;- 3 Structures
Structure pstruct
  id.i
  armor.i
  maxArmor.i
  ammo.i
  maxAmmo.i
  box.i
  maxBox.i
  dmgmin.i
  dmgmax.i
  spmax.i
  mat.i
  kills.i
  behavior.i
  aggrorange.i
  t.i
  tx.i
  ty.i
  load.i
  fired.i
  collected.i
  boxdestroyed.i
  spentarmor.i
  spentammo.i
  won.i
EndStructure
Structure coord3d
  x.f
  y.f
  z.f
EndStructure
Structure coord2d
  x.f
  y.f
EndStructure

;- 4 Global variables
Global tank.pstruct
tank\ammo = 450
tank\maxAmmo = 1000
tank\armor = 250
tank\maxArmor = 2000
tank\box = 0
tank\dmgmin = 1
tank\dmgmax = 3
tank\load = 0
Global bugscount.i = 0
Global bugswiper.i = #BGS
Global NewList bugs()
Global Dim object.pstruct(2020)
Global aim.coord3d
Global matanim.i
Global tsp.f
Global c1.i = RGB(150, 80, 20)
Global c2.i = RGB(0, 0, 0)
Global midscreen.coord2d
Global mins.i, seconds.i, score.i
Global layertexture

Global holeimg = CatchImage(#PB_Any, ?hole)
ResizeImage(holeimg, 8, 8)

Global splatimg = CatchImage(#PB_Any, ?bsplat)
ResizeImage(splatimg, 8, 8)

Global eggdimg = CatchImage(#PB_Any, ?eggd)
ResizeImage(eggdimg, 10, 10, #PB_Image_Raw)

Global bugdimg = CatchImage(#PB_Any, ?deadbug)
ResizeImage(bugdimg, 8, 8, #PB_Image_Raw)

;- 5 Modules start
;- 5.1 DeclareModule petskii 
DeclareModule petskii
  Declare init()
  Declare textout(x, y, text.s, color.i, intensity.i = 255)
  Declare textoutlined(x, y, text.s, color.i, outlinecolor.i, intensity.i = 255)
  Declare ctobject(x, y, text.s, color.i, outlinecolor.i, intensity.i = 255)
  Declare destroy()
EndDeclareModule
Module petskii
  #USED_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()-_=+[{]};:',<.>/?"+Chr(34)
  Global Dim petskiifont(370)
  Global Dim fontimport.i(370)
  Procedure sub_loadfont()
    Protected x.i, i.i, j.i, sprline.a
    For i = 1 To Len(#USED_CHARACTERS):fontImport(Asc(Mid(#USED_CHARACTERS, i, 1))) = 1 : Next i 
    Restore petskii_font
    For x = 1 To 370
      If fontimport(x) = 1
        petskiifont(x) = CreateSprite(#PB_Any, 8, 12, #PB_Sprite_AlphaBlending)
        StartDrawing(SpriteOutput(petskiifont(x)))
        DrawingMode(#PB_2DDrawing_AllChannels)
        For j = 0 To 11  
          Read.a sprline 
          For i = 0 To 7
            If sprline&%1 :Plot(i, j, RGBA(255, 255, 255, 255)): Else : Plot(i, j, RGBA(0, 0, 0, 0)) : EndIf
            sprline>>1 
          Next i
        Next j
        StopDrawing()
        ZoomSprite(petskiifont(x), 16, 24)
      EndIf
    Next x
  EndProcedure
  Procedure init()
    sub_loadfont()
  EndProcedure
  Procedure textout(x, y, text.s, color.i, intensity.i = 255) : Protected.i textlength, i, character
    textlength.i = Len(text.s)
    For i = 1 To textlength.i
      character.i = Asc(Mid(text.s, i, 1))
      If character.i>ArraySize(petskiifont()) : ProcedureReturn #Null : EndIf
      If IsSprite(petskiifont(character))
        DisplayTransparentSprite(petskiifont(character), (x+((i-1) * 16)), (y), intensity, color.i)
      EndIf
    Next i
  EndProcedure
  Procedure textoutlined(x, y, text.s, color.i, outlinecolor.i, intensity = 255)
    textout(x-2, y, text.s, outlinecolor, intensity)
    textout(x+2, y, text.s, outlinecolor, intensity)
    textout(x, y-2, text.s, outlinecolor, intensity)
    textout(x, y+2, text.s, outlinecolor, intensity)
    textout(x, y, text.s, color, intensity)
  EndProcedure
  Procedure ctobject(x, y, text.s, color.i, outlinecolor.i, intensity = 255)
    textlength.i = Len(text.s)
    x = x-(textlength*16)/2 : y = y-8
    textout(x-2, y, text.s, outlinecolor, intensity)
    textout(x+2, y, text.s, outlinecolor, intensity)
    textout(x, y-2, text.s, outlinecolor, intensity)
    textout(x, y+2, text.s, outlinecolor, intensity)
    textout(x, y, text.s, color, intensity)
  EndProcedure
  Procedure destroy()
    Protected i.i
    For i = 1 To Len(#USED_CHARACTERS)
      If IsSprite(petskiifont(i)) : FreeSprite(petskiifont(i)) : EndIf
    Next i
  EndProcedure
  DataSection
    petskii_font:
    Data.q $3838383838380000, $EEEE000000003800, $00000000000000EE, $FFEEFFEEEEEE0000, $383800000000EEEE, $0000387EE07C0EFC, $1C3870EECECE0000, $7C7C00000000E6EE, $0000FCEEEE3C7CEE
    Data.q $00003870E0E00000, $7070000000000000, $000070381C1C1C38, $707070381C1C0000, $0000000000001C38, $000000EE7CFF7CEE, $38FE383800000000, $0000000000000038, $001C383800000000
    Data.q $00FE000000000000, $0000000000000000, $0000383800000000, $3870E0C000000000, $7C7C000000000E1C, $00007CEEEEFEFEEE, $38383C3838380000, $7C7C00000000FE38, $0000FE0E1C70E0EE
    Data.q $E078E0EE7C7C0000, $E0E0000000007CEE, $0000E0E0FEEEF8F0, $E0E07E0EFEFE0000, $7C7C000000007CEE, $00007CEEEE7E0EEE, $383870EEFEFE0000, $7C7C000000003838, $00007CEEEE7CEEEE
    Data.q $E0FCEEEE7C7C0000, $3838000000007CEE, $0000383800000038, $0000003838380000, $F0F00000001C3838, $0000F0381C0E1C38, $FE00FE0000000000, $1E1E000000000000, $00001E3870E07038
    Data.q $3870E0EE7C7C0000, $7C7C000000003800, $00007CCE0EFEFEEE, $EEFEEE7C38380000, $7E7E00000000EEEE, $00007EEEEE7EEEEE, $0E0E0EEE7C7C0000, $3E3E000000007CEE, $00003E7EEEEEEE7E
    Data.q $0E3E0E0EFEFE0000, $FEFE00000000FE0E, $00000E0E0E3E0E0E, $EEFE0EEE7C7C0000, $EEEE000000007CEE, $0000EEEEEEFEEEEE, $383838387C7C0000, $F8F8000000007C38, $00003C7E70707070
    Data.q $3E1E3E7EEEEE0000, $0E0E00000000EE7E, $0000FE0E0E0E0E0E, $CEFEFEFECECE0000, $EEEE00000000CECE, $0000EEEEFEFEFEFE, $EEEEEEEE7C7C0000, $7E7E000000007CEE, $00000E0E0E7EEEEE
    Data.q $EEEEEEEE7C7C0000, $7E7E00000000F07C, $0000EE7E3E7EEEEE, $E07C0EEE7C7C0000, $FEFE000000007CEE, $0000383838383838, $EEEEEEEEEEEE0000, $EEEE000000007CEE, $0000387CEEEEEEEE
    Data.q $FEFECECECECE0000, $EEEE00000000CEFE, $0000EEEE7C387CEE, $387CEEEEEEEE0000, $FEFE000000003838, $0000FE0E1C3870E0, $1C1C1C1C7C7C0000, $7C7C000000007C1C, $00007C7070707070
    Data.q $3838FE7C38380000, $0000000000003838, $0000FF0000000000, $FCE07C0000000000, $000000000000FCEE, $00007EEEEE7E0E0E, $0E0E7C0000000000, $0000000000007C0E, $0000FCEEEEFCE0E0
    Data.q $FEEE7C0000000000, $0000000000007C0E, $0000383838FC38F0, $EEEEFC0000000000, $0E0E0000007EE0FC, $0000EEEEEEEE7E0E, $38383C0038380000, $0000000000007C38, $003C707070700070
    Data.q $3E7E0E0E0E0E0000, $3C3C00000000EE7E, $00007C3838383838, $FEFEEE0000000000, $000000000000CEFE, $0000EEEEEEEE7E00, $EEEE7C0000000000, $0000000000007CEE, $000E0E7EEEEE7E00
    Data.q $EEEEFC0000000000, $0000000000E0E0FC, $00000E0E0EEE7E00, $7C0EFC0000000000, $0000000000007EE0, $0000F0383838FE38, $EEEEEE0000000000, $000000000000FCEE, $0000387CEEEEEE00
    Data.q $FEFECE0000000000, $000000000000FCFC, $0000EE7C387CEE00, $EEEEEE0000000000, $00000000003E70FC, $0000FE1C3870FE00, $381E3838F0F00000, $1E1E00000000F038, $00001E3838F03838
  EndDataSection
EndModule

;- 5.2 DeclareModule ticker
DeclareModule ticker
  #TICKS_FOREVER = -10
  #MAXIMUM_ALLOWED_TICKERS = 255
  Structure tickerstructure
    timeout.i
    lasttick.i
    current_tick_count.i
    target_tick_count.i
    alive.i
  EndStructure
  Declare.i create(ID.i, ticktime_ms.i, number_of_ticks.i = #TICKS_FOREVER)
  Declare.i triggered(ID.i)
  Declare.i kill(ID.i)
EndDeclareModule
Module ticker
  Global Dim tickers.tickerstructure(#MAXIMUM_ALLOWED_TICKERS)
  Procedure.i create(ID.i, ticktime_ms.i, number_of_ticks.i = #TICKS_FOREVER)
    If ID.i>= 0 And ID.i<= #MAXIMUM_ALLOWED_TICKERS
      With tickers(ID.i)
        \lasttick.i = ElapsedMilliseconds()
        \timeout.i = ticktime_ms.i
        \current_tick_count.i = 0
        \alive.i = #True
        \target_tick_count = number_of_ticks.i
      EndWith
      ProcedureReturn #True
    EndIf
    ProcedureReturn #False
  EndProcedure
  Procedure.i triggered(ID.i)
    If ID.i<0 Or ID.i>#MAXIMUM_ALLOWED_TICKERS
      Debug Str(ID.i) + " not exists, cant be checked"
      ProcedureReturn #False
    EndIf
    If tickers(ID.i)\alive <> #True
      ProcedureReturn #False
    EndIf
    If ElapsedMilliseconds()-tickers(ID.i)\lasttick<tickers(ID.i)\timeout
      ProcedureReturn #False
    EndIf
    tickers(ID.i)\current_tick_count + 1
    tickers(ID.i)\lasttick = ElapsedMilliseconds()
    If tickers(ID.i)\current_tick_count = tickers(ID.i)\target_tick_count
      tickers(ID.i)\alive = #False
    EndIf
    ProcedureReturn #True
  EndProcedure
  Procedure.i Kill(ID.i)
    If ID.i<0 Or ID.i>#MAXIMUM_ALLOWED_TICKERS
      ProcedureReturn #False
    EndIf
    tickers(ID.i)\alive = #False
    ProcedureReturn #True
  EndProcedure
EndModule
;-  5.x Modules end

;- 5.5 Sound stuff start
Procedure.f LERP(a.f, b.f, t.f)
  ProcedureReturn(((1.0-t.f)*a) + (b*t))
EndProcedure

Procedure.f INVLERP(a.f, b.f, v.f)
  If a = b : ProcedureReturn(1) : EndIf
  ProcedureReturn((v-a) / (b-a))
EndProcedure

Procedure.f remap(iMin.f, iMAX.f, oMin.f, oMax.f, v.f)  
  Protected t.f
  t.f = INVLERP(iMin, iMAX, v)
  ProcedureReturn(LERP(oMin, oMax, t))
EndProcedure

#SOUND_SAMPLE_RATE = 8000
#SOUND_BITS_PER_SAMPLE = 8
#SOUND_CHANNELS = 1
#SOUND_BYTERATE = (#SOUND_SAMPLE_RATE*#SOUND_CHANNELS*#SOUND_BITS_PER_SAMPLE)/8
Procedure snd(frequency.f, length.i, attack, decay, sustain, release , wf, af, tac, ns.i, vs.f, vd.f)
  Protected chunk.l = Int((length/1000)*#SOUND_BYTERATE)
  Protected samples.i = Int((length/1000)*#SOUND_SAMPLE_RATE)
  Protected headersize.i = 40 
  Protected result_id.i, i.i, mydata.a, output.i, position.i
  Protected fl_variable
  Protected *buffer
  Protected mastervolume.i = 127
  *buffer = AllocateMemory(headersize+4+(chunk))
  Restore waveheader3
  For i = 1 To 40
    Read.a mydata.a
    PokeA(*buffer+position, mydata.a) : position = position+1
  Next i
  PokeL(*buffer+position, chunk) : position = position+4
  Protected singlewavetime.f = 1.0/frequency
  Protected awt.f = 1.0/af
  Protected samplesperwave.i = Round(#SOUND_SAMPLE_RATE*singlewavetime, #PB_Round_Up)
  Protected aspw =  Round(#SOUND_SAMPLE_RATE*awt, #PB_Round_Up)
  Protected wavecount.i = Round(length/singlewavetime, #PB_Round_Up)
  Protected duty.f = 0.5
  Protected vbtp.f = 0
  Protected steps.f, vbtstp.f
  steps = #SOUND_SAMPLE_RATE/frequency
  vbtstp = #SOUND_SAMPLE_RATE*vs/frequency
  Protected capc.i = 0
  Protected attacksamples.i, decaysamples.i, sustainsamples.i, releasesamples.i, currentvolume.i
  attacksamples = remap(1, attack+decay+sustain+release, 1, samples, attack)
  decaysamples = remap(1, attack+decay+sustain+release, 1, samples, attack+decay)
  sustainsamples = remap(1, attack+decay+sustain+release, 1, samples, attack+decay+sustain)
  releasesamples = samples
  Protected counter.i, targetperiod.i, apn = 0
  counter.i = 0
  targetperiod = samplesperwave
  For i = 1 To samples
    counter.i = counter+1
    capc.i = capc.i+1
    If capc = tac
      capc = 0
      apn = 1-apn
    EndIf
    If counter>= targetperiod
      counter = 0 : duty = duty*-1
      If vd>0 And vs>0
        vbtp = vbtp+vs
        vbtp = ((2*3.14)/steps)*i*vs
        If apn
          targetperiod = Round(aspw*((1.0+(Sin(vbtp)*vd))), #PB_Round_Nearest)
        Else
          targetperiod = Round(samplesperwave*((1.0+(Sin(vbtp)*vd))), #PB_Round_Nearest)
        EndIf
      Else
        If apn
          targetperiod = aspw
        Else
          targetperiod = samplesperwave
        EndIf
      EndIf
    EndIf
    If i<attacksamples 
      currentvolume = lerp(0, mastervolume, i/attacksamples)
    ElseIf i<decaysamples
      currentvolume = lerp(mastervolume, mastervolume*0.8, i/decaysamples)
    ElseIf i<sustainsamples
      currentvolume = mastervolume*0.8
    Else
      currentvolume = lerp(0, mastervolume, i/releasesamples)
    EndIf
    output = 127+((currentvolume*duty)+(Random(ns)))
    PokeA(*buffer+position, output):position = position+1
  Next i
  result_id = CatchSound(#PB_Any, *buffer, headersize+4+(chunk))
  FreeMemory(*buffer)
  ProcedureReturn(result_id)
EndProcedure    
;- 5.6 Sound stuff end

Procedure spawnbug(num, x1, y1, x2, y2, big, behavior)
  count = 0
  For x = #BGS To #BGE
    If Not IsEntity(x)And count<num
      AddElement(bugs()) : bugs() = x : bugscount+1
      CreateEntity(x, MeshID(#box), MaterialID(#btex1), x1+Random(x2-x1), 20, y1+Random(y2-y1), #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
      c = Random(big, 0)
      object(x)\t = -1
      If c = 1
        object(x)\armor = 50
        object(x)\ID = #BUG
        object(x)\spmax = 10+Random(20, 10)
        f.f = 1.5+Random(500)/1000
        ScaleEntity(x, 2, 2, 2)
        object(x)\behavior = behavior
        object(x)\aggrorange = 250000+Random(250000)
      Else
        object(x)\armor = 6
        object(x)\ID = #BUG
        object(x)\spmax = 60+Random(30, 10)
        f.f = 1.0+Random(100)/1000
        ScaleEntity(x, f, f, f)
        object(x)\behavior = behavior
        object(x)\aggrorange = 400000+Random(100000)
      EndIf
      count+1
      CreateEntityBody(x, #PB_Entity_BoxBody, 1, 1, 1)
      EntityAngularFactor(x, 0, 1, 0)
      EntityLinearFactor(x, 1, 0, 1)
      If count = num : x = #BGE : EndIf
    EndIf
  Next x
EndProcedure

Procedure createmat(id.i, *img, size.i)
  CreateTexture(id, size, size)
  CatchImage(id, *img)
  StartDrawing(TextureOutput(id))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, OutputWidth(), OutputHeight())
  DrawAlphaImage(ImageID(id), 0, 0)
  StopDrawing()
  ; SaveImage(id, Str(id) + ".png",  #PB_ImagePlugin_PNG)
  CreateMaterial(id, TextureID(id))
  MaterialFilteringMode(id, #PB_Material_None)
  FreeImage(id)
EndProcedure

Procedure setmat_basic(a)
  SetMaterialAttribute(a, #PB_Material_DepthWrite, #True)
  SetMaterialAttribute(a, #PB_Material_AlphaReject, #True)
  SetMaterialAttribute(a, #PB_Material_TAM, #PB_Material_ClampTAM)
  MaterialFilteringMode(a, #PB_Material_None)
EndProcedure

Procedure.i dist(x1, y1, x2, y2)
  Protected retval.i
  retval.i = ((x2-x1)*(x2-x1))+((y2-y1)*(y2-y1))
  ProcedureReturn retval
EndProcedure

Procedure app_start()
  ExamineDesktops()
  OpenWindow(#MAINWINDOW_H, 0, 0, DesktopUnscaledX(DesktopWidth(#MAINDESKTOP_H)), DesktopUnscaledY(DesktopHeight(#MAINDESKTOP_H)), #MAINWINDOW_NAME, #MAINWINDOW_FLAGS)
  OpenWindowedScreen(WindowID(#MAINWINDOW_H), 0, 0, WindowWidth(#MAINWINDOW_H), WindowHeight(#MAINWINDOW_H), #AUTOSTRETCH_ON, 0, 0, #SCREEN_FLAGS)
  
  SetFrameRate(#SCREEN_FRAMERATE)
  midscreen\x = ScreenWidth()/2
  midscreen\y = ScreenHeight()/2
  petskii::init()
  Add3DArchive(#PB_Compiler_Home+"examples/3d/Data/Main", #PB_3DArchive_FileSystem)
  Parse3DScripts()
  EnableWorldPhysics(#True)
  EnableWorldCollisions(#True)
  CreateCamera(#MAINCAMERA, 0, 0, 100, 100, #MASK_MAINCAMERA)
  CameraRenderMode(#MAINCAMERA, #PB_Camera_Textured)
  CameraProjectionMode(#MAINCAMERA, #PB_Camera_Orthographic)
  MoveCamera(#MAINCAMERA, 0, -0, -8, #PB_Absolute)
  RotateCamera(#MAINCAMERA, 0, 180, 0)
  CreateCamera(#FINAL_RENDERCAMERA, 0, 0, 100, 100, #MASK_FINAL_RENDERCAMERA)
  CameraRenderMode(#FINAL_RENDERCAMERA, #PB_Camera_Textured)
  CameraProjectionMode(#FINAL_RENDERCAMERA, #PB_Camera_Perspective)
  CameraRange(#FINAL_RENDERCAMERA, 0, 100000)
  MoveCamera(#FINAL_RENDERCAMERA, 0, -0, 200, #PB_Absolute|#PB_World)
  CreateRenderTexture(#RENDEROBJECT, CameraID(#MAINCAMERA), #RENDERWIDTH, #RENDERHEIGHT, #PB_Texture_ManualUpdate)
  CreateMaterial(#RENDEROBJECT, TextureID(#RENDEROBJECT))
  DisableMaterialLighting(#RENDEROBJECT, #True)
  MaterialFilteringMode(#RENDEROBJECT, #PB_Material_None)
  CreatePlane(#RENDEROBJECT, (ScreenWidth()/ScreenHeight())*1000, 1000, 1, 1, 1, 1)
  CreateEntity(#RENDEROBJECT, MeshID(#RENDEROBJECT), MaterialID(#RENDEROBJECT), 0, 0, -1000, #MASK_NOPICKMASK, #MASK_FINAL_RENDERCAMERA)
  RotateEntity(#RENDEROBJECT, 90, 180, 0, #PB_Absolute)
  SetRenderQueue(EntityID(#RENDEROBJECT), 0, 0)
  layertexture = CreateTexture(#PB_Any, 1024, 1024)
  StartDrawing(TextureOutput(layertexture))
  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, OutputWidth(), OutputHeight(), RGBA(0, 0, 0, 0))
  StopDrawing()
  
  createmat(#ground, ?ground, 16)
  AddMaterialLayer(#ground, TextureID(layertexture), #PB_Material_AlphaBlend)
  ScaleMaterial(#GROUND, 0.01, 0.01, 0)
  CreatePlane(#GROUND, 10240, 10240, 1, 1, 1, 1)
  CreateEntity(#GROUND, MeshID(#GROUND), MaterialID(#GROUND), 0, 0, 0, #MASK_NOPICKMASK, #MASK_MAINCAMERA)
  CreateEntityBody(#GROUND, #PB_Entity_StaticBody, 1, 1, 1)
  MoveCamera(#MAINCAMERA, 0, 3000, 0, #PB_World|#PB_Absolute)
  CameraLookAt(#MAINCAMERA, EntityX(#GROUND), EntityY(#GROUND), EntityZ(#GROUND))
  
  createmat(#HULL, ?base, 16)
  setmat_basic(#HULL) 
  CreateCube(#HULL, 100)
  CreateEntity(#HULL, MeshID(#HULL), MaterialID(#HULL), 0, 40, 0, #MASK_NOPICKMASK, #MASK_MAINCAMERA)
  ScaleEntity(#HULL, 1/2, 1/1.5, 1/1.5)
  CreateEntityBody(#HULL, #PB_Entity_BoxBody, 1, 1, 1)
  EntityLinearFactor(#HULL, 1, 0, 1)
  
  createmat(#TURR, ?turret, 16)
  setmat_basic(#TURR)
  CreateCube(#TURR, 80)
  CreateEntity(#TURR, MeshID(#TURR), MaterialID(#TURR), 0, 61, 0, #MASK_NOPICKMASK, #MASK_MAINCAMERA)
  
  CatchImage(#AMMOPOD, ?ammopod)
  ResizeImage(#AMMOPOD, 25, 25, #PB_Image_Raw)
  StartDrawing(TextureOutput(layertexture))
  DrawingMode(#PB_2DDrawing_AllChannels)
  DrawAlphaImage(ImageID(#AMMOPOD), 530, 500)
  StopDrawing()
  
  CatchImage(#REP, ?rep)
  ResizeImage(#REP, 25, 25, #PB_Image_Raw)
  StartDrawing(TextureOutput(layertexture))
  DrawingMode(#PB_2DDrawing_AllChannels)
  DrawAlphaImage(ImageID(#REP), 470, 500)
  StopDrawing()
  
  CatchImage(#HELI, ?heli)
  ResizeImage(#HELI, 25, 25, #PB_Image_Raw)
  StartDrawing(TextureOutput(layertexture))
  DrawingMode(#PB_2DDrawing_AllChannels)
  DrawAlphaImage(ImageID(#HELI), 500, 500)
  StopDrawing()
  
  createmat(#EGG, ?egg, 16)
  setmat_basic(#EGG)
  CreateCube(#EGG, 40)
  
  createmat(#EGGEMPTY, ?eggd, 16)
  setmat_basic(#EGGEMPTY)
  CreateCube(#EGGEMPTY, 40)
  
  createmat(#DEADBUG, ?deadbug, 16)
  setmat_basic(#DEADBUG)
  CreateCube(#DEADBUG, 40)
  
  createmat(#BOX, ?box, 16)
  setmat_basic(#BOX)
  CreateCube(#BOX, 40)
  CatchSprite(#BOX, ?box, #PB_Sprite_AlphaBlending) 
  ZoomSprite(#BOX, 64, 64)
  
  ; generate the objects 
  For x = #RESS To #RESE
    test = Random(4, 1)
    If test = 4
      CreateEntity(x, MeshID(#BOX), MaterialID(#BOX), -5000+Random(10000), 20, -5000+Random(10000), #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
      EntityRenderMode(x, #PB_Entity_DisplaySkeleton )
      object(x)\id = #BOX
      object(x)\armor = 3+Random(3)
      CreateEntityBody(x, #PB_Entity_BoxBody, 1, 1, 10) : RotateEntity(x, 0, Random(360), 0)
      EntityAngularFactor(x, 0, 0.1, 0)
      EntityLinearFactor(x, 0.1, 0, 0.1)
      SetEntityAttribute(x, #PB_Entity_AngularSleeping, 10)
      SetEntityAttribute(x, #PB_Entity_LinearSleeping, 10)
      SetEntityAttribute(x, #PB_Entity_MaxVelocity, 20)
    Else
      CreateEntity(x, MeshID(#EGG), MaterialID(#EGG), -5000+Random(10000), 20, -5000+Random(10000), #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
      ScaleEntity(x, 2, 2, 2)
      object(x)\id = #EGG
      object(x)\armor = 10+Random(10)
      CreateEntityBody(x, #PB_Entity_BoxBody, 1, 1, 10) : RotateEntity(x, 0, Random(360), 0)
      EntityAngularFactor(x, 0, 0.025, 0)
      EntityLinearFactor(x, 0.025, 0, 0.025)
      SetEntityAttribute(x, #PB_Entity_AngularSleeping, 0.1)
      SetEntityAttribute(x, #PB_Entity_LinearSleeping, 1)
      SetEntityAttribute(x, #PB_Entity_MaxVelocity, 0)
      SetEntityAttribute(x, #PB_Entity_Friction, 10)   
    EndIf
  Next x
  createmat(#WALL, ?wall, 16)
  setmat_basic(#WALL)
  CreateCube(#WALL, 102)
  For x = 2000 To 2020
    Repeat  
      tx = Random(10000)-20000
    Until Abs(tx)>250
    Repeat  
      tz = Random(10000)-20000
    Until Abs(tz)>250
    CreateEntity(x, MeshID(#WALL), MaterialID(#WALL), tx, 48+x*0.001, tz, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA): RotateEntity(x, 0, Random(360), 0)
    ScaleEntity(x, 2, 1, 2)
    CreateEntityBody(x, #PB_Entity_StaticBody, 1, 1, 1) 
    object(x)\id = #WALL
  Next x
  CreateEntity(#WALL_RIGHT, MeshID(#WALL), MaterialID(#WALL), tx, 58+x*0.1, tz, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA) 
  ScaleEntity(#WALL_RIGHT, 100, 10, 2, #PB_Absolute)
  MoveEntity(#WALL_RIGHT, 0, 10, 5012.5, #PB_World|#PB_Absolute)
  CreateEntityBody(#WALL_RIGHT, #PB_Entity_StaticBody, 1, 1, 1) 
  object(#WALL_RIGHT)\id = #WALL
  CreateEntity(#WALL_LEFT, MeshID(#WALL), MaterialID(#WALL), tx, 98+x*0.1, tz, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA) 
  ScaleEntity(#WALL_LEFT, 100, 10, 2, #PB_Absolute)
  MoveEntity(#WALL_LEFT, 0, 15, -5012.5, #PB_World|#PB_Absolute)
  CreateEntityBody(#WALL_LEFT, #PB_Entity_StaticBody, 1, 1, 1) 
  object(#WALL_LEFT)\id = #WALL
  CreateEntity(#WALL_BELOW, MeshID(#WALL), MaterialID(#WALL), tx, 98+x*0.1, tz, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
  RotateEntity(#WALL_BELOW, 0, 90, 0)
  ScaleEntity(#WALL_BELOW, 100, 10, 2, #PB_Absolute)
  MoveEntity(#WALL_BELOW, -5012.5, 20, 0, #PB_World|#PB_Absolute)
  CreateEntityBody(#WALL_BELOW, #PB_Entity_StaticBody, 1, 1, 1) 
  object(#WALL_BELOW)\id = #WALL
  CreateEntity( #WALL_ABOVE, MeshID(#WALL), MaterialID(#WALL), tx, 98+x*0.1, tz, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
  RotateEntity( #WALL_ABOVE, 0, 90, 0)
  ScaleEntity( #WALL_ABOVE, 100, 10, 2, #PB_Absolute)
  MoveEntity( #WALL_ABOVE, 5012.5, 25, 0, #PB_World|#PB_Absolute)
  CreateEntityBody( #WALL_ABOVE, #PB_Entity_StaticBody, 1, 1, 1) 
  object(#WALL_ABOVE)\id = #WALL
  createmat(#NEST, ?nest, 16)
  setmat_basic(#NEST)
  CreateCube(#NEST, 300)
  CreateEntity(#NEST, MeshID(#NEST), MaterialID(#NEST), 0, 0, 0, #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
  CreateEntityBody(#NEST, #PB_Entity_SphereBody, 1, 1, 1, 1, 200, 200, 200) 
  MoveEntity(#NEST, 0, -100, 4500, #PB_World|#PB_Absolute)
  EntityAngularFactor(#NEST, 0, 0, 0)
  EntityLinearFactor(#NEST, 0, 0, 0)
  object(#NEST)\id = #NEST
  object(#NEST)\armor = 1500
  MoveEntity(#NEST, 0, 0, 0, #PB_Local|#PB_Relative)
  createmat(#btex1, ?bug1, 16)
  setmat_basic(#btex1)
  createmat(#btex2, ?bug2, 16)
  setmat_basic(#btex2)
  createmat(#AIM, ?aim, 16)
  setmat_basic(#AIM)
  CreateCube(#AIM, 50)
  CreateEntity(#AIM, MeshID(#AIM), MaterialID(#AIM), 0, 300, 0, #MASK_NOPICKMASK, #MASK_MAINCAMERA)
  aim\x = 0 : aim\y = 250 : aim\z = 0
  CreateLight(0, RGB(255, 255, 255), 0, 0, 0, #PB_Light_Directional)
  LightDirection(0, -1, -2, -1)
  ;WorldDebug(#PB_World_DebugBody  )
  ticker::create(1, 500)
  ticker::create(2, 200)
  ticker::create(3, 15000)
  ticker::create(4, 6000)
  Global shot.i = snd(840, 100, 30, 30, 100, 30, 0, 440, 0, 1, 0.016, 0.8)
  SoundVolume(shot, 25)
  Global empty.i = snd(200, 200, 30, 30, 1, 300, 0, 0, 0, 0, 0.0, 0)
  SoundVolume(empty, 25)
  Global engine.i = snd(60, 20, 30, 30, 1, 30, 60, 60, 0, 0, 0.0, 0)
  SoundVolume(engine, 18)
  SetSoundFrequency(engine, 5000)
  PlaySound(engine, #PB_Sound_Loop)
  Global pickup.i = snd(200, 80, 30, 30, 1, 300, 1200, 120, 0, 1, 1.0, 1)
  SoundVolume(pickup, 25)
  Global eat.i = snd(200, 180, 30, 30, 1, 3000, 1200, 1200, 100, 1, 1.0, 1)
  SoundVolume(eat, 50)
  Global crunch.i = snd(300, 80, 30, 30, 1, 3000, 1200, 1200, 100, 1, 1.0, 1)
  SoundVolume(crunch, 50)
  Global bcrunch.i = snd(450, 120, 10, 300, 100, 30, 2500, 200, 10, 1, 5.0, 0.5)
  SoundVolume(bcrunch, 50)
  MoveEntity(#HULL, 0, 0, tsp, #PB_Local|#PB_Relative)
EndProcedure

Procedure splashimage(img, x, y, a)
  StartDrawing(TextureOutput(layertexture))
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  DrawAlphaImage(ImageID(img), x, y, a)
  StopDrawing()
EndProcedure

Procedure app_update()
  Protected w_event.i
  Repeat 
    w_event = WindowEvent() : If w_event = #PB_Event_CloseWindow : End : EndIf
  Until Not w_event
  ExamineKeyboard():ExamineMouse()
  aim\x = aim\x-(MouseDeltaX()*0.5)
  aim\z = aim\z-(MouseDeltaY()*0.5)
  If aim\x>EntityX(#turr)+#MAXDIST : aim\x = EntityX(#turr)+#MAXDIST : EndIf
  If aim\x<EntityX(#turr)-#MAXDIST : aim\x = EntityX(#turr)-#MAXDIST : EndIf
  If aim\z>EntityZ(#turr)+#MAXDIST : aim\z = EntityZ(#turr)+ #MAXDIST : EndIf
  If aim\z<EntityZ(#turr)-#MAXDIST : aim\z = EntityZ(#turr)-#MAXDIST : EndIf
  If tank\armor>0 And tank\won = 0
    MoveCamera(#MAINCAMERA, CameraX(#MAINCAMERA)*0.9+EntityX(#aim)*0.1, CameraY(#MAINCAMERA), CameraZ(#MAINCAMERA)*0.9+EntityZ(#aim)*0.1, #PB_World|#PB_Absolute)
    MoveEntity(#AIM, aim\x, aim\y, aim\z, #PB_Absolute|#PB_World)
    EntityLookAt(#TURR, EntityX(#AIM), EntityY(#TURR), EntityZ(#AIM))
    If KeyboardPushed(#PB_Key_A) Or KeyboardPushed(#PB_Key_D) Or KeyboardPushed(#PB_Key_Right) Or KeyboardPushed(#PB_Key_Left)
      If KeyboardPushed(#PB_Key_A) Or KeyboardPushed(#PB_Key_Left)
        RotateEntity(#HULL, 0, 1.5, 0, #PB_World|#PB_Relative)
      EndIf
      If KeyboardPushed(#PB_Key_D) Or KeyboardPushed(#PB_Key_Right)
        RotateEntity(#HULL, 0, -1.5, 0, #PB_World|#PB_Relative)
      EndIf
    Else
      RotateEntity(#HULL, 0, 0, 0, #PB_World|#PB_Relative)
    EndIf
    If KeyboardPushed(#PB_Key_W) Or KeyboardPushed(#PB_Key_S) Or KeyboardPushed(#PB_Key_Up) Or KeyboardPushed(#PB_Key_Down)
      If KeyboardPushed(#PB_Key_S) Or KeyboardPushed(#PB_Key_Down)
        tsp = tsp*0.97+(100*-0.03)
        If tsp<-60 : tsp = -60 : EndIf
      EndIf
      If KeyboardPushed(#PB_Key_W) Or KeyboardPushed(#PB_Key_Up)
        tsp = tsp*0.95+(100*0.05)
        If tsp>100 : tsp = 100 : EndIf
      EndIf
    Else
      tsp = tsp*0.95
    EndIf
    If tsp>1 Or tsp<-1
      MoveEntity(#HULL, 0, 0, tsp, #PB_Local|#PB_Relative)
      SetSoundFrequency(engine, 5000+Abs(tsp)*10)
    Else
      EntityVelocity(#hull, 0, 0, 0)
    EndIf
    MoveEntity(#TURR, EntityX(#HULL), 61, EntityZ(#HULL), #PB_World|#PB_Absolute)
    
    If MouseButton(#PB_MouseButton_Left) Or KeyboardPushed(#PB_Key_E)
      rayhitbool = RayCast(EntityX(#aim), 5000, EntityZ(#aim), 0 , -5000, 0, #MASK_GENERALPICKMASK)
      ;  If rayhitbool
      If IsEntity(rayhitbool)
        If tank\box<5 And object(rayhitbool)\id = #BOX
          If (EntityX(#HULL)-PickX())*(EntityX(#HULL)-PickX())+(EntityZ(#HULL)-PickZ())*(EntityZ(#HULL)-PickZ())<10000
            FreeEntity(rayhitbool)
            tank\box+1
            tank\collected+1
            PlaySound(pickup)
          EndIf
          
        ElseIf rayhitbool>= #RESS And rayhitbool<= #RESE And tank\box = 5
          PlaySound(empty)     
         
        ElseIf object(rayhitbool)\id = #EGGEMPTY
          If (EntityX(#HULL)-PickX())*(EntityX(#HULL)-PickX())+(EntityZ(#HULL)-PickZ())*(EntityZ(#HULL)-PickZ())<10000
            tank\armor +object(rayhitbool)\armor
            FreeEntity(rayhitbool)
            PlaySound(pickup)
          EndIf
        EndIf
      EndIf
      ; EndIf
      If rayhitbool = -1  
        
        If EntityX(#aim) >- 100 And EntityX(#aim)<100 And EntityX(#hull) >- 100 And EntityX(#hull)<100
          If EntityZ(#aim) >- 100 And EntityZ(#aim)<100 And EntityZ(#hull) >- 100 And EntityZ(#hull)<100
            If tank\box>0 And tank\load<50 ;And ticker::triggered(1)
              tank\box-1
              tank\load+1
              If tank\load = 50
                tank\won = #COLLECT_ALL
                For x = 1 To 1000
                  If object(x)\id = #BUG
                    If IsEntity(x)
                      FreeEntity(x)
                    EndIf
                  EndIf
                Next x
              EndIf
              PlaySound(pickup)
            EndIf
          EndIf
        EndIf
        If EntityX(#aim)>184 And EntityX(#aim)<406 And EntityX(#hull)>184 And EntityX(#hull)<406
          If EntityZ(#aim) >- 100 And EntityZ(#aim)<100 And EntityZ(#hull) >- 100 And EntityZ(#hull)<100
            If tank\box>0 And tank\armor<tank\maxArmor ; And ticker::triggered(1)                         
              tank\box-1
              tank\armor+25                     
              tank\spentarmor+1
              PlaySound(pickup)
            EndIf
          EndIf
        EndIf
        If EntityX(#aim) >- 400 And EntityX(#aim)<-200 And EntityX(#hull) >- 400 And EntityX(#hull)<-200
          If EntityZ(#aim) >- 100 And EntityZ(#aim)<100 And EntityZ(#hull) >- 100 And EntityZ(#hull)<100
            If tank\box>0 And tank\ammo<tank\maxAmmo ;And ticker::triggered(1)                         
              tank\box-1
              tank\ammo+50
              tank\spentammo+1          
              PlaySound(pickup)
            EndIf
          EndIf
        EndIf
      EndIf
    EndIf
    
    If KeyboardPushed(#PB_Key_H) ; show homebase
      CreateLine3D(3000, EntityX(#hull), EntityY(#hull), EntityZ(#hull), RGB(200, 255, 200), 0, 0, 0, RGB(200, 55, 200))
    EndIf
    
    ;     If KeyboardPushed(#PB_Key_M) ; show map
    ;       For x = #RESS To #RESE
    ;         If object(x)\id = #BOX
    ;           If IsEntity(x)
    ;             CreateLine3D(3300, EntityX(x)-2, EntityY(#hull), EntityZ(x)-2, RGBA(255, 255, 255, 50), EntityX(x)+2, EntityY(#hull), EntityZ(x)+2, RGB(255, 255, 127))
    ;           EndIf
    ;         EndIf
    ;       Next    
    ;     EndIf
    
    
    
    If MouseButton(#PB_MouseButton_Right)
      If tank\ammo<1 And SoundStatus(empty)<>#PB_Sound_Playing
        PlaySound(empty) 
      EndIf
      If SoundStatus(shot)<>#PB_Sound_Playing And tank\ammo>0: PlaySound(shot) 
        aoff = Random(10)-5
        boff = Random(10)-5
        tank\fired+1
        tank\ammo-1
        dist.f = Sqr((EntityX(#aim)+aoff-EntityX(#hull))  *   (EntityX(#aim)+aoff-EntityX(#hull))+((EntityZ(#aim)+boff-EntityZ(#hull))*(EntityZ(#aim)+boff-EntityZ(#hull))) )
        rayhitbool = RayCast(EntityX(#hull), 10, EntityZ(#hull), EntityDirectionX(#turr)*dist , 10, EntityDirectionZ(#turr)*dist, #MASK_GENERALPICKMASK)
        If rayhitbool 
          If IsEntity(rayhitbool)
            distent.f = Sqr((EntityX(#hull)-EntityX(rayhitbool))  *   (EntityX(#hull)-EntityX(rayhitbool))+((EntityZ(#hull)-EntityZ(rayhitbool))*(EntityZ(#hull)-EntityZ(rayhitbool))) )
            If rayhitbool<651:distb = 25 :Else:distb = 100:EndIf
            If Abs(distent)<Abs(dist)+distb
              CreateLine3D(3000, EntityX(#hull), EntityY(#hull), EntityZ(#hull), RGBA(255, 0, 0, 50), PickX(), PickY(), PickZ(), RGB(255, 255, 127))
              hg2 = 1
              
              If object(rayhitbool)\id = #EGGEMPTY
                FreeEntity(rayhitbool)                   
                PlaySound(crunch)            
              ElseIf rayhitbool<#BGE
                If object(rayhitbool)\id = #box
                  ApplyEntityImpulse(rayhitbool, NormalX()*-50, 0, NormalZ()*-50)
                Else
                  ApplyEntityImpulse(rayhitbool, NormalX()*-15, 0, NormalZ()*-15)
                EndIf
                object(rayhitbool)\armor-(Random(tank\dmgmax, tank\dmgmin))
                object(rayhitbool)\behavior = #b_attack
                If object(rayhitbool)\armor<1
                  If object(rayhitbool)\id = #box
                    FreeEntity(rayhitbool)
                    PlaySound(bcrunch)
                  ElseIf object(rayhitbool)\id = #nest
                    FreeEntity(rayhitbool)
                    ticker::kill(1):ticker::kill(2):ticker::kill(3)
                    For x = 1 To 1000
                      If object(x)\id = #BUG
                        If IsEntity(x)
                          FreeEntity(x)
                        EndIf
                      EndIf
                    Next x
                    PlaySound(bcrunch)
                    tank\won = #KILLED_NEST
                  ElseIf object(rayhitbool)\id = #Egg
                    SetEntityMaterial(rayhitbool, MaterialID(#box))
                    StartDrawing(TextureOutput(layertexture))
                    DrawingMode(#PB_2DDrawing_AlphaBlend)
                    DrawAlphaImage(ImageID(eggdimg), 506-(EntityX(rayhitbool)/10), 506-EntityZ(rayhitbool)/10, 156)
                    StopDrawing()
                    object(rayhitbool)\id = #box
                    object(rayhitbool)\armor = 8
                    ScaleEntity(rayhitbool, 0.5, 0.5, 0.5)
                    EntityAngularFactor(rayhitbool, 0, 1, 0) 
                    EntityLinearFactor(rayhitbool, 1, 0, 1) 
                    PlaySound(crunch)
                    spawnbug(Random(5, 0), PickX()-5, PickZ()-5, PickX()+5, PickZ()+5, 0, #b_attack)
                    
                    ;---  NEED   a object list!!!!       
                    x = 1000
                    CreateEntity(x, MeshID(#EGGEMPTY), MaterialID(#EGGEMPTY), EntityX(rayhitbool), 20, EntityZ(rayhitbool), #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
                    ScaleEntity(x, 2, 2, 2)
                    object(x)\id = #EGGEMPTY
                    object(x)\armor = 100+Random(100)
                    CreateEntityBody(x, #PB_Entity_BoxBody, 1, 1, 10) : RotateEntity(x, 0, Random(360), 0)
                    EntityAngularFactor(x, 0, 0.025, 0)
                    EntityLinearFactor(x, 0.025, 0, 0.025)
                    SetEntityAttribute(x, #PB_Entity_AngularSleeping, 0.1)
                    SetEntityAttribute(x, #PB_Entity_LinearSleeping, 1)
                    SetEntityAttribute(x, #PB_Entity_MaxVelocity, 0)
                    SetEntityAttribute(x, #PB_Entity_Friction, 10)  
                    
                    
                  ElseIf object(rayhitbool)\id = #DEADBUG
                    FreeEntity(rayhitbool)                   
                    If tank\armor< tank\maxArmor                   
                      tank\armor = object(x)\armor    
                    EndIf
                    ;tank\spentarmor+1
                    PlaySound(pickup)           
                    
                    
                    
                  ElseIf object(rayhitbool)\id = #BUG
                    StartDrawing(TextureOutput(layertexture))
                    DrawingMode(#PB_2DDrawing_AlphaBlend)
                    DrawAlphaImage(ImageID(bugdimg), 506-(EntityX(rayhitbool)/10), 506-EntityZ(rayhitbool)/10, 156)
                    StopDrawing()
                    PlaySound(crunch)
                    FreeEntity(rayhitbool)
                    bugscount-1
                    tank\kills+1
                    
                    ; Create a dead bug (gives energy)
                    ;                     CreateEntity(rayhitbool, MeshID(#DEADBUG), MaterialID(#DEADBUG), EntityX(rayhitbool), 20, EntityZ(rayhitbool), #MASK_GENERALPICKMASK, #MASK_MAINCAMERA)
                    ;                     ScaleEntity(rayhitbool, 2, 2, 2)
                    ;                     object(rayhitbool)\id = #DEADBUG
                    ;                     object(rayhitbool)\armor = 0
                    ;                     CreateEntityBody(rayhitbool, #PB_Entity_BoxBody, 1, 1, 10) : RotateEntity(rayhitbool, 0, Random(360), 0)
                    ;                     EntityAngularFactor(rayhitbool, 0, 0.025, 0)
                    ;                     EntityLinearFactor(rayhitbool, 0.025, 0, 0.025)
                    ;                     SetEntityAttribute(rayhitbool, #PB_Entity_AngularSleeping, 0.1)
                    ;                     SetEntityAttribute(rayhitbool, #PB_Entity_LinearSleeping, 1)
                    ;                     SetEntityAttribute(rayhitbool, #PB_Entity_MaxVelocity, 0)
                    ;                     SetEntityAttribute(rayhitbool, #PB_Entity_Friction, 10)  
                    
                  EndIf
                EndIf
              EndIf
            Else
              CreateLine3D(3000, EntityX(#hull), EntityY(#hull), EntityZ(#hull), RGB(255, 0, 0), EntityX(#AIM)+aoff, EntityY(#AIM), EntityZ(#AIM)+boff, RGB(255, 255, 127))
              hg = 1
            EndIf
          Else
            CreateLine3D(3000, EntityX(#hull), EntityY(#hull), EntityZ(#hull), RGB(255, 0, 0), EntityX(#AIM)+aoff, EntityY(#AIM), EntityZ(#AIM)+boff, RGB(255, 255, 127))
            hg = 1
          EndIf
        Else
          CreateLine3D(3000, EntityX(#hull), EntityY(#hull), EntityZ(#hull), RGB(255, 0, 0), EntityX(#AIM)+aoff, EntityY(#AIM), EntityZ(#AIM)+boff, RGB(255, 255, 127))
          hg = 1
        EndIf
      EndIf
    EndIf
    If hg >0
      splashimage(holeimg, 512-((EntityX(#aim)+aoff)/10), 512-(EntityZ(#aim)+boff)/10, 128)
      hg = 0
    EndIf
    If hg2 >0
      If object(rayhitbool)\id = #EGG Or object(rayhitbool)\id = #BUG Or object(rayhitbool)\id = #Nest
        If IsEntity(rayhitbool)      
          splashimage(splatimg, 510-(EntityX(rayhitbool)/10), 510-EntityZ(rayhitbool)/10, 128)
        Else
          Debug "This line should not shown!!! rayhitbool no longer existing? :" + Str(rayhitbool)
        EndIf
      Else
        splashimage(holeimg, 512-(PickX()/10), 512-PickZ()/10, 128)
      EndIf
      hg2 = 0
    EndIf
  Else
    EntityVelocity(#hull, 0, 0, 0)
    EntityAngularFactor(#hull, 0, 0, 0)
    MoveEntity(#TURR, EntityX(#HULL), 61, EntityZ(#HULL), #PB_World|#PB_Absolute)
    MoveCamera(#MAINCAMERA, EntityX(#HULL), CameraY(#MAINCAMERA), EntityZ(#HULL), #PB_World|#PB_Absolute)
    StopSound(engine)
  EndIf
  If ticker::triggered(4) 
    If object(#NEST)\armor<1000
      spawnbug(1, 0, 4550, 1, 4551, 1, #b_attack)
    EndIf
    If object(#NEST)\armor<500
      spawnbug(5, 3, 4550, 1, 4551, 0, #b_attack)
    EndIf
    If tank\ammo>500 And tank\load>25
      spawnbug(5, 3, 4550, 1, 4551, 1, #b_attack)
    EndIf
  EndIf
  If ticker::triggered(3) 
    If bugscount = 0
      If killcount<200
        spawnbug(Random(10, 5), 0, 4550, 1, 4551, 0, #b_guard)
        spawnbug(Random(10, 5), 0, 4550, 1, 4551, 0, #b_wonder)
      Else
        spawnbug(Random(5, 1), 0, 4550, 1, 4551, 10, #b_guard)
        spawnbug(Random(10, 5), 0, 4550, 1, 4551, 10, #b_wonder)
      EndIf
    ElseIf bugscount<50
      If killcount<200
        spawnbug(Random(6, 2), 0, 4550, 1, 4551, 15, #b_wonder)
      Else
        spawnbug(Random(5, 1), 0, 4550, 1, 4551, 5, #b_wonder)
      EndIf
    ElseIf bugscount>= 50
      If killcount<500
        spawnbug(Random(8, 3), 0, 4550, 1, 4551, 0, #b_attack)
      Else
        spawnbug(Random(20, 5), 0, 4550, 1, 4551, 10, #b_attack)
        spawnbug(Random(20, 5), 0, 4550, 1, 4551, 10, #b_wonder)
        spawnbug(Random(1, 1), 0, 4550, 1, 4551, 2, #b_guard)
      EndIf
    EndIf
  EndIf
  For z = 1 To 2
    If bugswiper>#BGE : bugswiper = #BGS : EndIf : x = bugswiper
    If IsEntity(x) And object(x)\id = #bug
      If object(x)\behavior = #b_wonder
        If object(x)\t = -1 
          object(x)\t = 0 : object(x)\tx = Random(10000)-5000 : object(x)\ty = Random(10000)-5000
        Else
          If dist(EntityX(x), EntityZ(x), object(x)\tx, object(x)\ty)<10000
            object(x)\t = -1
          EndIf
          If dist(EntityX(x), EntityZ(x), EntityX(#HULL), EntityZ(#HULL))<object(x)\aggrorange
            object(x)\behavior = #b_attack
            If SoundStatus(eat) = #PB_Sound_Stopped:PlaySound(eat):EndIf
          EndIf
        EndIf
      EndIf
      If object(x)\behavior = #b_idle
        If dist(EntityX(x), EntityZ(x), EntityX(#HULL), EntityZ(#HULL))<object(x)\aggrorange
          object(x)\behavior = #b_attack
          If SoundStatus(eat) = #PB_Sound_Stopped:PlaySound(eat):EndIf
        EndIf
      EndIf
      If object(x)\behavior = #b_guard
        If dist(EntityX(x), EntityZ(x), EntityX(#HULL), EntityZ(#HULL))<object(x)\aggrorange+500000
          object(x)\behavior = #b_attack
          If SoundStatus(eat) = #PB_Sound_Stopped:PlaySound(eat):EndIf
        EndIf
      EndIf
    EndIf
    bugswiper+1
  Next
  ForEach bugs()
    If IsEntity(bugs())
      x = bugs()
      If object(x)\behavior = #b_attack
        EntityLookAt(x, EntityX(#hull), 20, EntityZ(#hull))
        MoveEntity(x, 0, 0, -object(x)\spmax, #PB_Local|#PB_Relative)
      ElseIf object(x)\behavior = #b_wonder
        EntityLookAt(x, object(x)\tx, 20, object(x)\ty)
        MoveEntity(x, 0, 0, -object(x)\spmax/2, #PB_Local|#PB_Relative)
      ElseIf object(x)\behavior = #b_guard
        EntityLookAt(x, object(x)\tx, 20, object(x)\ty)
        MoveEntity(x, 0, 0, 0, #PB_Local|#PB_Relative)
      Else
        EntityLookAt(x, 0, 20, 0)
        MoveEntity(x, 0, 0, 0, #PB_Local|#PB_Relative)
      EndIf
      If EntityCollide(x, #HULL)
        object(x)\behavior = #b_attack
        tank\armor-Random(5, 1)
        If SoundStatus(eat) = #PB_Sound_Stopped
          PlaySound(eat)
        EndIf
      EndIf
    Else
      DeleteElement(bugs())
    EndIf
  Next
  If ticker::triggered(2)
    matanim = 1-matanim
    For x = #BGS To #BGE
      If IsEntity(x)
        If matanim = 1
          SetEntityMaterial(x, MaterialID(#btex1))
        Else
          SetEntityMaterial(x, MaterialID(#btex2))
        EndIf
      EndIf
    Next x
  EndIf
  UpdateRenderTexture(#RENDEROBJECT)
  If IsMesh(3000)
    FreeMesh(3000)
  EndIf
  If IsMesh(3001)
    FreeMesh(3001)
  EndIf
  RenderWorld(60)
  If EntityX(#hull) >- 400 And EntityX(#hull)<406
    If EntityZ(#hull) >- 100 And EntityZ(#hull)<100
      If EntityX(#hull) >- 400 And EntityX(#hull)<-200
        petskii::ctobject(ScreenWidth()/2, ScreenHeight()/2+50, "Exchange 1 crate for 50 AMMUNITION.", c1, c2)
      EndIf
      If EntityX(#hull) >- 100 And EntityX(#hull)<100
        petskii::ctobject(ScreenWidth()/2, ScreenHeight()/2+50, "Load 50 crates to Helipad to WIN.", c1, c2)
      EndIf
      If EntityX(#hull)>200 And EntityX(#hull)<400
        petskii::ctobject(ScreenWidth()/2, ScreenHeight()/2+50, "Exchange 1 crate for 25 ARMOR.", c1, c2)
      EndIf
    EndIf
  EndIf
  If tank\won = #KILLED_NEST
    c3 = RGB(0, 255, 0)
    petskii::ctobject(ScreenWidth()/2, 100, "TRIUMPHED (WIN)", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 150, "You fired "+Str(tank\fired)+" shots.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 180, "You killed "+Str(tank\kills)+" bugs.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 210, "You accidentally destroyed "+Str(tank\boxdestroyed)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 240, "You collected "+Str(tank\collected)+" crates, ", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 270, "You uploaded "+Str(tank\load)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 300, "You spent "+Str(tank\spentarmor)+" crates on armor and "+Str(tank\spentammo)+" on ammo.", c3, c2)
    If object(#NEST)\armor>0
      petskii::ctobject(ScreenWidth()/2, 330, "The Nest has been destroyed.", c3, c2)
    EndIf
    If mins = 0 And seconds = 0
      mins = (ElapsedMilliseconds()/1000)/60
      seconds = Mod(ElapsedMilliseconds()/1000, 60)
      score = 5000+(tank\kills*8) + tank\fired -(tank\boxdestroyed*10) + tank\collected*10 + (tank\load*50)-tank\spentarmor-tank\spentammo-object(#NEST)\armor
    EndIf
    petskii::ctobject(ScreenWidth()/2, 380, "You survived "+Str(mins)+" minutes and "+Str(seconds)+" seconds.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 410, "Your Score is "+Str(score)+".", c3, c2)
  EndIf
  If tank\won = #COLLECT_ALL
    c3 = RGB(255, 255, 0)
    petskii::ctobject(ScreenWidth()/2, 100, "COLLECTED (WIN)", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 150, "You fired "+Str(tank\fired)+" shots.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 180, "You killed "+Str(tank\kills)+" bugs.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 210, "You accidentally destroyed "+Str(tank\boxdestroyed)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 240, "You collected "+Str(tank\collected)+" crates, ", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 270, "You uploaded "+Str(tank\load)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 300, "You spent "+Str(tank\spentarmor)+" crates on armor and "+Str(tank\spentammo)+" on ammo.", c3, c2)
    If object(#NEST)\armor>0
      petskii::ctobject(ScreenWidth()/2, 330, "The Nest has not been destroyed.", RGB(255, 0, 0), c2)
    EndIf
    If mins = 0 And seconds = 0
      mins = (ElapsedMilliseconds()/1000)/60
      seconds = Mod(ElapsedMilliseconds()/1000, 60)
      score = 5000+(tank\kills*8) + tank\fired -(tank\boxdestroyed*10) + tank\collected*10 + (tank\load*50)-tank\spentarmor-tank\spentammo-object(#NEST)\armor
    EndIf
    petskii::ctobject(ScreenWidth()/2, 380, "You survived "+Str(mins)+" minutes and "+Str(seconds)+" seconds.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 410, "Your Score is "+Str(score)+".", c3, c2)
  EndIf
  If tank\armor <= 0 And tank\won = 0
    tank\armor = 0
    c3 = RGB(255, 0, 0)
    petskii::ctobject(ScreenWidth()/2, 100, "DEVOURED", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 150, "You fired "+Str(tank\fired)+" shots.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 180, "You killed "+Str(tank\kills)+" bugs.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 210, "You accidentally destroyed "+Str(tank\boxdestroyed)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 240, "You collected "+Str(tank\collected)+" crates, ", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 270, "You uploaded "+Str(tank\load)+" crates.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 300, "You spent "+Str(tank\spentarmor)+" crates on armor and "+Str(tank\spentammo)+" on ammo.", c3, c2)
    If object(#NEST)\armor>0
      petskii::ctobject(ScreenWidth()/2, 330, "The nest has not been destroyed.", c3, c2)
    EndIf
    If mins = 0 And seconds = 0
      mins = (ElapsedMilliseconds()/1000)/60
      seconds = Mod(ElapsedMilliseconds()/1000, 60)
      score = (tank\kills*8) + tank\fired -(tank\boxdestroyed*10) + tank\collected*10 + (tank\load*50)-tank\spentarmor-tank\spentammo-object(#NEST)\armor
    EndIf
    petskii::ctobject(ScreenWidth()/2, 380, "You survived "+Str(mins)+" minutes and "+Str(seconds)+" seconds.", c3, c2)
    petskii::ctobject(ScreenWidth()/2, 410, "Your Score is "+Str(score)+".", c3, c2)
  Else
    petskii::textoutlined(0, 0, "NEST HEALTH : "+Str(object(#NEST)\armor)+"/1500", c1, c2)
    petskii::textoutlined(0, 30, "AMMO : "+Str(tank\ammo), c1, c2)
    petskii::textoutlined(0, 60, "ARMOR : "+Str(tank\armor), c1, c2)
    petskii::textoutlined(0, 90, "LOAD : "+Str(tank\load)+"/50", c1, c2)
  EndIf
  For x = 5 To 1 Step -1
    If x<= tank\box
      DisplayTransparentSprite(#box, ScreenWidth()-480+(x*80), 0, 255)
    Else
      DisplayTransparentSprite(#box, ScreenWidth()-480+(x*80), 0, 128)
    EndIf
  Next x
  FlipBuffers()
  Delay(#MAINLOOP_DELAY)
EndProcedure

;- 6 main
app_start()
Repeat
  app_update()
Until KeyboardPushed(#PB_Key_Escape)

;- } Datasection
DataSection
  ground:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $5F, $49, $44, $41, $54
  Data.a $38, $CB, $63, $30, $36, $36, $FE, $5F, $5E, $5E, $FE, $1F, $44, $13, $C2, $D8, $D4, $31, $10, $A3, $11, $DD, $10, $64, $83, $48, $36, $80, $24, $17, $C0, $6C, $C3, $E7, $45, $06, $52, $9C, $8E, $D7, $00
  Data.a $62, $02, $92, $60, $20, $22, $3B, $97, $90, $D3, $E9, $13, $88, $24, $19, $40, $6C, $62, $22, $2A, $0C, $08, $19, $86, $AC, $86, $22, $2F, $80, $0C, $61, $20, $27, $EE, $31, $BC, $80, $4D, $21, $BA, $18
  Data.a $2E, $AF, $D1, $3E, $2F, $10, $32, $00, $00, $6E, $B8, $AD, $94, $79, $97, $60, $22, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  base:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00
  Data.a $93, $49, $44, $41, $54, $38, $CB, $A5, $93, $81, $0D, $80, $30, $08, $04, $DB, $55, $5C, $A1, $6B, $B8, $4F, $67, $71, $8C, $8E, $E3, $0A, $2E, $A1, $D2, $E4, $93, $0F, $85, $16
  Data.a $A3, $C9, $27, $A4, $C2, $F9, $50, $4C, $F7, $FB, $E4, $9C, $BB, $38, $F6, $A4, $F3, $93, $04, $A5, $94, $2E, $89, $B7, $B6, $77, $D5, $5A, $CD, $18, $F9, $80, $24, $04, $0C, $90
  Data.a $02, $4B, $0C, $40, $FE, $E0, $C0, $2B, $86, $96, $0E, $38, $19, $60, $0B, $E0, $3A, $40, $0B, $38, $63, $48, $68, $06, $FA, $EB, $DA, $45, $68, $06, $BA, $98, $21, $21, $07, $11
  Data.a $C0, $F2, $16, $56, $2D, $B8, $0E, $8E, $F3, $72, $01, $F2, $EE, $D3, $1E, $CC, $AE, $31, $B4, $07, $B3, $45, $72, $1D, $A0, $05, $4B, $DC, $C2, $74, $06, $16, $04, $E7, $83, $83
  Data.a $BF, $BF, $F3, $03, $4C, $88, $B8, $D8, $9A, $0C, $38, $DB, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  turret:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00
  Data.a $01, $73, $52, $47, $42, $00, $AE, $CE, $1C, $E9, $00, $00, $00, $04, $67, $41, $4D, $41, $00, $00, $B1, $8F, $0B, $FC, $61, $05, $00, $00, $00, $09, $70, $48, $59, $73, $00, $00
  Data.a $0E, $C2, $00, $00, $0E, $C2, $01, $15, $28, $4A, $80, $00, $00, $00, $48, $49, $44, $41, $54, $38, $4F, $63, $C0, $07, $EA, $EB, $EB, $FF, $83, $30, $94, $4B, $3A, $38, $7C, $F8
  Data.a $F0, $7F, $10, $86, $72, $B1, $02, $26, $28, $4D, $36, $18, $35, $80, $81, $81, $11, $4A, $63, $00, $50, $E8, $EF, $D9, $B3, $07, $CC, $76, $71, $71, $61, $B0, $B5, $B5, $C5, $AA
  Data.a $96, $62, $17, $E0, $05, $C4, $A4, $83, $51, $30, $F0, $80, $81, $01, $00, $DE, $F8, $19, $26, $E0, $78, $F6, $64, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  wall:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $29, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $64, $64, $FC, $4F, $09, $66, $00, $11, $E5, $E5, $E5, $64, $61, $14, $03, $8C, $8D, $8D, $49, $C2, $A3, $06, $8C, $1A, $30, $5C, $0D, $A0, $28, $33, $51, $82, $01, $88, $AC, $9E, $58
  Data.a $A1, $88, $0D, $92, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  box:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $5B, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $64, $64, $FC, $4F, $09, $66, $00, $11, $69, $2E, $0C, $64, $61, $14, $03, $60, $F4, $DD, $8E, $50, $BC, $18, $59, $2D, $86, $0B, $08, $19, $82, $AC, $06, $C3, $00, $74, $05, $F8, $34
  Data.a $23, $F3, $19, $D0, $35, $60, $33, $04, $9F, $18, $03, $36, $1B, $B1, $39, $15, $97, $1A, $06, $42, $4E, $26, $24, $4F, $1B, $03, $28, $F2, $02, $45, $81, $48, $51, $34, $52, $9C, $90, $A8, $92, $94, $C9
  Data.a $CE, $4C, $94, $60, $00, $10, $96, $C7, $44, $CF, $DD, $33, $A8, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  aim:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $43, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $00, $02, $46, $46, $C6, $FF, $30, $CC, $40, $00, $60, $A8, $25, $56, $23, $2E, $83, $18, $C8, $D1, $8C, $6C, $08, $E5, $06, $0C, $5E, $80, $EC, $3C, $B2, $9D, $FA, $EE, $5D, $F9, $7F
  Data.a $10, $26, $DB, $15, $14, $19, $40, $15, $2F, $D0, $3F, $B4, $07, $26, $25, $52, $9C, $99, $28, $CD, $CE, $00, $56, $9C, $2D, $89, $00, $54, $A3, $09, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60
  Data.a $82
  hole:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $4D, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $64, $64, $FC, $CF, $80, $03, $E0, $93, $43, $51, $04, $C2, $E5, $E5, $E5, $FF, $8D, $8D, $8D, $FF, $C3, $F8, $44, $69, $86, $01, $90, $66, $98, $26, $90, $21, $20, $0C, $12, $23, $DA
  Data.a $00, $74, $9B, $49, $76, $05, $36, $E7, $83, $F8, $44, $BB, $00, $5D, $23, $49, $5E, $C0, $17, $88, $24, $05, $24, $C9, $D1, $37, $0A, $46, $01, $12, $00, $00, $76, $BB, $38, $E9, $51, $9C, $DC, $DF, $00
  Data.a $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  bsplat:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $38, $49, $44, $41, $54
  Data.a $38, $CB, $63, $E8, $60, $60, $F8, $0F, $C2, $0C, $40, $80, $CC, $26, $09, $20, $6B, $82, $19, $42, $92, $61, $E8, $9A, $48, $76, $05, $36, $03, $28, $32, $84, $E4, $F0, $A0, $8A, $ED, $F8, $5C, $43, $94
  Data.a $ED, $D8, $F8, $64, $45, $E9, $28, $18, $91, $00, $00, $E3, $7D, $3B, $92, $FC, $FB, $7A, $4E, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  ammopod:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $4D, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $80, $02, $46, $46, $C6, $FF, $A4, $60, $06, $64, $00, $12, $D8, $BD, $7B, $37, $49, $18, $6E, $08, $39, $9A, $51, $0C, $81, $19, $50, $5E, $5E, $0E, $C6, $F8, $D8, $B4, $35, $C0, $D8
  Data.a $D8, $18, $8C, $F1, $B1, $47, $0D, $A0, $C0, $00, $E4, $14, $88, $D3, $00, $42, $09, $06, $99, $26, $CB, $00, $DA, $B9, $80, $E2, $CC, $44, $69, $76, $06, $00, $AB, $1B, $41, $63, $3C, $CF, $AC, $CB, $00
  Data.a $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  egg:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $88, $49, $44, $41, $54
  Data.a $38, $CB, $B5, $93, $8B, $09, $00, $21, $0C, $43, $75, $26, $87, $73, $38, $87, $BB, $A3, $42, $24, $A4, $B5, $CA, $C1, $15, $8A, $1F, $C8, $33, $95, $B6, $94, $BF, $A2, $D6, $FA, $20, $3F, $09, $5B, $6B
  Data.a $2B, $AF, $41, $2C, $B4, $E8, $BD, $3B, $D0, $15, $C0, $84, $1C, $38, $A7, $10, $88, $C7, $18, $33, $55, $8C, $FB, $10, $02, $B1, $0A, $18, $82, $33, $CA, $5A, $90, $48, $0C, $00, $84, $0C, $73, $90, $A8
  Data.a $6E, $76, $81, $BD, $AE, $0E, $90, $39, $50, $F0, $D1, $01, $BF, $1C, $95, $E0, $3E, $92, $5D, $B0, $40, $A1, $00, $6F, $01, $6A, $79, $17, $61, $2F, $70, $17, $EE, $3E, $CE, $D6, $B4, $1B, $75, $0E, $50
  Data.a $EF, $B1, $0B, $B3, $49, $3C, $4D, $E5, $0B, $14, $A4, $B1, $9C, $BF, $6A, $0C, $CE, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  eggd:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $A4, $49, $44, $41, $54
  Data.a $38, $CB, $8D, $93, $8B, $09, $00, $21, $0C, $43, $75, $26, $87, $73, $38, $87, $BB, $23, $C2, $83, $5C, $AF, $7E, $02, $A2, $62, $4D, $63, $5A, $4B, $B9, $40, $6B, $ED, $11, $B6, $41, $B5, $D6, $19, $30
  Data.a $C6, $78, $32, $02, $DF, $67, $31, $29, $21, $A4, $57, $67, $92, $48, $26, $1D, $82, $18, $C8, $59, $4A, $EE, $04, $1A, $92, $CA, $7C, $CC, $8E, $82, $DE, $FB, $BC, $A0, $B5, $66, $ED, $35, $8E, $26, $7A
  Data.a $16, $08, $04, $2E, $6F, $8D, $53, $90, $AF, $B9, $0C, $50, $82, $F4, $B4, $AC, $FE, $36, $CF, $0A, $48, $12, $4B, $5A, $32, $D7, $21, $88, $0A, $E2, $33, $3E, $2A, $5C, $01, $66, $6A, $66, $0D, $BC, $E9
  Data.a $52, $63, $91, $EA, $EE, $BB, $47, $4B, $13, $3D, $08, $66, $24, $C7, $0A, $2D, $4B, $E8, $32, $E3, $1F, $59, $FD, $9D, $5F, $33, $79, $CD, $63, $DB, $1E, $9B, $E9, $2A, $53, $C0, $0B, $4C, $01, $22, $3E
  Data.a $EB, $4B, $38, $B0, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  bug1:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $7D, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $C0, $02, $18, $19, $19, $FF, $E3, $E3, $E3, $05, $20, $C5, $FF, $CB, $CB, $FF, $C3, $34, $A1, $F3, $B1, $6A, $C0, $66, $63, $9A, $0B, $03, $1C, $63, $93, $47, $11, $C3, $66, $08, $48
  Data.a $E3, $DD, $8E, $50, $B0, $01, $84, $2C, $C4, $2A, $81, $EC, $02, $82, $9A, $D1, $15, $20, $6B, $46, $F6, $06, $51, $81, $89, $CD, $10, $A2, $35, $A3, $3B, $1D, $16, $06, $E8, $5E, $C1, $6B, $33, $3E, $17
  Data.a $10, $15, $80, $84, $5C, $40, $30, $0A, $89, $09, $03, $82, $2E, $C1, $E6, $02, $A2, $A3, $10, $DD, $1B, $78, $9D, $8F, $2F, $C3, $E0, $0A, $7D, $A2, $0D, $80, $19, $42, $8C, $3A, $8A, $00, $00, $EB, $05
  Data.a $9B, $3C, $30, $13, $76, $9B, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  bug2:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $81, $49, $44, $41, $54
  Data.a $38, $CB, $A5, $52, $C1, $0D, $80, $30, $08, $84, $DD, $5C, $C1, $15, $5C, $A1, $2B, $B8, $A4, $B3, $D4, $60, $82, $39, $09, $D4, $AB, $5E, $C2, $83, $96, $3B, $0E, $82, $48, $02, $55, $ED, $A3, $7C, $08
  Data.a $2B, $EE, $AD, $75, $27, $C5, $9C, $16, $D9, $16, $B9, $63, $8A, $EC, $30, $E2, $B1, $AF, $97, $80, $7C, $01, $3A, $F8, $45, $A6, $45, $6C, $4E, $8C, $B8, $03, $8C, $92, $58, $75, $47, $17, $A5, $10, $DA
  Data.a $77, $07, $BE, $44, $CF, $E9, $11, $B2, $EE, $C3, $CE, $F8, $C8, $38, $78, $88, $64, $67, $5B, $39, $A0, $CE, $1B, $05, $DC, $01, $7D, $8D, $71, $94, $78, $03, $AF, $22, $B1, $20, $6E, $7E, $5A, $80, $F9
  Data.a $3F, $01, $DC, $74, $90, $72, $05, $16, $E0, $DE, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  deadbug:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $7D, $49, $44, $41, $54
  Data.a $38, $CB, $9D, $93, $D1, $0D, $80, $30, $08, $44, $61, $37, $67, $71, $85, $AE, $E0, $D6, $35, $7C, $60, $F0, $42, $F5, $29, $5F, $A6, $1E, $AF, $07, $B9, $9A, $81, $3A, $CC, $E6, $AB, $68, $DF, $80, $A8
  Data.a $E8, $6E, $FA, $AE, $79, $8E, $81, $80, $ED, $0D, $15, $18, $DF, $75, $04, $77, $9F, $18, $12, $8D, $0A, $6C, $F7, $51, $A9, $29, $C8, $C6, $76, $66, $52, $01, $D5, $DB, $D1, $18, $EA, $46, $21, $F1, $1F
  Data.a $ED, $41, $5D, $74, $4E, $AE, $B3, $A7, $A0, $04, $24, $9D, $A0, $60, $A9, $C5, $CE, $05, $4A, $26, $1D, $63, $99, $7B, $75, $52, $01, $78, $89, $9F, $E2, $4B, $5F, $E1, $EF, $60, $AD, $EA, $04, $78, $05
  Data.a $5F, $7C, $02, $34, $D9, $67, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  nest:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $95, $49, $44, $41, $54
  Data.a $38, $CB, $95, $53, $09, $0E, $80, $30, $08, $63, $6F, $DA, $17, $7C, $8B, $5F, $D8, $F3, $67, $30, $A9, $E9, $2A, $E0, $24, $21, $C8, $5C, $29, $D7, $CC, $44, $5A, $6B, $F3, $3C, $6C, $F6, $DE, $17, $0B
  Data.a $B5, $4A, $00, $1E, $63, $DC, $16, $3E, $14, $7E, $08, $E6, $0B, $0C, $8C, $BE, $DD, $86, $CC, $60, $77, $DF, $D5, $D3, $67, $AB, $01, $1F, $66, $FC, $C0, $C5, $48, $39, $48, $18, $40, $D9, $AB, $20, $DC
  Data.a $58, $E3, $4E, $57, $60, $0E, $B2, $64, $B1, $CB, $AE, $25, $82, $D8, $F8, $E0, $4F, $06, $F0, $4D, $E7, $BC, $93, $01, $97, $BD, $DD, $C4, $68, $A4, $CB, $24, $AA, $46, $6A, $ED, $AF, $B5, $E6, $C3, $6A
  Data.a $99, $CA, $75, $46, $16, $BA, $95, $D9, $4A, $97, $6F, $81, $67, $9D, $D6, $9D, $89, $96, $F3, $05, $BC, $00, $A1, $34, $23, $9B, $6A, $83, $C8, $21, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60
  Data.a $82
  rep:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $5F, $49, $44, $41, $54
  Data.a $38, $CB, $BD, $93, $51, $0A, $00, $20, $08, $43, $F5, $D4, $1E, $CE, $C3, $15, $45, $85, $1F, $6A, $93, $20, $61, $24, $C1, $1E, $53, $90, $68, $15, $33, $B7, $8A, $C8, $D6, $F8, $50, $D5, $92, $0E, $04
  Data.a $31, $8B, $C8, $94, $0B, $41, $01, $5E, $FF, $07, $B0, $E3, $5B, $C1, $80, $C8, $08, $01, $6E, $E6, $14, $80, $98, $5D, $40, $36, $2F, $0C, $88, $B6, $ED, $25, $2D, $01, $EC, $0B, $EF, $A0, $9C, $20, $9B
  Data.a $35, $4C, $F0, $7C, $4C, $AF, $E7, $DC, $01, $9F, $A3, $6B, $FF, $D7, $FF, $9D, $8F, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  heli:
  Data.a $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44, $52, $00, $00, $00, $10, $00, $00, $00, $10, $08, $06, $00, $00, $00, $1F, $F3, $FF, $61, $00, $00, $00, $57, $49, $44, $41, $54
  Data.a $38, $CB, $63, $60, $80, $02, $46, $46, $C6, $FF, $A4, $60, $06, $64, $00, $12, $D8, $BD, $7B, $37, $49, $18, $6E, $08, $36, $CD, $E5, $E5, $E5, $58, $31, $56, $43, $90, $0D, $C0, $A5, $11, $97, $41, $58
  Data.a $0D, $80, $01, $74, $4D, $C8, $E2, $58, $0D, $C0, $A6, $10, $97, $01, $30, $43, $68, $6B, $00, $2E, $40, $3F, $03, $E8, $1F, $06, $14, $47, $23, $55, $12, $12, $59, $49, $99, $E2, $CC, $44, $69, $76, $06
  Data.a $00, $FE, $37, $75, $77, $2B, $A4, $71, $D7, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  Waveheader3:
  Data.a $52, $49, $46, $46, $24, $08, $00, $00, $57, $41, $56, $45, $66, $6D, $74, $20, $10, $00, $00, $00, $01, $00, $01, $00, $40, $1F, $00, $00, $40, $1F, $01, $00, $04, $00, $08, $00, $64, $61, $74, $61
EndDataSection
; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 43
; FirstLine = 18
; Folding = -------------------------
; EnableXP
; DPIAware