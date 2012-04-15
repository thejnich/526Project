#
# That's right, pdflatex has to be run 3 times.
#

all: proposal update final_report

open: final_report
	open final_report.pdf

final_report: final_report.pdf

proposal: proposal.pdf

update: status_update.pdf

proposal.pdf: proposal.tex refs.bib
	pdflatex proposal.tex        # first pass
	bibtex proposal              # extract reference data
	pdflatex proposal.tex        # matches citations/references
	pdflatex proposal.tex        # finishes all cross referencing

status_update.pdf: status_update.tex refs.bib
	pdflatex status_update.tex
	bibtex status_update
	pdflatex status_update.tex
	pdflatex status_update.tex

final_report.pdf: final_report.tex Makefile
	pdflatex final_report.tex
	bibtex final_report
	pdflatex final_report.tex
	pdflatex final_report.tex

# This is ugly, rm -rf proposal.{aux,bbl,blg,...} doesn't work though
clean:
	rm -r proposal.aux
	rm -r proposal.bbl
	rm -r proposal.blg
	rm -r proposal.log
	rm -r proposal.out
	rm -r proposal.pdf
	rm -r proposal.toc
	rm -r status_update.aux
	rm -r status_update.bbl
	rm -r status_update.blg
	rm -r status_update.log
	rm -r status_update.out
	rm -r status_update.pdf
	rm -r status_update.toc
	rm -rf texput.log
	rm -r final_report.aux
	rm -r final_report.pdf
	rm -r final_report.log
	rm -r final_report.blg
	rm -r final_report.bbl


