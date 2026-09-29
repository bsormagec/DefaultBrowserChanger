import os
import re
import sys

def test_landing_page():
    index_path = "docs/index.html"
    assert os.path.exists(index_path), f"File {index_path} not found"
    
    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()

    # 1. Basic Structure & Meta
    assert "<!DOCTYPE html>" in html, "Missing <!DOCTYPE html>"
    assert "<title>" in html and "DefaultBrowserChanger" in html, "Missing proper title"
    assert 'meta name="description"' in html, "Missing meta description"
    assert 'link rel="icon"' in html, "Missing favicon link"

    # 2. Section IDs
    for section_id in ["features", "setup", "faq"]:
        assert f'id="{section_id}"' in html, f"Missing section id: {section_id}"

    # 3. Nav Anchors
    for href in ["#features", "#setup", "#faq"]:
        assert f'href="{href}"' in html, f"Missing nav link to: {href}"

    # 3a. Mobile navigation and responsive layout hooks
    assert '<details class="mobile-nav">' in html, "Missing native mobile navigation disclosure"
    assert '<summary class="mobile-nav-toggle"' in html, "Mobile navigation toggle must be a summary element"
    assert 'class="mobile-nav-links"' in html, "Missing mobile navigation link group"
    assert "@media (max-width: 850px)" in html, "Missing tablet/mobile layout breakpoint"
    assert "@media (max-width: 420px)" in html, "Missing narrow-phone layout breakpoint"
    assert "section[id]" in html and "scroll-margin-top" in html, "In-page navigation must account for the sticky header"
    assert "document.querySelector('.mobile-nav').open = false" in html, "Mobile navigation should close after selecting a link"
    assert "<br> Speed of Thought." in html, "Hiding the desktop line break must preserve a space on mobile"

    # 4. Download Link & GitHub Link
    assert "https://github.com/bsormagec/DefaultBrowserChanger/releases/latest/download/DefaultBrowserChanger.zip" in html, "Missing latest release download URL"
    assert "https://github.com/bsormagec/DefaultBrowserChanger" in html, "Missing GitHub repository URL"

    # 5. Gatekeeper Command
    assert "xattr -cr /Applications/DefaultBrowserChanger.app" in html, "Missing xattr Gatekeeper command"

    # 6. Author credit
    assert "bsormagec" in html, "Missing bsormagec in footer"
    assert "Burak Ormagec" not in html, "Full name should not appear in footer"

    # 7. Local assets existence
    local_img_srcs = re.findall(r'<img[^>]+src=["\']([^"\']+)["\']', html)
    assert len(local_img_srcs) > 0, "No image tags found"
    for src in local_img_srcs:
        if not src.startswith("http") and not src.startswith("data:"):
            # Clean and resolve relative to docs/
            cleaned = src.lstrip("/")
            if cleaned.startswith("files/"):
                cleaned = "assets/" + cleaned[6:]
            elif not cleaned.startswith("assets/"):
                cleaned = "assets/" + cleaned
            disk_path = os.path.join("docs", cleaned)
            assert os.path.exists(disk_path), f"Image source {src} resolved to {disk_path} does not exist"

    print("All landing page verification tests passed successfully!")

if __name__ == "__main__":
    test_landing_page()
