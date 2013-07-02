<%=
#!/usr/bin/env ruby

# Purpose: Generate RSS feed for the site
# Author : Anh K. Huynh
# Date   : 2013 April 13th
# License: GPL v2
# Usage  :
#   When a new commit is pushed on `contents/news/index.html`
#   the feed will be updated. However, the commit subject must be
#   started by `news: ` to be recorded by our script. This is to help
#   us to fix some typo error in the old pages.

require "rss"
require "git"
require "date"

$this_year = Date.today.strftime("%Y").to_i
$repo = Git.open("./")

# Because `ruby-git` doesn't the `--follow` option, we need this trick
# See my feature request https://github.com/schacon/ruby-git/issues/82
#
# NOTE: this changes require the `post-receive` githook to be updated
$object = "./content/news/#{$this_year == 2013 ? "index" : $this_year}.html"

rss = RSS::Maker.make("2.0") do |maker|
  first_object = $repo.log(1).object($object).first
  maker.channel.author = "TheSLinux"
  maker.channel.updated = first_object.nil? ? Time.now : first_object.date
  maker.channel.about = "http://theslinux.org/news/rss/"
  maker.channel.title = "TheSLinux - news #{$this_year}"
  maker.channel.description = "News from TheSLinux"
  maker.channel.link = "http://theslinux.org/news/"

  $repo \
    .log(20) \
    .object($object) \
    .since("40 weeks ago")\
    .each do |c|
      next unless c.message.to_s.match(/^news: /)
      maker.items.new_item do |item|
        item.link = "https://github.com/TheSLinux/homepage/commit/#{c.sha}"
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
