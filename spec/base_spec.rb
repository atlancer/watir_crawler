describe 'WatirCrawler::Base : ' do
  before(:all) do
    #log_file = File.join('/tmp', 'watir_crawler.log')
    #puts "\nSaving debug log to: '#{log_file}'"
    #WatirCrawler.logger = ::Logger.new(log_file)
    #WatirCrawler.debug = true

    @htmlfile = Htmlfile.new

    @crawler = WatirCrawler::Base.new(:wait_timeout => 3)
    @crawler.browser_start
    @crawler.goto @htmlfile.url
  end

  after(:all) do
    @crawler.browser_stop
    @htmlfile.delete
  end

  # --------------------------------------------------------------------------------------------------------------------

  it 'pull' do
    # unknown option
    begin
      @crawler.pull(:unknown_option)
    rescue => e
      e.should be_a(RuntimeError)
      e.message.should =~ /Unknown option/i
    end

    # not exist tag
    @crawler.pull('//not_exist_tag').should be_nil
    @crawler.pull(:first, '//not_exist_tag').should be_nil
    @crawler.pull(:all, '//not_exist_tag').should =~ []

    # exist tag, :present? mode by default
    @crawler.pull('//div').should be_a(Watir::HTMLElement)
    @crawler.pull(:first, '//div').should be_a(Watir::HTMLElement)

    result = @crawler.pull(:all, '//div')
    result.should be_a(Array)
    result.size.should eq(3)

    # exist tag, :present? mode
    @crawler.pull(:present?, '//div').should be_a(Watir::HTMLElement)
    @crawler.pull(:present?, :first, '//div').should be_a(Watir::HTMLElement)

    result = @crawler.pull(:present?, :all, '//div')
    result.should be_a(Array)
    result.size.should eq(3)

    # exist tag, :exist? mode
    @crawler.pull(:exist?, '//div').should be_a(Watir::HTMLElement)
    @crawler.pull(:exist?, :first, '//div').should be_a(Watir::HTMLElement)

    result = @crawler.pull(:exist?, :all, '//div')
    result.should be_a(Array)
    result.size.should eq(4)

    # hidden tag, :present? mode
    @crawler.pull(:present?, "//div[@id='4']").should be_nil

    result = @crawler.pull(:present?, :all, "//div[@id='4']")
    result.should be_a(Array)
    result.should be_empty

    # hidden tag, :exist? mode
    @crawler.pull(:exist?, "//div[@id='4']").should be_a(Watir::HTMLElement)

    result = @crawler.pull(:exist?, :all, "//div[@id='4']")
    result.should be_a(Array)
    result.size.should eq(1)
  end

  # --------------------------------------------------------------------------------------------------------------------

  it 'wait' do
    @crawler.wait.should be_nil

    # wait without params but with block
    @crawler.wait{ true }.should be_true

    begin
      @crawler.wait{ false }
    rescue => e
      e.should be_a(WatirCrawler::SiteChanged)
    end

    # unknown option
    begin
      @crawler.wait(:unknown_option)
    rescue => e
      e.should be_a(RuntimeError)
      e.message.should =~ /Unknown option/i
    end

    # not exist tag
    begin
      @crawler.wait('//not_exist_tag')
    rescue => e
      e.should be_a(WatirCrawler::SiteChanged)
    end

    # exist tag, :present? mode by default
    @crawler.wait('//div').should be_a(Watir::HTMLElement)

    # exist tag, :present? mode
    @crawler.wait(:present?, '//div').should be_a(Watir::HTMLElement)

    # hidden tag, :present? mode
    begin
      @crawler.wait(:present?, "//div[@id='4']")
    rescue => e
      e.should be_a(WatirCrawler::SiteChanged)
    end

    # exist tag, :exist? mode
    @crawler.wait(:exist?, "//div[@id='1']").should be_a(Watir::HTMLElement)

    # hidden tag, :exist? mode
    @crawler.wait(:exist?, "//div[@id='4']").should be_a(Watir::HTMLElement)
  end

  # --------------------------------------------------------------------------------------------------------------------

  it 'exist?' do
    @crawler.exist?("//div[@id='1']").should be_true
    @crawler.exist?('//not_exist_tag').should be_false
  end

  # --------------------------------------------------------------------------------------------------------------------

  it 'pull for nested elements' do
    @crawler.pull("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
    @crawler.pull(".//span[text()='Test span 1']").should be_a(Watir::HTMLElement)

    result = @crawler.pull(:all, '//span')
    result.should be_a(Array)
    result.size.should eq(2)

    result = @crawler.pull(:all, './/span')
    result.should be_a(Array)
    result.size.should eq(2)

    @crawler.pull("//p[@id='level_1']") do
      @crawler.pull("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
      @crawler.pull(".//span[text()='Test span 1']").should be_nil

      result = @crawler.pull(:all, '//span')
      result.should be_a(Array)
      result.size.should eq(2)

      result = @crawler.pull(:all, './/span')
      result.should be_a(Array)
      result.should be_empty

      @crawler.pull("//p[@id='level_2']") do
        @crawler.pull("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
        @crawler.pull(".//span[text()='Test span 1']").should be_a(Watir::HTMLElement)

        result = @crawler.pull(:all, '//span')
        result.should be_a(Array)
        result.size.should eq(2)

        result = @crawler.pull(:all, './/span')
        result.should be_a(Array)
        result.size.should eq(2)
      end
    end

  end

  it 'wait for nested elements' do
    @crawler.wait("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
    @crawler.wait(".//span[text()='Test span 1']").should be_a(Watir::HTMLElement)

    result = @crawler.wait(:all, '//span')
    result.should be_a(Array)
    result.size.should eq(2)

    result = @crawler.wait(:all, './/span')
    result.should be_a(Array)
    result.size.should eq(2)

    @crawler.pull("//p[@id='level_1']") do
      @crawler.wait("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)

      begin
        @crawler.wait(".//span[text()='Test span 1']")
      rescue => e
        e.should be_a(WatirCrawler::SiteChanged)
      end

      result = @crawler.wait(:all, '//span')
      result.should be_a(Array)
      result.size.should eq(2)

      begin
        @crawler.wait('.//span')
      rescue => e
        e.should be_a(WatirCrawler::SiteChanged)
      end

      @crawler.pull("//p[@id='level_2']") do
        @crawler.wait("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
        @crawler.wait(".//span[text()='Test span 1']").should be_a(Watir::HTMLElement)

        result = @crawler.wait(:all, '//span')
        result.should be_a(Array)
        result.size.should eq(2)

        result = @crawler.wait(:all, './/span')
        result.should be_a(Array)
        result.size.should eq(2)
      end
    end
  end

  it 'frame', :frame => true do
    @crawler.pull('//iframe') do
      @crawler.pull(".//span[text()='Test span 11']").should be_a(Watir::HTMLElement)

      @crawler.pull(".//span[text()='Test span 21']").should be_nil
      @crawler.pull('.//iframe') do
        @crawler.pull("//span[text()='Test span 1']").should be_a(Watir::HTMLElement)
        @crawler.pull("//span[text()='Test span 11']").should be_nil
        @crawler.pull("//span[text()='Test span 21']").should be_nil
        @crawler.pull(".//span[text()='Test span 11']").should be_nil
        @crawler.pull(".//span[text()='Test span 21']").should be_a(Watir::HTMLElement)
      end
    end
  end

end