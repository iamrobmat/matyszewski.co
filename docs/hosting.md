# Hosting: GitHub Pages i lustro Cloudflare

Stan na 5 listopada 2026.

## Model docelowy

- `https://matyszewski.co/` pozostaje publiczną stroną produkcyjną na GitHub Pages.
- `https://matyszewski-co.robert-matyszewski.workers.dev/` jest technicznym lustrem Cloudflare
  Workers, używanym do testów i zawsze oznaczonym nagłówkiem `X-Robots-Tag: noindex`.
- Oba środowiska budują ten sam commit z gałęzi `main`.
- DNS domeny, rekordy poczty i konfiguracja custom domain pozostają bez zmian.

Canonicale, Open Graph i sitemap wskazują wyłącznie na `https://matyszewski.co/`. Adres Workera
nie jest drugim publicznym źródłem treści.

## GitHub Pages — produkcja

Workflow `.github/workflows/pages.yml` uruchamia:

```bash
bash scripts/build-site.sh _site github
```

Profil `github` zawiera pliki `CNAME` i `.nojekyll` oraz wszystkie publiczne PDF-y, w tym
`kwartalnik-78.pdf`.

Wymagana zmienna repozytorium GitHub Actions:

- `GOOGLE_ANALYTICS_ID` — identyfikator GA4 w formacie `G-...`.

## Cloudflare Workers — lustro

Worker `matyszewski-co` używa static assets zdefiniowanych w `wrangler.jsonc`.

Ustawienia Workers Builds:

| Ustawienie | Wartość |
|---|---|
| Repozytorium | `iamrobmat/matyszewski.co` |
| Production branch | `main` |
| Root directory | `/` |
| Build command | `bash scripts/build-site.sh _site cloudflare` |
| Deploy command | `npx wrangler deploy` |
| Preview builds | wyłączone |
| Build variable | `GOOGLE_ANALYTICS_ID` |

Profil `cloudflare` zawiera `_headers` i `_redirects`, ale pomija `CNAME`, `.nojekyll` oraz
`kwartalnik-78.pdf`. Kwartalnik ma 58 MB i przekracza limit 25 MiB pojedynczego assetu Workers;
zgodnie z decyzją projektową jego adres zwraca w lustrze prawdziwe 404. Pozostałe dwa PDF-y są
publikowane na obu hostach.

Skrypt `scripts/check-cloudflare-assets.mjs` przerywa build, jeżeli do artefaktu Cloudflare trafi
plik większy niż 25 MiB.

## Różnice w zachowaniu

| Adres lub plik | GitHub Pages | Cloudflare Workers |
|---|---|---|
| `/kwartalnik-78.pdf` | 200, pełny PDF | 404 |
| `/szkolenie.pdf` | 200, pełny PDF | 200, pełny PDF |
| `/ankieta` | zapasowy redirect HTML | redirect HTTP 302 z `_redirects` |
| Nieznany URL | GitHub Pages 404 | własny `404.html` z kodem 404 |
| Indeksowanie | dozwolone zgodnie z `robots.txt` | zablokowane `X-Robots-Tag: noindex` |

## Materiały niepublikowane

Katalogi `drafts/` i `kurs/` nie są kopiowane do żadnego artefaktu. Publikacja materiału z tych
katalogów wymaga osobnej decyzji i zmiany źródeł buildu.

## Kontrola po zmianie `main`

1. Sprawdzić zielony workflow GitHub Pages.
2. Sprawdzić udany build produkcyjny Workera z tego samego SHA commita.
3. Porównać reprezentatywne HTML i CSS na obu hostach.
4. Potwierdzić `X-Robots-Tag: noindex` na `workers.dev`.
5. Potwierdzić statusy PDF-ów, `/ankieta`, `robots.txt`, `sitemap.xml` i nieznanego adresu.
