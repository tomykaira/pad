# -*- coding: utf-8 -*-
# File.open("pad.app/DATA001.BIN", "rb") do |f|
#   content = f.read
#   p content.index("レッツゴー".force_encoding("ASCII-8BIT"))
#   # puts content[0x00c50370...0x00c65400].force_encoding('utf-8').gsub("\u0000", "\n\n")
#   # p content[0x00c6a8e0...0xc73fa0].force_encoding('utf-8')
# end

File.open("pad.app/DATA002.BIN", "rb") do |f|
  content = f.read
  prev = 0
  start_at = 0

  while start_at = content.index('TEX1', start_at + 1)
    header_raw = content[start_at...(start_at + 0x30)]
    header = header_raw.split(//)
    puts "%d (%d)" % [start_at, start_at - prev]
    prev = start_at
    puts header.map { |x| "%02x" % x.ord }.join(" ")
    puts header[24..(header_raw.index("G\0"))].join("")
  end
end
