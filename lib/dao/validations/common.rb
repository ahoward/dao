# -*- encoding : utf-8 -*-
module Dao
  module Validations
    module Common
      def validates_length_of(*args)
        options = Map.options_for!(args)

        message = options[:message]

        if options[:in].is_a?(Range)
          options[:minimum] = options[:in].begin
          options[:maximum] = options[:in].end
        end
        minimum = options[:minimum] || options[:min] || 1
        maximum = options[:maximum] || options[:max]

        exact = options[:value] || options[:exact] || options[:exactly] || options[:is]
        if exact
          minimum = maximum = exact
        end

        too_short = options[:too_short] || message || 'is too short'
        too_long = options[:too_long] || message || 'is too long'

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        minimum = Float(minimum)
        maximum = Float(maximum) if maximum

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip unless(value.respond_to?(:empty?) and value.respond_to?(:size))

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            if value.size < minimum
              m[:message] = too_short
              m[:valid] = false
              throw(:validation, m)
            end

            if(maximum and(value.size > maximum))
              m[:message] = too_long
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        validates(*args, &block)
      end

      alias_method('validates_size_of', 'validates_length_of')

      def validates_word_count_of(*args)
        options = Map.options_for!(args)

        message = options[:message]

        if options[:in].is_a?(Range)
          options[:minimum] = options[:in].begin
          options[:maximum] = options[:in].end
        end
        minimum = options[:minimum] || 1
        maximum = options[:maximum]

        too_short = options[:too_short] || message || 'is too short'
        too_long = options[:too_long] || message || 'is too long'

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        minimum = Float(minimum)
        maximum = Float(maximum) if maximum

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            words = value.split(/\s+/)

            if words.size < minimum
              m[:message] = too_short
              m[:valid] = false
              throw(:validation, m)
            end

            if(maximum and(words.size > maximum))
              m[:message] = too_long
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        validates(*args, &block)
      end

      def validates_inclusion_of(*args)
        options = Map.options_for!(args)

        list = Array(options[:in])
        message = options[:message]
         message ||= "not in #{ list.map{|item| item.inspect}.join(' | ') }"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            unless list.any?{|item| item === value}
              m[:message] = message
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        validates(*args, &block)
      end

      def validates_case_of(*args)
        options = Map.options_for!(args)

        target = [:case, :target, :is, :as].map{|k| options.getopt(k)}.compact.first
        message = options[:message] || "is not a case of #{ target.inspect }"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            if [value].join.strip.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            unless target === value
              m[:message] = message
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        validates(*args, &block)
      end

      def validates_type_of(*args)
        options = Map.options_for(args)
        target = [:case, :target, :is, :as].map{|k| options.getopt(k)}.compact.first
        options[:message] ||= "is not of type #{ target.inspect }"
        args.push(options)
        validates_case_of(*args)
      end

      def validates_value_of(*args)
        options = Map.options_for(args)
        target = [:case, :target, :is, :as].map{|k| options.getopt(k)}.compact.first
        options[:message] ||= "does not have the value #{ target.inspect }"
        args.push(options)
        validates_case_of(*args)
      end

      def validates_as_email(*args)
        options = Map.options_for!(args)

        message = options[:message] || "doesn't look like an email (username@domain.com)"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            parts = value.split(/@/)

            unless parts.size == 2
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        args.push(:message => message)
        validates(*args, &block)
      end

      def validates_as_url(*args)
        options = Map.options_for!(args)

        message = options[:message] || "doesn't look like a url (http://domain.com)"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            parts = value.split(%r|://|)

            unless parts.size >= 2
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        args.push(:message => message)
        validates(*args, &block)
      end

      def validates_as_phone(*args)
        options = Map.options_for!(args)

        message = options[:message] || "doesn't look like a phone number (012.345.6789)"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil? and allow_nil
              m[:valid] = true
              throw(:validation, m)
            end

            value = value.to_s.strip

            if value.empty? and allow_blank
              m[:valid] = true
              throw(:validation, m)
            end

            parts = value.scan(/\d+/)

            unless parts.size >= 1
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        args.push(:message => message)
        validates(*args, &block)
      end

      def validates_presence_of(*args)
        options = Map.options_for!(args)

        message = options[:message] || 'is blank or missing'

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil?
              unless allow_nil
                m[:message] = message
                m[:valid] = false
                throw(:validation, m)
              end
            end

            value = value.to_s.strip

            if value.empty?
              unless allow_blank
                m[:message] = message
                m[:valid] = false
                throw(:validation, m)
              end
            end

            m
          end

        validates(*args, &block)
      end

      def validates_any_of(*args)
        options = Map.options_for!(args)
        list = args + Array(options.delete(:keys)) + Array(options.delete(:or))

        list.each do |_args|
          candidates = list.dup
          candidates.delete(_args)

          message = options[:message] || "(or #{ candidates.map{|candidate| Array(candidate).join('.')}.join(', ') } ) is blank or missing"
          allow_nil = options[:allow_nil]
          allow_blank = options[:allow_blank]

          result = self.result

          block =
            lambda do |value|
              m = Map(:valid => true)
              values = list.map{|key| result.get(key)}
              valid = false
              values.each do |val|
                if val
                  valid = true
                  break
                end

                if val.nil?
                  if allow_nil
                    valid = true
                    break
                  end
                end

                val = val.to_s.strip

                if val.empty?
                  if allow_blank
                    valid = true
                    break
                  end
                end
              end

              unless valid
                if value.nil?
                  unless allow_nil
                    m[:message] = message
                    m[:valid] = false
                    throw(:validation, m)
                  end
                end

                value = value.to_s.strip

                if value.empty?
                  unless allow_blank
                    m[:message] = message
                    m[:valid] = false
                    throw(:validation, m)
                  end
                end
              end

              m
            end
          validates(*_args, &block)
        end
      end

      def validates_all_of(*args)
        options = Map.options_for!(args)
        list = args + Array(options.delete(:keys)) + Array(options.delete(:or))

        list.each do |_args|
          candidates = list.dup
          candidates.delete(_args)

          message = options[:message] || "(and #{ candidates.map{|candidate| Array(candidate).join('.')}.join(', ') } ) is blank or missing"
          allow_nil = options[:allow_nil]
          allow_blank = options[:allow_blank]

          result = self.result

          block =
            lambda do |value|
              m = Map(:valid => true)

              values = list.map{|key| result.get(key)}
              valid = true
              values.each do |val|
                if val
                  break
                end

                if val.nil?
                  unless allow_nil
                    valid = false
                    break
                  end
                end

                val = val.to_s.strip

                if val.empty?
                  unless allow_blank
                    valid = false
                    break
                  end
                end
              end

              unless valid
                if value.nil?
                  unless allow_nil
                    m[:message] = message
                    m[:valid] = false
                    throw(:validation, m)
                  end
                end

                value = value.to_s.strip

                if value.empty?
                  unless allow_blank
                    m[:message] = message
                    m[:valid] = false
                    throw(:validation, m)
                  end
                end
              end

              m
            end
          validates(*_args, &block)
        end
      end

      def validates_confirmation_of(*args)
        options = Map.options_for!(args)


        confirmation_key = args.map{|k| k.to_s}
        last = confirmation_key.pop
        last = "#{ last }_confirmation" unless last =~ /_confirmation$/
        confirmation_key.push(last)

        key = args.map{|k| k.to_s}
        last = key.pop
        last.sub!(/_confirmation$/, '')
        key.push(last)

        message = options[:message] || "does not match #{ key.join('.') }"

        allow_nil = options[:allow_nil]
        allow_blank = options[:allow_blank]

        block =
          lambda do |value|
            m = Map(:valid => true)

            if value.nil?
              unless allow_nil
                m[:message] = message
                m[:valid] = false
                throw(:validation, m)
              end
            end

            value = value.to_s.strip

            if value.empty?
              unless allow_blank
                m[:message] = message
                m[:valid] = false
                throw(:validation, m)
              end
            end

            target = get(key).to_s.strip
            confirmed = target == value

            unless confirmed
              m[:message] = message
              m[:valid] = false
              throw(:validation, m)
            end

            m
          end

        validates(confirmation_key, &block)
      end
    end
  end

  def Validations.add(method_name, &block)
    ::Dao::Validations::Common.module_eval do
      define_method(method_name, &block)
    end
  end
end
