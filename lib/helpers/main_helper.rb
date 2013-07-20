########################################################################
# WARNING: normal authors are not allowed to change this file.         #
#          all changes will be simply ignored by server                #
########################################################################

require 'cgi'

module MainHelper

  # @purpose: print the Disqus comment form
  # @id     : the short name of your disqus identity
  # @return : string
  def disqus_show(id = "archlinuxvn")
    <<EOF
      <div id="disqus_thread"></div>
      <script type="text/javascript">
          (function() {
              var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
              dsq.src = 'http://#{id}.disqus.com/embed.js';
              (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
          })();
      </script>
      <noscript>Javascript is required to view comment(s).</a></noscript>
      <a href="http://disqus.com" class="dsq-brlink">comments powered by Disqus</a>
EOF
  end

  # @purpose: Find the file name associated to an item
  # @author : Anh K. Huynh
  # @return : File path (real path) or nil
  # @note   : Available extensions: .rb (ERB), .html (other formarts)
  def item_to_file(item)
    return nil if item.is_a?(Nanoc::Item) and item[:virtual]

    path = item.is_a?(String) ? item : item.identifier
    if path.nil?
      file_name = nil
    elsif File.file?(path)
      file_name = path
    else
      file_name = File.join("./content/", path.slice(0,path.size - 1))
      ext = %w{.html .md .rb /index.html /index.rb}.detect do |e|
        File.file?("#{file_name}#{e}")
      end
      file_name = ext ? "#{file_name}#{ext}" : nil
    end
    file_name = File.realpath(file_name) if file_name and File.symlink?(file_name)
    file_name
  end

  # @purpose: Provide git information of an item
  # @author:  Anh K. Huynh
  # @syntax:
  #   git(:date, item)
  #   git(:author, item)
  #   git(:stat, item)
  #   git(:last_update, item)
  # @example: see in layouts/default.html
  def git(op, item)
    file_name = item_to_file(item)

    command = case op
      when :date        then "git log -1 --pretty=\"format:%cd\" \"#{file_name}\""
      when :author      then "git log -1 --pretty=\"format:%an\" \"#{file_name}\""
      when :last_update then "git log -1 --pretty=\"format:last updated by %an @ %cd\" \"#{file_name}\""
      when :stat        then
                              <<-EOF
                                git log --pretty="format:%an" "#{file_name}" | sort    | wc -l ;
                                echo ' commit(s) ';
                                git log --pretty="format:%an" "#{file_name}" | sort -u | wc -l ;
                                echo ' author(s)';
                              EOF
      else nil
    end

    # FIXME: Why do we need a check `File.file?` here?
    op and file_name and command and File.file?(file_name) \
      ? %x{#{command}}.strip.gsub("\n", "") \
      : "Couldn't fetch information for item '#{path}'"
  end

  # @purpose: Test if an item age is lessn than `offset` day(s)
  # @author : Anh K. Huynh
  # @notes  : offset should less than 30
  def item_news?(it, offset = 7)
    file_name = item_to_file(it)
    return false unless file_name

    stdout = %x{git log --date=relative -1 --pretty="format:%cd" \"#{file_name}\"}.strip.gsub("\n", "")
    if stdout.match(/(hour|minute)s? ago/)
      true
    elsif gs = stdout.match(/^([0-9]+) days? ago/)
      gs[1].to_i <= offset
    end
  end

  # @purpose: Print last <num> changes in git log
  # @author : Anh K. Huynh
  # @date   : 2012 July 19th
  # @syntax : recent_changs(number_of_changes)
  def recent_changes(num = 30)
    github = "https://github.com/archlinuxvn/home/commit/"
    command = "git log --pretty=\"format:%h:%an:%s\" -#{num}"

    ret = ["<ol>"]

    current_author = nil
    ret << %x{#{command}}.split(/\n+/).map do |s|
      splitted = CGI.escapeHTML(s.strip).split(":")
      hash = splitted.first
      if hash.match(/^[0-9a-z]+$/)
        author, subject = splitted[1], splitted[2, splitted.size].join(":")
        d_author = (author == current_author ? "" : "-- <strong>#{author}</strong>")
        current_author = author
        "<li><a href=\"%s%s\">%s</a> %s %s</li>" % [github, hash, hash, subject, d_author]
      else
        current_author = nil
        "<li>#{s}</li>"
      end
    end

    ret << ["</ol>"]
    ret.join("\n")
  end

  # @purpose: Provide a hash of all tags and tags' counter
  # @return : Hash {:tag => :counter} (Sorted by :counter)
  # @author : Anh K. Huynh
  # @note   : Valid tag matches /^[a-z0-9]+[a-z0-9-]*[a-z0-9]$/
  def all_tags
    tags = {}
    @items.find_all.each do |p|
      if p[:tags] and p[:tags].is_a?(Array)
        p[:tags].map(&:to_s).map(&:downcase).uniq.select do |tag|
          tag.match(/^[a-z0-9]+[a-z0-9-]*[a-z0-9]$/)
        end.each do |tag|
          tags[tag] = 0 unless tags[tag]
          tags[tag] += 1
        end
      end
    end
    tags.sort do |tix, tax|
      tax[1] <=> tix[1]
    end
  end

  # @purpose: Print last Mnum> posts
  # @author : Anh K. Huynh
  # @date   : 2012 July 25th
  # @syntax : recent_posts(<num>)
  # @notes  : This method is tricky. It reports only some selected posts.
  #           The posts are sorted by modified time returned by the system.
  #           This isn't like (Blogging) where you have to specify the
  #           (created_at) explicitly.
  def recent_posts(num = 30)
    all_items = @items.find_all.sort_by do |i|
      if file_name = item_to_file(i)
        File.mtime(file_name)
      else
        Time.new(0)
      end
    end.reverse.slice(0,num)

    return "" if all_items.empty?

    ret = ["<ol>"]
    all_items.each do |p|
      if gs = p.identifier.match(%r{^/blog/([^/]+)/.+})
        ret << "<li>%s - %s</li>" % [gs[1], link_to(p[:title], p.identifier)]
      elsif gs = p.identifier.match(%r{^/faq/.+})
        ret << "<li>faq - %s</li>" % [link_to(p[:title], p.identifier)]
      elsif gs = p.identifier.match(%r{^/vn/([^/]+)/})
        page = gs[1]
        if %w{author-guide members bot irc lists news}.include?(page)
          ret << "<li>home - %s</li>" % [link_to(p[:title], p.identifier)]
        end
      elsif gs = p.identifier.match(%r{^/doc/.+/})
        ret << "<li>doc - %s</li>" % [link_to(p[:title], p.identifier)]
      end
    end
    ret << ["</ol>"]

    ret.join("\n")
  end

  # @purpose: print license text
  # @author : Anh K. Huynh
  # @date   : 2013 Feb 05
  def license_text(name = "CC BY-SA")
    texts = case name
      when nil, "CC BY-SA"
        ["Trang này là một phần của <b>TheSLInux</b>,",
         " và được phân phối với giấy phép <a href=\"http://creativecommons.org/licenses/by-sa/3.0/vn\">CC BY-SA 3.0</a>.",
         "",
         "Bạn được <b>Sao chép</b>, <b>Chia sẻ</b>, <b>Phân phối</b> trang này dưới điều kiện sau:",
         "",
         "(1) Bạn phải ghi tên tác giả <b>TheSLinux</b> và giấy phép; tuy nhiên <b>không</b>",
         "    được hàm ý tác giả  trao trang này hay quyền sử dụng trang này cho bạn;",
         "(2) Nếu bạn sử dụng, chuyển đổi, hoặc xây dựng dự án từ nội dung được chia sẻ này,",
         "    bạn phải áp dụng giấy phép này hoặc giấy phép khác có các điều khoản tương tự",
         "    như giấy phép này cho dự án của bạn."
        ]
      when false
        []
      when "CC BY-NC-ND 3.0"
        ["Trang này là một phần của <b>TheSLinux</b>,",
         "  và được phân phối với giấy phép <a href=\"http://creativecommons.org/licenses/by-nc-nd/3.0/\">CC BY-NC-ND 3.0</a>.",
         "",
         "Bạn được <b>Sao chép</b>, <b>Chia sẻ</b>, <b>Phân phối</b> trang này dưới điều kiện sau:",
         "",
         "(1) Bạn phải ghi tên tác giả <b>TheSLinux</b> và giấy phép; tuy nhiên <b>không</b>",
         "    được hàm ý tác giả  trao trang này hay quyền sử dụng trang này cho bạn;",
         "(2) Bạn <b>không</b> dùng trang này vào mục đích thương mại;",
         "(3) Bạn <b>không</b> thay đổi, điều chỉnh hay tạo ra sản phẩm từ trang này.",
        ]
      else
        ["This page is published under the license <strong>#{name}</strong>"]
    end
    texts.join("\n")
  end
end
