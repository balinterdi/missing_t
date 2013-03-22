require 'spec_helper'

# use mocha for mocking instead of
# Rspec's own mock framework
RSpec.configure do |config|
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

  #TODO: Refactor overcomplicated test setup and thus the actual design of the code
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
      content = %q(<div class="title_gray"><span><%= I18n.t("mycompany.welcome.#{key}") %></span></div>)
      @missing_t.extract_i18n_queries(content).should == [%q(mycompany.welcome.#{key})]
    end

  end

  describe "finding missing translations" do
    before do
      @t_queries = { :fake_file => ["mother", "zoo.bee", "zoo.wasp", "pen"] }
      @missing_t.stubs(:translation_keys).returns(@fr_translations.merge(@es_translations))
      @missing_t.stubs(:translation_queries).returns(@t_queries)
    end

    it "should correctly get missing translations for a specific language" do
      miss_entries = @missing_t.find_missing_translations("fr").map{ |e| e[1] }.flatten
      miss_entries.should include("fr.pen")
      miss_entries.should include("fr.zoo.bee")
    end

    it "should correctly get missing translations" do
      miss_entries = @missing_t.find_missing_translations.map{ |e| e[1] }.flatten
      miss_entries.should include("fr.zoo.bee")
      miss_entries.should include("fr.pen")
      miss_entries.should include("es.zoo.wasp")
      miss_entries.should include("es.mother")
    end
  end

end
