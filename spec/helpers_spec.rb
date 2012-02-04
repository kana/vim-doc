require './app.rb'




def parse(s)
  VimHelpP.new.parse(s)
end

def transform(tokens, context = nil)
  VimHelpT.new.apply(tokens, context)
end




describe UriParser do
  it 'should parse an absolute URI' do
    UriParser.new.parse('http://www.vim.org/').should == 'http://www.vim.org/'
  end
  it 'should not parse a modeline as a URI' do
    expect {
      UriParser.new.parse('vim:tw=78')
    }.to raise_error(Parslet::ParseFailed)
  end
end

describe VimHelpP do
  it 'should parse a plain character as :etc' do
    parse('foo bar baz').should == [
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'z'},
    ]
  end

  it 'should parse a tag anchor' do
    parse('foo *bar* baz').should == [
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: ' '},
      {begin: '*', tag_anchor: 'bar', end: '*'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'z'},
    ]
    parse('*foo bar*').should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '*'},
    ]
    parse("*foo\tbar*").should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\t"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '*'},
    ]
    parse("*foo\rbar*").should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\r"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '*'},
    ]
    parse("*foo\nbar*").should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\n"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '*'},
    ]
    parse('*foo*bar*').should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {begin: '*', tag_anchor: 'bar', end: '*'},
    ]
    parse('*foo|bar*').should == [
      {etc: '*'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: '|'},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '*'},
    ]
  end

  it 'should parse a tag link' do
    parse('foo |bar| baz').should == [
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: ' '},
      {begin: '|', tag_link: 'bar', end: '|'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'z'},
    ]
    parse('|foo bar|').should == [
      {etc: '|'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: ' '},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
    parse("|foo\tbar|").should == [
      {etc: '|'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\t"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
    parse("|foo\rbar|").should == [
      {etc: '|'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\r"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
    parse("|foo\nbar|").should == [
      {etc: '|'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: "\n"},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
    parse('|foo|bar|').should == [
      {begin: '|', tag_link: 'foo', end: '|'},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
    parse('|foo*bar|').should == [
      {etc: '|'},
      {etc: 'f'}, {etc: 'o'}, {etc: 'o'},
      {etc: '*'},
      {etc: 'b'}, {etc: 'a'}, {etc: 'r'},
      {etc: '|'},
    ]
  end

  it 'should parse a header' do
    parse("FOO-BAR BAZ *qux*").should == [
      {header: 'FOO-BAR BAZ'},
      {etc: ' '},
      {begin: '*', tag_anchor: 'qux', end: '*'},
    ]
    parse("FOO-BAR BAZ |qux|").should == [
      {etc: 'F'},
      {etc: 'O'},
      {etc: 'O'},
      {etc: '-'},
      {etc: 'B'},
      {etc: 'A'},
      {etc: 'R'},
      {etc: ' '},
      {etc: 'B'},
      {etc: 'A'},
      {etc: 'Z'},
      {etc: ' '},
      {begin: '|', tag_link: 'qux', end: '|'},
    ]
  end

  it 'should parse a section header' do
    parse("======\n").should == [
      {section_separator: '======'},
      {etc: "\n"},
    ]
    parse('======').should == [
      {etc: '='},
      {etc: '='},
      {etc: '='},
      {etc: '='},
      {etc: '='},
      {etc: '='},
    ]
    parse("------\n").should == [
      {section_separator: '------'},
      {etc: "\n"},
    ]
    parse('------').should == [
      {etc: '-'},
      {etc: '-'},
      {etc: '-'},
      {etc: '-'},
      {etc: '-'},
      {etc: '-'},
    ]
  end

  it 'should parse a special key' do
    parse('<Esc>').should == [
      {special_key: '<Esc>'},
    ]
    parse('<C-@>').should == [
      {special_key: '<C-@>'},
    ]
    parse('CTRL-@').should == [
      {special_key: 'CTRL-@'},
    ]
    parse('CTRL-Break').should == [
      {special_key: 'CTRL-Break'},
    ]
    parse('CTRL-{char}').should == [
      {special_key: 'CTRL-{char}'},
    ]
    parse('<E?c>').should == [
      {etc: '<'},
      {etc: 'E'},
      {etc: '?'},
      {etc: 'c'},
      {etc: '>'},
    ]
  end

  it 'should parse a special term' do
    parse('{lhs}').should == [
      {special_term: '{lhs}'},
    ]
    parse('{l s}').should == [
      {etc: '{'},
      {etc: 'l'},
      {etc: ' '},
      {etc: 's'},
      {etc: '}'},
    ]
  end

  it 'should parse a optional term' do
    parse('[range]').should == [
      {optional_term: '[range]'},
    ]
    parse('[ra ge]').should == [
      {etc: '['},
      {etc: 'r'},
      {etc: 'a'},
      {etc: ' '},
      {etc: 'g'},
      {etc: 'e'},
      {etc: ']'},
    ]
  end

  it 'should parse an option' do
    parse("'foo'").should == [
      {option: "'foo'"}
    ]
    parse("'t_XY'").should == [
      {option: "'t_XY'"}
    ]
    parse("'f o'").should == [
      {etc: "'"},
      {etc: 'f'},
      {etc: ' '},
      {etc: 'o'},
      {etc: "'"},
    ]
    parse("'t_foo'").should == [
      {etc: "'"},
      {etc: 't'},
      {etc: '_'},
      {etc: 'f'},
      {etc: 'o'},
      {etc: 'o'},
      {etc: "'"},
    ]
  end

  it 'should parse a vimscript link' do
    parse("vimscript#2100").should == [
      {vimscript_link: {id: '2100'}},
    ]
  end

  it 'should parse a subheader' do
    parse("foo ~\n").should == [
      {subheader: {text: 'foo ', marker: '~'}},
      {etc: "\n"},
    ]
    parse("foo ~").should == [
      {etc: 'f'},
      {etc: 'o'},
      {etc: 'o'},
      {etc: ' '},
      {etc: '~'},
    ]
  end

  it 'should parse an example' do
    parse(">\n foo\n bar\n<").should == [
      {example: {begin: ">", text: "\n foo\n bar", end: "\n<"}},
    ]
    parse(">\n foo\n bar\nbaz").should == [
      {example: {begin: ">", text: "\n foo\n bar", end: "\n"}},
      {etc: 'b'},
      {etc: 'a'},
      {etc: 'z'},
    ]
    parse(">\nLicense: ...\n  ...\n}}}\n").should == [
      {etc: '>'},
      {etc: "\n"},
      {etc: 'L'}, {etc: 'i'}, {etc: 'c'}, {etc: 'e'},
      {etc: 'n'}, {etc: 's'}, {etc: 'e'}, {etc: ':'},
      {etc: ' '}, {etc: '.'}, {etc: '.'}, {etc: '.'},
      {etc: "\n"},
      {etc: ' '}, {etc: ' '},
      {etc: '.'}, {etc: '.'}, {etc: '.'},
      {etc: "\n"},
      {etc: '}'}, {etc: '}'}, {etc: '}'},
      {etc: "\n"},
    ]
  end

  it 'should parse an absolute URI' do
    parse('http://www.vim.org/').should == [
      {uri: 'http://www.vim.org/'},
    ]
  end
end

describe VimHelpT do
  it 'should transform :etc into a plain string' do
    transform({etc: 'f'}).should == 'f'
    transform(parse('foo')).should == ['f', 'o', 'o']
    transform({etc: '<'}).should == '&lt;'
    transform({etc: '>'}).should == '&gt;'
    transform({etc: '"'}).should == '&quot;'
    transform({etc: '&'}).should == '&amp;'
  end

  it 'should transform :tag_anchor into an anchor' do
    transform({
      begin: '*',
      tag_anchor: 'foo',
      end: '*',
    }).should == '<span class="tag_anchor">*<a id="foo">foo</a>*</span>'
    transform(parse('*foo*')).should == [
      '<span class="tag_anchor">*<a id="foo">foo</a>*</span>',
    ]
    transform(parse('*f<o*')).should == [
      '<span class="tag_anchor">*<a id="f&lt;o">f&lt;o</a>*</span>',
    ]
  end

  it 'should transform :tag_link into a link' do
    transform({
      begin: '|',
      tag_link: 'foo',
      end: '|',
    }).should == '<span class="tag_link">|<a href="#foo">foo</a>|</span>'
    transform(parse('|foo|')).should == [
      '<span class="tag_link">|<a href="#foo">foo</a>|</span>',
    ]
    transform(parse('|f<o|')).should == [
      '<span class="tag_link">|<a href="#f&lt;o">f&lt;o</a>|</span>',
    ]
    transform(parse('|foo|'), {:tag_dict => {'foo' => 'b<|r'}}).should == [
      '<span class="tag_link">|<a href="b&lt;|r">foo</a>|</span>',
    ]
  end

  it 'should transform :header into a header' do
    transform(parse("FOO-BAR BAZ *qux*")).should == [
      '<span class="header">FOO-BAR BAZ</span>',
      ' ',
      '<span class="tag_anchor">*<a id="qux">qux</a>*</span>',
    ]
  end

  it 'should transform :section_separator' do
    transform(parse("======\n")).should == [
      '<span class="section_separator">======</span>',
      "\n",
    ]
  end

  it 'should transform :special_key' do
    transform(parse('<Esc>')).should == [
      '<span class="special_key">&lt;Esc&gt;</span>',
    ]
  end

  it 'should transform :special_term' do
    transform(parse('{lhs}')).should == [
      '<span class="special_term">{lhs}</span>',
    ]
  end

  it 'should transform :optional_term' do
    transform(parse('[range]')).should == [
      '<span class="optional_term">[range]</span>',
    ]
  end

  it 'should transform :option' do
    transform(parse("'wrap'")).should == [
      %q(<span class="option">'wrap'</span>),
    ]
  end

  it 'should transform :vimscript_link' do
    transform(parse('vimscript#2100')).should == [
      %q(<a class="vimscript_link" href="http://www.vim.org/scripts/script.php?script_id=2100">vimscript#2100</a>),
    ]
  end

  it 'should transform :subheader' do
    transform(parse("foo ~\n")).should == [
      '<span class="subheader">foo </span>' +
        '<span class="subheader_marker">~</span>',
      "\n",
    ]
  end

  it 'should transform :example' do
    transform(parse(">\n foo\n bar\n<")).should == [
      %Q(<span class="example"><span class="example_marker">&gt;</span>\n foo\n bar<span class="example_marker">\n&lt;</span></span>),
    ]
    transform(parse(">\n foo\n bar\nbaz")).should == [
      %Q(<span class="example"><span class="example_marker">&gt;</span>\n foo\n bar<span class="example_marker">\n</span></span>),
      'b',
      'a',
      'z',
    ]
  end

  it 'should transform :uri' do
    transform(parse('http://www.vim.org/')).should == [
      %Q(<a href="http://www.vim.org/" class="uri">http://www.vim.org/</a>)
    ]
  end
end
