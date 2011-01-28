require 'yaml'
require 'yaml/store'
require 'fileutils'

module Dao
  class Db
    attr_accessor :path

    def initialize(*args)
      options = Dao.options_for!(args)
      @path = (args.shift || options[:path] || './db/dao.yml').to_s
      FileUtils.mkdir_p(File.dirname(@path)) rescue nil
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

      def delete(id)
        @db.delete(@name, id)
      end

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

    def [](name)
      Collection.new(name, db)
    end

    def transaction(*args, &block)
      ystore.transaction(*args, &block)
    end

    def save(collection, data = {})
      data = data_for(data)
      ystore.transaction do |y|
        collection = (y[collection.to_s] ||= {})
        id = next_id_for(collection, data)
        collection[id] = data
        record = collection[id]
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
        defined?(Rails.root) ? File.join(Rails.root.to_s, 'db') : './db'
      end

      def default_path()
        File.join(default_root, 'dao.yml')
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
    end
  end
end
