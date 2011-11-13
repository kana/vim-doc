require './app.rb'

describe 'VimHelp' do
  describe 'parse' do
    it 'should parse Vim :help document correctly' do
      VimHelp.parse('foo bar baz').should == [
        Token.new('foo bar baz', nil, nil),
      ]
      VimHelp.parse('foo |bar| baz').should == [
        Token.new('foo ', nil, nil),
        Token.new('|bar|', 'bar', nil),
        Token.new(' baz', nil, nil),
      ]
      VimHelp.parse('| ... To screen column ...').should == [
        Token.new('| ... To screen column ...', nil, nil),
      ]
      VimHelp.parse('foo *bar* baz').should == [
        Token.new('foo ', nil, nil),
        Token.new('*bar*', nil, 'bar'),
        Token.new(' baz', nil, nil),
      ]
      VimHelp.parse('* ... blah blah ...').should == [
        Token.new('* ... blah blah ...', nil, nil),
      ]
    end
  end

  describe 'htmlize' do
    it 'should output normal text as is' do
      VimHelp.htmlize('foo bar baz').should ==
        'foo bar baz'
    end

    it 'should escape meta characters for HTML' do
      VimHelp.htmlize(%q[foo < > ' " baz]).should ==
        %q[foo &lt; &gt; ' &quot; baz]
    end

    it 'should make a link to other item' do
      VimHelp.htmlize('foo |bar| baz').should ==
        'foo <a href="#bar">|bar|</a> baz'
      VimHelp.htmlize('foo |>>| baz').should ==
        'foo <a href="#&gt;&gt;">|&gt;&gt;|</a> baz'
    end

    it 'should make an anchor to link from others' do
      VimHelp.htmlize('foo *bar* baz').should ==
        'foo <a id="bar">*bar*</a> baz'
      VimHelp.htmlize('foo *>>* baz').should ==
        'foo <a id="&gt;&gt;">*&gt;&gt;*</a> baz'
    end

    it 'should generate valid id for HTML to link'
  end
end
