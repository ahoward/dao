module Dao
  module Errors2Html
    class View
      def View.controller(&block)
        controller = ::Current.controller ? ::Current.controller.dup : ::Current.mock_controller
        block ? controller.instance_eval(&block) : controller
      end

      def View.render(*args)
        options = args.extract_options!.to_options!
        args.push(options)

        unless options.has_key?(:layout)
          options[:layout] = false
        end

        Array(View.controller{ render(*args) }).join.html_safe
      end
    end

    def Errors2Html.to_html(*args)
      if args.size == 1
        case args.first
          when Array, String, Symbol
            messages = Array(args.first)
            args = [{:base => messages}]
        end
      end

      args.flatten!
      args.compact!

      at_least_one_error = false

      errors = Map.new
      errors[:global] = []
      errors[:fields] = {} 

      args.each do |e|
        flatten(e).each do |key, messages|
          Array(messages).each do |message|
            at_least_one_error = true
            message = message.to_s.html_safe

            if Array(key).join =~ /\A(?:[*]|base)\Z/iomx
              errors.global.push(message).uniq!
            else
              (errors.fields[key] ||= []).push(message).uniq!
            end
          end
        end
      end

      return "" unless at_least_one_error

      locals = {
        :errors => errors,
        :global_errors => errors.global,
        :fields_errors => errors.fields
      }

      if template
        View.render(:template => template, :locals => locals, :layout => false)
      else
        View.render(:inline => inline, :locals => locals, :layout => false)
      end
    end

    def Errors2Html.flatten(hashlike)
      case hashlike
        when Map
          hash = Hash.new
          hashlike.depth_first_each do |key, value|
            _ = key.pop if key.last.is_a?(Integer)
            (hash[key] ||= []).push(value)
          end
          hash
        else
          hashlike.respond_to?(:to_hash) ? hashlike.to_hash : hashlike
      end
    end

    Fattr(:inline) do
      <<-erb
        <div class="errors2html errors-summary">
          <h4 class="errors-caption">Sorry, we encountered some errors:</h4>

          <% unless errors.global.empty?  %>

            <ul class="errors-global-list">
              <% errors.global.each do |message| %>
                <li class="errors-message">
                  <%= message %>
                </li>
              <% end %>
            </ul>
          <% end %>

          <% unless errors.fields.empty?  %>

            <dl class="errors-fields-list">
              <% 
                errors.fields.each do |key, messages|
                  title = Array(key).join(" ").titleize
              %>
                <dt class="errors-title">
                  <%= title %>
                </dt>
                <% Array(messages).each do |message| %>
                  <dd class="errors-message">
                    <%= message %>
                  </dd>

                <% end %>
              <% end %>
            </dl>
          <% end %>
        </div>
      erb
    end

    Fattr(:template){ nil }
  end

  ##
  #
    Errors2HTML = Errors2Html
end
