require "rubygems"
require "spec"
require "mocha"

require File.join(File.dirname(__FILE__), 'spec_helper')

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

  describe "extracting i18n queries" do
    before do
      content = <<-EOS
        <div class="title_gray"><span><%= I18n.t("anetcom.member.projects.new.page_title") %></span></div>
        <%= submit_tag I18n.t('anetcom.member.projects.new.create_project'), :class => 'button' %>
        <%= link_to I18n.t("tog_headlines.admin.publish"), publish_admin_headlines_story_path(story), :class => 'button' %>
        :html => {:title => I18n.t("tog_social.sharing.share_with", :name => shared.name)} 
      EOS
      $stubba = Mocha::Central.new
      @missing_t.stubs(:get_content_of_file_with_i18n_queries).returns(content)
    end

    it "should extract the I18n queries correctly when do" do
      i18n_queries = @missing_t.extract_i18n_queries(nil)
      i18n_queries.should == ["anetcom.member.projects.new.page_title", "anetcom.member.projects.new.create_project", "tog_headlines.admin.publish", "tog_social.sharing.share_with"]
    end

  end

  describe "finding missing translations" do
    before do
      @t_queries = { :fake_file => ["mother", "zoo.bee", "zoo.wasp", "pen"] }
      $stubba = Mocha::Central.new
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