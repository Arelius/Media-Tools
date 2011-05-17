# encoding: UTF-8   
require 'find'
require 'fileutils'

include FileUtils::Verbose
SourceDirOgg = "./S-OGG/"
SourceDirFlac = "./S-FLAC/"
ToolsDir = "./Tools/"
DestDir = "./Converted/"

Find.find(SourceDirFlac) do |path|
  if !FileTest.directory?(path)
    if path =~ /\.flac$/i
      wavpath = path.gsub(/\.flac$/i, '.wav')
      mp3path = path.gsub(/\.flac$/i, '.mp3')
      mp3path = mp3path.gsub(/S-FLAC/i, 'Converted')
      unless File.exists?(mp3path)
        puts("Converting File \"" + path + "\".")
        mp3dir, mp3file = File.split(mp3path)
        makedirs(mp3dir)
        print (ToolsDir + "flac -d -f " + "\"" + path + "\"\n")
        system (ToolsDir + "flac -d -f " + "\"" + path + "\"")
        $TrackTitle = ""
        $TrackArtist = ""
        $TrackAlbum = ""
        $TrackNumber = ""
        system(ToolsDir + "metaflac --export-tags-to=Tags.tmp " + "\"" + path + "\"")
        $Tags =  IO.popen(ToolsDir + "metaflac --show-tag=artist --show-tag=title --show-tag=album --show-tag=tracknumber " + "\"" + path + "\"", "r")
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
      else
        puts("Skipping File \"" + path + "\" already found converted.")
      end
    end
  end
end

Find.find(SourceDirOgg) do |path|
  if !FileTest.directory?(path)
    if path =~ /\.ogg$/i
      wavpath = path.gsub(/\.ogg$/i, '.wav')
      mp3path = path.gsub(/\.ogg$/i, '.mp3')
      mp3path = mp3path.gsub(/S-OGG/i, 'Converted')
      unless File.exists?(mp3path)
        puts("Converting File \"" + path + "\".")
        mp3dir, mp3file = File.split(mp3path)
        makedirs(mp3dir)
        system (ToolsDir + "oggdec " + "\"" + path + "\"")
        $TrackTitle = ""
        $TrackArtist = ""
        $TrackAlbum = ""
        $TrackNumber = ""
        $Tags =  IO.popen(ToolsDir + "ogginfo " + "\"" + path + "\"", "r")
        $Tags.each_line do |tag|
          case tag
            when /TITLE=(.*)/i; $TrackTitle = $1
            when /ARTIST=(.*)/i; $TrackArtist = $1
            when /ALBUM=(.*)/i; $TrackAlbum = $1
            when /TRACKNUMBER=(.*)/i; $TrackNumber = $1
          end
        end
        system (ToolsDir + "lame --tt \"" + $TrackTitle + "\" --ta \"" + $TrackArtist + "\" --tl \"" + $TrackAlbum + "\" --tn \" " + $TrackNumber + "\" " + "\"" + wavpath + "\" \"" + mp3path + ".tmp\"")
        File.delete wavpath
        File.rename(mp3path+".tmp", mp3path)
        puts(wavpath)
      else
        puts("Skipping File \"" + path + "\" already found converted.")
      end
    end
  end
end
