#!/usr/bin/env ruby

require 'optparse'
require 'base64'
require 'zlib'

@scale = 1
@xscale = nil
@yscale = nil
@sep = '='
@reverse = false

opt = OptionParser.new
opt.on('-s=#', Integer, "Scale factor. Default is 1.") {|v|
  abort "-s option must be positive value" if v <= 0
  @scale = v
}
opt.on('-x=#', Integer, "Scale factor for width. This overwrites -s option. Default is 1.") {|v|
  abort "-x option must be positive value" if v <= 0
  @xscale = v
}
opt.on('-y=#', Integer, "Scale factor for height. This overwrites -s option. Default is 1.") {|v|
  abort "-y option must be positive value" if v <= 0
  @yscale = v
}
opt.on('-p=#', String, "Separator for multiple message quine. The separator must be a line only includes this string.") {|v|
  @sep = v
}
opt.on('-r', "Reversible.") {|v|
  @reverse = true
}
opt.parse!(ARGV)

@xscale = @scale if @xscale.nil?
@yscale = @scale if @yscale.nil?

banner = Array.new
while line = gets
  banner << line
end

if banner.size == 0
  abort "Give me a banner from standard input!"
end

banner << ""
unless banner[0].size == 0
  banner.unshift("")
end

def separate_banner(banner, sep)
  banners = Array.new
  buf = Array.new
  banner.each do |b|
    if b.chomp == @sep
      banners << buf if buf.size > 0
      buf = Array.new
    else
      buf << b
    end
  end
  banners
end

def enclose(s)
  "\"#{s}\""
end

def make_bitmap(banner, width)
  banner.map { |s|
    buf = Array.new
    case @reverse
    when false
      s = s.chomp.gsub(/#/, '1' * @xscale).gsub(/ /, '0' * @xscale).ljust(width, '0')
    when true
      s = s.chomp.gsub(/#/, '0' * @xscale).gsub(/ /, '1' * @xscale).ljust(width, '1')
    end
    @yscale.times { buf << s }
    buf
  }.flatten.join
end

def deflate(str)
  Base64.encode64(Zlib::Deflate.deflate(str)).gsub(/\n/, '')
end

unless banner.find {|v| v.chomp == @sep}
  width = (banner.max {|a,b| a.size <=>b.size}.size + 1) * @xscale
  height = banner.size * @yscale + 1
  banner = make_bitmap(banner, width)

  bin = deflate(banner)
  puts "eval$s=%w'require\"base64\";require\"zlib\";b=\"#{bin}\";n=Zlib::Inflate.inflate(Base64.decode64(b));o=\"eval$s=%w\"<<39;j=-1;0.upto(#{width}*#{height}-1){|i|o<<((n[i]==#{"1"[0]})?$s[(j+=1)%$s.size]:32);o<<((i%#{width}==#{width-1})?10:\"\")};o[-6,6]=\"\"<<39<<\".join\";puts(o)\#'.join"
else
  w = Array.new
  h = Array.new
  b = Array.new
  banners = separate_banner(banner, @sep)
  banners.each do |banner|
    width = (banner.max {|x,y| x.size <=>y.size}.size + 1) * @xscale
    height = banner.size * @yscale + 1
    w.push(width)
    h.push(height)
    b.push(make_bitmap(banner, width))
  end
#  w = "[#{w.join(',')}]"
#  h = "[#{h.join(',')}]"
#  b = "[#{b.map {|v| enclose(v)}.join(',')}]"
  data = deflate(Marshal.dump([w,h,b]))
#  puts Marshal.load(Zlib::Inflate.inflate(Base64.decode64(deflate(Marshal.dump([w,h,b])))))

  puts "eval$s=%w'x=0;$s[0..2+x.to_s.size]=\"x=\#{(x+1)%#{banners.size}};\";require\"base64\";require\"zlib\";d=Marshal.load(Zlib::Inflate.inflate(Base64.decode64(\"#{data}\")));w=d[0];h=d[1];b=d[2];o=\"eval$s=%w\"<<39;j=-1;0.upto(w[x]*h[x]-1){|i|o<<((b[x][i]==#{"1"[0]})?$s[(j+=1)%$s.size]:32);o<<((i%w[x]==w[x]-1)?10:\"\")};o[-6,6]=\"\"<<39<<\".join\";puts(o)\#'.join"
end
