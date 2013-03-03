
module TaggingHelper
  # Purpose: Add a slash / to the end of the link
  #          The original version in Nanoc::Helpers::Tagging
  #          does not contain the slash, and we need redirection
  #          step in server configuration
  def link_for_tag(tag, base_url)
    %[<a href="#{h base_url}#{h tag}/" rel="tag">#{h tag}</a>]
  end
end
