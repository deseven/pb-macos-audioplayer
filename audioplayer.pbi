﻿; pb-macos-audioplayer rev.2
; written by deseven
;
; https://github.com/deseven/pb-macos-audioplayer

DeclareModule audioplayer
  
  Enumeration player
    #None
    #PBSoundLibrary
    #AVAudioPlayer
  EndEnumeration
  
  Declare.b isSupportedFile(path.s)
  Declare.b load(path.s,startPlaying = #False)
  Declare.b play()
  Declare.b pause()
  Declare.b toggle()
  Declare.b stop()
  Declare.b free()
  Declare.i getCurrentTime()
  Declare.i getDuration()
  Declare.b getPlayer()
  Declare.i getPlayerID()
  Declare.b isPaused()
  Declare.b isStarted()
  Declare.s getPath()
  Declare.b setFinishEvent(event.i)
  Declare.b checkFinishRoutine()
  
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
  
  Procedure.b cleanUp()
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
  
  Procedure.b isSupportedFile(path.s)
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
  
  Procedure.b load(path.s,startPlaying = #False)
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
  
  Procedure.b play()
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
  
  Procedure.b pause()
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
  
  Procedure.b toggle()
    If audio\initialized
      If audio\isPaused Or Not audio\isStarted
        play()
      Else
        pause()
      EndIf
      ProcedureReturn #True
    EndIf
  EndProcedure
  
  Procedure.b stop()
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
  
  Procedure.b free()
    cleanUp()
    ProcedureReturn #True
  EndProcedure
  
  Procedure.i getCurrentTime()
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
  
  Procedure.i getDuration()
    ProcedureReturn audio\duration
  EndProcedure
  
  Procedure.b getPlayer()
    ProcedureReturn audio\player
  EndProcedure
  
  Procedure.i getPlayerID()
    ProcedureReturn audio\playerID
  EndProcedure
  
  Procedure.b isPaused()
    ProcedureReturn audio\isPaused
  EndProcedure
  
  Procedure.b isStarted()
    ProcedureReturn audio\isStarted
  EndProcedure
  
  Procedure.s getPath()
    ProcedureReturn audio\path
  EndProcedure
  
  Procedure.b setFinishEvent(event.i)
    audio\finishEvent = event
    If audio\player = #AVAudioPlayer
      CocoaMessage(0,audio\playerID,"setDelegate:",AVPdelegate)
    EndIf
    ProcedureReturn #True
  EndProcedure
  
  Procedure.b checkFinishRoutine()
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