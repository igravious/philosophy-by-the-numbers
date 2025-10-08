# Markdown+ERB Layout (DISABLED)

## File: application.mderb.unused

This layout was renamed from `application.mderb` to disable it because:

1. **Redcarpet gem not installed** - The custom `.mderb` template handler requires the Redcarpet markdown gem, which is not in the Gemfile
2. **No active usage** - No current controller code uses `format.mderb` (only found in `.orig` backup files)
3. **Test failures** - Caused `uninitialized constant ActionView::CompiledTemplates::Redcarpet` errors in test suite

## What it was for

The `.mderb` extension is a custom template handler registered in:
- `config/initializers/markdown_config.rb`
- `lib/markdown_erb_template_handler.rb`

It processes ERB first, then runs the result through Redcarpet markdown rendering.

## To re-enable

If you need this functionality again:

1. Add to Gemfile: `gem 'redcarpet'`
2. Run: `bundle install`
3. Rename back: `mv application.mderb.unused application.mderb`
4. The template handler registration already exists in config/initializers/markdown_config.rb

## Historical context

Originally used in `philosophers_controller.rb` (see .orig backup) for rendering markdown-formatted responses.
The simplified layout contains just CSS/JS includes and yield - likely for AJAX or partial requests.
