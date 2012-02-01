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




__END__
