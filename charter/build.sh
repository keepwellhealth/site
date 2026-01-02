#!/bin/bash
# Build script for Charter Book
# Converts Markdown files to HTML, PDF, and EPUB formats

set -e  # Exit on error

# Configuration
BOOK_TITLE="Charter Book"
BOOK_PDF="charter-book.pdf"
BOOK_EPUB="charter-book.epub"
BOOK_HTML="charter-book.html"
INDEX_HTML="index.html"
STYLE_CSS="style.css"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_dependencies() {
    if ! command -v pandoc &> /dev/null; then
        print_error "pandoc is not installed. Please install it first."
        echo "  Ubuntu/Debian: sudo apt-get install pandoc"
        echo "  macOS: brew install pandoc"
        exit 1
    fi
    print_info "Dependencies check passed"
}

create_css() {
    if [ ! -f "$STYLE_CSS" ]; then
        print_info "Creating stylesheet..."
        cat > "$STYLE_CSS" <<'EOF'
/* Reset and base styles */
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: Georgia, serif;
    line-height: 1.6;
    color: #333;
    overflow: hidden;
    height: 100vh;
}

/* Book viewer layout */
.book-viewer {
    display: flex;
    height: 100vh;
    width: 100%;
}

/* Table of Contents sidebar */
.toc-sidebar {
    width: 320px;
    background: #f8f9fa;
    border-right: 1px solid #dee2e6;
    overflow-y: auto;
    flex-shrink: 0;
}

.toc-header {
    padding: 1.5rem;
    background: #0066cc;
    color: white;
    position: sticky;
    top: 0;
    z-index: 10;
}

.toc-header h1 {
    font-size: 1.5rem;
    margin-bottom: 0.5rem;
}

.toc-header p {
    font-size: 0.9rem;
    opacity: 0.9;
}

.toc-list {
    list-style: none;
    padding: 0;
}

.toc-list li {
    border-bottom: 1px solid #e9ecef;
}

.toc-list a {
    display: block;
    padding: 0.75rem 1.5rem;
    color: #495057;
    text-decoration: none;
    transition: all 0.2s;
}

.toc-list a:hover {
    background: #e9ecef;
    color: #0066cc;
    padding-left: 2rem;
}

.toc-list a.active {
    background: #e7f3ff;
    color: #0066cc;
    border-left: 4px solid #0066cc;
    font-weight: bold;
}

.download-section {
    padding: 1.5rem;
    border-top: 2px solid #dee2e6;
    background: #fff;
}

.download-section h3 {
    margin-bottom: 1rem;
    font-size: 1rem;
    color: #495057;
}

.download-links {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
}

.download-links a {
    padding: 0.5rem 1rem;
    background: #0066cc;
    color: white;
    text-decoration: none;
    border-radius: 4px;
    text-align: center;
    transition: background 0.2s;
}

.download-links a:hover {
    background: #0052a3;
}

/* Chapter viewer */
.chapter-viewer {
    flex: 1;
    overflow-y: auto;
    background: white;
}

.chapter-content {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
}

.chapter-content h1 {
    margin-bottom: 1.5rem;
    color: #0066cc;
}

.chapter-content h2 {
    margin-top: 2rem;
    margin-bottom: 1rem;
    color: #495057;
}

.chapter-content h3 {
    margin-top: 1.5rem;
    margin-bottom: 0.75rem;
    color: #6c757d;
}

.chapter-content p {
    margin-bottom: 1rem;
}

.chapter-content ul, .chapter-content ol {
    margin-bottom: 1rem;
    padding-left: 2rem;
}

.chapter-content li {
    margin-bottom: 0.5rem;
}

/* Loading state */
.loading {
    text-align: center;
    padding: 3rem;
    color: #6c757d;
}

/* Mobile toggle button */
.mobile-toggle {
    display: none;
    position: fixed;
    bottom: 1rem;
    right: 1rem;
    background: #0066cc;
    color: white;
    border: none;
    border-radius: 50%;
    width: 56px;
    height: 56px;
    font-size: 1.5rem;
    cursor: pointer;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    z-index: 1000;
}

