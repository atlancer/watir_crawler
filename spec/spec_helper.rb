RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
end

require 'watir_crawler'
WORKING_DIRECTORY = '/tmp'
$debug = true
# ----------------------------------------------------------------------------------------------------------------------

require 'tempfile'

class Htmlfile
  def initialize
    @frameset = Tempfile.new('frameset.html')
    @frameset.write(frameset_content)
    @frameset.close

    @frame2 = Tempfile.new('frame2.html')
    @frame2.write(frame2_content)
    @frame2.close

    @frame1 = Tempfile.new('frame1.html')
    @frame1.write(frame1_content)
    @frame1.close

    @file = Tempfile.new('test.html')
    @file.write(content)
    @file.close
    @file
  end

  def content
    # todo     #{frameset}
    cnt = <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>Test</title>
</head>
<body>
    <div id="1">div 1</div>
    <div id="2">div 2</div>
    <div id="3">div 3</div>
    <div id="4" style="display:none;">div 4</div>
    <p id="level_1">
      <p id="level_2">
        <span>Test span 1</span>
        <span>Test span 2</span>
      </p>
    </p>
    #{frame1}
</body>
</html>
    EOF

    cnt
  end

  def frame1
    cnt = <<-EOF
    <iframe id="loginframe1" src="#{file_url @frame1}" style=""></iframe>
    EOF

    cnt
  end

  def frame2
    cnt = <<-EOF
    <iframe id="loginframe2" src="#{file_url @frame2}" style=""></iframe>
    EOF

    cnt
  end

  def frame1_content
    cnt = <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>Frame 1</title>
</head>
<body>
    <h2>Frame 1</h2>
    <div id="11">div 1</div>
    <div id="12">div 2</div>
    <div id="13">div 3</div>
    <div id="14" style="display:none;">div 4</div>
    <p id="level_11">
      <p id="level_12">
        <span>Test span 11</span>
        <span>Test span 12</span>
      </p>
    </p>
#{frame2}
</body>
</html>
    EOF

    cnt
  end

  def frame2_content
    cnt = <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>Frame 2</title>
</head>
<body>
    <h2>Frame 2</h2>
    <div id="21">div 1</div>
    <div id="22">div 2</div>
    <div id="23">div 3</div>
    <div id="24" style="display:none;">div 4</div>
    <p id="level_21">
      <p id="level_22">
        <span>Test span 21</span>
        <span>Test span 22</span>
      </p>
    </p>
</body>
</html>
    EOF

    cnt
  end

  def frameset
    # TODO
    cnt = <<-EOF
<frameset rows="80,*" cols="*">
  <frame src="#{file_url @frameset}" name="topFrame">
  <frameset cols="80,*">
    <frame src="#{file_url @frameset}" name="leftFrame">
    <frame src="#{file_url @frameset}" name="mainFrame">
  </frameset>
</frameset>
    EOF

    cnt
  end

  def frameset_content
    cnt = <<-EOF
<!DOCTYPE html>
<html>
<head>
    <title>Frameset Frame</title>
</head>
<body>
    <h2>Frameset Frame</h2>
    <div id="111">div 1</div>
    <div id="112">div 2</div>
    <div id="113">div 3</div>
    <div id="114" style="display:none;">div 4</div>
    <p id="level_111">
      <p id="level_112">
        <span>Test span 111</span>
        <span>Test span 112</span>
      </p>
    </p>
</body>
</html>
    EOF

    cnt
  end

  def url
    file_url @file
  end

  def file_url file
    "file://#{file.path}"
  end

  def delete
    [
      @frameset,
      @frame1,
      @frame2,
      @file
    ].each{|file| file.unlink }
  end
end


