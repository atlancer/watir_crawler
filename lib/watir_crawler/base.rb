require 'timeout' # fix error 'uninitialized constant WatirCrawler::Base::Timeout'

module WatirCrawler
  class Base < Abstract
    attr_reader :timeouts

    def initialize(timeouts = {})
      @elements_path = []
      @timeouts = { :wait_timeout => 150 }.merge(timeouts)
      @browser = WatirCrawler::Browser.new(@timeouts)
    end

    def browser_profile
      @browser.profile do |profile|
        yield profile if block_given?
      end
    end

    def browser
      @browser.browser
    end

    def browser_start
      @browser.start
    end

    def browser_stop
      @browser.stop
    end

    def browser_session
      timer do
        catch_error do
          browser_start
          yield
        end
      end
    ensure
      browser_stop
    end

    def timer
      log.info "Session start"
      start_time = Time.now
      yield
    ensure
      log.info "Session end, elapsed time: #{Time.now - start_time}"
    end

    def catch_error
      yield
    rescue Timeout::Error, # http connection with driver
           Selenium::WebDriver::Error::TimeOutError, # browser.driver.manage.timeouts.page_load
           Selenium::WebDriver::Error::ScriptTimeOutError # browser.driver.manage.timeouts.script_timeout

      log.error "Site is too slow at page: '#{browser.url}'"
      raise SiteTooSlow

    rescue SystemCallError, # 'Unknown error - Connection reset by peer'
           Errno::ECONNREFUSED, # 'Connection refused - Connection refused'
           Selenium::WebDriver::Error::WebDriverError => e # 'unable to obtain stable firefox connection in 60 seconds (127.0.0.1:7055)'
                                                           # 'unable to bind to locking port 7054 within 45 seconds'
      messages = [
          /Connection reset by peer/, # SystemCallError
          /Connection refused/, # Errno::ECONNREFUSED
          /unable to obtain stable firefox connection/, # Selenium::WebDriver::Error::WebDriverError
          /unable to bind to locking port/ # Selenium::WebDriver::Error::WebDriverError
      ]

      log "#{e.class}: #{e.message} \n#{e.backtrace.join("\n")}"

      klass = messages.select{|msg| msg =~ e.message }.any? ? WebdriverError : SiteChanged
      raise klass
    end

    # --- commands

    def goto url
      browser.goto url if url != browser.url
    end

    def exec script
      browser.execute_script(script)
    end

  #  #####################################################################################################

    # --------------------------------------------------------------------------------------------------------------------
    def pull *args, &block
      opts, xpaths = args.flatten.partition{|a| a.is_a?(Symbol) }
      opt_mode  =   opts.delete(:exist?) ||  opts.delete(:present?) || :present? # default is :present?
      opt_first = !!opts.delete(:first)  || !opts.delete(:all) # default is true, return 1th element
      raise "Unknown options: '#{opts.inspect}'" if opts.any?

      elements = xpaths.select do |xpath|
        node_for(xpath).send(opt_mode) # detect element on the page by opt_mode
      end.map do |xpath|
        nodes_for(xpath) # get all elements
      end.flatten.select do |node|
        node.send(opt_mode) # select elements by mode
      end

      # flash result nodes
      elements = elements.take(1) if opt_first
      elements.each{|node| node.flash unless node.is_a?(Watir::Frame) }

      first_element = elements.first

      if block
        raise SiteChanged, "Not found elements for xpath: #{xpaths.inspect}" if first_element.nil?
        nodes_path << first_element.node_xpath
        yield
      else
        if opt_first
          first_element && first_element.to_subtype
        else
          elements.map{|element| element.to_subtype }
        end
      end
    rescue Selenium::WebDriver::Error::StaleElementReferenceError,
           Selenium::WebDriver::Error::ObsoleteElementError
      sleep 1
      retry
    ensure
      nodes_path.pop if block
    end

    # --------------------------------------------------------------------------------------------------------------------
    # :first - get FIRST element of FIRST founded xpath, DEFAULT OPTION
    # :all   - get ALL elements of FIRST founded xpath
    def wait *xpaths, &block
      #todo 3 raise_if_site_too_slow if respond_to?(:raise_if_site_too_slow)
      common_wait *xpaths, &block
    end

    # --------------------------------------------------------------------------------------------------------------------
    def common_wait *args, &block
      browser.wait_until(@timeouts[:wait_timeout]) do
        #todo 1 raise_if_firefox_error if respond_to?(:raise_if_firefox_error)
        #todo 2 raise_if_service_unavailable if respond_to?(:raise_if_service_unavailable) # see class method :raise_service_unavailable_if

        if args.any? || block
          pull(args) || (block && instance_eval(&block))
        else
          return nil # running raise_if 1 times and exit if no args & block
        end
      end
    rescue Selenium::WebDriver::Error::StaleElementReferenceError,
           Selenium::WebDriver::Error::ObsoleteElementError
      sleep 1
      retry
    rescue Watir::Wait::TimeoutError
      raise SiteChanged
    end
    # --------------------------------------------------------------------------------------------------------------------

    def exist? xpath
      !!pull(xpath)
    end

    # --------------------------------------------------------------------------------------------------------------------

    private

    def nodes_path
      @nodes_path ||= []
    end

    def node_for xpath
      get_nodes(xpath, :get_all => false).first
    end

    def nodes_for xpath
      get_nodes(xpath, :get_all => true)
    end

    def get_nodes xpath, opts
      element_path = xpath_relative?(xpath) ? nodes_path.map { |node_xpath| element_name_for(node_xpath) } : nil
      element_name = element_name_for(xpath, opts[:get_all])

      eval_string = [element_path, element_name].flatten.compact.join('.')

      log "#{File.basename(__FILE__)}:#{__LINE__}, eval_string: " + eval_string.inspect

      elements = browser.instance_eval(eval_string)
      elements = elements.to_a if elements.is_a? Watir::ElementCollection
      elements = [elements].flatten

      elements.map.with_index do |element, index|
        class << element
          attr_accessor :node_xpath
        end

        element.node_xpath = xpath + "[#{index + 1}]"
        element
      end
    end

    def element_name_for xpath, plural = false
      [
          xpath_with_frame?(xpath) ? 'frame' : 'element',
          plural ? 's' : '',
          '(:xpath, "' + xpath + '")'
      ].join
    end

    def xpath_relative? xpath
      xpath =~ /^\.\/.*/ # "./"
    end

    def xpath_with_frame? xpath
      xpath =~ /^[\.]?\/[\/]?[i]?frame.*/ # "//frame", "//iframe", ".//frame", ".//iframe"
    end

  end
end
