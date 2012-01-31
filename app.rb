require 'cgi'
require 'haml'
require 'httpclient'
require 'parslet'
require 'sinatra'




class App < Sinatra::Application
  NAME = 'vim-doc'
  GITHUB_REPOS_URI = 'https://github.com/kana/vim-doc'

  get '/' do
    haml :index
  end

  get '/:host/:user/:repos/:ref/*.html' do |host, user, repos, ref, path|
    cache_control :public, :max_age => 30 * 24 * 60 * 60

    case host
    when 'github'
      doc_uri = get_doc_uri_in_github(user, repos, ref, path)
    else
      halt 403, "Host '#{host}' is not supported."
    end

    response = fetch(doc_uri)
    if response.status == 200 then
      haml :help,
           locals: {
             conversion_time: Time.now,
             doc_uri: doc_uri,
             host: host,
             html_help: htmlize(response.body),
             path: path,
             ref: ref,
             repos: repos,
             user: user,
           }
    else
      halt response.status, response.header['Status']
    end
  end

  helpers do
    def fetch(uri)
      HTTPClient.new.get(uri)
    end

    def get_doc_uri_in_github(user, repos, ref, path)
      "https://raw.github.com/#{user}/#{repos}/#{ref}/#{path}"
    end

    def htmlize(s)
      VimHelpT.new.apply(VimHelpP.new.parse(s)).join()
    end
  end
end

module Parslet::Atoms::DSL
  def repeat0()
    repeat(0, nil)
  end

  def repeat1()
    repeat(1, nil)
  end
end

class UriParser < Parslet::Parser
  root(:uri)
  rule(:uri) {
    # str('#') >> fragment |
    # relative_uri >> (str('#') >> fragment).maybe |
    absolute_uri >> (str('#') >> fragment).maybe
  }
  rule(:absolute_uri) {
    # scheme >> str(':') >> (hier_part | opaque_part)
    scheme >> str(':') >> hier_part
  }
  rule(:relative_uri) {
    (net_path | abs_path | rel_path) >> (str('?') >> query).maybe
  }

  rule(:hier_part) {
    (net_path | abs_path) >> (str('?') >> query).maybe
  }
  rule(:opaque_part) {
    uric_no_slash >> uric.repeat
  }

  rule(:uric_no_slash) {
    unreserved | escaped | str(';') | str('?') | str(':') | str('@') |
    str('&') | str('=') | str('+') | str('$') | str(',')
  }

  rule(:net_path) {
    # str('//') >> authority >> abs_path.maybe
    str('//') >> authority >> abs_path
  }
  rule(:abs_path) {
    str('/') >> path_segments
  }
  rule(:rel_path) {
    rel_segment >> abs_path.maybe
  }

  rule(:rel_segment) {
    (
      unreserved | escaped |
      str(';') | str('@') | str('&') | str('=') |
      str('+') | str('$') | str(',')
    ).repeat(1)
  }

  rule(:scheme) {
    alpha >> (alpha | digit | str('+') | str('-') | str('.')).repeat
  }

  rule(:authority) {
    server | reg_name
  }

  rule(:reg_name) {
    (
      unreserved | escaped |
      str('$') | str(',') | str(';') | str(':') |
      str('@') | str('&') | str('=') | str('+')
    ).repeat(1)
  }

  rule(:server) {
    ((userinfo >> str('@')).maybe >> hostport).maybe
  }
  rule(:userinfo) {
    (
      unreserved | escaped |
      str(';') | str(':') | str('&') | str('=') |
      str('+') | str('$') | str(',')
    ).repeat
  }

  rule(:hostport) {
    host >> (str(':') >> port).maybe
  }
  rule(:host) {
    hostname | ipv4address
  }
  rule(:hostname) {
    (domainlabel >> str('.')).repeat >> toplabel >> str('.').maybe
  }
  rule(:domainlabel) {
    alphanum | alphanum >> (alphanum | str('-')).repeat >> alphanum
  }
  rule(:toplabel) {
    alpha | alpha >> (alphanum | str('-')).repeat >> alphanum
  }
  rule(:ipv4address) {
    digit.repeat(1) >> str('.') >>
    digit.repeat(1) >> str('.') >>
    digit.repeat(1) >> str('.') >>
    digit.repeat(1)
  }
  rule(:port) {
    digit.repeat
  }

  rule(:path) {
    (abs_path | opaque_part).maybe
  }
  rule(:path_segments) {
    segment >> (str('/') >> segment).repeat
  }
  rule(:segment) {
    pchar.repeat >> (str(';') >> param).repeat
  }
  rule(:param) {
    pchar.repeat
  }
  rule(:pchar) {
    unreserved | escaped |
    str(':') | str('@') | str('&') | str('=') |
    str('+') | str('$') | str(',')
  }

  rule(:query) {
    uric.repeat
  }

  rule(:fragment) {
    uric.repeat
  }

  rule(:uric) {
    reserved | unreserved | escaped
  }
  rule(:reserved) {
    str(';') | str('/') | str('?') | str(':') |
    str('@') | str('&') | str('=') | str('+') |
    str('$') | str(',')
  }
  rule(:unreserved) {
    alphanum | mark
  }
  rule(:mark) {
    str('-') | str('_') | str('.') | str('!') |
    str('~') | str('*') | str("'") | str('(') | str(')')
  }

  rule(:escaped) {
    str('%') >> hex >> hex
  }
  rule(:hex) {
    digit | match('[A-F]') | match('[a-f]')
  }

  rule(:alphanum) {
    alpha | digit
  }
  rule(:alpha) {
    lowalpha | upalpha
  }

  rule(:lowalpha) {
    match('[a-z]')
  }
  rule(:upalpha) {
    match('[A-Z]')
  }
  rule(:digit) {
    match('[0-9]')
  }
