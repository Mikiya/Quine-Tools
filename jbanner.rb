#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$KCODE = 'UTF-8'

require 'optparse'
require 'kconv'

class BitmapFile
  def initialize(bdf=nil)
    @bitmaps = Hash.new
    @font = ""
    @font_width = 0
    @font_height = 0
    read_bdf_file(bdf) if bdf
  end

  def print_parser_error(line_no, code, str)
    puts("ERROR at line #{line_no}, CODE(#{code}): #{str}")
  end

  def extract_bitmap(bitmap, char)
    buf = Array.new
    bitmap.each do |b|
      line = ''
      b = b.hex
      (@font_width-1).downto(0) do |i|
        line << (b[i] == 1 ? char[0] : ' '[0])
      end
      buf << line
    end
    buf
  end

  def get_jis_code(c)
    j = [c].pack("U").tojis;
    j[3] * 256 + j[4]
  end

  def get_word_bitmap(w, char='#')
    w.unpack("U*").map {|a| get_jis_code(a)}.map{|c| get_banner_char(c, char) }
  end

  def bitmap_to_s(b, margin=1, char='#')
    out = Array.new
    margin.times { out << "" }
    0.upto(@font_height - 1) do |i|
      line = ""
      b.each do |bb|
        line << (" " * margin) << bb[i]
      end
      out << line
    end
    out
  end

  def get_banner_char(code, char='#')
    b = @bitmaps[code]
    if b.nil?
      b = @bitmaps[2222] # tofu
      if b.nil?
        return nil
      end
    end
    extract_bitmap(b, char)
  end

  def print_banner(w, margin=1, char='#')
    data = get_word_bitmap(w)
    puts bitmap_to_s(data, margin, '#')
  end

  def read_bdf_file(bdf)
    buf = Array.new
    in_bitmap = false
    code = 0
    n = 0
    open(bdf) do |f|
      while line = f.gets
        case
        when line =~ /^BBX\s+(\d+)\s+(\d+)/
          @font_width = $1.to_i
          @font_height = $2.to_i
        when line =~ /^STARTCHAR\s+(\w+)/
          code = $1.hex
        when line =~ /^BITMAP/
          in_bitmap = true
        when line =~ /^ENDCHAR/
          if code == 0
            print_parser_error(n, code, "code is not set.")
          end
          if @font_height != buf.size
            print_parser_error(n, code, "Incorrect font height.")
          end
          in_bitmap = false
          @bitmaps[code] = buf
          buf = Array.new
        when in_bitmap
          buf.push(line)
        end
        n += 1
      end
    end
  end
end

@width = 8 # in characters
@vertical = false
@bdf = nil
@margin = 1
opt = OptionParser.new

opt.on('-f=file', String, "Bitmap font filename.") {|v|
  if File.exist?(v)
    @bdf = v
  end
}
opt.on('-v', "Print vertically.") { @vertical = true }
opt.on('-n=#', Integer, "Number of characters in a single line.") {|v| @width = v }
opt.on('-m=#', Integer, "Space between characters") {|v| @margin = v }

opt.parse!(ARGV)

if @bdf.nil?
  abort "ERROR: Specify valid bitmap font file."
end

if @width <= 0
  abort "ERROR: Specify a positive integer for width"
end

if @vertical
  @width = 1
end

bitmap = BitmapFile.new(@bdf)

ARGV.each do |v|
  v.split(/\s/).each do |vv|
    bitmap.print_banner(vv, @margin)
  end
end

@margin.times { puts "" }
