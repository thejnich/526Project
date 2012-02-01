#
# That's right, pdflatex has to be run 3 times.
#

all: proposal.pdf

proposal.pdf: proposal.tex refs.bib
	pdflatex proposal.tex
	bibtex proposal
	pdflatex proposal.tex
	pdflatex proposal.tex

# This is ugly, rm -rf proposal.{aux,bbl,blg,...} doesn't work though
clean:
	rm -r proposal.aux
	rm -r proposal.bbl
	rm -r proposal.blg
	rm -r proposal.log
	rm -r proposal.out
	rm -r proposal.pdf
	rm -r proposal.toc

