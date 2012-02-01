#
# That's right, pdflatex has to be run 3 times.
#

all: proposal.pdf

proposal.pdf: proposal.tex refs.bib
	pdflatex proposal.tex
	bibtex proposal
	pdflatex proposal.tex
	pdflatex proposal.tex

