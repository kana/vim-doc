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
           }
    else
      halt fetch_response.status, fetch_response.header['Status']
    end
  end

  helpers do
    def fetch(uri)
      HTTPClient.new.get(uri)
    end

    def htmlize(s)
      VimHelpT.new.apply(VimHelpP.new.parse(s)).join()
    end
  end
end




__END__
