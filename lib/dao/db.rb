# -*- encoding : utf-8 -*-

require 'yaml'
require 'yaml/store'
require 'fileutils'

module Dao
  class Db
    attr_accessor :path

    def initialize(*args)
      options = args.extract_options!.to_options!
      @path = ( args.shift || options[:path] || Db.default_path ).to_s
      FileUtils.mkdir_p(File.dirname(@path)) rescue nil
    end

    def rm_f
      FileUtils.rm_f(@path) rescue nil
    end

    def rm_rf
      FileUtils.rm_rf(@path) rescue nil
    end

    def truncate
      rm_f
    end

    def db
      self
    end

    def ystore
      @ystore ||= YAML::Store.new(path)
    end

    class Collection
      def initialize(name, db)
        @name = name.to_s
        @db = db
      end

      def save(data = {})
        @db.save(@name, data)
      end
      alias_method(:create, :save)
      alias_method(:update, :save)

      def find(id = :all)
        @db.find(@name, id)
      end

      def all
        find(:all)
      end

      def [](id)
        find(id)
      end

      def []=(id, data = {})
        data.delete(:id)
        data.delete('id')
        data[:id] = id
        save(data)
      end

      def delete(id)
        @db.delete(@name, id)
        id
      end
      alias_method('destroy', 'delete')

      def to_hash
        transaction{|y| y[@name]}
      end

      def to_yaml(*args, &block)
        Hash.new.update(to_hash).to_yaml(*args, &block)
      end

      def transaction(*args, &block)
        @db.ystore.transaction(*args, &block)
      end
    end

    def collection(name)
      Collection.new(name, db)
    end
    alias_method('[]', 'collection')

    def method_missing(method, *args, &block)
      if args.empty? and block.nil?
        return self.collection(method)
      end
      super
    end

    def transaction(*args, &block)
      ystore.transaction(*args, &block)
    end

    def save(collection, data)
      data = data_for(data)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        id = next_id_for(collection, data)
        collection[id] = data
        id
      end
    end

    def data_for(data)
      data ? Map.for(data) : nil
    end

    alias_method(:create, :save)

    def find(collection, id = :all, &block)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        if id.nil? or id == :all
          list = collection.values.map{|data| data_for(data)}
          if block
            collection[:all] = list.map{|record| data_for(block.call(record))}
          else
            list
          end
        else
          key = String(id)
          record = data_for(collection[key])
          if block
            collection[key] = data_for(block.call(record))
          else
            record
          end
        end
      end
    end

    def update(collection, id = :all, updates = {})
      data = data_for(data)
      find(collection, id) do |record|
        record.update(updates)
      end
    end

    def delete(collection, id = :all)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        if id.nil? or id == :all
          collection.clear()
        else
          deleted = collection.delete(String(id))
          data_for(deleted) if deleted
        end
      end
    end
    alias_method('destroy', 'delete')

    def next_id_for(collection, data)
      data = data_for(data)
      begin
        id = id_for(data)
        raise if id.strip.empty?
        id
      rescue
        data['id'] = String(collection.size + 1)
        id_for(data)
      end
    end

    def id_for(data)
      data = data_for(data)
      %w( id _id ).each{|key| return String(data[key]) if data.has_key?(key)}
      raise("no id discoverable for #{ data.inspect }")
    end

    def to_hash
      ystore.transaction do |y|
        y.roots.inject(Hash.new){|h,k| h.update(k => y[k])}
      end
    end

    def to_yaml(*args, &block)
      to_hash.to_yaml(*args, &block)
    end

    class << Db
      attr_writer :root
      attr_writer :instance

      def default_root()
        defined?(Rails.root) && Rails.root ? File.join(Rails.root.to_s, 'db') : './db'
      end

      def default_path()
        File.join(default_root, 'db.yml')
      end

      def method_missing(method, *args, &block)
        super unless instance.respond_to?(method)
        instance.send(method, *args, &block)
      end

      def instance
        @instance ||= Db.new(Db.default_path)
      end

      def root
        @root ||= default_root
      end

      def tmp(&block)
        require 'tempfile' unless defined?(Tempfile)
        tempfile = Tempfile.new("#{ Process.pid }-#{ Process.ppid }-#{ Time.now.to_f }-#{ rand }")
        path = tempfile.path
        db = new(:path => path)
        if block
          begin
            block.call(db)
          ensure
            db.rm_rf
          end
        else
          db
        end
      end
    end
  end
end