end

class VimHelpP < Parslet::Parser
  rule(:space) {match('[ \t]')}
  rule(:newline) {match('[\r\n]')}
  rule(:star) {str('*')}
  rule(:pipe) {str('|')}
  rule(:header_letter) {match('[-A-Z]')}
  rule(:header_word) {header_letter.repeat1}
  rule(:header_words) {header_word >> (space.repeat1 >> header_word).repeat0}

  rule(:header) {
      (
        header_words >>
        (space.repeat1 >> tag_anchor).present?
      ).as(:header)
  }
  rule(:section_separator) {
    (str('=') | str('-')).repeat(3).as(:section_separator) >>
    newline.present?
  }
  rule(:subheader) {
    (
      (
        ((space | newline | str('~')).absent? >> any) >>
        ((newline | str('~')).absent? >> any).repeat0
      ).as(:text) >>
      str('~').as(:marker) >> newline.present?
    ).as(:subheader)
  }
  rule(:special_key) {
    (
      str('CTRL-') >>
      (
        str('{char}') |
        match('[A-Za-z0-9]').repeat1 |
        any
      ) |
      str('<') >>
      (
        match('[ACDMS]') >> str('-') >> any |
        match('[A-Za-z0-9_-]').repeat1
      ) >>
      str('>')
    ).as(:special_key)
  }
  rule(:special_term) {
    (
      str('{') >>
      match(%q([-a-zA-Z0-9'"*+/:%#=\[\]<>.,])).repeat1 >>
      str('}')
    ).as(:special_term)
  }
  rule(:optional_term) {
    (
      str('[') >>
      match('[^ \t\[\]]').repeat1 >>
      str(']')
    ).as(:optional_term)
  }
  rule(:option) {
    (
      str("'") >>
      (
        match('[a-z]').repeat(2) |
        str('t_') >> any >> any
      ) >>
      str("'")
    ).as(:option)
  }
  rule(:vimscript_link) {
    (
      str('vimscript#') >>
      match('[0-9]').repeat1.as(:id)
    ).as(:vimscript_link)
  }
  rule(:tag_anchor) {
    star.as(:begin) >>
    ((space | newline | star | pipe).absent? >> any).
      repeat1.
      as(:tag_anchor) >>
    star.as(:end) >>
    (any.absent? | (space | newline).present?)
  }
  rule(:tag_link) {
    pipe.as(:begin) >>
    ((space | newline | star | pipe).absent? >> any).
      repeat1.
      as(:tag_link) >>
    pipe.as(:end)
  }
  rule(:etc) {any.as(:etc)}
  rule(:example_begin) {
    str('>')
  }
  rule(:example_end) {
    newline >> (str('<') | (space | newline).absent?)
  }
  rule(:example) {
    (
      example_begin.as(:begin) >>
      (
        newline >> newline.present? |
        newline >> space >> (newline.absent? >> any).repeat0 |
        example_end.absent? >> any
      ).repeat1.as(:text) >>
      example_end.as(:end)
    ).as(:example)
  }
  rule(:uri) {
    UriParser.new.as(:uri)
  }
  rule(:token) {
    header |
    section_separator |
    subheader |
    special_key |
    special_term |
    optional_term |
    option |
    vimscript_link |
    tag_anchor |
    tag_link |
    example |
    uri |
    etc
  }
  rule(:help) {token.repeat0}
  root(:help)
end

def highlight(type, token)
  %Q[<span class="#{type.to_s}">#{CGI.escape_html(token.to_s)}</span>]
end

class VimHelpT < Parslet::Transform
  [
    :header,
    :section_separator,
    :special_key,
    :special_term,
    :optional_term,
    :option,
  ].each do |type|
    rule(type => simple(:token)) {
      highlight(type, token)
    }
  end
  rule(:vimscript_link => {:id => simple(:id)}) {
    base_uri = 'http://www.vim.org/scripts/script.php'
    %Q[<a class="vimscript_link" href="#{base_uri}?script_id=#{id.to_s}">vimscript##{id.to_s}</a>]
  }
  rule(:subheader => {:text => simple(:text), :marker => simple(:marker)}) {
    highlight(:subheader, text) + highlight(:subheader_marker, marker)
  }
  rule(
    :begin => simple(:b),
    :tag_anchor => simple(:id),
    :end => simple(:e)
  ) {
    s_b = CGI.escape_html(b.to_s)
    s_id = CGI.escape_html(id.to_s)
    s_e = CGI.escape_html(e.to_s)
    %Q[<span class="tag_anchor">#{s_b}<a id="#{s_id}">#{s_id}</a>#{s_e}</span>]
  }
  rule(
    :begin => simple(:b),
    :tag_link => simple(:id),
    :end => simple(:e)
  ) {
    # TODO: Link to vimdoc.sf.net for built-in stuffs.
    # TODO: Link to vim-doc.heroku.com for others but "learned" stuffs.
    s_b = CGI.escape_html(b.to_s)
    s_id = CGI.escape_html(id.to_s)
    s_e = CGI.escape_html(e.to_s)
    %Q[<span class="tag_link">#{s_b}<a href="##{s_id}">#{s_id}</a>#{s_e}</span>]
  }
  rule(
    :example => {
      :begin => simple(:b),
      :text => simple(:t),
      :end => simple(:e)
    }
  ) {
    s_b = CGI.escape_html(b.to_s)
    s_t = CGI.escape_html(t.to_s)
    s_e = CGI.escape_html(e.to_s)
    %Q[<span class="example"><span class="example_marker">#{s_b}</span>#{s_t}<span class="example_marker">#{s_e}</span></span>]
  }
  rule(:uri => simple(:uri)) {
    s_uri = CGI.escape_html(uri.to_s)
    %Q[<a href="#{s_uri}" class="uri">#{s_uri}</a>]
  }
  rule(:etc => simple(:char)) {
    CGI.escape_html(char.to_s)
  }
end




__END__
