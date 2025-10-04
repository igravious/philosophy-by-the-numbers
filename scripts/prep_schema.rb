
require 'rouge'

# make some nice lexed html
source = IO.read(File.join(Rails.root, 'db/schema.rb'))
formatter = Rouge::Formatters::HTML.new
lexer = Rouge::Lexers::Ruby.new
html_schema = formatter.format(lexer.lex(source))
#
# # Get some CSS
css_schema = Rouge::Themes::Base16.mode(:light).render(scope: '.highlight')
puts "<style>\n#{css_schema}\n</style>\n<pre class='highlight'>\n#{html_schema}</pre>"
