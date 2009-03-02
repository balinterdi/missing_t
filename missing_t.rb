require "yaml"
require "forwardable"
require "pp"
require "ruby-debug"

class Hash
  def has_nested_key?(key)
    h = self
    key.to_s.split('.').each do |segment|
      return false unless h.key?(segment)
      h = h[segment]
    end
    true
  end
end

class MissingT
  extend Forwardable
  def_delegators :@translations, :[]
  
  # attr_reader :translations
  
  def initialize
    @translations = Hash.new
  end
  
  # NOTE: this method is needed(?) to be able to
  # able to stub it out
  def translations
    @translations
  end
  
  def add_translations(translations)
    @translations.merge!(translations)    
  end
  
  def collect_translations
    Dir.glob("locales/**/*.yml") do |file|
      add_translations(translations_in_file(file))
    end
  end

  def hashify(strings)
    h = Hash.new
    strings.map { |s| s.split('.') }.
      each do |segmented_string|
        root = h
        segmented_string.each do |segment|
          root[segment] ||= {}
          root = root[segment]
        end
      end
    h
  end
  
  def translations_in_file(yaml_file)
    open(yaml_file) { |f| YAML.load(f.read) }
  end

  def collect_translation_queries
  end
  
  def has_translation?(lang, query)
    t = translations
    (lang + '.' + query).split('.').each do |segment|
      return false unless t.key?(segment)
      t = t[segment]
    end
    true    
  end
  
  def get_missing_translations(lang=nil)
    languages = lang.nil? ? translations.keys : [lang]
    languages.map do |l|
      miss_trs = get_missing_translations_for_lang(l, collect_translation_queries).map do |q|
        "#{l}.#{q}"
      end
    end.flatten
  end
    
  private
    def get_missing_translations_for_lang(lang, queries)
      raise Exception, "There are no translations in #{lang}" unless translations.key?(lang)
      # debugger
      queries.select do |q|
        # pp "XXX Checking if #{translations[lang].inspect} has nested key #{q.inspect}: #{translations[lang].has_nested_key?(q)}"
        !translations[lang].has_nested_key?(q)
      end
    
    end
  
end
