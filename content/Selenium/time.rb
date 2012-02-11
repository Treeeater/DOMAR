require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Yelp < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
      :host => "chromium.cs.virginia.edu",
      :port => 12345,
      :browser => "*chrome",
      :url => "http://www.time.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_yelp
    count = 0
	errcount = 0
	@selenium.open "/time"
	while (count<10000)
		count = count+1
		#@selenium.execution_delay = "3000"
		p count
		@selenium.refresh
		sleep(8)
	end
  end
end
