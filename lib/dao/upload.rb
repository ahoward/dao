module Dao
class Upload < ::Map
  class << Upload
    def url
      @url ||= (
        if defined?(Rails.root) and Rails.root
          '/system/uploads'
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
          root = File.join(Rails.root, 'public', Upload.url)
          FileUtils.mkdir_p(root) unless test(?d, root)
          root
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
      FileUtils.mkdir_p(tmpdir)
      if block
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

    Thread.new do
      Thread.current.abort_on_exception = true

      loop do
        sleep(60 * 60)
        begin
          Upload.clear!
        rescue Object
          nil
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

    def path_for(arg)
      [:original_path, :original_filename, :path, :filename, :pathname].
        map{|msg| arg.send(msg).to_s if arg.respond_to?(msg)}.
        compact.
        first or raise("could not find path_for(#{ arg.inspect })")
    end

    alias_method('mount', 'new')
  end

  attr_accessor :conducer
  attr_accessor :key
  attr_accessor :options
  attr_accessor :hidden_key
  attr_accessor :name
  attr_accessor :value
  attr_reader :path
  attr_accessor :dirname
  attr_accessor :basename
  attr_accessor :io
  attr_accessor :tmpdir

  IOs = {}

  def initialize(conducer, *args, &block)
    @conducer   = conducer

    @options    = Map.options_for!(args)
    @key        = Dao.key_for(args)
    @hidden_key = Upload.hidden_key_for(@key)
    @name       = Upload.name_for(@hidden_key)

    @placeholder = Placeholder.new(@options[:placeholder])

    @path = nil
    @dirname, @basename = nil
    @value = nil
    @io = nil
    @tmpdir = nil

    url = @placeholder.url

    update(:file => @io, :cache => @value, :url => url)
  end

  def _set(value)
    return unless value

    value =
      case
        when value.is_a?(Hash)
          Map.for(value)
        when value.respond_to?(:read)
          Map.for(:file => value)
        else
          Map.for(:cache => value.to_s)
      end

    cache = value[:cache]
    file = value[:file]

    unless cache.blank?
      process_previously_uploaded(cache)
    end

    unless file.blank?
      process_currently_uploaded(file)
    end

    url = @value ? File.join(Upload.url, @value) : @placeholder.url

    update(:file => @io, :cache => @value, :url => url)

    set_path(Upload.path_for(@io)) rescue nil
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

  def hidden_value
    @value
  end

  def blank?
    @value.blank?
  end

  def url
    self[:url]
  end

  def to_s
    self[:url]
  end

  def process_previously_uploaded(cache)
    cache = cache.to_s.strip

    unless cache.empty?
      dirname, basename = File.split(File.expand_path(cache))
      relative_dirname = File.basename(dirname)
      relative_basename = File.join(relative_dirname, basename)
      path = Upload.root + '/' + relative_basename

      if test(?s, path)
        gcopen(path)
        @tmpdir = @dirname
      end
    end
  end

  def process_currently_uploaded(io)
    unless @tmpdir
      @tmpdir = Upload.tmpdir
    end

    original_basename =
      [:original_path, :original_filename, :path, :filename, :pathname].
        map{|msg| io.send(msg).to_s if io.respond_to?(msg)}.
        compact.
        first

    basename = Upload.cleanname(original_basename)

    path = File.join(@tmpdir, basename)

    copied = false

    Upload.rewind(io) do
      src = Upload.path_for(io)
      dst = path

      strategies = [
        proc{ `ln -f #{ src.inspect } #{ dst.inspect } || cp -f #{ src.inspect } #{ dst.inspect }`},
        proc{ FileUtils.ln(src, dst) },
        proc{ FileUtils.cp(src, dst) },
        proc{ 
          open(dst, 'wb'){|fd| fd.write(io.read)} 
        }
      ]

      FileUtils.rm_f(dst)
      strategies.each do |strategy|
        strategy.call rescue nil
        break if((copied = test(?e, dst)))
      end
    end

    raise("failed to copy #{ io.path.inspect } -> #{ path.inspect }") unless copied

    gcopen(path) if test(?s, path)
  end

  def gcopen(path)
    set_path(path)
    @io = open(@path, 'rb')
    IOs[object_id] = @io.fileno
    ObjectSpace.define_finalizer(self, Upload.method(:finalizer).to_proc)
    @io
  end

  def set_path(path)
    if path
      @path = path.to_s.strip
      @dirname, @basename = File.split(@path)
      @value = File.join(File.basename(@dirname), @basename).strip
      @path
    else
      @path, @dirname, @basename, @value = nil
    end
  end

  alias_method('path=', 'set_path')

  def inspect
    {
      Upload.name =>
        {
          :key          => key,
          :hidden_key   => hidden_key,
          :hidden_value => hidden_value,
          :name         => name,
          :path         => path,
          :io           => io
        }
    }.inspect
  end

  def clear!(&block)
    result = block ? block.call(@path) : nil 

    unless Upload.turd?
      begin
        FileUtils.rm_rf(@tmpdir) if test(?d, @tmpdir)
      rescue
        nil
      ensure
        @io.close rescue nil
        IOs.delete(object_id)
      end
    end

    result
  end
  alias_method('clear', 'clear!')

  class Placeholder < ::String
    def Placeholder.route
      "/assets"
    end

    def Placeholder.root
      File.join(Rails.root, "app", "assets", "placeholders")
    end

    attr_accessor :url
    attr_accessor :path

    def initialize(placeholder = '', options = {})
      replace(placeholder.to_s)
      options.to_options!
      @url = options[:url] || default_url
      @path = options[:path] || default_path
    end

    def default_url
      return nil if blank?
      absolute? ? self : File.join(Placeholder.route, self)
    end

    def default_path
      return nil if blank?
      absolute? ? nil : File.join(Placeholder.root, self)
    end

    def basename
      File.basename(self)
    end

    def absolute?
      self =~ %r|\A([^:/]++:/)?/|
    end
  end

  def placeholder
    @placeholder ||= Placeholder.new
  end

  def placeholder=(placeholder)
    @placeholder = placeholder.is_a?(Placeholder) ? placeholder : Placeholder.new(placeholder)
  end
end

end
