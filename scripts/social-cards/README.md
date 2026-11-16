# Wzorzec OG — Robert Bold Minimal

`bpnt-social.html` jest kanonicznym przykładem fotograficznego obrazu Open Graph dla kolejnych wpisów na matyszewski.co.

## Zasady

- format 1200 × 630 px;
- prawdziwe zdjęcie wypełnia cały kadr i jest kadrowane redakcyjnie;
- margines bezpieczny 56 px, czyli około 4,7% szerokości;
- nagłówek ma najwyżej dwie ręcznie złamane linie w Archivo Black;
- każda linia leży na osobnej, nieprzezroczystej plakietce;
- tylko jedna plakietka może być żółta (`#ffd60a`);
- plakietki są ostre: bez zaokrągleń, obrysów, cieni i przezroczystości;
- tekst nie zasłania twarzy ani kluczowego elementu zdjęcia;
- krótki kontekst może dostać mniejszą czarną plakietkę;
- w stopce zostaje tylko `MATYSZEWSKI.CO/BLOG`.

## Jak zrobić kolejny OG

1. Skopiuj `bpnt-social.html` i zmień zdjęcie oraz trzy linie tekstu.
2. Wybierz jedną linię tytułu jako żółty sygnał.
3. Dopasuj `object-position`, aby zachować twarz i temat kadru.
4. Wyrenderuj stronę w Chrome do PNG 1200 × 630 px.
5. Sprawdź PNG przy pełnym rozmiarze i jako małą miniaturę.
6. Dodaj odpowiadający SVG i ustaw `customSocialImage: true` w `blog/posts/posts.json`.

Lokalne fonty są w `blog/assets/social/fonts/`.
