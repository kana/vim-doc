require './app.rb'

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
    VimHelpP.new.parse("*foo\rbar*").should == [
      {:etc => '*'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\r"},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '*'},
    ]
    VimHelpP.new.parse("*foo\nbar*").should == [
      {:etc => '*'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\n"},
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
    VimHelpP.new.parse("|foo\rbar|").should == [
      {:etc => '|'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\r"},
      {:etc => 'b'}, {:etc => 'a'}, {:etc => 'r'},
      {:etc => '|'},
    ]
    VimHelpP.new.parse("|foo\nbar|").should == [
      {:etc => '|'},
      {:etc => 'f'}, {:etc => 'o'}, {:etc => 'o'},
      {:etc => "\n"},
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

  it 'should parse a header' do
    VimHelpP.new.parse("FOO-BAR BAZ *qux*").should == [
      {:header => 'FOO-BAR BAZ'},
      {:etc => ' '},
      {:tag_anchor_begin => '*', :tag_anchor => 'qux', :tag_anchor_end => '*'},
    ]
    VimHelpP.new.parse("FOO-BAR BAZ |qux|").should == [
      {:etc => 'F'},
      {:etc => 'O'},
      {:etc => 'O'},
      {:etc => '-'},
      {:etc => 'B'},
      {:etc => 'A'},
      {:etc => 'R'},
      {:etc => ' '},
      {:etc => 'B'},
      {:etc => 'A'},
      {:etc => 'Z'},
      {:etc => ' '},
      {:tag_link_begin => '|', :tag_link => 'qux', :tag_link_end => '|'},
    ]
  end
end

describe VimHelpT do
  it 'should transform :etc into a plain string' do
    VimHelpT.new.apply({:etc => 'f'}).should == 'f'
    VimHelpT.new.apply(VimHelpP.new.parse('foo')).should == ['f', 'o', 'o']
    VimHelpT.new.apply({:etc => '<'}).should == '&lt;'
    VimHelpT.new.apply({:etc => '>'}).should == '&gt;'
    VimHelpT.new.apply({:etc => '"'}).should == '&quot;'
    VimHelpT.new.apply({:etc => '&'}).should == '&amp;'
  end

  it 'should transform :tag_anchor into an anchor' do
    VimHelpT.new.apply({
      :tag_anchor_begin => '*',
      :tag_anchor => 'foo',
      :tag_anchor_end => '*',
    }).should == '<span class="tag_anchor">*<a id="foo">foo</a>*</span>'
    VimHelpT.new.apply(VimHelpP.new.parse('*foo*')).should == [
      '<span class="tag_anchor">*<a id="foo">foo</a>*</span>',
    ]
    VimHelpT.new.apply(VimHelpP.new.parse('*f<o*')).should == [
      '<span class="tag_anchor">*<a id="f&lt;o">f&lt;o</a>*</span>',
    ]
  end

  it 'should transform :tag_link into a link' do
    VimHelpT.new.apply({
      :tag_link_begin => '|',
      :tag_link => 'foo',
      :tag_link_end => '|',
    }).should == '<span class="tag_link">|<a href="#foo">foo</a>|</span>'
    VimHelpT.new.apply(VimHelpP.new.parse('|foo|')).should == [
      '<span class="tag_link">|<a href="#foo">foo</a>|</span>',
    ]
    VimHelpT.new.apply(VimHelpP.new.parse('|f<o|')).should == [
      '<span class="tag_link">|<a href="#f&lt;o">f&lt;o</a>|</span>',
    ]
  end
end
