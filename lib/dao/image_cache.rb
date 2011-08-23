module Dao
  require 'uuidtools'
  require 'fileutils'
  require 'cgi'

  class ImageCache
    Version = '1.0.0'

    class << ImageCache
      def version
        ImageCache::Version
      end

      def base
        @base ||= 'images/cache'
      end

      def base=(base)
        @base = base.to_s.sub(%r|^/+|, '')
      end

      def url
        '/' + base
      end

      def root
        @root ||= File.join(Rails.root, 'public', base)
      end

      def uuid(*args)
        UUIDTools::UUID.timestamp_create.to_s
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

      def cache_key_for(key)
        "#{ key }__cache"
      end

      def for(params, key = :image)
        image = params[key]
        if image.respond_to?(:read)
          tmpdir do |tmp|
            basename = cleanname(image.original_path)

            path = File.join(tmp, basename)
            open(path, 'w'){|fd| fd.write(image.read)}
            image_cache = new(key, path)
            params[key] = image_cache.io
            return image_cache
          end
        end

        cache_key = cache_key_for(key)
        image_cache = params[cache_key]
        if image_cache
          dirname, basename = File.split(image_cache)
          path = root + '/' + File.join(File.basename(dirname), basename)
          image_cache = new(key, path)
          params[key] = image_cache.io
          return image_cache
        end

        return new(key, path=nil)
      end

      def finalizer(object_id)
        if fd = IOs[object_id]
          IO.for_fd(fd).close
          IOs.delete(object_id)
        end
      end

      UUIDPattern = %r/^[a-zA-Z0-9-]+$/io
      Age = 60 * 60 * 24

      def clear!(options = {})
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
                  age = since - stat.atime
                  age >= Age
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
    end

    attr_accessor :key
    attr_accessor :cache_key
    attr_accessor :path
    attr_accessor :dirname
    attr_accessor :basename
    attr_accessor :value
    attr_accessor :io

    IOs = {}

    def initialize(key, path)
      @key = key.to_s
      @cache_key = ImageCache.cache_key_for(key)

      if path
        @path = path
        @dirname, @basename = File.split(@path)
        @value = File.join(File.basename(@dirname), @basename).strip
        @io = open(@path)
        IOs[object_id] = @io.fileno
        ObjectSpace.define_finalizer(self, ImageCache.method(:finalizer).to_proc)
      else
        @path = nil
        @value = nil
      end
    end

    def hidden
      raw("<input type='hidden' name='#{ @cache_key }' value='#{ @value }' />") if @value
    end

    def to_s
      hidden.to_s
    end

    def url
      File.join(ImageCache.url, @value) if @value
    end

    def raw(*args)
      string = args.join
      if string.respond_to?(:html_safe)
        string.html_safe
      else
        string
      end
    end

    def clear!
      FileUtils.rm_rf(@dirname) if test(?d, @dirname)
    rescue
      nil
    ensure
      if @io
        @io.close
        IOs.delete(object_id)
      end
      Thread.new{ ImageCache.clear! }
    end
  end

  Image_cache = ImageCache unless defined?(Image_cache)

  if defined?(Rails.env)
    unless Rails.env.production?
      if defined?(unloadable)
        unloadable(ImageCache)
        unloadable(Image_cache)
      end
    end
  end
end
