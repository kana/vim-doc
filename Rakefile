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
