module Errors2Html
  VERSION = '1.5.0'

  def Errors2Html.version
    Errors2Html::VERSION
  end

  def Errors2Html.dependencies
    {
      'fattr'      => [ 'fattr'         , ' >= 2.2.1' ],
      'map'        => [ 'map'           , ' >= 6.2.0' ],
      'rails_view' => [ 'rails_view'    , ' >= 1.0.1' ]
    }
  end
    
  begin
    require 'rubygems'
  rescue LoadError
    nil
  end

  Errors2Html.dependencies.each do |lib, dependency|
    gem(*dependency) if defined?(gem)
    require(lib)
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
          index = key.pop if key.last.is_a?(Integer)
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

  module Mixin
    def to_html
      ::Errors2Html.to_html(self)
    end

    def to_s
      to_html
    end
  end
end

##
#
  Errors2HTML = Errors2Html

##
#
  require 'active_model' unless defined?(ActiveModel)

  ActiveModel::Errors.send(:include, Errors2Html::Mixin)

  ActiveModel::Errors.class_eval do
    def inspect(*args, &block)
      to_hash.inspect(*args, &block)
    end
  end

