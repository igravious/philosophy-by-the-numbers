
def texify(delivery)

	require 'erb'
	require 'tilt'

	@delivery = delivery
	
	edition_template = Tilt.new('/home/anthony/LaTeX/limited.tex.erb')

	#puts edition_template.render(self)
	f = File.new('/home/anthony/LaTeX/limited.tex', 'w')
	f.write(edition_template.render(self))
	f.close   

	unique_template = Tilt.new('/home/anthony/LaTeX/unique.tex.erb')

	#puts unique_template.render(self)
	f = File.new('/home/anthony/LaTeX/unique.tex', 'w')
	f.write(unique_template.render(self))
	f.close

	ENV['PATH'] += ':/usr/local/texlive/2016/bin/x86_64-linux'
	wd = Dir.getwd
	Dir.chdir '/home/anthony/LaTeX'
	foo = system('make -f /home/anthony/LaTeX/Makefile')
	#foo = `make -f /home/anthony/LaTeX/Makefile`
	Dir.chdir wd
	return foo
end	
