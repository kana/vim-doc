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
             html_help: VimHelp.htmlize(response.body),
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
    s  # FIXME: Implement.
  end
end




__END__
