# matyszewski.co

Local static website for Robert Matyszewski.

This repository is prepared for a future personal site, public notebook and optional GitHub Pages
deployment. It is not published from this workspace unless deployment is explicitly enabled later.

## Structure

- `index.html` - static one-page website
- `styles.css` - responsive visual system
- `.nojekyll` - disables Jekyll processing if GitHub Pages is enabled later

No `CNAME` file is included. Add one only after `matyszewski.co` is registered, DNS is configured,
and publishing is intentionally enabled.

## Local preview

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.
