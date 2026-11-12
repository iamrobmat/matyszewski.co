# `/kurs` — prototyp strefy uczestnika

Stan: niepublikowany prototyp. Żaden profil `scripts/build-site.sh` nie kopiuje tego katalogu do
`_site`.

## Co jest gotowe

- bramka hasłowa po stronie przeglądarki oparta na Web Crypto;
- treść szkolenia podzielona na 11 kroków;
- warianty instrukcji dla Claude Code i Codexa;
- zapisywanie postępu i wybranego narzędzia w `localStorage`;
- kopiowanie poleceń oraz dostępne stany formularza i komunikatów.

## Czego brakuje przed publikacją

- `scripts/encrypt-course-page.mjs`, który podczas buildu zaszyfruje `tresc.html` i wstawi payload
  w miejsce `<!-- COURSE_PAYLOAD -->` w `index.html`;
- przekazania hasła przez bezpieczną zmienną buildową `COURSE_PASSWORD`;
- przeglądu aktualności instrukcji, zrzutów ekranu i nazw opcji w Claude Code oraz Codexie;
- testów bezpieczeństwa, dostępności i zachowania po błędnym haśle.

Sama bramka JavaScript bez brakującego kroku szyfrowania nie stanowi gotowej ochrony treści.
