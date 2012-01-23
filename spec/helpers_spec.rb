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

describe VimHelpP do
  it 'should parse a plain character as :etc' do
    VimHelpP.new.parse('foo bar baz').should == [
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'z'},
    ]
  end

  it 'should parse a tag anchor' do
    VimHelpP.new.parse('foo *bar* baz').should == [
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => ' '},
      {:tag_anchor_begin => '*', :tag_anchor => 'bar', :tag_anchor_end => '*'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'z'},
    ]
    VimHelpP.new.parse('*foo bar*').should == [
      {:etc => '*'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '*'},
    ]
    VimHelpP.new.parse("*foo\tbar*").should == [
      {:etc => '*'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\t"},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '*'},
    ]
    VimHelpP.new.parse('*foo*bar*').should == [
      {:tag_anchor_begin => '*', :tag_anchor => 'foo', :tag_anchor_end => '*'},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '*'},
    ]
    VimHelpP.new.parse('*foo|bar*').should == [
      {:etc => '*'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => '|'},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '*'},
    ]
  end

  it 'should parse a tag link' do
    VimHelpP.new.parse('foo |bar| baz').should == [
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => ' '},
      {:tag_link_begin => '|', :tag_link => 'bar', :tag_link_end => '|'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'z'},
    ]
    VimHelpP.new.parse('|foo bar|').should == [
      {:etc => '|'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => ' '},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '|'},
    ]
    VimHelpP.new.parse("|foo\tbar|").should == [
      {:etc => '|'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\t"},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '|'},
    ]
    VimHelpP.new.parse('|foo|bar|').should == [
      {:tag_link_begin => '|', :tag_link => 'foo', :tag_link_end => '|'},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '|'},
    ]
    VimHelpP.new.parse('|foo*bar|').should == [
      {:etc => '|'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => '*'},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '|'},
    ]
  end
end

describe VimHelpT do
  it 'should transform :etc into a plain string' do
    VimHelpT.new.apply({:etc => 'f'}).should == 'f'
    VimHelpT.new.apply(VimHelpP.new.parse('foo')).should == ['f', 'o', 'o']
  end

  it 'should transform :tag_anchor into an anchor' do
    VimHelpT.new.apply({
      :tag_anchor_begin => '*',
      :tag_anchor => 'foo',
      :tag_anchor_end => '*',
    }).should == '*foo*'
    VimHelpT.new.apply(VimHelpP.new.parse('*foo*')).should == ['*foo*']
  end

  it 'should transform :tag_link into a link' do
    VimHelpT.new.apply({
      :tag_link_begin => '|',
      :tag_link => 'foo',
      :tag_link_end => '|',
    }).should == '|foo|'
    VimHelpT.new.apply(VimHelpP.new.parse('|foo|')).should == ['|foo|']
  end
end