.mobile-toggle:hover {
    background: #0052a3;
}

/* Responsive design */
@media (max-width: 768px) {
    .toc-sidebar {
        position: fixed;
        left: -100%;
        top: 0;
        height: 100vh;
        width: 280px;
        z-index: 999;
        transition: left 0.3s;
        box-shadow: 2px 0 10px rgba(0, 0, 0, 0.1);
    }
    
    .toc-sidebar.open {
        left: 0;
    }
    
    .mobile-toggle {
        display: block;
    }
    
    .chapter-content {
        padding: 1rem;
    }
}

/* Chapter navigation for individual chapter pages */
.chapter-nav {
    margin: 2em 0;
    padding: 1em;
    background: #f5f5f5;
    text-align: center;
    border-radius: 4px;
}

.chapter-nav a {
    margin: 0 1em;
    text-decoration: none;
    color: #0066cc;
}

.chapter-nav a:hover {
    text-decoration: underline;
}
EOF
    fi
}

build_html() {
    print_info "Building HTML files..."
    
    local chapters=($(ls md/chapter-*.md 2>/dev/null | sort))
    local total=${#chapters[@]}
    
    if [ $total -eq 0 ]; then
        print_error "No chapter files found!"
        exit 1
    fi
    
    for i in "${!chapters[@]}"; do
        local chapter="${chapters[$i]}"
        local html_file="$(basename "${chapter%.md}").html"
        local current_num=$((i + 1))

        # Determine previous and next chapters
        local prev_chapter=""
        local next_chapter=""

        if [ $i -gt 0 ]; then
            prev_chapter="$(basename "${chapters[$((i-1))]%.md}").html"
        fi

        if [ $i -lt $((total - 1)) ]; then
            next_chapter="$(basename "${chapters[$((i+1))]%.md}").html"
        fi
        
        # Build navigation
        local nav="<nav class='chapter-nav'>"
        [ -n "$prev_chapter" ] && nav="$nav<a href='$prev_chapter'>← Previous</a>"
        nav="$nav <a href='$INDEX_HTML'>Index</a> "
        [ -n "$next_chapter" ] && nav="$nav<a href='$next_chapter'>Next →</a>"
        nav="$nav</nav>"
        
        # Convert to HTML
        print_info "  [$current_num/$total] $chapter -> $html_file"
        pandoc --standalone --to=html5 --css="$STYLE_CSS" "$chapter" -o "${html_file}.tmp"
        sed "s|</body>|$nav</body>|" "${html_file}.tmp" > "$html_file"
        rm "${html_file}.tmp"
    done
    
    print_info "HTML files created successfully"
}

build_index() {
    print_info "Building index page..."
    
    cat > "$INDEX_HTML" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset='utf-8'>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Charter Book - Interactive Viewer</title>
    <link rel='stylesheet' href='style.css'>
</head>
<body>
    <div class="book-viewer">
        <!-- Table of Contents Sidebar -->
        <aside class="toc-sidebar" id="tocSidebar">
            <div class="toc-header">
                <h1>Charter Book</h1>
                <p>An Interactive Reading Experience</p>
            </div>
            <nav>
                <ul class="toc-list" id="tocList">
HTMLEOF

    # Generate TOC list items
    for chapter in $(ls md/chapter-*.md 2>/dev/null | sort); do
        local title=$(grep "^# " "$chapter" | head -1 | sed 's/^# //')
        local base="$(basename "${chapter%.md}")"
        cat >> "$INDEX_HTML" <<ITEMEOF
                    <li><a href="#" data-chapter="$base.html">$title</a></li>
ITEMEOF
    done

    cat >> "$INDEX_HTML" <<'HTMLEOF'
                </ul>
            </nav>
            <div class="download-section">
                <h3>Download Options</h3>
                <div class="download-links">
HTMLEOF

    cat >> "$INDEX_HTML" <<DOWNLOADEOF
                    <a href="$BOOK_HTML">📄 Single Page HTML</a>
                    <a href="$BOOK_PDF">📕 Download PDF</a>
                    <a href="$BOOK_EPUB">📚 Download EPUB</a>
DOWNLOADEOF

    cat >> "$INDEX_HTML" <<'HTMLEOF'
                </div>
            </div>
        </aside>

        <!-- Chapter Viewer -->
        <main class="chapter-viewer" id="chapterViewer">
            <div class="chapter-content" id="chapterContent">
                <div class="loading">
                    <h2>Welcome to Charter Book</h2>
                    <p>Select a chapter from the left sidebar to begin reading.</p>
                </div>
            </div>
        </main>
    </div>

    <!-- Mobile TOC Toggle Button -->
    <button class="mobile-toggle" id="mobileToggle" aria-label="Toggle Table of Contents">
        ☰
    </button>

    <script>
        // Book Viewer JavaScript
        const tocList = document.getElementById('tocList');
        const chapterContent = document.getElementById('chapterContent');
        const chapterViewer = document.getElementById('chapterViewer');
        const tocSidebar = document.getElementById('tocSidebar');
        const mobileToggle = document.getElementById('mobileToggle');

        // Load chapter content
        async function loadChapter(chapterFile) {
            try {
                chapterContent.innerHTML = '<div class="loading">Loading chapter...</div>';
                
                const response = await fetch(chapterFile);
                if (!response.ok) throw new Error('Failed to load chapter');
                
                const html = await response.text();
                
                // Parse the HTML to extract just the content
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                const body = doc.body;
                
                // Remove navigation elements if present
                const nav = body.querySelector('.chapter-nav');
                if (nav) nav.remove();
                
                // Extract and display content
                chapterContent.innerHTML = body.innerHTML;
                
                // Scroll to top of chapter viewer
                chapterViewer.scrollTop = 0;
                
                // Update URL hash
                window.location.hash = chapterFile;
                
                // Update active state in TOC
                updateActiveTOC(chapterFile);
                
                // Close mobile menu if open
                if (window.innerWidth <= 768) {
                    tocSidebar.classList.remove('open');
                }
            } catch (error) {
                chapterContent.innerHTML = `
                    <div class="loading">
                        <h2>Error Loading Chapter</h2>
                        <p>Could not load the chapter. Please try again.</p>
                    </div>
                `;
                console.error('Error loading chapter:', error);
            }
        }

        // Update active TOC item
        function updateActiveTOC(chapterFile) {
            const links = tocList.querySelectorAll('a');
            links.forEach(link => {
                if (link.dataset.chapter === chapterFile) {
                    link.classList.add('active');
                    // Scroll TOC to show active item
                    link.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                } else {
                    link.classList.remove('active');
                }
            });
        }

        // Handle TOC clicks
        tocList.addEventListener('click', (e) => {
            if (e.target.tagName === 'A') {
                e.preventDefault();
                const chapterFile = e.target.dataset.chapter;
                if (chapterFile) {
                    loadChapter(chapterFile);
                }
            }
        });

        // Mobile toggle handler
        mobileToggle.addEventListener('click', () => {
            tocSidebar.classList.toggle('open');
        });

        // Close mobile menu when clicking outside
        document.addEventListener('click', (e) => {
            if (window.innerWidth <= 768 && 
                tocSidebar.classList.contains('open') &&
                !tocSidebar.contains(e.target) && 
                e.target !== mobileToggle) {
                tocSidebar.classList.remove('open');
            }
        });

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            const activeLink = tocList.querySelector('a.active');
            if (!activeLink) return;

            let nextLink = null;
            
            if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
                // Next chapter
                const nextLi = activeLink.parentElement.nextElementSibling;
                if (nextLi) nextLink = nextLi.querySelector('a');
            } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
                // Previous chapter
                const prevLi = activeLink.parentElement.previousElementSibling;
                if (prevLi) nextLink = prevLi.querySelector('a');
            }

            if (nextLink) {
                e.preventDefault();
                loadChapter(nextLink.dataset.chapter);
            }
        });

        // Load chapter from URL hash on page load
        window.addEventListener('load', () => {
            const hash = window.location.hash.substring(1);
            if (hash) {
                loadChapter(hash);
            } else {
                // Load first chapter by default
                const firstLink = tocList.querySelector('a');
                if (firstLink) {
                    loadChapter(firstLink.dataset.chapter);
                }
            }
        });

        // Handle browser back/forward
        window.addEventListener('hashchange', () => {
            const hash = window.location.hash.substring(1);
            if (hash) {
                loadChapter(hash);
            }
        });
    </script>
