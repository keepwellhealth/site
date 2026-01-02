# Charter Book Build System

This directory contains tools to build your charter book from Markdown files into multiple formats.

## Files Created

- **Makefile** - GNU Make-based build system
- **build.sh** - Standalone bash script (more portable, colorful output)
- **README.md** - This file

## Quick Start

### Using the Shell Script (Recommended)

```bash
# Build everything (HTML, PDF, EPUB, and index page)
./build.sh

# Or build specific formats
./build.sh html      # Just HTML files
./build.sh pdf       # Just PDF
./build.sh epub      # Just EPUB
./build.sh html pdf  # HTML and PDF

# Clean up generated files
./build.sh clean
```

### Using Make

```bash
# Build everything
make

# Or build specific targets
make html      # Individual HTML files with navigation
make pdf       # Single PDF book
make epub      # EPUB ebook
make index     # HTML index/table of contents

# Clean up
make clean
```

## What Gets Built

1. **Individual HTML files** - One for each chapter with:
   - Previous/Next navigation links
   - Link back to index
   - Responsive CSS styling

2. **index.html** - Table of contents page linking all chapters

3. **charter-book.pdf** - Single PDF containing all chapters with:
   - Table of contents
   - Proper pagination

4. **charter-book.epub** - EPUB ebook format for e-readers

5. **style.css** - Clean, readable stylesheet (auto-generated)

## Requirements

- **pandoc** - Document converter
  - Ubuntu/Debian: `sudo apt-get install pandoc texlive-xetex`
  - macOS: `brew install pandoc basictex`

## Customization

Edit these variables in either file:

- `BOOK_TITLE` - Change the book title
- `BOOK_PDF` / `BOOK_EPUB` - Change output filenames
- Pandoc options for different styling or formats

## Tips

- The build system automatically finds all `chapter-*.md` files
- Chapters are sorted alphabetically (so chapter-01, chapter-02, etc.)
- HTML files include navigation between chapters
- You can customize `style.css` after first build
- Use `make help` or `./build.sh help` for more options

## Troubleshooting

**PDF generation fails:**
- Make sure you have a LaTeX distribution installed (texlive-xetex)
- Try changing `--pdf-engine=xelatex` to `--pdf-engine=pdflatex`

**Missing chapters:**
- Ensure files are named `chapter-*.md`
- Check that files are in the same directory as the build scripts
