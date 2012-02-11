require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Newegg < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
      :host => "chromium.cs.virginia.edu",
      :port => 12345,
      :browser => "*chrome",
      :url => "http://www.newegg.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_newegg_xml
	@selenium.execution_delay = "3000"
	@selenium.open "/Product/Product.aspx?Item=N82E16834152266"
	#sleep(8)
	count = 0
	while (count<9990)
		count = count+1
		while (!@selenium.element? "//div[@id='logo']")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.refresh
		p count
		#sleep(8)
	end
  end
end
