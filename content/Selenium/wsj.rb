require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Nytimes < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
	  :host => "chromium.cs.virginia.edu", #:host => "localhost", #
      :port => 12345,
      :browser => "*chrome",
      :url => "http://blogs.wsj.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_nytimes
    count = 0
    @selenium.execution_delay = "20"
    @selenium.open "/deals/2012/01/09/fresh-low-for-zynga-shares/"
	puts "opened!"
	sleep(8)
	errcount = 0
	while (count<800)
		count = count+1
		#To make sure this page loads first
		while (!@selenium.element? "//div[@id='weatherContent']")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.refresh
		sleep(8)
		errcount = 0
		puts count
	end
  end
end
