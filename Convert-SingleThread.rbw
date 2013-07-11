# encoding: UTF-8   
require 'find'
require 'fileutils'

include FileUtils::Verbose
SourceDirOgg = "./S-OGG/"
SourceDirFlac = "./S-FLAC/"
ToolsDir = "./Tools/"
DestDir = "./Converted/"

def flacTags(path)
  tags = {}
  system(ToolsDir + "metaflac --export-tags-to=Tags.tmp " + "\"" + path + "\"")
  ret = IO.popen(ToolsDir + "metaflac --show-tag=artist --show-tag=title --show-tag=album --show-tag=tracknumber " + "\"" + path + "\"", "r")
  ret.each_line do |tag|
    case tag
    when /TITLE=(.*)/i; tags['TrackTitle'] = $1
    when /ARTIST=(.*)/i; tags['TrackArtist'] = $1
    when /ALBUM=(.*)/i; tags['TrackAlbum'] = $1
    when /TRACKNUMBER=(.*)/i; tags['TrackNumber'] = $1
    end
  end
  return tags
end

def oggTags(path)
  tags = {}
  ret = IO.popen(ToolsDir + "ogginfo " + "\"" + path + "\"", "r")
  ret.each_line do |tag|
    case tag
    when /TITLE=(.*)/i; tags['TrackTitle'] = $1
    when /ARTIST=(.*)/i; tags['TrackArtist'] = $1
    when /ALBUM=(.*)/i; tags['TrackAlbum'] = $1
    when /TRACKNUMBER=(.*)/i; tags['TrackNumber'] = $1
    end
  end
  return tags
end

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
        $Tags = flacTags(path)

        print path

        mExec = ToolsDir + "lame --tt \"" + $Tags['TrackTitle'] + "\" --ta \"" + $Tags['TrackArtist'] + "\" --tl \"" + $Tags['TrackAlbum'] + "\" --tn \"" + $Tags['TrackNumber'] + "\" " + "\"" + wavpath + "\" \"" + mp3path + ".tmp\""
        print mExec + "\n"
        system mExec
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
        $Tags = oggTags(path)
        mExecToolsDir + "lame --tt \"" + $Tags['TrackTitle'] + "\" --ta \"" + $Tags['TrackArtist'] + "\" --tl \"" + $Tags['TrackAlbum'] + "\" --tn \" " + $Tags['TrackNumber'] + "\" " + "\"" + wavpath + "\" \"" + mp3path + ".tmp\""
        print mExec + "\n"
        system mExec
        File.delete wavpath
        File.rename(mp3path+".tmp", mp3path)
        puts(wavpath)
      else
        puts("Skipping File \"" + path + "\" already found converted.")
      end
    end
  end
end
