# pb-macos-audioplayer
A simple wrapper built around internal sound library and macOS AVAudioPlayer for [PureBasic](http://purebasic.com). Totally asynchronous, but NOT threadsafe. Should support mp3, m4a, aac, wav, aiff, flac and ogg.  

## usage
```
IncludeFile "audioplayer.pbi"
If audioplayer::load("file.mp3")
  Debug "Playing file " + audioplayer::getPath()
  Debug "File duration: " + Str(audioplayer::getDuration()/1000) + " sec"
  audioplayer::play()
  Delay(5100)
  audioplayer::pause()
  Debug "Played: " +  Str(audioplayer::getCurrentTime()/1000) + " sec"
  audioplayer::stop()
  audioplayer::free()
EndIf
```
For advanced usage check out the included `example.pb`.