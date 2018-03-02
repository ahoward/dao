# -*- encoding : utf-8 -*-
module Dao
  class Messages < ::Array
    include Tagz.globally

    class << Messages
      include Tagz.globally
    end

    class Message < ::String
      attr_accessor(:type)

      def initialize(string, type = nil)
        super("#{ string }")
      ensure
        @type = type ? "#{ type }" : nil
      end
    end

    attr_accessor :object

    def initialize(*args)
      @object = args.shift
    end

    def Messages.for(object)
      new(object)
    end

    def Messages.to_html(*args, &block)
      if block
        define_method(:to_html, &block)
      else
        at_least_one = false

        html =
          div_(:class => "dao dao-messages"){
            Messages.each(*args) do |message|
              at_least_one = true
              slug = Slug.for(message.type)

              div_(:class => "dao dao-message alert alert-block alert-#{ slug }"){
                tagz << Tagz.html_safe(message) << ' '

                a_(:href => "#", :class => "close", :data_dismiss => "alert", :onClick => "javascript:$(this).closest('div').remove();false;"){
                  Tagz.html_safe('&times;')
                }
              }
            end
          }

        at_least_one ? html : ''
      end
    end

    def to_html(*args)
      Messages.to_html(self)
    end

    def Messages.to_text(*args)
      to_text = []
      Messages.each(*args) do |message|
        to_text.push([message.type, message].compact.join(': '))
      end
      to_text.join("\n")
    end

    def to_text
      Messages.to_text(self)
    end

    def Messages.each(*args, &block)
      args.flatten.compact.each do |arg|
        message = arg.is_a?(Message) ? arg : Message.new(arg)
        block.call(message)
      end
    end

    def to_s(format = :html, *args, &block)
      case format.to_s
        when /html/
          to_html(*args, &block)
        when /text/
          to_text(*args, &block)
      end
    end

    def add(message, type = nil)
      push(Message.new(message, type))
      self
    end

    def method_missing(method, *args, &block)
      if block.nil?
        type = method.to_s
        message = args.join
        add(message, type)
      else
        super
      end
    end
  end
end
