<%=
#!/usr/bin/env ruby

# Purpose: Generate RSS feed for the site
# Author : Anh K. Huynh
# Date   : 2013 April 13th
# License: GPL v2
# Usage  :
#   Every time a new commit is made on `contents/news/index.html`
#   the feed will be updated. However, the commit subject must be
#   started by `news: ` to be recorded by our script. This is to help
#   we fix some typo error in the old pages.

require "rss"
require "git"

$repo = Git.open("./")
$object = "./content/news/index.html"

rss = RSS::Maker.make("2.0") do |maker|
  maker.channel.author = "TheSLinux"
  maker.channel.updated = $repo.log(1).object($object).first.date
  maker.channel.about = "http://theslinux.org/news/rss/"
  maker.channel.title = "TheSLinux - news"
  maker.channel.description = "News from TheSLinux"
  maker.channel.link = "http://theslinux.org/news/"

  $repo \
    .log(20) \
    .object($object) \
    .since("40 weeks ago")\
    .each do |c|
      next unless c.message.to_s.match(/^news: /)
      maker.items.new_item do |item|
        item.updated = c.date
        item.title = "#{c.message.split(/[\r\n]/).first}"
        item.description = "#{<<-EOF}"
<ul>
  <li>commit: <a href="https://github.com/TheSLinux/homepage/commit/#{c.sha}">#{c.sha}</a></li>
  <li>author: #{c.author.name}</li>
  <li>message: <pre>#{c.message}</pre></li>
</ul>
EOF
      end
    end
end

rss
%>
