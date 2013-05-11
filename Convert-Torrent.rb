# encoding: UTF-8   
require 'find'
require 'fileutils'

include FileUtils::Verbose
SourceDirFlac = "./Torrents/New/The Lion King (Special Edition) (2003) - FLAC/"
ToolsDir = "./Tools/"

TranscodeMap = {"MP3 V0" => "-V 0 --vbr-new",
                "MP3 V2" => "-V 2 --vbr-new",
                "MP3 320" => "-b 320 -h"}

Find.find(SourceDirFlac) do |path|
  if !FileTest.directory?(path)
    if path =~ /\.flac$/i
      wavpath = path.gsub(/\.flac$/i, '.wav')

      puts("Converting File \"" + path + "\".")

      print (ToolsDir + "flac -d -f " + "\"" + path + "\"\n")
      system (ToolsDir + "flac -d -f " + "\"" + path + "\"")
      $TrackTitle = ""
      $TrackArtist = ""
      $TrackAlbum = ""
      $TrackNumber = ""
      system(ToolsDir + "metaflac --export-tags-to=Tags.tmp " + "\"" + path + "\"")
      $Tags = IO.popen(ToolsDir + "metaflac --show-tag=artist --show-tag=title --show-tag=album --show-tag=tracknumber " + "\"" + path + "\"", "r")
        $Tags.each_line do |tag|
          case tag
            when /TITLE=(.*)/i; $TrackTitle = $1
            when /ARTIST=(.*)/i; $TrackArtist = $1
            when /ALBUM=(.*)/i; $TrackAlbum = $1
            when /TRACKNUMBER=(.*)/i; $TrackNumber = $1
          end
        end

      TranscodeMap.each do |type, transcode|
      
        mp3path = path.gsub(/\.flac$/i, '.mp3')
        mp3path = mp3path.gsub(/FLAC/i, type)
        unless File.exists?(mp3path)
          mp3dir, mp3file = File.split(mp3path)
          makedirs(mp3dir)
          print path
          
          $Transcode = ToolsDir + "lame #{transcode} --tt \"#{$TrackTitle}\" --ta \"#{$TrackArtist}\" --tl \"#{$TrackAlbum}\" --tn #{$TrackNumber} \"#{wavpath}\" \"#{mp3path}.tmp\""
          print ($Transcode + "\n")
          system ($Transcode)
          File.rename(mp3path+".tmp", mp3path)
          puts(wavpath)
        else
          puts("Skipping File \"" + path + "\" already found converted.")
        end
      end

      File.delete wavpath
    end
  end
end

