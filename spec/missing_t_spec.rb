require "rubygems"
require "spec"
require "mocha"

require File.join(File.dirname(__FILE__), 'spec_helper')

# use mocha for mocking instead of
# Rspec's own mock framework
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

describe "MissingT" do
  before do
    @missing_t = MissingT.new
    @es_translations =  {"es"=>
      {"zoo"=>{"elephant"=>"elefante", "bear"=>"oso", "lion"=>"leon", "bee" => "abeja"},
       "lamp"=>"lampa",
       "book"=>"libro",
       "handkerchief"=>"panuelo",
       "pen" => "boli"}}
    @fr_translations =  {"fr"=>
      {"zoo"=>{"elephant"=>"elephant", "bear"=>"ours", "lion"=>"lion", "wasp" => "guepe"},
       "lamp"=>"lampe",
       "book"=>"livre",
       "handkerchief"=>"mouchoir",
       "mother" => "mere"}}

    @other_es_translations = { "es" => {"zoo" => {}}}
    @yet_other_es_translations = { "es" => {"zoo" => {"monkey" => "mono", "horse" => "caballo"}}}
  end

  describe "adding translations" do
    before do
      @missing_t.add_translations(@es_translations)
    end

    it "should pick up the new translations" do
      @missing_t.translations.should == @es_translations
    end

    it "should correctly merge different translations" do
      @missing_t.add_translations(@fr_translations)
      @missing_t["fr"]["zoo"].should have_key("wasp")
      @missing_t["fr"].should have_key("mother")
      @missing_t["es"]["zoo"].should have_key("bee")
    end

    it "should not overwrite translations keys" do
      @missing_t.add_translations(@other_es_translations)
      @missing_t["es"]["zoo"].should have_key("bear")
      @missing_t["es"]["zoo"].should have_key("bee")
    end

    it "should add the new translations even if they contain keys already in the translations hash" do
      @missing_t.add_translations(@yet_other_es_translations)
      @missing_t["es"]["zoo"].should have_key("monkey")
      @missing_t["es"]["zoo"].should have_key("bear")
    end

  end

  describe "hashification" do
    before do
      queries = ["zoo.bee", "zoo.departments.food", "zoo.departments.qa", "lamp", "mother", "mother.maiden_name"]
      @queries_hash = @missing_t.hashify(queries)
      @h = { "fr" => { "book" => "livre", "zoo" => {"elephant" => "elephant"} } }
    end

    it "should find a nested key and return it" do
      @h.should have_nested_key('fr.zoo.elephant')
      @h.should have_nested_key('fr.book')
    end

    it "should return false when it does not have a nested key" do
      @h.should_not have_nested_key('fr.zoo.seal')
      @h.should_not have_nested_key('xxx')
    end

    it "an empty hash should not have any nested keys" do
      {}.should_not have_nested_key(:puppy)
    end

    it "should turn strings to hash keys along their separators (dots)" do
      ["zoo", "lamp", "mother"].all? { |k| @queries_hash.key?(k) }.should == true
      ["bee", "departments"].all? { |k| @queries_hash["zoo"].key?(k) }.should == true
      @queries_hash["zoo"]["departments"].should have_key("food")
      @queries_hash["zoo"]["departments"].should have_key("qa")
    end
  end

  describe "the i18n query extracion" do
    before do
      metaclass = class << @missing_t; self; end
      metaclass.instance_eval do
        define_method :get_content_of_file_with_i18n_queries do |content|
          content
        end
      end
    end

    it "should correctly extract the I18n.t type of messages" do
      content = <<-EOS
        <div class="title_gray"><span><%= I18n.t("anetcom.member.projects.new.page_title") %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.page_title"]
    end

    it "should correctly extract the I18n.t type of messages not right after the <%= mark" do
      content = <<-EOS
        <%= submit_tag I18n.t('anetcom.member.projects.new.create_project'), :class => 'button' %>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.create_project"]
    end

    it "should correctly extract the I18n.t type of messages from a link_to" do
      # honestly, I am not sure anymore why this qualifies as a sep. test case
      # but I am sure there was something special about this one :)
      content = <<-EOS
        <%= link_to I18n.t("tog_headlines.admin.publish"), publish_admin_headlines_story_path(story), :class => 'button' %>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["tog_headlines.admin.publish"]
    end

    it "should correctly extract the I18n.t type of messages with an argument in the message" do
      content = <<-EOS
        :html => {:title => I18n.t("tog_social.sharing.share_with", :name => shared.name)}
      EOS
      @missing_t.extract_i18n_queries(content).should == ["tog_social.sharing.share_with"]
    end

    it "should correctly extract the I18n.translate type of messages" do
      content = <<-EOS
        <div class="title_gray"><span><%= I18n.translate("anetcom.member.projects.new.page_title") %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.page_title"]
    end

    it "should correctly extract the t type of messages" do
      content = <<-EOS
        <div class="title_gray"><span><%= t("anetcom.member.projects.new.page_title") %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.page_title"]
    end

    it "should find several messages on the same line" do
      content = <<-EOS
      <div class="title_gray"><span><%= t("anetcom.member.projects.new.page_title") %></span><span>t("anetcom.member.projects.new.page_size")</span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.page_title", "anetcom.member.projects.new.page_size"]
    end

    it "should find messages with a parens-less call" do
      content = <<-EOS
        <div class="title_gray"><span><%= t "anetcom.member.projects.new.page_title" %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == ["anetcom.member.projects.new.page_title"]
    end

    it "should not extract a function call that just ends in t" do
      content = <<-EOS
        <div class="title_gray"><span><%= at(3) %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == []
    end

    it "should find and correctly extract a dynamic key translation message" do
      # @missing_t.stubs(:get_content_of_file_with_i18n_queries).returns(content)
      content = %q(<div class="title_gray"><span><%= I18n.t("mycompany.welcome.#{key}") %></span></div>)
      @missing_t.extract_i18n_queries(content).should == [%q(mycompany.welcome.#{key})]
    end

  end

  describe "finding missing translations" do
    before do
      @t_queries = { :fake_file => ["mother", "zoo.bee", "zoo.wasp", "pen"] }
      @missing_t.stubs(:translations).returns(@fr_translations.merge(@es_translations))
      # @missing_t.stubs(:collect_translation_queries).returns(@t_queries)
    end

    it "should return true if it has a translation given in the I18n form" do
      @missing_t.has_translation?("fr", "zoo.wasp").should == true
      @missing_t.has_translation?("es", "pen").should == true
    end

    it "should return false if it does not have a translation given in the I18n form" do
      @missing_t.has_translation?("fr", "zoo.bee").should == false
      @missing_t.has_translation?("es", "mother").should == false
    end

    describe "of dynamic message strings" do
      it "should return true if it has a translation that matches the fix parts" do
        @missing_t.has_translation?("fr", %q(zoo.#{animal})).should == true
      end

      it "should return false if it does not have a translation that matches all the fix parts" do
        @missing_t.has_translation?("fr", %q(household.#{animal})).should == false
      end
    end

    it "should correctly get missing translations for a spec. language" do
      miss_entries = @missing_t.get_missing_translations(@t_queries, "fr").map{ |e| e[1] }.flatten
      miss_entries.should include("fr.pen")
      miss_entries.should include("fr.zoo.bee")
    end

    it "should correctly get missing translations" do
      miss_entries = @missing_t.get_missing_translations(@t_queries).map{ |e| e[1] }.flatten
      miss_entries.should include("fr.zoo.bee")
      miss_entries.should include("fr.pen")
      miss_entries.should include("es.zoo.wasp")
      miss_entries.should include("es.mother")
    end
  end

end
