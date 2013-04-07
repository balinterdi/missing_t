require_relative '../spec_helper'

describe "MissingT" do
  describe "correctly finds all missing translations" do
    m = MissingT.new({ languages: ["en"], path: "spec/support/new.html.erb" })
    m.collect_missing['spec/support/new.html.erb'].should == {
      "en.flights.new.new_flight" => "",
      "en.flights.new.name" => "Name",
      "en.flights.new.capacity" => "Capacity",
      "en.flights.new.duration" => "Duration",
      "en.flights.new.from" => "From",
      "en.flights.new.to" => "",
      "en.flights.new.create" => "Create",
      "en.flights.new.back" => "Back"
    }
  end
end
