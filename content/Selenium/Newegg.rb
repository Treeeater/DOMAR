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
	@selenium.execution_delay = "4000"
	@selenium.open "/"
	count = 0
	while (count<50)
		count = count+1
		while (!@selenium.element? "link=Yuchen Zhou")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Yuchen Zhou"
		#@selenium.wait_for_page_to_load "30000"
		sleep(8)
		while (!@selenium.element? "link=Order History")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Order History"
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "link=Account Settings")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Account Settings"
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "css=a[name=\"&lid=Laptops / Notebooks&lpos=RollOverMenu\"] > span.title")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "css=a[name=\"&lid=Laptops / Notebooks&lpos=RollOverMenu\"] > span.title"
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "//div[@id='cellItem13']/div[2]/ul/li[2]")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "//div[@id='cellItem13']/div[2]/ul/li[2]"
		@selenium.click "id=titleDescriptionID6"
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "css=h2.promo")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "css=h2.promo"
		@selenium.click "css=a[name=\"&lid=AddCartN82E16834152286\"]"
		#@selenium.wait_for_page_to_load "30000"
		while (!@selenium.element? "link=Newegg.com")
			puts "needs refresh!"
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Newegg.com"
		#@selenium.wait_for_page_to_load "30000"
		puts ("Finished test number "+count.to_s)
	end
  end
end
