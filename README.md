# pb-macos-audioplayer
A simple wrapper built around internal sound library and macOS AVAudioPlayer for [PureBasic](http://purebasic.com). Totally asynchronous, but not threadsafe. Should support mp3, m4a, aac, wav, aiff, flac and ogg.  

## usage
```
IncludeFile "audioplayer.pbi"
If audioplayer::load("file.mp3")
  Debug audioplayer::getDuration()
  audioplayer::play()
  Delay(5000)
  audioplayer::pause()
  Debug audioplayer::getCurrentTime()
  audioplayer::stop()
EndIf
```