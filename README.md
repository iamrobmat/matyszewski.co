# matyszewski.co

Personal website for Robert Matyszewski, deployed through GitHub Pages.

## Structure

- `index.html` - static one-page website
- `styles.css` - responsive visual system
- `.nojekyll` - disables Jekyll processing

The intended custom domain is `matyszewski.co`. Add a `CNAME` file with that value
after the domain is registered and DNS points to GitHub Pages.

## Local preview

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080`.
