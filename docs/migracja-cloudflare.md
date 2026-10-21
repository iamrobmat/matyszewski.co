# Plan przejścia z GitHub Pages na Cloudflare

Stan na 21 października 2026. Cel: przenieść hosting strony `matyszewski.co` z GitHub Pages
na Cloudflare (Workers ze static assets) bez utraty pozycji w Google i widoczności w
wyszukiwarkach AI.

Ten plik nie jest publikowany na stronie (`scripts/build-site.sh` go nie kopiuje).

## Punkt wyjścia

- Domena jest zarejestrowana w Cloudflare Registrar, a DNS jest już w Cloudflare
  (`eve.ns.cloudflare.com`, `chad.ns.cloudflare.com`). Przeniesienie DNS nie jest potrzebne.
- Strona jest serwowana przez GitHub Pages: 4 rekordy A na adresy GitHuba i `www` jako CNAME
  na `iamrobmat.github.io`, bez proxy Cloudflare (szara chmurka).
- Poczta działa przez iCloud: rekordy MX, SPF, `apple-domain`, DKIM `sig1._domainkey`
  i `_dmarc`. Tych rekordów nie zmieniamy.
- DNSSEC jest wyłączony.

### SEO: obecny stan

Działa dobrze:

- Każda strona ma `canonical` na `https://matyszewski.co/...`, a także `description`,
  `og:url` i `lang="pl"`.
- `www` przekierowuje kodem 301 na adres bez `www`.

Brakuje:

- `robots.txt` i `sitemap.xml` zwracają 404.
- Nie ma własnej strony 404.
- Żadna strona nie ma danych strukturalnych (JSON-LD).
- `/ankieta` działa przez meta-refresh. Adres jest w kodzie QR na slajdach, więc musi
  działać zawsze.
- `szkolenie.md` jest publiczny i może trafić do indeksu. Uczestnicy każą agentowi pobrać ten
  plik, więc musi zostać dostępny bez logowania.

Największe zagrożenia dla indeksowania przy migracji:

1. Domyślna blokada botów AI w Cloudflare.
2. Duplikat strony pod adresem podglądu (`*.workers.dev`).
3. Zmiana adresów URL.
4. Strona 404 zwracająca kod 200 (soft 404).

## Faza 0: Decyzje

| Decyzja | Ustalenie |
|---|---|
| Cloudflare Pages czy Workers (static assets) | Workers. Tam Cloudflare rozwija nowe funkcje; obsługuje `_headers` i `_redirects` |
| Gdzie budować stronę | Cloudflare Workers Builds z tym samym `scripts/build-site.sh`. `GOOGLE_ANALYTICS_ID` jako zmienna w Cloudflare. Podgląd każdego brancha |
| `szkolenie.pdf` | Usunięty z repo i z buildu (21.10.2026). Stary adres przekierowujemy na stronę szkolenia |
| `szkolenie.md` | Publiczny, z `X-Robots-Tag: noindex` |
| `/kurs` z hasłem | Osobny etap po migracji. Najpierw przenosimy stronę 1:1 |

## Faza 1: Repo (Claude, na branchu)

- [x] `robots.txt`: wszystko dozwolone i link do sitemapy.
- [x] `sitemap.xml` generowana przy każdym buildzie z listy stron i z
      `blog/posts/posts.json`, z datami `lastmod`.
- [x] `404.html`: własna strona błędu z prawdziwym kodem 404, bez trybu SPA.
- [x] `_redirects`:
  - `/ankieta` → formularz Google, kod 302 (cel można później zmienić, kod QR dalej działa);
  - `/szkolenie.pdf` → `/szkolenia/agenci-ai-dla-menedzerow/`, kod 301;
  - miejsce na przyszłe przekierowania, np. po zmianie adresu wpisu.
- [x] `_headers`:
  - `X-Robots-Tag: noindex` dla `szkolenie.md` i adresów podglądu `*.workers.dev`;
  - cache: HTML krótko, obrazy dłużej;
  - podstawowe nagłówki bezpieczeństwa; HSTS na początek z krótkim `max-age`.
- [x] JSON-LD:
  - strona główna: `Person` i `ProfessionalService`;
  - `/szkolenia/...`: `Course`;
  - `/uslugi/...`: `Service`;
  - wpisy blogowe: `BlogPosting` przez `scripts/generate-blog-preview.swift`.
- [x] `wrangler.jsonc`: katalog `_site`, końcowe ukośniki w adresach jak dziś (`/uslugi/`),
      strona 404 dla nieznanych adresów.
- [x] Opcjonalnie `llms.txt`: krótki opis strony dla modeli AI.

Punkty z `robots.txt`, sitemapą, stroną 404 i JSON-LD pomagają także na GitHub Pages.
`_redirects` i `_headers` działają dopiero na Cloudflare.

## Faza 2: Panel Cloudflare (Robert, przed przepięciem)

Dziś te ustawienia nic nie zmieniają, bo ruch omija proxy. Po przepięciu zaczną działać.

