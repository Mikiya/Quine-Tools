#!/usr/bin/env ruby

require 'optparse'
require 'base64'
require 'zlib'

@scale = 1
opt = OptionParser.new
opt.on('-s=#', Integer, "Scale factor. Default is 1.") {|v| @scale = v }
opt.parse!(ARGV)

if @scale <= 0
  abort "Specify positive scale value."
end

banner = Array.new
while line = gets
  banner << line
end

if banner.size == 0
  abort "Give me a banner from standard input!"
end

banner << ""

width = (banner.max {|a,b| a.size <=>b.size}.size + 1) * @scale
height = banner.size * @scale + 1
banner = banner.map { |s|
  buf = Array.new
  s = s.gsub(/#/, '1' * @scale).gsub(/ /, '0' * @scale).ljust(width, '0')
  @scale.times { buf << s }
  buf
}.flatten.join

bin = Base64.encode64(Zlib::Deflate.deflate(banner)).gsub(/\n/, '')

puts "eval$s=%w'require\"base64\";require\"zlib\";b=\"#{bin}\";n=Zlib::Inflate.inflate(Base64.decode64(b));e=$s*3;o=\"eval$s=%w\"<<39;j=-1;0.upto(#{width}*#{height}-1){|i|o<<((n[i]==\"1\"[0])?e[j+=1]:32);o<<((i%#{width}==#{width-1})?10:\"\")};o[-10,6]=\"\"<<39<<\".join\";puts(o)\#'.join"
