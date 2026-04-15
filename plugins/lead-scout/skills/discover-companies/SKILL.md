---
name: discover-companies
description: "Multi-source company discovery. Used as a sub-routine by lead-scout to produce a candidate list of companies in an industry + geography, using firecrawl and/or web search across several source types in parallel."
---

# Discover Companies

Produce a deduplicated list of candidate company URLs for a given industry + geography. Runs as a subroutine under `lead-scout`.

## Input

- `industry` (string, e.g. "title insurance", "pilates studios")
- `geography` (string, optional — e.g. "Austin, TX")
- `target_count` (int, e.g. 15)
- `firecrawl_available` (bool)
- `skip_domains` (list, from preferences)

## Sources to consider

Pick 1-3 sources based on the industry type. Run them in parallel (multiple tool calls in a single message).

### General web search

Best when the industry is broad or B2B.

- **Firecrawl** (if available): `firecrawl search "<industry> companies <geography>" --limit <target_count*2> --country <iso> --location "<geo>"`
- **Web fallback**: WebSearch tool with the same kind of query

### Local business directories

Best for local services (gyms, studios, clinics, contractors, restaurants).

- **Google Maps**: `firecrawl search "<industry> <geography>" --sources web --location "<geo>"` often returns maps results; or scrape the maps search URL directly: `firecrawl scrape "https://www.google.com/maps/search/<urlencoded-query>"` — note this is heavy; prefer search with location targeting first
- **Yelp**: `firecrawl scrape "https://www.yelp.com/search?find_desc=<query>&find_loc=<geo>"` — good for service businesses

### Industry-specific directories

If you know of one relevant to the industry, use it. Examples:
- Title insurance: state-level underwriter lookups
- Healthcare: NPI registry (Medicare/Medicaid)
- Legal: state bar directories
- Restaurants: OpenTable, Resy

Don't invent directories. If you're not sure one exists, skip it and rely on general search.

## Dedup rules

Dedupe by **root domain** (e.g., `foo.com/contact` and `foo.com/about` → one entry for `foo.com`). Drop any domain in `skip_domains`. Drop obvious aggregators (yelp.com itself, yellowpages.com, maps.google.com as entries — those are sources, not targets).

## Output

Return a list of objects: `[{company_name, url, source, snippet}, ...]`. Truncate to `target_count` (slight overshoot OK if dedup reveals extras).

If you have fewer than `target_count` after all sources, return what you have — don't pad with weak candidates.

## Failure handling

If a source errors (firecrawl rate-limit, network), note it but proceed with the others. If ALL sources error, report back to lead-scout orchestrator with the error — don't fake results.
