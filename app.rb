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
  rule(:tag_anchor) {
    star.as(:begin) >>
    ((space | newline | star | pipe).absent? >> any).
      repeat1.
      as(:tag_anchor) >>
    star.as(:end)
  }
  rule(:tag_link) {
    pipe.as(:begin) >>
    ((space | newline | star | pipe).absent? >> any).
      repeat1.
      as(:tag_link) >>
    pipe.as(:end)
  }
  rule(:etc) {any.as(:etc)}
  rule(:token) {
    header |
    section_separator |
    tag_anchor |
    tag_link |
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
  ].each do |type|
    rule(type => simple(:token)) {
      highlight(type, token)
    }
  end
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
  rule(:etc => simple(:char)) {
    CGI.escape_html(char.to_s)
  }
end




__END__
