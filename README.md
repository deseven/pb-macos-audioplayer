# pb-macos-audioplayer
A simple wrapper built around macOS AVAudioPlayer for [PureBasic](http://purebasic.com). Totally asynchronous, but NOT threadsafe. Should support mp3, m4a, aac, wav, aiff, alac natively and everything else with the help of [FFmpeg](https://www.ffmpeg.org/).  

## Usage
```
IncludeFile "audioplayer.pbi"
If audioplayer::load(0,"file.mp3")
  Debug "Playing file " + audioplayer::getPath(0)
  Debug "File duration: " + StrD(audioplayer::getDuration(0)) + " sec"
  audioplayer::play(0)
  Delay(5100)
  audioplayer::pause(0)
  Debug "Played: " +  StrD(audioplayer::getCurrentTime(0)) + " sec"
  audioplayer::stop(0)
  audioplayer::free(0)
EndIf
```
For advanced usage check out the included `example.pb`.

## FFmpeg
In order to support additional formats, FFMpeg can be used by defining its path with `audioplayer::setFFmpegPath(path.s)` and needed formats with `audioplayer::addFFmpegFormat(ext.s)`. This is totally optional and the module works with native formats without any external stuff. In case you want to have a portable FFmpeg and use it with your project, here's your options:  
1. You can simply grab FFmpeg from [here](https://evermeet.cx/ffmpeg/).  
2. I made a build script that builds statically-linked (i.e. portable) FFmpeg that can process ape, flac, ogg and wv files, with a binary of just 1.4MB, you can find it [here](https://github.com/deseven/iCanHazMusic/blob/master/build/build-ffmpeg.sh). Also check [the one it's based on](https://github.com/albinoz/ffmpeg-static-OSX/blob/master/ffmpeg-static-OSX.command).  
3. Build it yourself depending on what you need, start [here](https://trac.ffmpeg.org/wiki/CompilationGuide).  

Don't forget to check legal information here - https://www.ffmpeg.org/legal.html