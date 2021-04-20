; pb-macos-audioplayer rev.2
; written by deseven
;
; https://github.com/deseven/pb-macos-audioplayer

DeclareModule audioplayer
  
  Enumeration player
    #None
    #PBSoundLibrary
    #AVAudioPlayer
  EndEnumeration
  
  Declare isSupportedFile(path.s)
  Declare load(path.s,startPlaying = #False)
  Declare play()
  Declare pause()
  Declare toggle()
  Declare stop()
  Declare free()
  Declare getCurrentTime()
  Declare getDuration()
  Declare getPlayer()
  Declare getPlayerID()
  Declare isPaused()
  Declare isStarted()
  Declare.s getPath()
  Declare setFinishEvent(event.i)
  Declare checkFinishRoutine()
  
EndDeclareModule

Module audioplayer
  
  Structure audio
    initialized.b
    isPaused.b
    isStarted.b
    path.s
    player.b
    playerID.i
    duration.i
    finishEvent.i
  EndStructure
  
  UseFLACSoundDecoder()
  UseOGGSoundDecoder()
  InitSound()
  ImportC "-framework AVKit" : EndImport
  
  DeclareC AVAudioPlayerDidFinishPlaying()
  Define AVPdelegateClass = objc_allocateClassPair_(objc_getClass_("NSObject"),"myDelegateClass",0)
  class_addMethod_(AVPdelegateClass,sel_registerName_("audioPlayerDidFinishPlaying:successfully:"),@AVAudioPlayerDidFinishPlaying(),"v@:@@")
  objc_registerClassPair_(AVPdelegateClass)
  Global AVPdelegate = class_createInstance_(AVPdelegateClass,0)
  
  Global audio.audio
  
  Procedure cleanUp()
    If audio\playerID
      Select audio\player
        Case #PBSoundLibrary
          StopSound(audio\playerID)
          FreeSound(audio\playerID)
        Case #AVAudioPlayer
          CocoaMessage(0,audio\playerID,"stop")
          CocoaMessage(0,audio\playerID,"dealloc")
      EndSelect
    EndIf
    ClearStructure(@audio,audio)
  EndProcedure
  
  Procedure isSupportedFile(path.s)
    path = LCase(GetExtensionPart(path))
    If path = "mp3" Or
       path = "m4a" Or
       path = "aac" Or
       path = "ac3" Or
       path = "wav" Or
       path = "aif" Or
       path = "aiff" Or
       path = "flac" Or
       path = "alac" Or
       path = "ogg" Or
       path = "oga"
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure load(path.s,startPlaying = #False)
    If FileSize(path) And isSupportedFile(path)
      cleanUp()
      Select LCase(GetExtensionPart(path))
        Case "flac","ogg","oga"
          audio\playerID = LoadSound(#PB_Any,path)
          If audio\playerID
            audio\duration = SoundLength(audio\playerID,#PB_Sound_Millisecond)
            If startPlaying
              PlaySound(audio\playerID)
              audio\isStarted = #True
            EndIf
            audio\player = #PBSoundLibrary
            audio\initialized = #True
          EndIf
        Default
          audio\playerID = CocoaMessage(0,CocoaMessage(0,0,"AVAudioPlayer alloc"),
                                        "initWithContentsOfURL:",CocoaMessage(0,0,"NSURL fileURLWithPath:$",@path),
                                        "error:",#Null)
          If audio\playerID
            Protected duration.d
            CocoaMessage(@duration,audio\playerID,"prepareToPlay")
            CocoaMessage(@duration,audio\playerID,"duration")
            audio\duration = duration * 1000
            If startPlaying
              CocoaMessage(0,audio\playerID,"play")
              audio\isStarted = #True
            EndIf
            audio\player = #AVAudioPlayer
            audio\initialized = #True
          EndIf
      EndSelect
      audio\path = path
    EndIf
    If audio\initialized
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure play()
    If audio\initialized And (audio\isPaused Or Not audio\isStarted)
      audio\isPaused = #False
      audio\isStarted = #True
      Select audio\player
        Case #PBSoundLibrary
          Select SoundStatus(audio\playerID)
            Case #PB_Sound_Stopped
              PlaySound(audio\playerID)
            Case #PB_Sound_Paused
              ResumeSound(audio\playerID)
          EndSelect
        Case #AVAudioPlayer
          CocoaMessage(0,audio\playerID,"play")
      EndSelect
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure pause()
    If audio\initialized And Not audio\isPaused
      audio\isPaused = #True
      Select audio\player
        Case #PBSoundLibrary
          Select SoundStatus(audio\playerID)
            Case #PB_Sound_Playing
              PauseSound(audio\playerID)
          EndSelect
        Case #AVAudioPlayer
          CocoaMessage(0,audio\playerID,"pause")
      EndSelect
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
      Select audio\player
        Case #PBSoundLibrary
          StopSound(audio\playerID)
        Case #AVAudioPlayer
          CocoaMessage(0,audio\playerID,"pause")
          Define time.d = 0.0
          CocoaMessage(@time,audio\playerID,"setCurrentTime:")
      EndSelect
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
      Select audio\player
        Case #PBSoundLibrary
          ProcedureReturn GetSoundPosition(audio\playerID,#PB_Sound_Millisecond)
        Case #AVAudioPlayer
          Protected position.d
          CocoaMessage(@position,audio\playerID,"currentTime")
          ProcedureReturn(position * 1000)
      EndSelect
    EndIf
  EndProcedure
  
  Procedure getDuration()
    ProcedureReturn audio\duration
  EndProcedure
  
  Procedure getPlayer()
    ProcedureReturn audio\player
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
  
  Procedure setFinishEvent(event.i)
    audio\finishEvent = event
    If audio\player = #AVAudioPlayer
      CocoaMessage(0,audio\playerID,"setDelegate:",AVPdelegate)
    EndIf
    ProcedureReturn #True
  EndProcedure
  
  Procedure checkFinishRoutine()
    If audio\finishEvent And audio\isStarted And audio\player = #PBSoundLibrary And SoundStatus(audio\playerID) = #PB_Sound_Stopped
      audio\isStarted = #False
      PostEvent(audio\finishEvent)
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  ProcedureC AVAudioPlayerDidFinishPlaying()
    If audio\finishEvent
      audio\isStarted = #False
      PostEvent(audio\finishEvent)
    EndIf
  EndProcedure
  
EndModule