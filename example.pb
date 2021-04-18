EnableExplicit

IncludeFile "audioplayer.pbi"

#playingFinished = #PB_Event_FirstCustomValue

OpenWindow(0,0,0,400,115,"pb-macos-audioplayer example",#PB_Window_SystemMenu|#PB_Window_ScreenCentered)

ButtonGadget(0,5,85,100,25,"Open file")
ButtonGadget(1,105,85,100,25,"Play")
ButtonGadget(2,205,85,100,25,"Stop")
HideGadget(1,#True) : HideGadget(2,#True)

TextGadget(3,10,5,380,60,"File not loaded")
TextGadget(4,10,65,380,20,"Playback stopped")


Repeat
  Define ev = WaitWindowEvent(100)
  audioplayer::checkFinishRoutine() ; needs to be called from time to time if you want the finish event
  If audioplayer::isStarted() And Not audioplayer::isPaused()
    ; can be optimised a lot in terms of resource usage
    ; for example don't update the text if it's not changed
    ; and don't call audioplayer::getCurrentTime() so often
    SetGadgetText(4,"Playing " + FormatDate("%hh:%ii:%ss",audioplayer::getCurrentTime()/1000) + "/" + FormatDate("%hh:%ii:%ss",audioplayer::getDuration()/1000))
  EndIf
  Select ev
    Case #PB_Event_Gadget
      Select EventGadget()
        Case 0 ; open file button
          If audioplayer::load(OpenFileRequester("Choose file to play","","",0))
            HideGadget(1,#False) : HideGadget(2,#False)
            SetGadgetText(3,audioplayer::getPath())
            TextGadget(4,10,65,380,20,"Playback stopped")
            SetGadgetText(1,"Play")
            audioplayer::setFinishEvent(#playingFinished) ; even that will be fired when the track is played to the end
          EndIf
        Case 1 ; play/pause
          audioplayer::toggle()
          If audioplayer::isPaused()
            SetGadgetText(1,"Play")
          Else
            SetGadgetText(1,"Pause")
          EndIf
        Case 2 ; stop
          audioplayer::stop()
          SetGadgetText(1,"Play")
          SetGadgetText(4,"Playback stopped")
      EndSelect
    Case #playingFinished
      audioplayer::free()
      HideGadget(1,#True) : HideGadget(2,#True)
      TextGadget(4,10,65,380,20,"Playback stopped")
      SetGadgetText(3,"File not loaded")
  EndSelect
Until ev = #PB_Event_CloseWindow