require 'spec_helper'

class ContentReader
  def read(content)
    yield content
  end
end

describe "MissingT" do
  before do
    @missing_t = MissingT.new(reader: ContentReader.new)
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

  describe "the i18n query extracion" do
    describe "when the translation function is called as I18n.t" do
      it "should correctly extract the key" do
        content = <<-EOS
          <div class="title_gray"><span><%= I18n.t("anetcom.member.projects.new.page_title") %></span></div>
        EOS
        @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.page_title" => ""}
      end
      it "should correctly extract the key not right after the <%= mark" do
        content = <<-EOS
          <%= submit_tag I18n.t('anetcom.member.projects.new.create_project'), :class => 'button' %>
        EOS
        @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.create_project" => ""}
      end

      it "should correctly extract the key when there is an argument in the call" do
        content = <<-EOS
          :html => {:title => I18n.t("tog_social.sharing.share_with", :name => shared.name)}
        EOS
        @missing_t.extract_i18n_queries(content).should == {"tog_social.sharing.share_with" => ""}
      end

      it "should find and correctly extract a dynamic key translation message" do
        content = %q(<div class="title_gray"><span><%= I18n.t("mycompany.welcome.#{key}") %></span></div>)
        @missing_t.extract_i18n_queries(content).should == {%q(mycompany.welcome.#{key}) => ""}
      end
    end

    describe "when the translation function is called as t" do
      it "should correctly extract the key" do
        content = <<-EOS
          <div class="title_gray"><span><%= t("anetcom.member.projects.new.page_title") %></span></div>
        EOS
        @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.page_title" => ""}
      end

      it "should find several messages on the same line" do
        content = <<-EOS
          <div class="title_gray"><span><%= t("anetcom.member.projects.new.page_title") %></span><span>t("anetcom.member.projects.new.page_size")</span></div>
        EOS
        @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.page_title" => "", "anetcom.member.projects.new.page_size" => ""}
      end

      it "should find messages with a parens-less call" do
        content = <<-EOS
          <div class="title_gray"><span><%= t "anetcom.member.projects.new.page_title" %></span></div>
        EOS
        @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.page_title" => ""}
      end
    end

    it "should correctly extract the I18n.translate type of messages" do
      content = <<-EOS
        <div class="title_gray"><span><%= I18n.translate("anetcom.member.projects.new.page_title") %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == {"anetcom.member.projects.new.page_title" => ""}
    end

    it "should not extract a function call that just ends in t" do
      content = <<-EOS
        <div class="title_gray"><span><%= at(3) %></span></div>
      EOS
      @missing_t.extract_i18n_queries(content).should == {}
    end

  end
end
