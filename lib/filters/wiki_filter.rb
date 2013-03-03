########################################################################
# WARNING: normal authors are not allowed to change this file.         #
#          all changes will be simply ignored by server                #
########################################################################

# @purpose: A post-processed filter to provide wiki-style when writing
#           article. This filter should be executed after any other filter.
# @author : Anh K. Huynh
#
# @desc   : Replaces [[id<title>]] by a link. The <title> is optional.
#           The `id` may be absolute or relative to `/doc/`. For example
#               /vn/author-guide/   : absolute
#               git/gitconfig       : it's /doc/git/gitconfig/
#           The colon (:) can be used instead of a slash (/)
#           If thte <title> is missing, the last part of the `id` will be
#           used as title: it will be transformed to the camelized form
#           by splitting the original `id` by the underscore (_).
#
# @example:
#   Absolute path
#     [[/vn/author-guide]]
#     [[/doc/git/gitconfig]]
#     [[/blog:~huy:Ibus_and_Qt Configure Ibus for Qt applications]]
#
#   Relative path ([[foobar]] is equivalent to [[/doc/foobar]])
#     [[git/gitconfig]]
#     [[git:gitconfig Git Configuration]]
#
# @return : HTML output
#
class WikiFilter < Nanoc::Filter
  identifier :wiki
  type :text => :text

  def run(content, params={})
    content.gsub(%r{\[\[([^\[\][:space:]]+)( .*)?\]\]}) do |m|
      path, title = $1, $2
      path.gsub!(":", "/")
      path = "#{path.chomp('/')}/"
      path = "/doc/#{path}" unless path[0] == "/"
      title = path.split("/").last.split("_").map(&:capitalize).join(" ") if title.nil?
      title.strip!
      "<a href=\"%s\">%s</a>" % [path, title]
    end.gsub(%r{:([a-z0-9_-]+):}) do |m|
      smile = $1.downcase
      file_name = "./content/i/sm/#{smile}.gif"
      File.file?(file_name) \
        ? "<img width=\"25px\" src=\"/i/sm/#{smile}.gif\"/>" \
        : m
    end
  end
end
