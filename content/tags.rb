---
title: Thẻ (tag) đánh dấu bài viết
virtual: true
---

<%= all_tags.map {|tag, count| sprintf("%s (%s)", link_for_tag(tag, "/tags/"), count) }.join(", ") %>
