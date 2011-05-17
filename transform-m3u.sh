cat Default.m3u  | sed s/.flac/.mp3/ | sed s/.ogg/.mp3/ | sed s/S-FLAC/Converted/ | sed s/S-OGG/Converted/ > Default-C.m3u
cat G.m3u  | sed s/.flac/.mp3/ | sed s/.ogg/.mp3/ | sed s/S-FLAC/Converted/ | sed s/S-OGG/Converted/ > G-C.m3u
cat D.m3u  | sed s/.flac/.mp3/ | sed s/.ogg/.mp3/ | sed s/S-FLAC/Converted/ | sed s/S-OGG/Converted/ > D-C.m3u
cat S.m3u  | sed s/.flac/.mp3/ | sed s/.ogg/.mp3/ | sed s/S-FLAC/Converted/ | sed s/S-OGG/Converted/ > S-C.m3u