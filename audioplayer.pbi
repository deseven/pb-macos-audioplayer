; pb-macos-audioplayer rev.3
; written by deseven
;
; https://github.com/deseven/pb-macos-audioplayer

DeclareModule audioplayer
  
  Declare addFFmpegFormat(ext.s)
  Declare setFFmpegPath(path.s)
  Declare isSupportedFile(path.s)
  Declare load(path.s,startPlaying = #False)
  Declare play()
  Declare pause()
  Declare toggle()
  Declare stop()
  Declare free()
  Declare getCurrentTime()
  Declare getDuration()
  Declare getPlayerID()
  Declare isPaused()
  Declare isStarted()
  Declare.s getPath()
  Declare.s getTempPath()
  Declare setFinishEvent(event.i)
  
EndDeclareModule

Module audioplayer
  
  UseMD5Fingerprint()
  
  Structure audio
    initialized.b
    isPaused.b
    isStarted.b
    path.s
    tempPath.s
    playerID.i
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
  
  DeclareC AVAudioPlayerDidFinishPlaying()
  Define AVPdelegateClass = objc_allocateClassPair_(objc_getClass_("NSObject"),"myDelegateClass",0)
  class_addMethod_(AVPdelegateClass,sel_registerName_("audioPlayerDidFinishPlaying:successfully:"),@AVAudioPlayerDidFinishPlaying(),"v@:@@")
  objc_registerClassPair_(AVPdelegateClass)
  Global AVPdelegate = class_createInstance_(AVPdelegateClass,0)
  
  Global audio.audio
  
  Global FFmpegPath.s
  
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
  
  Procedure cleanUp()
    If audio\playerID
      CocoaMessage(0,audio\playerID,"stop")
      CocoaMessage(0,audio\playerID,"dealloc")
    EndIf
    If audio\tempPath
      If FileSize(audio\tempPath) > -1
        DeleteFile(audio\tempPath,#PB_FileSystem_Force)
      EndIf
    EndIf
    ClearStructure(@audio,audio)
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
  
  Procedure load(path.s,startPlaying = #False)
    Protected FFmpegFailed.b
    Protected tempPath.s
    Protected FFmpeg.i
    If FileSize(path) And isSupportedFile(path)
      cleanUp()
      audio\path = path
      Protected ext.s = LCase(GetExtensionPart(path))
      ForEach formats()
        If formats()\ext = ext
          Select formats()\type
            Case #formatNative
              audio\playerID = CocoaMessage(0,CocoaMessage(0,0,"AVAudioPlayer alloc"),
                                            "initWithContentsOfURL:",CocoaMessage(0,0,"NSURL fileURLWithPath:$",@path),
                                            "error:",#Null)
            Case #formatFFmpeg
              tempPath = GetTemporaryDirectory() + StringFingerprint(Str(Date()),#PB_Cipher_MD5) + ".wav"
              ffmpeg = RunProgram(ffmpegPath,~"-i \"" + path + ~"\" -y -map_metadata -1 -v 0 \"" + tempPath + ~"\"","",#PB_Program_Open)
              If IsProgram(ffmpeg)
                WaitProgram(ffmpeg,5000)
                If ProgramRunning(ffmpeg)
                  KillProgram(ffmpeg)
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
                cleanUp()
                ProcedureReturn #False
              EndIf
              
              audio\playerID = CocoaMessage(0,CocoaMessage(0,0,"AVAudioPlayer alloc"),
                                            "initWithContentsOfURL:",CocoaMessage(0,0,"NSURL fileURLWithPath:$",@tempPath),
                                            "error:",#Null)
          EndSelect
          Break
        EndIf
      Next
    Else
      ProcedureReturn #False
    EndIf
    
    If audio\playerID
      audio\tempPath = tempPath
      Protected duration.d
      CocoaMessage(@duration,audio\playerID,"prepareToPlay")
      CocoaMessage(@duration,audio\playerID,"duration")
      audio\duration = duration * 1000
      If startPlaying
        CocoaMessage(0,audio\playerID,"play")
        audio\isStarted = #True
      EndIf
      audio\initialized = #True
    EndIf
    
    If audio\initialized
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure play()
    If audio\initialized And (audio\isPaused Or Not audio\isStarted)
      audio\isPaused = #False
      audio\isStarted = #True
      CocoaMessage(0,audio\playerID,"play")
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure pause()
    If audio\initialized And Not audio\isPaused
      audio\isPaused = #True
      CocoaMessage(0,audio\playerID,"pause")
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure toggle()
    If audio\initialized
      If audio\isPaused Or Not audio\isStarted
        play()
      Else
        pause()
      EndIf
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure stop()
    If audio\initialized
      CocoaMessage(0,audio\playerID,"pause")
      Define time.d = 0.0
      CocoaMessage(@time,audio\playerID,"setCurrentTime:")
      audio\isStarted = #False
      audio\isPaused = #False
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure free()
    cleanUp()
    ProcedureReturn #True
  EndProcedure
  
  Procedure getCurrentTime()
    If audio\initialized
      Protected position.d
      CocoaMessage(@position,audio\playerID,"currentTime")
      ProcedureReturn(position * 1000)
    EndIf
  EndProcedure
  
  Procedure getDuration()
    ProcedureReturn audio\duration
  EndProcedure
  
  Procedure getPlayerID()
    ProcedureReturn audio\playerID
  EndProcedure
  
  Procedure isPaused()
    ProcedureReturn audio\isPaused
  EndProcedure
  
  Procedure isStarted()
    ProcedureReturn audio\isStarted
  EndProcedure
  
  Procedure.s getPath()
    ProcedureReturn audio\path
  EndProcedure
  
  Procedure.s getTempPath()
    ProcedureReturn audio\tempPath
  EndProcedure
  
  Procedure setFinishEvent(event.i)
    audio\finishEvent = event
    CocoaMessage(0,audio\playerID,"setDelegate:",AVPdelegate)
    ProcedureReturn #True
  EndProcedure
  
  ProcedureC AVAudioPlayerDidFinishPlaying()
    If audio\finishEvent
      audio\isStarted = #False
      PostEvent(audio\finishEvent)
    EndIf
  EndProcedure
  
EndModule