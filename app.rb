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

class VimHelpP < Parslet::Parser
  rule(:etc) {match('.').as(:etc)}
  rule(:tag_anchor) {
    str('*').as(:tag_anchor_begin) >>
    match('[^ \t\r\n*|]').repeat(1).as(:tag_anchor) >>
    str('*').as(:tag_anchor_end)
  }
  rule(:tag_link) {
    str('|').as(:tag_link_begin) >>
    match('[^ \t\r\n*|]').repeat(1).as(:tag_link) >>
    str('|').as(:tag_link_end)
  }
  rule(:token) {tag_anchor | tag_link | etc}
  rule(:help) {token.repeat}
  root(:help)
end

class VimHelpT < Parslet::Transform
  rule(:etc => simple(:char)) {
    CGI.escape_html(char.to_s)
  }
  rule(
    :tag_anchor_begin => simple(:b),
    :tag_anchor => simple(:id),
    :tag_anchor_end => simple(:e)
  ) {
    s_b = CGI.escape_html(b.to_s)
    s_id = CGI.escape_html(id.to_s)
    s_e = CGI.escape_html(e.to_s)
    %Q[<span class="tag_anchor">#{s_b}<a id="#{s_id}">#{s_id}</a>#{s_e}</span>]
  }
  rule(
    :tag_link_begin => simple(:b),
    :tag_link => simple(:id),
    :tag_link_end => simple(:e)
  ) {
    # TODO: Link to vimdoc.sf.net for built-in stuffs.
    # TODO: Link to vim-doc.heroku.com for others but "learned" stuffs.
    s_b = CGI.escape_html(b.to_s)
    s_id = CGI.escape_html(id.to_s)
    s_e = CGI.escape_html(e.to_s)
    %Q[<span class="tag_link">#{s_b}<a href="##{s_id}">#{s_id}</a>#{s_e}</span>]
  }
end




__END__
