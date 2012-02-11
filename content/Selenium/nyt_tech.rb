require "test/unit"
require "rubygems"
gem "selenium-client"
require "selenium/client"

class Nyt_tech < Test::Unit::TestCase

  def setup
    @verification_errors = []
    @selenium = Selenium::Client::Driver.new \
      :host => "chromium.cs.virginia.edu",
      :port => 12345,
      :browser => "*chrome",
      :url => "http://www.nytimes.com/",
      :timeout_in_second => 60

    @selenium.start_new_browser_session
  end
  
  def teardown
    @selenium.close_current_browser_session
    assert_equal [], @verification_errors
  end
  
  def test_Nyt_tech
    @selenium.open "/2011/12/05/technology/xbox-live-challenges-the-cable-box.html?_r=1&ref=technology"
	sleep(4)
	for i in 1..400
		while (!@selenium.element? "css=nyt_text > p")
			@selenium.refresh
			puts "need refresh"
			sleep(4)
		end
		@selenium.click "css=nyt_text > p"
		sleep(1)
		@selenium.click "//div[@id='article']/div/div[6]/p[5]"
		sleep(1)
		@selenium.click "//div[@id='article']/div/div[6]/p[14]"
		sleep(1)
		if (@selenium.element? "//div[@id='MiddleRight']")
			@selenium.mouse_over "//div[@id='MiddleRight']"
			p "flash mouseovered"
			sleep(1)
		end
		if (@selenium.element? "//div[@id='regiLite']/div[2]/form/div")
			@selenium.click "//div[@id='regiLite']/div[2]/form/div"
			p "email clicked"
			sleep(1)
		end
		if (@selenium.element? "//li[@id='mostPopTabMostViewed']")
			@selenium.click "//li[@id='mostPopTabMostViewed']"
			puts "tabmostvisited clicked"
			sleep(1)
		end
		if (@selenium.element? "//li[@id='mostPopTabMostEmailed']")
			@selenium.focus "//li[@id='mostPopTabMostEmailed']"
			@selenium.click "//li[@id='mostPopTabMostEmailed']"
			puts "tabmostemailed clicked"
			sleep(1)
		end
		if (@selenium.element? "//div[@id='adxSponLinkA']")
			@selenium.focus "//div[@id='adxSponLinkA']"
			@selenium.click "//div[@id='adxSponLinkA']"
			p "google ads clicked"
			sleep(1)
		end
		@selenium.refresh
		sleep(4)
		p i
	end
  end
end
