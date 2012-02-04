require 'cgi'
require 'haml'
require 'httpclient'
require 'sinatra'
require 'uri'

require './parser.rb'




class App < Sinatra::Application
  NAME = 'vim-doc'
  GITHUB_REPOS_URI = 'https://github.com/kana/vim-doc'

  get '/' do
    haml :index
  end

  get '/view' do
    raw_uri = request.query_string
    m = /^uri=(.*)$/.match(raw_uri)
    if m then
      redirect to("/view?#{URI.decode(m[1])}")
    end
    normalized_uri = normalize_document_uri(raw_uri)
    if normalized_uri != raw_uri then
      redirect to("/view?#{normalized_uri}")
    end

    fetch_response = fetch(raw_uri)
    if fetch_response.status == 200 then
      cache_control :public, :max_age => 30 * 24 * 60 * 60
      haml :help,
           locals: {
             conversion_time: Time.now,
             doc_uri: raw_uri,
             html_help: htmlize(fetch_response.body, load_builtin_tag_dict()),
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

    def htmlize(s, builtin_tag_dict)
      ast = VimHelpP.new.parse(s)
      self_tag_dict = VimHelpTagExtractor.extract(ast)
      merged_tag_dict = builtin_tag_dict.merge(self_tag_dict)

      VimHelpT.new.
        apply(ast, {tag_dict: merged_tag_dict}).
        join()
    end

    def load_builtin_tag_dict()
      File.open('data/tags.rb', 'r') do |f|
        return eval(f.read())
      end
    end

    def normalize_document_uri(uri)
      s = uri
      s = s.sub(
        %r{^https?://github\.com/(?<user>[^/]+)/(?<repos>[^/]+)/blob/(?<ref>[^/]+)/(?<path>.+)$},
        'https://raw.github.com/\k<user>/\k<repos>/\k<ref>/\k<path>'
      )
      s
    end
  end
end




__END__
