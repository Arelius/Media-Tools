require 'find'
require 'fileutils'
require 'pathname'
require 'net/scp'
require 'json'
require 'bencode'

File.open("./config.json", "r") do |infile|
  Conf = JSON.parse(infile.read)
end

WaitDir = Conf["waitDir"]
RemoteServer = Conf["torrentServer"]
User = Conf["torrentServerUser"]
Password = Conf["torrentServerPass"]

Find.find(WaitDir) do |path|
  if path =~ /\.torrent$/i

    data = BEncode.load(File.read(path).force_encoding("binary"))

    if data["info"]["files"]
      dir = data["info"]["name"] || ""
      data["info"]["files"].map {|x| puts(dir + "/" + x["path"].join("/"))}
    else
      puts data.keys
      puts data["info"]["name"]
      puts data["info"]["md5sum"]
    end
  end
end