- [ ] AI Crawl Control / Bots: zezwolić crawlerom wyszukiwarek i asystentów: GPTBot,
      OAI-SearchBot, ChatGPT-User, ClaudeBot, Claude-SearchBot, PerplexityBot,
      Google-Extended. Blokowanie botów trenujących: do decyzji.
- [ ] Managed robots.txt: wyłączony, żeby Cloudflare nie dopisywał nic do naszego `robots.txt`.
- [ ] Bot Fight Mode: wyłączony na start.
- [ ] Ukrywanie e-maili (Scrape Shield) i Rocket Loader: wyłączone.
- [ ] Always Use HTTPS: włączone.
- [ ] Crawler Hints: włączone (powiadamia Bing i inne wyszukiwarki przez IndexNow).
- [ ] 2FA na koncie Cloudflare, najlepiej passkey.

Nazwy opcji w panelu Cloudflare często się zmieniają. Sprawdzamy je na żywo w Fazie 4.

## Faza 3: Search Console i Bing (Robert, przed przepięciem)

- [ ] Google Search Console: usługa typu „Domena” (weryfikacja rekordem TXT) i zgłoszenie
      sitemapy.
- [ ] Punkt odniesienia: liczba i lista zaindeksowanych stron, statystyki indeksowania.
- [ ] Bing Webmaster Tools: import z Search Console. Bing zasila m.in. wyszukiwanie w ChatGPT.

## Faza 4: Test pod adresem podglądu (Claude)

- [ ] Każdy adres z sitemapy zwraca 200 pod tym samym URL co dziś, bez łańcuchów przekierowań.
- [ ] `canonical` na każdej stronie wskazuje na `matyszewski.co`.
- [ ] Nieistniejący adres zwraca 404.
- [ ] `/ankieta` i `/szkolenie.pdf` przekierowują, `szkolenie.md` się pobiera.
- [ ] Adres podglądu ma `noindex`, strony publiczne go nie mają.
- [ ] `robots.txt` jest dokładnie nasz.
- [ ] Google Analytics działa po zgodzie.
- [ ] Widok mobilny i desktop, brak błędów w konsoli.

## Faza 5: Przepięcie domeny (Robert, ok. 15 minut, najlepiej wieczorem)

- [ ] Usunąć 4 rekordy A na GitHub i podpiąć `matyszewski.co` jako Custom Domain projektu.
- [ ] `www`: rekord przez proxy i reguła przekierowania 301 `www` → `matyszewski.co`
      z zachowaniem ścieżki (gotowy szablon w Cloudflare).
- [ ] Rekordów poczty nie ruszać: MX, TXT, `sig1._domainkey`, `_dmarc`.
- [ ] GitHub Pages zostaje włączony jako plan awaryjny.

## Faza 6: Weryfikacja po przepięciu

| Kiedy | Co |
|---|---|
| Od razu | Testy z Fazy 4 na `matyszewski.co`. Test URL na żywo w Search Console: strona główna, `/uslugi/`, `/szkolenia/...`, jeden wpis |
| Dzień 1–2 | AI Crawl Control: boty AI dostają 200, nie są blokowane. Statystyki indeksowania: brak skoku błędów 4xx/5xx |
| Tydzień 1 | Raport „Strony” w Search Console porównany z punktem odniesienia. Bing Webmaster bez błędów |
| Tydzień 4 | Liczba zaindeksowanych stron co najmniej taka jak przed migracją, ruch z wyszukiwarek stabilny |

## Faza 7: Sprzątanie (po ok. 2 tygodniach stabilności)

- [ ] Robert: wyłączyć GitHub Pages w ustawieniach repo.
- [ ] Claude: usunąć `.github/workflows/pages.yml`, `CNAME` i `.nojekyll` z buildu,
      zaktualizować `README.md` i `AGENTS.md`.
- [ ] Opcjonalnie: prywatne repo. Na indeksowanie nie ma wpływu.

## Plan awaryjny

Do czasu Fazy 7 powrót zajmuje kilka minut: odpiąć Custom Domain i przywrócić 4 rekordy A
na GitHub z szarą chmurką. Żaden adres URL się nie zmienia, więc niczego więcej nie trzeba
cofać.

## Podział pracy

- Claude: Fazy 1, 4, 7 i weryfikacja techniczna w Fazie 6 (ok. 2 godziny).
- Robert: Fazy 2, 3, 5 i wyłączenie GitHub Pages (ok. 1 godzina).

## Źródła

- [Cloudflare Workers static assets: headers](https://developers.cloudflare.com/workers/static-assets/headers/)
- [Cloudflare Workers static assets: redirects](https://developers.cloudflare.com/workers/static-assets/redirects/)
- [Cloudflare Pages: custom domains](https://developers.cloudflare.com/pages/platform/custom-domains/)
- [Cloudflare bots changelog (managed robots.txt)](https://developers.cloudflare.com/bots/changelog/)
- [GitHub Pages limits](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)
