require Rails.root.join("lib", "markdown_erb_template_handler").to_s

ActionView::Template.register_template_handler(:mderb, MarkdownErbTemplateHandler.new)
