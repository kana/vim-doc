task :deploy do
  sh 'git diff --quiet HEAD'
  sh <<'END'
    sed -i -e "s!@@VERSION@@!$(git describe --always --dirty)!g" $(
      for i in $(git ls-files)
      do
        test -f "$i" && ! test -h "$i" && echo "$i"
      done
    )
END
  sh 'git commit -am "Replace version numbers"'
  sh 'git reset --hard HEAD~1'
  sh 'git push heroku HEAD@{1}:master -f'
end

file 'data/tags.rb' => ['data/tags'] do |t|
  BASE_URI = 'http://vimdoc.sourceforge.net/htmldoc'
  dict = {}
  t.prerequisites.each do |p|
    File.open(p, 'r') do |f|
      f.readlines().each do |l|
        tag, path, _ = l.split(/\t/)
        dict[tag] = "#{BASE_URI}/#{path.sub(/\.txt$/, '.html')}##{tag}"
      end
    end
  end
  File.open(t.name, 'w') do |f|
    f.write(dict.to_s)
  end
end
