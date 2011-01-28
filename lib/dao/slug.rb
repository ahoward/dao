module Dao
  class Slug < ::String
    def Slug.for(*args)
      string = args.flatten.compact.join('-')
      words = string.to_s.scan(%r/\w+/)
      words.map!{|word| word.gsub(%r/[^0-9a-zA-Z_-]/, '')}
      words.delete_if{|word| word.nil? or word.strip.empty?}
      new(words.join('-').downcase)
    end
  end
end
