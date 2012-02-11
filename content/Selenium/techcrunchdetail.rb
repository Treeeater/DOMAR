require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Nytimes < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
	  :host => "chromium.cs.virginia.edu", #:host => "localhost", #
      :port => 12340,
      :browser => "*chrome",
      :url => "http://www.techcrunch.com/",
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
    @selenium.open "/2012/02/02/visualizing-facebooks-media-store-how-big-is-100-petabytes/"
	puts "opened!"
	sleep(60)
	errcount = 0
	while (count<2000)
		count = count+1
		#To make sure this page loads first
		while (!@selenium.element? "//img[@id='site-logo-cutout']")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 200) 
				exit 2
			end
			@selenium.refresh
			sleep(60)
		end
		@selenium.refresh
		sleep(60)
		errcount = 0
		puts count
	end
  end
end
