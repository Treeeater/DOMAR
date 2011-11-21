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
      :url => "http://www.yelp.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_yelp
    count = 0
	while (count<50)
		count = count+1
		#@selenium.execution_delay = "4000"
		@selenium.open "/charlottesville-va"
		sleep(8)
		while (!@selenium.element? "id=about_me")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "id=about_me"
		sleep(8)
		while ((!@selenium.element? "id=find_desc")||(!@selenium.element? "id=header-search-submit"))
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		#@selenium.wait_for_page_to_load "30000"
		@selenium.type "id=find_desc", "Peter Changs China Grill"
		sleep(1)
		@selenium.click "id=header-search-submit"
		sleep(8)
		while (!@selenium.element? "//a[@id='bizTitleLink0']/span[3]")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		#@selenium.wait_for_page_to_load "30000"
		@selenium.click "//a[@id='bizTitleLink0']/span[3]"
		sleep(8)
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "//img[@alt=\"Peter Chang's China Grill entrance\"]")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "//img[@alt=\"Peter Chang's China Grill entrance\"]"
		sleep(8)
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "id=about_me")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "id=about_me"
		#@selenium.wait_for_page_to_load "30000"
		puts ("Finished test number "+count.to_s)
		sleep(8)
	end
  end
end
