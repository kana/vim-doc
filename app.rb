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
             html_help: VimHelp.htmlize(response.body),
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
  end
end

class VimHelp
  def self.htmlize(s)
    self.parse(s).map do |token|
      if token.link then
        label = CGI.escape_html(token.label)
        uri = "\##{CGI.escape_html(token.link)}"
        %Q[<a href="#{uri}">#{label}</a>]
      elsif token.tag then
        label = CGI.escape_html(token.label)
        id = CGI.escape_html(token.tag)
        %Q[<a id="#{id}">#{label}</a>]
      else
        CGI.escape_html(token.label)
      end
    end.join('')
  end

  def self.parse(s)
    tokens = []
    s.scan(/((\|(\S+)\|)|(\*(\S+)\*)|(\|[^|]*)|(\*[^*]*)|([^|*]+))/) do
      |label, _, link, _, tag, _, _, _|
      tokens.push(Token.new(label, link, tag))
    end
    tokens
  end
end

class Token
  attr_accessor :label, :link, :tag

  def initialize(label, link, tag)
    self.label = label
    self.link = link
    self.tag = tag
  end

  def ==(other)
    self.label == other.label and
    self.link == other.link and
    self.tag == other.tag
  end
end

class VimHelpP < Parslet::Parser
  rule(:etc) {match('.').as(:etc)}
  rule(:tag_anchor) {
    str('*').as(:tag_anchor_begin) >>
    match('[^ \t*|]').repeat(1).as(:tag_anchor) >>
    str('*').as(:tag_anchor_end)
  }
  rule(:tag_link) {
    str('|').as(:tag_link_begin) >>
    match('[^ \t*|]').repeat(1).as(:tag_link) >>
    str('|').as(:tag_link_end)
  }
  rule(:token) {tag_anchor | tag_link | etc}
  rule(:help) {token.repeat}
  root(:help)
end

class VimHelpT < Parslet::Transform
  rule(:etc => simple(:char)) {char}
  rule(
    :tag_anchor_begin => simple(:b),
    :tag_anchor => simple(:id),
    :tag_anchor_end => simple(:e)
  ) {
    # TODO: Make a real anchor.
    "#{b}#{id}#{e}"
  }
  rule(
    :tag_link_begin => simple(:b),
    :tag_link => simple(:id),
    :tag_link_end => simple(:e)
  ) {
    # TODO: Make a real link.
    "#{b}#{id}#{e}"
  }
end




__END__
