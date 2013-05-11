require 'find'
require 'fileutils'
require 'pathname'
require 'net/scp'
require 'json'

include FileUtils::Verbose

File.open("./config.json", "r") do |infile|
  Conf = JSON.parse(infile.read)
end

DropDir = Conf["dropDir"]
WaitDir = Conf["waitDir"]
RemoteServer = Conf["torrentServer"]
User = Conf["torrentServerUser"]
Password = Conf["torrentServerPass"]
RemoteDir = Conf["remoteTorrentDir"]

Find.find(DropDir) do |path|
  if path =~ /\.torrent$/i
    basePath = File.basename(path)
    remotePath = RemoteDir + basePath
    waitPath = WaitDir + basePath
    puts "Found file #{path}."
    Net::SSH.start(RemoteServer, User, {:password => Password}) do |ssh|
      ssh.scp.upload! path, remotePath
end
    #Net::SCP.upload!(RemoteServer, User, path, remotePath, {:password=> Password})
    File.rename(path, waitPath)
    puts "Uploaded file #{path}."
  end
end
