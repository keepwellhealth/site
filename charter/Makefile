# Makefile for Charter Book
# Converts Markdown files to HTML, PDF, and EPUB formats

# Configuration
CHAPTERS := $(sort $(wildcard chapter-*.md))
HTML_FILES := $(CHAPTERS:.md=.html)
BOOK_TITLE := "Charter Book"
BOOK_PDF := charter-book.pdf
BOOK_EPUB := charter-book.epub
INDEX_HTML := index.html

# Pandoc options
PANDOC := pandoc
PANDOC_HTML_OPTS := --standalone --to=html5 --css=style.css
PANDOC_PDF_OPTS := --pdf-engine=xelatex --toc --toc-depth=2
PANDOC_EPUB_OPTS := --toc --toc-depth=2

# Default target
.PHONY: all
all: html pdf epub index

# Build all HTML files
.PHONY: html
html: $(HTML_FILES)

# Pattern rule for converting MD to HTML with navigation
%.html: %.md
	@echo "Building $@..."
	@PREV=$$(ls chapter-*.md 2>/dev/null | grep -B1 "^$<$$" | head -1 | sed 's/\.md//'); \
	NEXT=$$(ls chapter-*.md 2>/dev/null | grep -A1 "^$<$$" | tail -1 | sed 's/\.md//'); \
	CURRENT=$$(basename $< .md); \
	NAV="<nav class='chapter-nav'>"; \
	if [ "$$PREV" != "" ] && [ "$$PREV" != "$$CURRENT" ]; then \
		NAV="$$NAV<a href='$$PREV.html'>← Previous</a>"; \
	fi; \
	NAV="$$NAV <a href='index.html'>Index</a> "; \
	if [ "$$NEXT" != "" ] && [ "$$NEXT" != "$$CURRENT" ]; then \
		NAV="$$NAV<a href='$$NEXT.html'>Next →</a>"; \
	fi; \
	NAV="$$NAV</nav>"; \
	$(PANDOC) $(PANDOC_HTML_OPTS) $< -o $@.tmp && \
	sed "s|</body>|$$NAV</body>|" $@.tmp > $@ && \
	rm $@.tmp

# Build single PDF from all chapters
.PHONY: pdf
pdf: $(BOOK_PDF)

$(BOOK_PDF): $(CHAPTERS)
	@echo "Building PDF book..."
	$(PANDOC) $(PANDOC_PDF_OPTS) -M title=$(BOOK_TITLE) $(CHAPTERS) -o $@
	@echo "PDF created: $(BOOK_PDF)"

# Build EPUB from all chapters
.PHONY: epub
epub: $(BOOK_EPUB)

$(BOOK_EPUB): $(CHAPTERS)
	@echo "Building EPUB book..."
	$(PANDOC) $(PANDOC_EPUB_OPTS) -M title=$(BOOK_TITLE) $(CHAPTERS) -o $@
	@echo "EPUB created: $(BOOK_EPUB)"

# Build index page
.PHONY: index
index: $(INDEX_HTML)

$(INDEX_HTML): $(CHAPTERS)
	@echo "Building index page..."
	@echo "<!DOCTYPE html>" > $@
	@echo "<html><head><meta charset='utf-8'>" >> $@
	@echo "<title>$(BOOK_TITLE) - Table of Contents</title>" >> $@
	@echo "<link rel='stylesheet' href='style.css'></head><body>" >> $@
	@echo "<h1>$(BOOK_TITLE)</h1>" >> $@
	@echo "<h2>Table of Contents</h2><ul>" >> $@
	@for f in $(CHAPTERS); do \
		TITLE=$$(grep "^# " $$f | head -1 | sed 's/^# //'); \
		BASE=$$(basename $$f .md); \
		echo "<li><a href='$$BASE.html'>$$TITLE</a></li>" >> $@; \
	done
	@echo "</ul>" >> $@
	@echo "<p><a href='$(BOOK_PDF)'>Download PDF</a> | <a href='$(BOOK_EPUB)'>Download EPUB</a></p>" >> $@
	@echo "</body></html>" >> $@
	@echo "Index created: $(INDEX_HTML)"

# Create a basic CSS file if it doesn't exist
style.css:
	@echo "Creating basic stylesheet..."
	@echo "body { max-width: 800px; margin: 2em auto; padding: 0 1em; font-family: Georgia, serif; line-height: 1.6; }" > $@
	@echo "h1, h2, h3 { color: #333; }" >> $@
	@echo ".chapter-nav { margin: 2em 0; padding: 1em; background: #f5f5f5; text-align: center; }" >> $@
	@echo ".chapter-nav a { margin: 0 1em; text-decoration: none; color: #0066cc; }" >> $@
	@echo ".chapter-nav a:hover { text-decoration: underline; }" >> $@

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build files..."
	rm -f $(HTML_FILES) $(BOOK_PDF) $(BOOK_EPUB) $(INDEX_HTML)
	@echo "Clean complete"

# Clean including CSS
.PHONY: distclean
distclean: clean
	rm -f style.css

# Help target
.PHONY: help
help:
	@echo "Charter Book Build System"
	@echo ""
	@echo "Targets:"
	@echo "  make all       - Build everything (HTML, PDF, EPUB, and index)"
	@echo "  make html      - Build individual HTML files with navigation"
	@echo "  make pdf       - Build single PDF book"
	@echo "  make epub      - Build EPUB book"
	@echo "  make index     - Build HTML index/table of contents"
	@echo "  make clean     - Remove all generated files"
	@echo "  make distclean - Remove all generated files including CSS"
	@echo "  make help      - Show this help message"
