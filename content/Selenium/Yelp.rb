require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Yelp < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
      :host => "localhost",
      :port => 4444,
      :browser => "*chrome",
      :url => "http://www.yelp.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_yelp
	@selenium.execution_delay = "3000"
    @selenium.open "/charlottesville-va"
    @selenium.click "id=about_me"
    @selenium.wait_for_page_to_load "30000"
    @selenium.type "id=find_desc", "Peter Changs China Grill"
    @selenium.click "id=header-search-submit"
    @selenium.wait_for_page_to_load "30000"
=begin
    @selenium.click "//a[@id='bizTitleLink0']/span[3]"
    @selenium.wait_for_page_to_load "30000"
    @selenium.click "//img[@alt=\"Peter Chang's China Grill entrance\"]"
    @selenium.wait_for_page_to_load "30000"
    @selenium.click "id=about_me"
    @selenium.wait_for_page_to_load "30000"
=end
  end
end
