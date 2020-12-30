all: html

pdf: index.adoc
	touch Clean_Architectures_in_Python.pdf
	docker run --rm -v $$(pwd):/documents/ asciidoctor/docker-asciidoctor asciidoctor-pdf -a pdf-theme=theme.yml index.adoc -o Clean_Architectures_in_Python.pdf

html: index.adoc
	asciidoctor -a stylesheet=custom.css -a source-highlighter=rouge -T html5 -r ./asciidoctor-extensions-lab/lib/google-analytics-docinfoprocessor.rb index.adoc

release: html
	rm -fR pycabook.github.io/*
	cp -R index.html custom.css images pycabook.github.io
