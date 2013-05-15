# encoding: UTF-8   
require 'find'
require 'fileutils'

include FileUtils::Verbose
SourceDirOgg = "./S-OGG/"
SourceDirFlac = "./S-FLAC/"
ToolsDir = "./Tools/"
DestDir = "./Converted/"

def convertDir(SourceDir, extReg, pathProc = nil)
  Find.find(SourceDir) do |path|
    if !FileTest.directory?(path)
      if path =~ extReg
        destpath = path
        if(pathProc != nil)
          destpath = pathProc.call(destpath)
        end
        unless File.exists?(destpath)
          yield(path, destpath)
        else
          puts("Skipping File \"" + path + "\" already found converted.")
        end
      end
    end
  end
end

def convertDirMP3(SourceDir, extReg, dirReg)
  renameProc = Proc.new do |path|
    mp3path = path.gsub(extReg, '.mp3')
    mp3path = mp3path.gsub(dirReg, 'Converted')
    mp3path
  end
  convertDirReg(SourceDir, extReg, renameProc) do |path, mp3path|
    wavpath = path.gsub(extReg, '.wav')

    puts("Converting File \"" + path + "\".")
    mp3dir, mp3file = File.split(mp3path)
    makedirs(mp3dir)
    $Tags = yield(path)
    $TrackTitle = ""
    $TrackArtist = ""
    $TrackAlbum = ""
    $TrackNumber = ""
    $Tags.each_line do |tag|
      case tag
      when /TITLE=(.*)/i; $TrackTitle = $1
      when /ARTIST=(.*)/i; $TrackArtist = $1
      when /ALBUM=(.*)/i; $TrackAlbum = $1
      when /TRACKNUMBER=(.*)/i; $TrackNumber = $1
      end
    end

    print path

    print (ToolsDir + "lame --tt \"" + $TrackTitle + "\" --ta \"" + $TrackArtist + "\" --tl \"" + $TrackAlbum + "\" --tn " + $TrackNumber + " " + "\"" + wavpath + "\" \"" + mp3path + ".tmp\"\n")
    system (ToolsDir + "lame --tt \"" + $TrackTitle + "\" --ta \"" + $TrackArtist + "\" --tl \"" + $TrackAlbum + "\" --tn \"" + $TrackNumber + "\" " + "\"" + wavpath + "\" \"" + mp3path + ".tmp\"")
    File.delete wavpath
    File.rename(mp3path+".tmp", mp3path)
    puts(wavpath)
  end
end

convertDirMP3(SourceDirFlac, /\.flac$/i, /S-FLAC/i) do |path|
  print (ToolsDir + "flac -d -f " + "\"" + path + "\"\n")
  system (ToolsDir + "flac -d -f " + "\"" + path + "\"")
  #system(ToolsDir + "metaflac --export-tags-to=Tags.tmp " + "\"" + path + "\"")
  IO.popen(ToolsDir + "metaflac --show-tag=artist --show-tag=title --show-tag=album --show-tag=tracknumber " + "\"" + path + "\"", "r")
end

convertDirMP3(SourceDirOgg, /\.ogg$/i, /S-OGG/i) do |path|
  print (ToolsDir + "oggdec " + "\"" + path + "\"\n")
  system (ToolsDir + "oggdec " + "\"" + path + "\"")
  IO.popen(ToolsDir + "ogginfo " + "\"" + path + "\"", "r")
end