</body>
</html>
HTMLEOF
    
    print_info "Index page created: $INDEX_HTML"
}

build_pdf() {
    print_info "Building PDF book..."
    
    local chapters=($(ls md/chapter-*.md 2>/dev/null | sort))
    
    if [ ${#chapters[@]} -eq 0 ]; then
        print_error "No chapter files found!"
        exit 1
    fi
    
    pandoc --pdf-engine=xelatex --toc --toc-depth=2 \
        -M title="$BOOK_TITLE" \
        "${chapters[@]}" -o "$BOOK_PDF"
    
    print_info "PDF created: $BOOK_PDF ($(du -h "$BOOK_PDF" | cut -f1))"
}

build_epub() {
    print_info "Building EPUB book..."
    
    local chapters=($(ls md/chapter-*.md 2>/dev/null | sort))
    
    if [ ${#chapters[@]} -eq 0 ]; then
        print_error "No chapter files found!"
        exit 1
    fi
    
    pandoc --toc --toc-depth=2 \
        -M title="$BOOK_TITLE" \
        "${chapters[@]}" -o "$BOOK_EPUB"
    
    print_info "EPUB created: $BOOK_EPUB ($(du -h "$BOOK_EPUB" | cut -f1))"
}

build_single_html() {
    print_info "Building single combined HTML document..."
    
    local chapters=($(ls md/chapter-*.md 2>/dev/null | sort))
    
    if [ ${#chapters[@]} -eq 0 ]; then
        print_error "No chapter files found!"
        exit 1
    fi
    
    pandoc --standalone --to=html5 --toc --toc-depth=2 \
        --css="$STYLE_CSS" \
        -M title="$BOOK_TITLE" \
        "${chapters[@]}" -o "$BOOK_HTML"
    
    print_info "Combined HTML created: $BOOK_HTML ($(du -h "$BOOK_HTML" | cut -f1))"
}

clean() {
    print_info "Cleaning build files..."
    rm -f chapter-*.html "$BOOK_PDF" "$BOOK_EPUB" "$BOOK_HTML" "$INDEX_HTML"
    print_info "Clean complete"
}

distclean() {
    clean
    rm -f "$STYLE_CSS"
    print_info "Deep clean complete"
}

show_help() {
    cat <<EOF
Charter Book Build System

Usage: ./build.sh [COMMAND]

Commands:
    all         Build everything (HTML, PDF, EPUB, single HTML, and index) [default]
    html        Build individual HTML files with navigation
    book        Build single combined HTML document with all chapters
    pdf         Build single PDF book
    epub        Build EPUB book
    index       Build HTML index/table of contents
    clean       Remove all generated files
    distclean   Remove all generated files including CSS
    help        Show this help message

Examples:
    ./build.sh              # Build everything
    ./build.sh html         # Build only HTML files
    ./build.sh book pdf     # Build combined HTML and PDF

EOF
}

# Main script
main() {
    check_dependencies
    create_css
    
    # If no arguments, build everything
    if [ $# -eq 0 ]; then
        set -- "all"
    fi
    
    # Process commands
    for cmd in "$@"; do
        case "$cmd" in
            all)
                build_html
                build_single_html
                build_pdf
                build_epub
                build_index
                print_info "✅ All builds complete!"
                ;;
            html)
                build_html
                ;;
            book)
                build_single_html
                ;;
            pdf)
                build_pdf
                ;;
            epub)
                build_epub
                ;;
            index)
                build_index
                ;;
            clean)
                clean
                ;;
            distclean)
                distclean
                ;;
            help|--help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown command: $cmd"
                show_help
                exit 1
                ;;
        esac
    done
}

# Run main function
main "$@"
