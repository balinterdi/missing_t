require "yaml"
require "optparse"
require "ostruct"
require "forwardable"

class Hash
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

  class FileReader
    def read(file)
      open(File.expand_path(file), "r") do |f|
        yield f.read
      end
    end
  end

  VERSION = "0.3.2"

  include Helpers

  def initialize(reader)
    @reader = reader
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

  def translation_keys
    locales_pathes = ["config/locales/**/*.yml", "vendor/plugins/**/config/locales/**/*yml", "vendor/plugins/**/locale/**/*yml"]
    locales_pathes.each_with_object({}) do |path, translations|
      Dir.glob(path) do |file|
        t = open(file) { |f| YAML.load(f.read) }
        translations.deep_safe_merge!(t)
      end
    end
  end

  def files_with_i18n_queries
    if path = @options.path
      path = path[0...-1] if path[-1..-1] == '/'
      [
        Dir.glob("#{path}/**/*.erb"),
        Dir.glob("#{path}/**/*.haml"),
        Dir.glob("#{path}/**/*.rb")
      ]
    else
      [
        Dir.glob("app/**/*.erb"),
        Dir.glob("app/**/*.haml"),
        Dir.glob("app/**/models/**/*.rb"),
        Dir.glob("app/**/controllers/**/*.rb"),
        Dir.glob("app/**/helpers/**/*.rb")
      ]
    end.flatten
  end

  def extract_i18n_queries(file)
    i18n_query_pattern = /[^\w]+(?:I18n\.translate|I18n\.t|translate|t)\s*\((.*?)[,\)]/
    i18n_query_no_parens_pattern = /[^\w]+(?:I18n\.translate|I18n\.t|translate|t)\s+(['"])(.*?)\1/

    @reader.read(file) do |content|
      ([]).tap do |i18n_message_strings|
        i18n_message_strings << content.scan(i18n_query_pattern).map { |match| match[0].gsub(/['"\s]/, '') }
        i18n_message_strings << content.scan(i18n_query_no_parens_pattern).map { |match| match[1].gsub(/['"\s]/, '') }
      end.flatten
    end
  end

  def translation_queries
    files_with_i18n_queries.each_with_object({}) do |file, queries|
      queries_in_file = extract_i18n_queries(file)
      if queries_in_file.any?
        queries[file] = queries_in_file
      end
    end
    #TODO: remove duplicate queries across files
  end

  def has_translation?(keys, lang, query)
    i18n_label(lang, query).split('.').each do |segment|
      return false unless segment =~ /#\{.*\}/ or (keys.respond_to?(:key?) and keys.key?(segment))
      keys = keys[segment]
    end
    true
  end

  def get_missing_translations(keys, queries, languages)
    languages.each_with_object({}) do |lang, missing|
      get_missing_translations_for_lang(keys, queries, lang).each do |file, queries|
        missing[file] ||= []
        missing[file].concat(queries).uniq!
      end
    end
  end

  def find_missing_translations(lang=nil)
    ts = translation_keys
    get_missing_translations(translation_keys, translation_queries, lang ? [lang] : ts.keys)
  end

  private
    def get_missing_translations_for_lang(keys, queries, lang)
      queries.map do |file, queries_in_file|
        queries_with_no_translation = queries_in_file.select { |q| !has_translation?(keys, lang, q) }
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
