require "yaml"
require "optparse"
require "ostruct"
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

  VERSION = "0.3.1"

  include Helpers
  extend Forwardable
  def_delegators :@translations, :[]

  # attr_reader :translations

  def initialize
    @translations = Hash.new
  end

  def parse_options(args)
    @options = OpenStruct.new
    @options.prefix = nil
    opts = OptionParser.new do |opts|
      opts.on("-f", "--file FILE_OR_DIR",
              "look for missing translations in files under FILE_OR_DIR",
              "(if a file is given, only look in that file)") do |path|
        @options.path = path
      end
    end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end

    opts.on_tail("--version", "Show version") do
      puts VERSION
      exit
    end

    opts.parse!(args)
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
    locales_pathes.each_with_object({}) do |path, translations|
      Dir.glob(path) do |file|
        t = open(file) { |f| YAML.load(f.read) }
        translations.add_translations(translations)
      end
    end
  end

  def files_with_i18n_queries
    if path = @options.path
      path = path[0...-1] if path[-1..-1] == '/'
      [ Dir.glob("#{path}/**/*.erb"), Dir.glob("#{path}/**/*.rb") ]
    else
      [ Dir.glob("app/**/*.erb"),
      Dir.glob("app/**/controllers/**/*.rb"),
      Dir.glob("app/**/helpers/**/*.rb")]
    end.flatten
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
    files_with_i18n_queries.each_with_object({}) do |file, queries|
      queries_in_file = extract_i18n_queries(file)
      if queries_in_file.any?
        queries[file] = queries_in_file
      end
    end
    #TODO: remove duplicate queries across files
  end

  def has_translation?(lang, query)
    t = translations
    i18n_label(lang, query).split('.').each do |segment|
      return false unless segment =~ /#\{.*\}/ or (t.respond_to?(:key?) and t.key?(segment))
      t = t[segment]
    end
    true
  end

  def get_missing_translations(queries, languages)
    languages.each_with_object({}) do |lang, missing|
      get_missing_translations_for_lang(queries, lang).each do |file, queries|
        missing[file] ||= []
        missing[file].concat(queries).uniq!
      end
    end
  end

  def find_missing_translations(lang=nil)
    collect_translations
    get_missing_translations(collect_translation_queries, lang ? [lang] : translations.keys)
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
