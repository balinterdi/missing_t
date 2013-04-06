require "yaml"

#TODO: Should I feel about these 'global' helper functions?
def hashify(strings)
  strings.map { |s| s.split('.') }.each_with_object({}) do |segmented_string, h|
    segmented_string.each do |segment|
      h[segment] ||= {}
      h = h[segment]
    end
  end
end

def print_hash(h, level)
  h.each_pair do |k,v|
    puts %(#{" " * (level*2)}#{k}:)
    print_hash(v, level+1)
  end
end

class Hash
  # idea snatched from deep_merge in Rails source code
  def deep_safe_merge(other_hash)
    self.merge(other_hash) do |key, oldval, newval|
      oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
      newval = newval.to_hash if newval.respond_to?(:to_hash)
      if oldval === Hash
        if newval === Hash
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

  def initialize(options={})
    @reader = options.fetch(:reader, FileReader.new)
    @languages = options[:languages]
    @path = options[:path]
  end

  def run
    missing_translations = collect
    missing_message_strings = missing_translations.values.map { |ms| hashify(ms) }

    missing = missing_message_strings.each_with_object({}) do |h, all_message_strings|
      all_message_strings.deep_safe_merge!(h)
    end

    missing.each do |language, missing_for_language|
      puts
      puts "#{language}:"
      print_hash(missing_for_language, 1)
    end
  end

  def collect
    ts = translation_keys
    #TODO: If no translation keys were found and the languages were not given explicitly
    # issue a warning and bail out
    languages = @languages ? @languages : ts.keys
    get_missing_translations(translation_keys, translation_queries, languages)
  end

  def get_missing_translations(keys, queries, languages)
    languages.each_with_object({}) do |lang, missing|
      get_missing_translations_for_lang(keys, queries, lang).each do |file, queries|
        missing[file] ||= []
        missing[file].concat(queries).uniq!
      end
    end
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

  def files_with_i18n_queries
    if @path
      path = File.expand_path(@path)
      if File.file?(path)
        [@path]
      else
        path.chomp!('/')
        [
          Dir.glob("#{path}/**/*.erb"),
          Dir.glob("#{path}/**/*.haml"),
          Dir.glob("#{path}/**/*.rb")
        ]
      end
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

    @reader.read(File.expand_path(file)) do |content|
      ([]).tap do |i18n_message_strings|
        i18n_message_strings.concat content.scan(i18n_query_pattern).map { |match| match[0].gsub(/['"\s]/, '') }
        i18n_message_strings.concat content.scan(i18n_query_no_parens_pattern).map { |match| match[1].gsub(/['"\s]/, '') }
      end
    end
  end

private

  def get_missing_translations_for_lang(keys, queries, lang)
    queries.map do |file, queries_in_file|
      queries_with_no_translation = queries_in_file.reject { |q| has_translation?(keys, lang, q) }
      if queries_with_no_translation.any?
        [file, queries_with_no_translation.map { |q| i18n_label(lang, q) }]
      end
    end.compact
  end

  def i18n_label(lang, query)
    "#{lang}.#{query}"
  end

end
