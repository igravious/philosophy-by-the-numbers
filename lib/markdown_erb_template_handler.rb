class MarkdownErbTemplateHandler
  def erb
    @erb ||= ActionView::Template.registered_template_handler(:erb)
  end	

  def call(template)
		compiled_source = erb.call(template)
		<<-SOURCE
    renderer = Redcarpet::Render::HTML.new # (hard_wrap: true)
    options = {
			tables: true,
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true 
    }
    Redcarpet::Markdown.new(renderer, options).render(begin;#{compiled_source};end)
    SOURCE
	end
end
