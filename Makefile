#
# That's right, pdflatex has to be run 3 times.
#

all: proposal.pdf

proposal.pdf: proposal.tex refs.bib
	pdflatex proposal.tex        # first pass
	bibtex proposal              # extract reference data
	pdflatex proposal.tex        # matches citations/references
	pdflatex proposal.tex        # finishes all cross referencing

# This is ugly, rm -rf proposal.{aux,bbl,blg,...} doesn't work though
clean:
	rm -r proposal.aux
	rm -r proposal.bbl
	rm -r proposal.blg
	rm -r proposal.log
	rm -r proposal.out
	rm -r proposal.pdf
	rm -r proposal.toc

