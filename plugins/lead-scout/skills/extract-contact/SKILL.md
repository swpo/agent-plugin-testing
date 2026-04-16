---
name: extract-contact
description: "Per-company constraint check and contact extraction. Designed to be the template prompt for a subagent invocation — each subagent handles one company. Also usable directly for ad-hoc single-company checks."
---

# Extract Contact

Given one company, check whether its website matches a constraint and — if yes — pull contact information. Return structured JSON.

## Input

- `company_name` — display name (may be best-guess from the search snippet)
- `url` — the company's homepage or landing URL
- `constraint` — natural-language check (e.g. "has a contact page", "offers private instruction", "provides 24-hour emergency service")
- `output_columns` — fields to include in the return object
- `firecrawl_available` — whether to use firecrawl or fallback to WebFetch

## Workflow

### 1. Fetch the homepage

- If Firecrawl MCP tools are available (`firecrawl_scrape` or similar): call the firecrawl scrape tool on the URL. Firecrawl returns clean markdown of the main content.
- Else: WebFetch tool on the URL, with a prompt asking for the page content as markdown.

### 2. Look for a contact page link

Look at the scraped content for links like "Contact", "Contact Us", "Get in Touch", "Reach Us". If found and `constraint` involves contact access, that's strong positive signal. Follow the link — scrape the contact page too (same mechanism).

### 3. Check the constraint

Use your judgment against the fetched content. Err toward `uncertain` over false `match` — the user would rather review a shortlist than chase bad leads.

- **"has a contact page"** → clear yes/no based on step 2.
- **Service offerings** ("offers private instruction", "provides X service") → look for an explicit mention in services/about/menu content. If you see adjacent but not explicit mentions, `uncertain` with evidence.
- **Operational attributes** ("accepts walk-ins", "open weekends") → usually on hours or FAQ page; may require fetching an additional page.
- **Geographic** ("serves the Bay Area") → check locations/service-area listings.

For semantic checks, quote a short (<15 words) snippet of supporting evidence from the page in the `match_evidence` field.

### 4. Extract contact info

For any fields in `output_columns` you can find:

- `email` — prefer a named inbox (`jane@example.com`) over a generic (`info@example.com`), but record whatever's visible. If multiple, pick the most appropriate (contact / sales / owner).
- `phone` — normalize to E.164 where obvious (+1 555 123 4567), else record as shown.
- `address` — full postal address if given.
- `contact_page_url` — URL of the contact page (absolute).
- `principal_name` — owner, founder, director, or primary contact name if given. Skip if not obvious.
- `notes` — short free-text. Useful for anything the user should know: "Contact form only, no email", "Only phone listed", "Large chain — may not be right fit".

Do NOT fabricate. If you can't find a field, leave it empty (empty string or null).

### 5. Return

Return a single JSON object with all requested columns plus `match_status` and `match_evidence`:

```json
{
  "company_name": "Example Title Co",
  "url": "https://example.com",
  "match_status": "match",
  "match_evidence": "'Get in Touch' page linked from footer",
  "contact_page_url": "https://example.com/contact",
  "email": "info@example.com",
  "phone": "+1 555 123 4567",
  "address": "123 Main St, Austin, TX 78701",
  "principal_name": "",
  "notes": ""
}
```

`match_status` values: `match` | `no-match` | `uncertain` | `error`.

On `error`, still return the object with `notes` explaining (e.g., `"404 on homepage"`, `"JS-heavy site, firecrawl returned empty"`).

## Tolerance

- Tolerate one retry on a transient fetch failure. Past that, return `error`.
- Don't follow more than 2-3 internal links. This is a shallow check, not a full site crawl.
- If the site is clearly a different company than the search result suggested (wrong industry, wrong location), return `match_status: no-match` with `notes: "Domain is not the expected company"`.
