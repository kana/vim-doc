require 'cgi'
require 'haml'
require 'httpclient'
require 'sinatra'

require './parser.rb'




class App < Sinatra::Application
  NAME = 'vim-doc'
  GITHUB_REPOS_URI = 'https://github.com/kana/vim-doc'

  get '/' do
    haml :index
  end

  get '/view' do
    raw_uri = request.query_string
    fetch_response = fetch(raw_uri)
    if fetch_response.status == 200 then
      cache_control :public, :max_age => 30 * 24 * 60 * 60
      haml :help,
           locals: {
             conversion_time: Time.now,
             doc_uri: raw_uri,
             html_help: htmlize(fetch_response.body),
             uri_info: extract_uri_info(raw_uri),
           }
    else
      halt fetch_response.status, fetch_response.header['Status']
    end
  end

  helpers do
    def extract_uri_info(uri)
      m = %r(^https://raw\.(?<host>github)\.com/(?<user>[^/]+)/(?<repos>[^/]+)/(?<ref>[^/]+)/(?<path>.+)$).match(uri)
      if m then
        {
          match?: true,
          host: m[:host],
          user: m[:user],
          repos: m[:repos],
          ref: m[:ref],
          path: m[:path],
        }
      else
        {
          match?: false,
        }
      end
    end

    def fetch(uri)
      HTTPClient.new.get(uri)
    end

    def htmlize(s)
      VimHelpT.new.apply(VimHelpP.new.parse(s)).join()
    end
  end
end




__END__
