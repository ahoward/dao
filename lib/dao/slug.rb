# -*- encoding : utf-8 -*-
module Dao
  class Slug < ::String
    Join = '-'

    def Slug.for(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      join = options[:join]||options['join']||Join
      string = args.flatten.compact.join(join)
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub %r/[^0-9a-zA-Z_-]/, ''}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      new(words.join(join).downcase)
    end
  end
end
