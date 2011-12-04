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
      :url => "http://www.nytimes.com/",
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
    @selenium.open "/"
	puts "opened!"
	sleep(8)
	errcount = 0
	while (count<200)
		count = count+1
		while (!@selenium.element? "link=Today's Paper")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Today's Paper"
		sleep(8)
		while (!@selenium.element? "link=International")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=International"
		sleep(8)
		while (!@selenium.element? "link=Most Popular")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Most Popular"
		sleep(8)
		while (!@selenium.element? "link=Technology")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=Technology"
		sleep(8)
		while (!@selenium.element? "//div[@class=\"storyFollowsLede\"]/h3/a")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "//div[@class=\"storyFollowsLede\"]/h3/a"
		sleep(8)
		while (!@selenium.element? "link=aaa123abc@gmail.com")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "link=aaa123abc@gmail.com"
		sleep(8)
		#To make sure this page loads first
		while (!@selenium.element? "id=NYTLogo")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
=begin
		#To find if the cookie is good, otherwise reenter information needed.
		if (@selenium.element? "id=reauthContinueButton")
			@selenium.type("id=reauthPassword","123456")
			@selenium.click "id=reauthContinueButton"
			sleep(8)
		elsif (@selenium.element? "//div[@class=\"normalizeBlock\"]/input[@type=\"submit\"]")
			@selenium.type("id=reauthPassword","123456")
			@selenium.click("//div[@class=\"normalizeBlock\"]/input[@type=\"submit\"]")
			sleep(8)
		end
		#check if reentered request goes through
		while (!@selenium.element? "//ul[@class=\"refer flush multiline\"]/li/a")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		@selenium.click "//ul[@class=\"refer flush multiline\"]/li/a"
		sleep(8)
		while (!@selenium.element? "id=NYTLogo")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10) 
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
		#To find if the cookie is good, otherwise reenter information needed.
		if (@selenium.element? "id=reauthContinueButton")
			@selenium.type("id=reauthPassword","123456")
			@selenium.click "id=reauthContinueButton"
			sleep(8)
		elsif (@selenium.element? "//div[@class=\"normalizeBlock\"]/input[@type=\"submit\"]")
			@selenium.type("id=reauthPassword","123456")
			@selenium.click("//div[@class=\"normalizeBlock\"]/input[@type=\"submit\"]")
			sleep(8)
		end

		while (!@selenium.element? "id=NYTLogo")
			puts "needs refresh!"
			errcount += 1
			if (errcount > 10)
				exit 2
			end
			@selenium.refresh
			sleep(8)
		end
=end
		@selenium.click "id=NYTLogo"
		sleep(8)
		errcount = 0
		puts count
	end
  end
end
