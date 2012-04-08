module Dao

class Upload
  class << Upload
    def url
      @url ||= (
        if defined?(Rails.root) and Rails.root
          '/system/dao/uploads'
        else
          "file:/#{ root }"
        end
      )
    end

    def url=(url)
      @url = '/' + Array(url).join('/').squeeze('/').sub(%r|^/+|, '').sub(%r|/+$|, '')
    end

    def root
      @root ||= (
        if defined?(Rails.root) and Rails.root
          File.join(Rails.root, 'public', Upload.url)
        else
          Dir.tmpdir
        end
      )
    end

    def root=(root)
      @root = File.expand_path(root)
    end

    def uuid
      Dao.uuid
    end

    def tmpdir(&block)
      tmpdir = File.join(root, uuid)
      if block
        FileUtils.mkdir_p(tmpdir)
        block.call(tmpdir)
      else
        tmpdir
      end
    end

    def cleanname(path)
      basename = File.basename(path.to_s)
      CGI.unescape(basename).gsub(%r/[^0-9a-zA-Z_@)(~.-]/, '_').gsub(%r/_+/,'_')
    end

    def hidden_key_for(*key)
      Dao.key_for('uploads', *key)
    end

    def finalizer(object_id)
      if fd = IOs[object_id]
        ::IO.for_fd(fd).close rescue nil
        IOs.delete(object_id)
      end
    end

    UUIDPattern = %r/^[a-zA-Z0-9-]+$/io
    Age = 60 * 60 * 24

    def clear!(options = {})
      return if Upload.turd?

      glob = File.join(root, '*')
      age = Integer(options[:age] || options['age'] || Age)
      since = options[:since] || options['since'] || Time.now

      Dir.glob(glob) do |entry|
        begin
          next unless test(?d, entry)
          next unless File.basename(entry) =~ UUIDPattern

          files = Dir.glob(File.join(entry, '**/**'))

          all_files_are_old =
            files.all? do |file|
              begin
                stat = File.stat(file)
                file_age = since - stat.atime
                file_age >= age
              rescue
                false
              end
            end

          FileUtils.rm_rf(entry) if all_files_are_old
        rescue
          next
        end
      end
    end

    at_exit{ Upload.clear! }

    def turd?
      @turd ||= !!ENV['DAO_UPLOAD_TURD']
    end

    def name_for(key, &block)
      if block
        @name_for = block
      else
        defined?(@name_for) ? @name_for.call(key) : [prefix, *Array(key)].compact.join('.')
      end
    end

    def prefix(*value)
      @prefix = value.shift if value
      @prefix
    end

    def prefix=(value)
      @prefix = value
    end

    def rewind(io, &block)
      begin
        pos = io.pos
        io.flush
        io.rewind
      rescue
        nil
      end

      begin
        block.call
      ensure
        begin
          io.pos = pos
        rescue
          nil
        end
      end
    end

    alias_method('mount', 'new')

    attr_accessor :placeholder
  end

  attr_accessor :conducer
  attr_accessor :key
  attr_accessor :options
  attr_accessor :hidden_key
  attr_accessor :name
  attr_accessor :value
  attr_accessor :path
  attr_accessor :dirname
  attr_accessor :basename
  attr_accessor :io
  attr_accessor :placeholder

  IOs = {}

  def initialize(conducer, *args, &block)
    @conducer = conducer
    
    @options = Map.options_for!(args)

    @key = Dao.key_for(args)
    @hidden_key = Upload.hidden_key_for(@key)

    @name = Upload.name_for(@hidden_key)

    @placeholder = @options[:placeholder] || Upload.placeholder

    @conducer.attributes.set(@key, upload=self)

    @path = nil
    @dirname, @basename = nil
    @value = nil
    @io = nil
  end

  def _set(value)
    if value.respond_to?(:read) or value.is_a?(IO)
      process_currently_uploaded(value)
    else
      process_previously_uploaded(value)
    end
  end

  def _key
    key
  end

  def _value
    path
  end

  def _clear
    clear!
  end

  def process_currently_uploaded(value)
    Upload.tmpdir do |tmp|
      original_basename =
        [:original_path, :original_filename, :path, :filename].
          map{|msg| value.send(msg) if value.respond_to?(msg)}.
          compact.
          first

      basename = Upload.cleanname(original_basename)

      path = File.join(tmp, basename)

      copied = false

      Upload.rewind(value) do
        src = value.path
        dst = path

        strategies = [
          proc{ `ln -f #{ src.inspect } #{ dst.inspect } || cp -f #{ src.inspect } #{ dst.inspect }`},
          proc{ FileUtils.ln(src, dst) },
          proc{ FileUtils.cp(src, dst) },
          proc{ 
            open(dst, 'wb'){|fd| fd.write(value.read)} 
          }
        ]

        FileUtils.rm_f(dst)
        strategies.each do |strategy|
          strategy.call rescue nil
          break if((copied = test(?e, dst)))
        end
      end

      raise("failed to copy #{ value.path.inspect } -> #{ path.inspect }") unless copied

      gcopen(path) if test(?s, path)
    end
  end

  def process_previously_uploaded(value)
    value = value.to_s.strip
    unless value.empty?
      dirname, basename = File.split(File.expand_path(value))
      relative_dirname = File.basename(dirname)
      relative_basename = File.join(relative_dirname, basename)
      path = Upload.root + '/' + relative_basename

      gcopen(path) if test(?s, path)
    end
  end

  def hidden_value
    @value
  end

  def gcopen(path)
    @path = path
    @dirname, @basename = File.split(@path)
    @value = File.join(File.basename(@dirname), @basename).strip
    @io = open(@path, 'rb')
    IOs[object_id] = @io.fileno
    ObjectSpace.define_finalizer(self, Upload.method(:finalizer).to_proc)
    @io
  end

  def inspect
    {
      Upload.name =>
        {
          :key => key,
          :hidden_key => hidden_key,
          :hidden_value => hidden_value,
          :name => name,
          :path => path,
          :io => io
        }
    }.inspect
  end

  def blank?
    @value.blank?
  end

  def url
    if @value
      File.join(Upload.url, @value)
    else
      @placeholder
    end
  end

  def to_s
    url
  end

  def hidden
    options = Map.for(options)
    options[:type] = :hidden
    options[:name] = @name
    options[:value] = @value
    options[:class] = [options[:class], 'dao hidden upload'].compact.join(' ')
    block ||= proc{}
    input_(options, &block) if @value
  end

  def input(options = {}, &block)
    options = Map.for(options)
    options[:type] = :file
    options[:name] = @name
    options[:class] = [options[:class], 'dao upload'].compact.join(' ')
    block ||= proc{}
    input_(options, &block)
  end

  def clear!(&block)
    result = block ? block.call(@path) : nil 

    unless Upload.turd?
      begin
        FileUtils.rm_rf(@dirname) if test(?d, @dirname)
      rescue
        nil
      ensure
        @io.close rescue nil
        IOs.delete(object_id)
        Thread.new{ Upload.clear! }
      end
    end

    result
  end
  alias_method('clear', 'clear!')
end

end
