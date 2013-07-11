require 'find'
require 'fileutils'
require 'pathname'
require 'net/scp'
require 'json'
require 'bencode'

include FileUtils::Verbose

File.open("./config.json", "r") do |infile|
  Conf = JSON.parse(infile.read)
end

WaitDir = Conf["waitDir"]
DoneDir = Conf["doneDir"]
RemoteServer = Conf["torrentServer"]
User = Conf["torrentServerUser"]
Password = Conf["torrentServerPass"]
RemoteDir = Conf["remoteDataDir"]
TmpDir = Conf["tmpDir"]
DataDir = Conf["dataDir"]
MusicDir = Conf["musicDir"]
PlaylistFile = Conf["dropPlaylist"]
ToolsDir = Conf["toolsDir"]

# From Convert-SingleThread
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

def getTags(path)
  ext = File.extname(path).downcase
  tags = nil
  case ext
    when ".flac" then
    tags = flacTags(path)
    tags['Type'] = 'FLAC'
    when ".ogg" then
    tags = oggTags(path)
    tags['Type'] = 'OGG'
  end
  return tags
end

def getFile(file)
  puts "Downloading file #{file}."
  remotePath = RemoteDir + file
  path = TmpDir + file
  FileUtils.mkpath(File.dirname(path))
  Net::SSH.start(RemoteServer, User, {:password => Password}) do |ssh|
    ssh.scp.download! remotePath, path
  end
  puts "Downloaded to #{path}."
  return path
end

def sortAlbum(files)
  dir = ''
  files.each do |file|
    tags = getTags(file)
    if tags != nil
      dir = "S-#{tags['Type']}/#{tags['TrackArtist']}/#{tags['TrackAlbum']}/"
      break
    end
  end
  FileUtils.mkpath(dir)
  album = []
  files.each do |file|
    path = dir + File.basename(file)
    File.rename file, MusicDir + path
    album.push path
    puts "Moved file to #{path}."
  end
  return album
end

def updatePlaylist(album)
  open(PlaylistFile, 'a') do |f|
    album.each do |a|
      f.puts a.gsub('/', '\\')
    end
  end
end

Find.find(WaitDir) do |path|
  if path =~ /\.torrent$/i
    torName = path.match(/([^\/\\]+)\.torrent$/i)[1]

    begin
      data = BEncode.load(File.read(path).force_encoding("binary"))
      files = []
      if data["info"]["files"]
        dir = data["info"]["name"] || ""
        data["info"]["files"].map {|x| files.push(getFile(dir + "/" + x["path"].join("/")))}
      else
        files.push(getFile(data["info"]["name"]))
      end
      files.each do |file|
        leafPath = file.sub(TmpDir, '')
        mpath = DataDir + leafPath
        FileUtils.mkpath(File.dirname(mpath))
        FileUtils.copy_file(file, mpath)
        puts "Put file in #{mpath}."
      end
      album = sortAlbum(files)
      updatePlaylist(album)
      puts "Appended tracks for #{path} to #{PlaylistFile}."
      FileUtils.mkpath(DoneDir)
      finishedPath = DoneDir + File.basename(path)
      File.rename(path, finishedPath)
      puts "Successful sync, moved to #{finishedPath}."
    rescue
      puts "Error on file #{path}"
    end
  end
end
