require "yaml"
require "forwardable"

class Hash
  def has_nested_key?(key)
    h = self
    key.to_s.split('.').each do |segment|
      return false unless h.key?(segment)
      h = h[segment]
    end
    true
  end

  # idea snatched from deep_merge in Rails source code
  def deep_safe_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      if oldval.class.to_s == 'Hash'
        if newval.class.to_s == 'Hash'
          oldval.deep_safe_merge(newval)
        else
          oldval
        end
      else
        newval
      end
    end
  end

  def deep_safe_merge!(other_hash)
    replace(deep_safe_merge(other_hash))
  end

end

module Helpers
  # snatched from rspec source
  def colour(text, colour_code)
    "#{colour_code}#{text}\e[0m"
  end

  def green(text); colour(text, "\e[32m"); end
  def red(text); colour(text, "\e[31m"); end
  def magenta(text); colour(text, "\e[35m"); end
  def yellow(text); colour(text, "\e[33m"); end
  def blue(text); colour(text, "\e[34m"); end

end

class MissingT
  include Helpers
  extend Forwardable
  def_delegators :@translations, :[]

  # attr_reader :translations

  def initialize
    @translations = Hash.new
  end

  # NOTE: this method is needed
  # because attr_reader :translations
  # does not seem to be stubbable
  def translations
    @translations
  end

  def add_translations(trs)
    translations.deep_safe_merge!(trs)
  end

  def collect_translations
    locales_pathes = ["config/locales/**/*.yml", "vendor/plugins/**/config/locales/**/*yml", "vendor/plugins/**/locale/**/*yml"]
    locales_pathes.each do |path|
      Dir.glob(path) do |file|
        add_translations(translations_in_file(file))
      end
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

  def files_with_i18n_queries
    [ Dir.glob("app/**/*.erb"),
    Dir.glob("app/**/controllers/**/*.rb"),
    Dir.glob("app/**/helpers/**/*.rb")].flatten
  end

  def get_content_of_file_with_i18n_queries(file)
    f = open(File.expand_path(file), "r")
    content = f.read()
    f.close()
    content
  end

  def extract_i18n_queries(file)
    i18n_query_pattern = /[^\w]+(?:I18n\.translate|I18n\.t|translate|t)\s*\((.*?)[,\)]/
    i18n_query_no_parens_pattern = /[^\w]+(?:I18n\.translate|I18n\.t|translate|t)\s+(['"])(.*?)\1/
    file_content = get_content_of_file_with_i18n_queries(file)
    file_content.scan(i18n_query_pattern).map { |match| match.first.gsub(/['"\s]/, '') }.
      concat(file_content.scan(i18n_query_no_parens_pattern).map { |match| match[1].gsub(/['"\s]/, '') })
  end

  def collect_translation_queries
    queries = {}
    files_with_i18n_queries.each do |file|
      queries_in_file = extract_i18n_queries(file)
      unless queries_in_file.empty?
        queries[file] = queries_in_file
      end
    end
    queries
    #TODO: remove duplicate queries across files
  end

  def has_translation?(lang, query)
    t = translations
    i18n_label(lang, query).split('.').each do |segment|
      return false unless (t.respond_to?(:key?) and t.key?(segment))
      t = t[segment]
    end
    true
  end

  def get_missing_translations(queries, lang=nil)
    missing = {}
    languages = lang.nil? ? translations.keys : [lang]
    languages.each do |l|
      get_missing_translations_for_lang(queries, l).each do |file, qs|
        missing[file] ||= []
        missing[file].concat(qs).uniq!
      end
    end
    missing
  end

  def find_missing_translations(lang=nil)
    collect_translations
    get_missing_translations(collect_translation_queries, lang)
  end

  private
    def get_missing_translations_for_lang(queries, lang)
      queries.map do |file, queries_in_file|
        queries_with_no_translation = queries_in_file.select { |q| !has_translation?(lang, q) }
        if queries_with_no_translation.empty?
          nil
        else
          [file, queries_with_no_translation.map { |q| i18n_label(lang, q) }]
        end
      end.compact

    end

    def i18n_label(lang, query)
      "#{lang}.#{query}"
    end

end

if __FILE__ == $0
  # pp MissingT.new.find_missing_translations(ARGV[0]).values.inject(0) { |sum, qs| sum + qs.length }
  @missing_t = MissingT.new
  @missing_t.instance_eval do
    find_missing_translations(ARGV[0]).each do |file, queries|
    puts
    puts "#{file}:"
    puts
    queries.each { |q| puts "    #{red(q)}" }
    end
  end
end
