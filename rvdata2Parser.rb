#! /usr/bin/env ruby

require 'zlib'
require 'RPG'
require 'YAML'

class Table
  def initialize(x, y = 0, z = 0)
     @dim = 1 + (y > 0 ? 1 : 0) + (z > 0 ? 1 : 0)
     @xsize, @ysize, @zsize = x, [y, 1].max, [z, 1].max
     @data = Array.new(x * y * z, 0)
  end
  def [](x, y = 0, z = 0)
     @data[x + y * @xsize + z * @xsize * @ysize]
  end
  def []=(*args)
     x = args[0]
     y = args.size > 2 ? args[1] : 0
     z = args.size > 3 ? args[2] : 0
     v = args.pop
     @data[x + y * @xsize + z * @xsize * @ysize] = v
  end
  def _dump(d = 0)
     [@dim, @xsize, @ysize, @zsize, @xsize * @ysize * @zsize].pack('LLLLL') <<
     @data.pack("S#{@xsize * @ysize * @zsize}")
  end
  def self._load(s)
     size, nx, ny, nz, items = *s[0, 20].unpack('LLLLL')
     t = Table.new(*[nx, ny, nz][0,size])                # The * breaks apart an array into an argument list
     t.data = s[20, items * 2].unpack("S#{items}")
     t
  end
  attr_accessor(:xsize, :ysize, :zsize, :data)
end

class AutoObject
  def method_missing(*args,&b)
    if args.size == 1 
      name = args[0]
      if instance_variable_defined? "@#{name}"
        self.class.send :attr_accessor, name
        send(*args)
      else
        super
      end
    elsif args.size == 2 && args[0].to_s[/=$/]
      name = args[0].to_s[0...-1]
      if instance_variable_defined? "@#{name}"
        self.class.send :attr_accessor, name
        send(*args)
      else
        super
      end
    end
  end
end

def Marshal.auto_load(data)
  Marshal.load(data)
rescue ArgumentError => e
  puts 'marshal'
  puts e
  n = 0
  classname = e.message[%r(^undefined class/module (.+)$), 1]
  raise e unless classname
  
  objectlist = classname.split("::")
  puts "objectlist"
  puts objectlist.inspect
  objectlist.inject(Object) do |outer, inner|
    if inner.nil?
      print "inner is empty \n"
    end
    if outer.nil?
      print "outer is empty \n"
    end
    if !outer.const_defined? inner
      outer.const_set inner, Class.new(AutoObject)
    else
      outer.const_get inner
    end
  end
  retry
end

def YAML.auto_load(data)
  YAML::load(data)
rescue ArgumentError => e
  puts 'yaml '
  puts e
  n = 0
  classname = e.message[%r(^undefined class/module (.+)$), 1]
  raise e unless classname
  
  objectlist = classname.split("::")
  objectlist.inject(Object) do |outer, inner|
    if inner.nil?
      print "inner is empty \n"
    end
    if outer.nil?
      print "outer is empty \n"
    end
    if !outer.const_defined? inner
      outer.const_set inner, Class.new(AutoObject)
    else
      outer.const_get inner
    end
  end
  retry
end


