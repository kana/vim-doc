require 'cgi'
require 'haml'
require 'httpclient'
require 'sinatra'




class App < Sinatra::Application
  NAME = 'vim-doc'
  GITHUB_REPOS_URI = 'https://github.com/kana/vim-doc'

  get '/' do
    haml :index
  end

  get '/:host/:user/:repos/:ref/*.html' do |host, user, repos, ref, path|
    case host
    when 'github'
      response = fetch_github(user, repos, ref, path)
    else
      halt 403, "Host '#{host}' is not supported."
    end

    # FIXME: Tweak caching.
    if response.status == 200 then
      haml :help,
           locals: {
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

    def fetch_github(user, repos, ref, path)
      fetch("https://raw.github.com/#{user}/#{repos}/#{ref}/#{path}")
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




__END__
