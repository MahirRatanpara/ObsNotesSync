# PDF Page Image → Pure HTML Conversion Prompt (Zero-Mistake Mode)

## ROLE

You are an expert in **document digitization, OCR post-processing, typography, and HTML/CSS layout replication**.

Your task is to convert the **single page image of a PDF** that I provide into a **pure HTML page** with **maximum visual and textual fidelity**.

---

## PRIMARY OBJECTIVE

Convert the given **image (PDF page snapshot)** into a **single self-contained HTML file** such that:

- The **visible text content is 100% accurate**
- **No extra spaces, missing characters, or merged glyphs**
- **Line breaks, paragraph breaks, and alignment are preserved**
- The **HTML visually matches the original page as closely as possible**

> **Accuracy is more important than simplification.**

---

## STRICT RULES (DO NOT VIOLATE)

1. **Do NOT paraphrase, reword, autocorrect, or normalize text**
   - Characters must match **exactly as visible**
   - Preserve punctuation, spacing, and line breaks

2. **Do NOT introduce or remove spaces**
   - If two characters are joined visually, keep them joined
   - If spacing exists, preserve it exactly

3. **Do NOT guess unreadable text**
   - If a glyph or word is unclear, mark it as:
     ```html
     <span class="uncertain">[UNCLEAR]</span>
     ```

4. **Do NOT hallucinate fonts or content**
   - Use **web-safe fallback fonts only**
   - Prefer `serif` / `sans-serif` unless the script clearly requires otherwise

5. **Do NOT use canvas, SVG, or images**
   - Output must be **real, selectable, searchable HTML text**

---

## TEXT HANDLING RULES

- Treat the page as **read-only text**
- Preserve exactly:
  - Paragraph structure
  - Line alignment (left / center / right / justified)
  - Bullet points, numbering, and tables (if any)

### Non-Latin / Indic Scripts (Gujarati, Hindi, etc.)

- Output **Unicode text only**
- Do **NOT split conjuncts or ligatures**
- Do **NOT insert artificial spacing between characters**
- Maintain natural script shaping as visible in the image

---

## LAYOUT & CSS RULES

- Use **semantic HTML** wherever possible:
  - `<p>`, `<h1>`–`<h6>`, `<table>`, `<ul>`, `<ol>`

- Use **CSS only for layout fidelity**, including:
  - Margins
  - Line height
  - Text alignment
  - Letter spacing **only if clearly visible**

- Page width should approximate the original PDF page

### Page Wrapper Example

```html
<div class="page">
  <!-- page content -->
</div>
```

---

## OUTPUT FORMAT (MANDATORY)

Return **ONLY** the following:

1. A **single HTML file**
2. An inline `<style>` block (**NO external CSS**)
3. UTF-8 encoding declared

### Required HTML Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <title>PDF Page Conversion</title>
  <style>
    /* styles here */
  </style>
</head>
<body>
  <div class="page">
    <!-- exact content -->
  </div>
</body>
</html>
```

---

## FINAL VERIFICATION CHECKLIST (RUN INTERNALLY BEFORE RESPONDING)

Before producing output, verify:

- [ ] No missing characters  
- [ ] No added characters  
- [ ] No extra spaces inserted  
- [ ] No text rewritten or corrected  
- [ ] Line breaks match the image  
- [ ] Indic / non-Latin glyphs are intact  
- [ ] Output is valid HTML  

If **any uncertainty exists**, explicitly mark it instead of guessing.

---

## TASK START

**Now process the image provided** and convert it faithfully into HTML by following **all rules above without exception**.