class RvParser
    attr_accessor :type
    attr_reader :target
 
    def initialize(target, type,mode)
        @target = target
        @type = type
        @mode = mode
    end
 
    def unpack
        fielname = File.basename(@target,".rvdata2").dup
        fielname.concat('_exports')
        puts fielname
        exportPath = File.join File.dirname(@target), fielname
        index = []
        puts @mode <=> 'object'
        if !(File.exist?(exportPath)) && (@mode.eql? 'script')
            begin
                Dir.mkdir exportPath
            rescue Exception => e
                raise "error: could not create directory \"#{exportPath}\", please create it personally"
            end
        end
        require 'RPG'
        objectslist = []
        marshalloadded = Marshal.auto_load(File.binread(target))
        # print "Marshal loaded with #{marshalloadded.inspect} \n"
        begin
            marshalloadded.each.with_index do |cont, i|
                id, name, code = cont
                skip = 0
                print "\"#{cont}\" \n"
                #print "\"#{id}\" \n"
                #print "\"#{name}\" \n"
                if (@mode.eql? 'map')
                    objectslist << cont
                    skip = 1
                end
                if !cont.nil? && name.nil? && skip == 0
                    puts "Not a Script"
                    if (@mode.eql? 'object')
                        objectslist << cont
                        #puts cont.inspect
                    end
                end
                if !cont.nil? && !name.nil? && skip == 0
                    name = "#{name}_#{i}" if name.size and index.eql?(name)
                    index.push name
                    next unless name.size
                    next if id.nil? or (code.size == 0)
                    code = Zlib::Inflate.inflate(code).force_encoding("utf-8")
                    File.open(File.join(exportPath, "#{name}.rb"), "wb").write code
                end
            end
        rescue NoMethodError => nme
            skip = 0
            cont = marshalloadded
            if (@mode.eql? 'map') || (@mode.eql? 'object')
                objectslist << cont
                skip = 1
                print "No Method Error \r\n"
            end
        end
        if @mode.eql? 'script'
            File.open(File.join(exportPath, ".index"), "wb").write index.join("\n")
        end
        if objectslist.length > 0
            File.open(fielname.concat(".yaml"), "w") do |file|
              objectslist.each do |object|
                file.puts YAML::dump(object)
                file.puts ""
              end
            end
        end
        puts 'unpack success'
    end
 
    def pack
        if @mode.eql? 'script'
            indexPath = File.join(@target, '.index')
            data = []
            File.read(indexPath).split("\n").each do |name|
                file = File.join(@target, name) + '.rb'
                code = File.exists?(file) ? Zlib::Deflate.deflate(File.read(file)) : ''
                data.push [Random.rand(100000), name, code]
            end
            feilname = File.basename(@target)
            feilname = feilname.split("_")[0]
            targetdum = @target.dup.concat("/")
            feil = targetdum.concat(feilname.concat(".rvdata2"))
            File.open(feil, 'wb') do |f|
                f.puts Marshal.dump data
            end
        end
        if (@mode.eql? 'object')
            array = []
            $/="\n\n"
            File.open(target, "r").each do |object|
              array << YAML::auto_load(object)
            end
            feilname = File.basename(@target)
            feilname = feilname.split("_")[0].concat(".rvdata2")
            dir = Dir.pwd.dup.concat("/")
            feilname = dir.concat(feilname)
            puts feilname
            puts array
            puts array[0].inspect
            File.open(feilname, 'wb') do |f| 
                array.insert(0, nil)
                f.write(Marshal.dump(array))
            end
        end
        if (@mode.eql? 'map')
            array = []
            $/="\n\n"
            File.open(target, "r").each do |object|
              array << YAML::auto_load(object)
            end
            feilname = File.basename(@target)
            feilname = feilname.split("_")[0].concat(".rvdata2")
            dir = Dir.pwd.dup.concat("/")
            feilname = dir.concat(feilname)
            puts feilname
            puts array
            puts array[0].inspect
            File.open(feilname, 'wb') do |f| 
                f.write(Marshal.dump(array[0]))
            end
        end
    end
end
 
begin
    case ARGV[2].to_s
    when 'object'
        puts 'Object Mode'
    when 'script'
        puts 'Script Mode'
    when 'map'
        puts 'Map mode'
    else
        raise 'error: unknown input; please type ruby rvdata2Parser.rb \'topdir/dir/dir2/..../fileordir\' \'unpack/pack\' \'script/object/map\''
    end
    parser = RvParser.new(ARGV[0].to_s,ARGV[1].to_s,ARGV[2].to_s)
    puts ARGV[0].to_s
    puts ARGV[1].to_s
    case parser.type
    when 'unpack'
        parser.unpack
    when 'pack'
        parser.pack
    else
        raise 'error: unknown input; please type ruby rvdata2Parser.rb \'topdir/dir/dir2/..../fileordir\' \'unpack/pack\' \'script/object/map\''
    end
    rescue Exception => e
        puts e
end
