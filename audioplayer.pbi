; pb-macos-audioplayer rev.5
; written by deseven
;
; https://github.com/deseven/pb-macos-audioplayer

DeclareModule audioplayer
  
  Declare addFFmpegFormat(ext.s)
  Declare setFFmpegPath(path.s)
  Declare setFFmpegTempDirPath(path.s)
  Declare isSupportedFile(path.s)
  Declare load(id.l,path.s)
  Declare play(id.l)
  Declare pause(id.l)
  Declare toggle(id.l)
  Declare stop(id.l)
  Declare free(id.l = #PB_All)
  Declare.d getCurrentTime(id.l)
  Declare.d setCurrentTime(id.l,time.d)
  Declare getDuration(id.l)
  Declare getPlayerID(id.l)
  Declare isPaused(id.l)
  Declare isStarted(id.l)
  Declare.s getPath(id.l)
  Declare.s getTempPath(id.l)
  Declare setFinishEvent(id.l,event.i)
  
EndDeclareModule

Module audioplayer
  
  UseMD5Fingerprint()
  
  Structure audio
    ID.l
    playerID.i
    initialized.b
    isPaused.b
    isStarted.b
    path.s
    tempPath.s
    duration.i
    finishEvent.i
  EndStructure
  
  Enumeration format_type
    #formatNative
    #formatFFmpeg
  EndEnumeration
  
  Structure format
    ext.s
    type.b
  EndStructure

  ImportC "-framework AVKit" : EndImport
  
  DeclareC AVAudioPlayerDidFinishPlaying(id.i,v.i,playerID.i)
  Define AVPdelegateClass = objc_allocateClassPair_(objc_getClass_("NSObject"),"myDelegateClass",0)
  class_addMethod_(AVPdelegateClass,sel_registerName_("audioPlayerDidFinishPlaying:successfully:"),@AVAudioPlayerDidFinishPlaying(),"v@:@@")
  objc_registerClassPair_(AVPdelegateClass)
  Global AVPdelegate = class_createInstance_(AVPdelegateClass,0)
  
  Global NewList players.audio()
  
  Global FFmpegPath.s
  Global FFmpegTempDirPath.s
  
  Global NewList formats.format()
  AddElement(formats()) : formats()\ext = "mp3"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "m4a"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "aac"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "ac3"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "wav"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "aif"  : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "aiff" : formats()\type = #formatNative
  AddElement(formats()) : formats()\ext = "alac" : formats()\type = #formatNative
  
  Procedure setFFmpegPath(path.s)
    If FileSize(path) > 0 And RunProgram(path,"-version","")
      ffmpegPath = path
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure setFFmpegTempDirPath(path.s)
    If FileSize(path) = -2
      FFmpegTempDirPath = path
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure addFFmpegFormat(ext.s)
    ext = LCase(ext)
    ForEach formats()
      If formats()\ext = ext
        foundFormat = #True
        formats()\type = #formatFFmpeg
        ProcedureReturn #True
      EndIf
    Next
    AddElement(formats()) : formats()\ext = ext : formats()\type = #formatFFmpeg
    ProcedureReturn #True
  EndProcedure
  
  Procedure isSupportedFile(path.s)
    Protected ext.s = LCase(GetExtensionPart(path))
    ForEach formats()
      If formats()\ext = ext
        Select formats()\type
          Case #formatNative
            ProcedureReturn #True
          Case #formatFFmpeg
            If FFmpegPath
              ProcedureReturn #True
            EndIf
        EndSelect
        Break
      EndIf
    Next
  EndProcedure
  
  Procedure loadNative(path.s)
    ProcedureReturn CocoaMessage(0,CocoaMessage(0,0,"AVAudioPlayer alloc"),
                                 "initWithContentsOfURL:",CocoaMessage(0,0,"NSURL fileURLWithPath:$",@path),
                                 "error:",#Null)
  EndProcedure
  
  Procedure loadFFmpeg(path.s,tempPath.s)
    Protected FFmpegFailed.b
    Protected FFmpeg.i
    ffmpeg = RunProgram(FFmpegPath,~"-i \"" + path + ~"\" -y -map_metadata -1 -v 0 \"" + tempPath + ~"\"","",#PB_Program_Open)
    If IsProgram(FFmpeg)
      WaitProgram(FFmpeg,5000)
      If ProgramRunning(FFmpeg)
        KillProgram(FFmpeg)
        FFmpegFailed = #True
      EndIf
      If FileSize(tempPath) <= 0
        FFmpegFailed = #True
      EndIf
      If ProgramExitCode(ffmpeg) <> 0
        FFmpegFailed = #True
      EndIf
      CloseProgram(ffmpeg)
    Else
      FFmpegFailed = #True
    EndIf
    
    If FFmpegFailed
      If FileSize(tempPath) >= 0
        DeleteFile(tempPath,#PB_FileSystem_Force)
      EndIf
      ProcedureReturn #False
    EndIf
    
    ProcedureReturn loadNative(tempPath)
  EndProcedure
  
  Procedure load(id.l,path.s)
    Protected tempPath.s
    Protected duration.d
    Protected anyID.l
    
    If id = #PB_Any
      While Not anyID
        anyID = Random(2147483647,1)
        ForEach players()
          If players()\id = anyID
            anyID = 0
            Break
          EndIf
        Next
      Wend
      id = anyID
    EndIf
    
    If id >= 0 And FileSize(path) And isSupportedFile(path)
      ForEach players()
        If players()\ID = id
          free(id)
        EndIf
      Next
      AddElement(players())
      players()\ID = id
      players()\path = path
      Protected ext.s = LCase(GetExtensionPart(path))
      ForEach formats()
        If formats()\ext = ext
          Select formats()\type
            Case #formatNative
              players()\playerID = loadNative(path)
            Case #formatFFmpeg
              If FFmpegTempDirPath
                tempPath = FFmpegTempDirPath + "/" + StringFingerprint(Str(Date()) + path,#PB_Cipher_MD5) + ".wav"
              Else
                tempPath = GetTemporaryDirectory() + StringFingerprint(Str(Date()) + path,#PB_Cipher_MD5) + ".wav"
              EndIf
              players()\playerID = loadFFmpeg(path,tempPath)
          EndSelect
          Break
        EndIf
      Next
    Else
      ProcedureReturn #False
    EndIf
    
    If players()\playerID
      players()\tempPath = tempPath
      CocoaMessage(0,players()\playerID,"prepareToPlay")
      CocoaMessage(@duration,players()\playerID,"duration")
      players()\duration = duration
      players()\initialized = #True
    EndIf
    
    If players()\initialized
      If anyID
        ProcedureReturn id
      Else
        ProcedureReturn #True
      EndIf
    Else
      free(id)
    EndIf
  EndProcedure
  
  Procedure play(id.l)
    ForEach players()
      If players()\ID = id And players()\initialized And (players()\isPaused Or Not players()\isStarted)
        players()\isPaused = #False
        players()\isStarted = #True
        CocoaMessage(0,players()\playerID,"play")
        ProcedureReturn #True
      EndIf
    Next
  EndProcedure
  
  Procedure pause(id.l)
    ForEach players()
      If players()\ID = id And players()\initialized And (Not players()\isPaused)
        players()\isPaused = #True
        CocoaMessage(0,players()\playerID,"pause")
        ProcedureReturn #True
      EndIf
    Next
  EndProcedure
  
  Procedure toggle(id.l)
    ForEach players()
      If players()\ID = id And players()\initialized
        If players()\isPaused Or (Not players()\isStarted)
          play(id)
        Else
          pause(id)
        EndIf
        ProcedureReturn #True
      EndIf
    Next
  EndProcedure
  
  Procedure stop(id.l)
    ForEach players()
      If players()\ID = id And players()\initialized
        CocoaMessage(0,players()\playerID,"pause")
        Define time.d = 0.0
        CocoaMessage(@time,players()\playerID,"setCurrentTime:")
        players()\isStarted = #False
        players()\isPaused = #False
        ProcedureReturn #True
      EndIf
    Next
  EndProcedure
  
  Procedure free(id.l = #PB_All)
    ForEach players()
      If players()\ID = id Or id = #PB_All
        With players()
          If \playerID
            CocoaMessage(0,\playerID,"stop")
            CocoaMessage(0,\playerID,"dealloc")
          EndIf
          If \tempPath
            If FileSize(\tempPath) > -1
              DeleteFile(\tempPath,#PB_FileSystem_Force)
            EndIf
          EndIf
        EndWith
        DeleteElement(players())
        If id <> #PB_All
          Break
        EndIf
      EndIf
    Next
  EndProcedure
  
  Procedure.d getCurrentTime(id.l)
    ForEach players()
      If players()\ID = id And players()\initialized
        Protected position.d
        CocoaMessage(@position,players()\playerID,"currentTime")
        ProcedureReturn(position)
      EndIf
    Next
  EndProcedure
  
  Procedure.d setCurrentTime(id.l,time.d)
    ForEach players()
      If players()\ID = id And players()\initialized
        CocoaMessage(0,players()\playerID,"setCurrentTime:@",@time)
        ProcedureReturn getCurrentTime(id)
      EndIf
    Next
  EndProcedure
  
  Procedure getDuration(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\duration
      EndIf
    Next
  EndProcedure
  
  Procedure getPlayerID(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\playerID
      EndIf
    Next
  EndProcedure
  
  Procedure isPaused(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\isPaused
      EndIf
    Next
  EndProcedure
  
  Procedure isStarted(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\isStarted
      EndIf
    Next
  EndProcedure
  
  Procedure.s getPath(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\path
      EndIf
    Next
  EndProcedure
  
  Procedure.s getTempPath(id.l)
    ForEach players()
      If players()\ID = id
        ProcedureReturn players()\tempPath
      EndIf
    Next
  EndProcedure
  
  Procedure setFinishEvent(id.l,event.i)
    ForEach players()
      If players()\ID = id
        players()\finishEvent = event
        CocoaMessage(0,players()\playerID,"setDelegate:",AVPdelegate)
        ProcedureReturn #True
      EndIf
    Next
  EndProcedure
  
  ProcedureC AVAudioPlayerDidFinishPlaying(id.i,v.i,playerID.i)
    ForEach players()
      If players()\playerID = playerID And players()\finishEvent
        players()\isStarted = #False
        PostEvent(players()\finishEvent)
      EndIf
    Next
  EndProcedure
  
EndModule