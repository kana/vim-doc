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
      {:begin => '*', :tag_anchor => 'bar', :end => '*'},
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
      {:begin => '*', :tag_anchor => 'foo', :end => '*'},
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
      {:begin => '|', :tag_link => 'bar', :end => '|'},
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
      {:begin => '|', :tag_link => 'foo', :end => '|'},
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
      {:begin => '*', :tag_anchor => 'qux', :end => '*'},
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
      {:begin => '|', :tag_link => 'qux', :end => '|'},
    ]
  end

  it 'should parse a section header' do
    VimHelpP.new.parse("======\n").should == [
      {:section_separator => '======'},
      {:etc => "\n"},
    ]
    VimHelpP.new.parse('======').should == [
      {:etc => '='},
      {:etc => '='},
      {:etc => '='},
      {:etc => '='},
      {:etc => '='},
      {:etc => '='},
    ]
    VimHelpP.new.parse("------\n").should == [
      {:section_separator => '------'},
      {:etc => "\n"},
    ]
    VimHelpP.new.parse('------').should == [
      {:etc => '-'},
      {:etc => '-'},
      {:etc => '-'},
      {:etc => '-'},
      {:etc => '-'},
      {:etc => '-'},
    ]
  end

  it 'should parse a special key' do
    VimHelpP.new.parse('<Esc>').should == [
      {:special_key => '<Esc>'},
    ]
    VimHelpP.new.parse('<E?c>').should == [
      {:etc => '<'},
      {:etc => 'E'},
      {:etc => '?'},
      {:etc => 'c'},
      {:etc => '>'},
    ]
  end

  it 'should parse a special term' do
    VimHelpP.new.parse('{lhs}').should == [
      {:special_term => '{lhs}'},
    ]
    VimHelpP.new.parse('{l s}').should == [
      {:etc => '{'},
      {:etc => 'l'},
      {:etc => ' '},
      {:etc => 's'},
      {:etc => '}'},
    ]
  end

  it 'should parse an option' do
    VimHelpP.new.parse("'foo'").should == [
      {:option => "'foo'"}
    ]
    VimHelpP.new.parse("'t_XY'").should == [
      {:option => "'t_XY'"}
    ]
    VimHelpP.new.parse("'f o'").should == [
      {:etc => "'"},
      {:etc => 'f'},
      {:etc => ' '},
      {:etc => 'o'},
      {:etc => "'"},
    ]
    VimHelpP.new.parse("'t_foo'").should == [
      {:etc => "'"},
      {:etc => 't'},
      {:etc => '_'},
      {:etc => 'f'},
      {:etc => 'o'},
      {:etc => 'o'},
      {:etc => "'"},
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
      :begin => '*',
      :tag_anchor => 'foo',
      :end => '*',
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
      :begin => '|',
      :tag_link => 'foo',
      :end => '|',
    }).should == '<span class="tag_link">|<a href="#foo">foo</a>|</span>'
    VimHelpT.new.apply(VimHelpP.new.parse('|foo|')).should == [
      '<span class="tag_link">|<a href="#foo">foo</a>|</span>',
    ]
    VimHelpT.new.apply(VimHelpP.new.parse('|f<o|')).should == [
      '<span class="tag_link">|<a href="#f&lt;o">f&lt;o</a>|</span>',
    ]
  end

  it 'should transform :header into a header' do
    VimHelpT.new.apply(VimHelpP.new.parse("FOO-BAR BAZ *qux*")).should == [
      '<span class="header">FOO-BAR BAZ</span>',
      ' ',
      '<span class="tag_anchor">*<a id="qux">qux</a>*</span>',
    ]
  end

  it 'should transform :section_separator' do
    VimHelpT.new.apply(VimHelpP.new.parse("======\n")).should == [
      '<span class="section_separator">======</span>',
      "\n",
    ]
  end

  it 'should transform :special_key' do
    VimHelpT.new.apply(VimHelpP.new.parse('<Esc>')).should == [
      '<span class="special_key">&lt;Esc&gt;</span>',
    ]
  end

  it 'should transform :special_term' do
    VimHelpT.new.apply(VimHelpP.new.parse('{lhs}')).should == [
      '<span class="special_term">{lhs}</span>',
    ]
  end

  it 'should transform :option' do
    VimHelpT.new.apply(VimHelpP.new.parse("'wrap'")).should == [
      %q(<span class="option">'wrap'</span>),
    ]
  end
end
