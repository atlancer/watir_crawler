module WatirCrawler
  class Browser < Abstract
    def initialize(timeouts)
      @browser = nil

      @timeouts = {
          :http_client_timeout => 120,
          :implicit_wait => 0,
          :page_load => 100,
          :script_timeout => 10
      }.merge(timeouts)
    end

    def profile
      @browser_profile ||= Selenium::WebDriver::Firefox::Profile.new
      yield @browser_profile if block_given?
      @browser_profile
    end

    def browser
      @browser
    end

    def start
      return if @browser && @browser.exist?

      # See http://code.google.com/p/selenium/wiki/RubyBindings#Timeouts
      http_client = Selenium::WebDriver::Remote::Http::Default.new
      http_client.timeout = @timeouts[:http_client_timeout]

      @browser = Watir::Browser.new :firefox, :profile => profile, :http_client => http_client
      @browser.driver.manage.timeouts.implicit_wait = @timeouts[:implicit_wait]
      @browser.driver.manage.timeouts.page_load = @timeouts[:page_load]
      @browser.driver.manage.timeouts.script_timeout = @timeouts[:script_timeout]
    end

    def stop
      @browser.close if @browser
    end
  end
end
