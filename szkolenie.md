# AI dla SPECJALISTÓW — od czatu do agenta AI

**Jak tworzyć i rozwijać agentów AI z Claude Code**

Robert Matyszewski · BPNT, Białystok · szkolenie 2 godziny: teoria, pokaz na żywo i krótkie ćwiczenie

---

## Spis treści

0. [Wstęp](#0-wstęp)
1. [Od czatu do agenta](#1-od-czatu-do-agenta)
2. [Czym jest agent — z czego się składa](#2-czym-jest-agent--z-czego-się-składa)
3. [Agent a software](#3-agent-a-software)
4. [Z czego składa się agent — przykłady](#4-z-czego-składa-się-agent--przykłady)
5. [Obsługa aplikacji](#5-obsługa-aplikacji)
6. [Tips and tricks: jak prowadzić pracę z agentem](#6-tips-and-tricks-jak-prowadzić-pracę-z-agentem)
7. [Od rozmowy do skilla i automatyzacji](#7-od-rozmowy-do-skilla-i-automatyzacji)
8. [Przykłady zaawansowane](#8-przykłady-zaawansowane)
9. [Pokaz na żywo i ćwiczenie](#9-pokaz-na-żywo-i-ćwiczenie)
10. [Zakończenie](#10-zakończenie)

**Myśl przewodnia:** Agent = model + cel + kontekst (pliki) + narzędzia zewnętrzne. Czat odpowiada, agent wykonuje pracę. Człowiek wyznacza cel, dostarcza kontekst i kontroluje wynik.

---

## 0. Wstęp

### 1. O mnie

**Robert Matyszewski**

- W branży IT od 2012 roku, między technologią a biznesem.
- Stwoprzyłem firmę IT LemonTea , sprzedaną w 2016 roku
- Kierowałem sprzedażą i marketingiem w SoftwareHut i TenderHut
- Pracowałem w Netguru i YourNextStore
- Współtworzyłem popularne narzędzia dla programistów GraphQL Editor
- Rozwijałem własną sieć zespołów IT na potrzeby klientów - TeamFinder
- Współorganizator konefrencji Programistoku od 10 lat
- Dziś buduję własne rozwiązania z AI i pomagam budować prototypy
- **Jestem menedżerem IT**

### 2. Pytanie do sali

**Kto najlepiej dziś sobie radzi z AI?**

### 3. Programistok 2026

**Programistok 2026** · 25–26.09.2026 · Wydział Elektryczny Politechniki Białostockiej

**Zapraszam na Programistok 2027!** Wrzesień 2027, Wydział Elektryczny PB · programistok.org

### 4. „Nie dałbym rady bez Klaudiusza”

> „Wiecie co, miałem tyle pism oficjalnych do napisania, że nie dałbym rady bez Klaudiusza.”
> — Karol Przybyszewski, organizator Programistoku, dyrektor liceum programistycznego INFOTECH

**Karol Przybyszewski**

- formalny organizator Programistoku: odpowiada za wszystkie dokumenty i współpracę z partnerami, m.in. z Politechniką Białostocką i Urzędem Marszałkowskim
- kiedyś programista i przedsiębiorca, dziś menedżer IT i dyrektor liceum programistycznego INFOTECH

Rozmowa odbyła się w trakcie konferencji Programistok. „Klaudiusz” to potoczna nazwa pracy z Claude jako agentem (Claude Code albo Claude Cowork). O tym jest to szkolenie.

### 5. Początki Claude Code

**Claude Code = model językowy + terminal**

Dowolna operacja na komputerze z użyciem języka człowieka. Prosty · bardzo szybki · ogromne możliwości.

**Dlaczego był atrakcyjny:** bezpośredni zakup usługi modeli językowych od największego dostawcy.

**Oś czasu:**

- 2025: wewnętrzne narzędzie Anthropic zostaje udostępnione publicznie
- Programistok 2025: praca z agentami to temat każdej prezentacji
- koniec 2025: Claude Code bardzo popularny w branży IT

### 6. Terminal: powrót do komputera tekstowego

**Kiedyś:** MS-DOS, czyli komputer obsługiwany wyłącznie tekstem. Wpisywało się polecenia, nie klikało.

**Dziś:** przez terminal mówimy do komputera ludzkim językiem, a agent AI tłumaczy to na komendy i sam je wykonuje.

### 7. OpenClaw agentic engineering: jak pracował Peter

Kilkanaście okien terminala, jedno duże oprogramowanie. Proces powstawania opisany na blogu.

*„Trochę jak zarządzanie ludźmi.”*

Peter Steinberger to twórca OpenClaw, autonomicznego agenta AI, po którym został zatrudniony przez OpenAI.

### 8. Dlaczego tu jestem

**W przyszłości każda organizacja będzie tworzyć swoje narzędzia informatyczne. Chcę uczyć tego ludzi.**

### 9. Plan szkolenia

1. Od czatu do agenta
2. Czym jest agent
3. Agent a software
4. Elementy agenta
5. Obsługa aplikacji
6. Tips and tricks
7. Od rozmowy do skilla
8. Przykłady zaawansowane
9. Pokaz i ćwiczenie
10. Zakończenie

Na końcu zabawa.

### 10. Wymagania części praktycznej

- Desktopowa aplikacja **Claude** w wersji na komputer: pobrana i zainstalowana
- Zalogowane płatne konto Claude
- Podczas części praktucznej pozamykane wszystkie inne aplikacje, okna i karty przeglądarki
- **Praca z agentem mocno obciąża komputer. Im mniej otwartych programów, tym lepiej.**

---

## 1. Od czatu do agenta

Czaty AI · Z czym kojarzy się „agent” · Czat odpowiada, agent wykonuje · Rodzaje agentów · Pętla agenta · Agent to nie magiczny pracownik

### Czaty AI

To miłe, wciągające narzędzie które czasem zmyśla fakty oraz działa na zasadzie losowania następnego słowa.

### Pytanie do sali

**Zanim zaczniemy:** Z czym kojarzy Wam się słowo agent?

### Czat odpowiada, agent wykonuje

| | Czat | Agent |
|---|---|---|
| Co dostaje | pytanie | cel + dostęp do folderu, plików i narzędzi |
| Co oddaje | odpowiedź do przeczytania i skopiowania | wykonaną pracę: plik, dokument, raport na Twoim dysku |
| Kto wykonuje kolejne kroki | Ty: kopiujesz, wklejasz, dopytujesz | agent, a Ty zatwierdzasz i sprawdzasz |
| Gdy coś nie wyjdzie | pytasz jeszcze raz | agent widzi błąd i próbuje innej drogi |

Przykład z codziennej pracy menedżera: pismo do partnera. W czacie wklejasz dane, dostajesz tekst, kopiujesz go do Worda, poprawiasz i wracasz z kolejnym pytaniem. Agent sam czyta poprzednie pisma i dane z folderu, zapisuje gotowy dokument i sprawdza go z Twoim wzorem.

Uczciwie: granica się zaciera. Claude w przeglądarce też szuka w internecie i tworzy pliki. Różnica jest w tym, **gdzie** pracuje agent (na Twoim komputerze, w Twoim folderze) i **kto** wykonuje kolejne kroki.

### Rodzaje agentów

| Nazwa | Przykłady | Skala działania | Miejsce działania | Kiedy używać |
|---|---|---|---|---|
| Agent zadaniowy | Claude Cowork | Rozmowa i kontekst kilku plików | Serwery zewnętrzne | Ograniczone zadanie na kilku plikach, dokumentach, przeglądarce lub konektorach |
| Agent projektowy | Claude Code | Folder z dowolną ilością plików i skryptów informatycznych | Nasz folder na komputerze | Duży projekt, duża ilość plików, możliwość programowania i tworzenia własnych narzędzi |

### Praca z agentami wymaga pętli

**cel → kontekst, pliki i narzędzia → działanie → sprawdzenie wyniku → kolejny krok**

Pętla kręci się, dopóki cel nie jest osiągnięty albo agent nie potrzebuje decyzji człowieka. Człowiek jest w niej w trzech miejscach: wyznacza cel, zatwierdza ważne kroki, ocenia wynik.

Przykład: „Zrób zestawienie ofert z folderu”. Agent czyta pliki → tworzy tabelę → sprawdza, czy są wszystkie oferty → widzi, że jednej brakuje → dopisuje ją → kończy.

Czat robi jedno okrążenie i oddaje odpowiedź. Agent kręci się w pętli wiele razy, zanim wróci do Ciebie.

### Agent to nie magiczny pracownik

**Agent AI jest ASYSTENTEM.** Nie dostaniesz bezbłędnego wyniku po jednym ogólnym poleceniu.

- **Precyzja:** jasny cel i kryteria, po czym poznasz dobry wynik
- **Dbałość o szczegóły:** dobre materiały na wejściu, sprawdzanie na wyjściu
- **Kontrola człowieka:** zatwierdzasz ważne kroki, odpowiadasz za wynik

Jak mówił Peter: „trochę jak zarządzanie ludźmi”. Praca z agentem to delegowanie, a delegować menedżerowie już umieją: cel, materiały, kryteria, kontrola.

---

## 2. Czym jest agent — z czego się składa

Wzór na agenta · Kontekst sprawia, że agent jest Twój · Co jest w pliku Word · Markdown · Ulubione formaty plików · Lepszy kontekst = krótsze polecenie

### Wzór na agenta

**MODEL + CEL + KONTEKST (PLIKI, INSTRUKCJE) + NARZĘDZIA = AGENT**

- **Model:** Claude
- **Cel:** co ma powstać
- **Kontekst:** pliki, instrukcje
- **Narzędzia:** MCP, wtyczki, API

*Połączenie modelu, Twojego celu, Twojego kontekstu i narzędzi zewnętrznych.*

### Kontekst sprawia, że agent jest Twój

W środku jest **model (LLM)**. Dookoła niego źródła kontekstu:

1. Pliki lokalne w folderze projektu: dokumenty, dane
2. Nasze cele, instrukcje projektu i skille do uruchomienia
3. Połączenia z aplikacjami: MCP (wtyczki), API (np. Google Docs, kalendarz, CRM)
4. Nasza rozmowa i możliwość pobierania danych z internetu

Ta wiedza nie zależy od modelu.

### Z czego składa się plik Word

Dla nas plik Word to dokument. Agent AI widzi go zupełnie inaczej.

Plik Word to spakowany folder, coś jak ZIP. W tym przykładzie to 13 plików, razem około 49 KB, a sam tekst to kilkaset znaków. Agent nie otworzy pliku Word wprost: musi go rozpakować albo zamienić na tekst (np. programem pandoc).

### Co jest w środku pliku Word

**Tak widzi agent po rozpakowaniu: 13 plików**

| Plik w paczce | Co zawiera |
|---|---|
| `word/document.xml` | **Właściwa treść:** tekst i formatowanie |
| `word/styles.xml` | Wygląd nagłówków, czcionki, odstępy |
| `word/numbering.xml` | Punktory i numeracja |
| `word/theme/theme1.xml` | Motyw kolorów i czcionek |
| `word/header1.xml, footer1.xml` | Nagłówek i stopka strony |
| `word/fontTable.xml, settings.xml` | Lista czcionek, ustawienia dokumentu |
| `docProps/…, _rels/…, [Content_Types].xml` | Metryczka i spis zawartości paczki |

Skrót pliku `word/document.xml`: linie 1–5 i 274–277.

```xml
<?xml version="1.0" ?>
<w:document xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" …>
  <w:body>
    <w:p>
      <w:pPr>
…
    </w:sectPr>
  </w:body>
</w:document>
```

**277 linii danych, podczas gdy nasz tekst to tylko 8 linii.**

Słowo „składa” jest zapisane w trzech kawałkach: „sk”, „ł”, „ada”. Kawałki różnią się ukrytymi ustawieniami, np. językiem. Człowiek tego nie widzi, a agent musi się przez to przebić. Markdown agent czyta od razu, bez strat.

### Markdown (.MD) - format zapisu tekstu

Zwykły tekst z prostym formatowaniem, czytelny i dla człowieka, i dla AI.

**Tak widzisz w podglądzie:** nagłówek, pogrubienie i lista, bez znaczków. Ten plik, który właśnie czytasz, też jest napisany w Markdown.

**Tak zapisuje to agent:** ten sam tekst ze znakami `#`, `**`, `-`.

```markdown
# AI dla specjalistów — od czatu do agenta AI

## Kontekst szkolenia
- Szkolenie otwarte, 2 godziny, poziom wprowadzający
- Odbiorcy: menedżerowie, właściciele firm, liderzy…
- Język materiałów: polski.
```

### markdown - Frontmatter

Kilka linii między `---` na początku pliku .md. Agent szuka i filtruje po nich bez czytania całego tekstu.

```
---
tytul: Precyzyjne podcinanie…
dzial: Maszyny komunalne…
typ: artykul
strony: 24
autor: Aneta Kralik
---
```

Przykład z bazy kwartalnika Pronar: aplikacja pokazuje te pola jako tabelkę, a w pliku to zwykłe linie „pole: wartość”. Dzięki nim agent znajdzie np. wszystkie artykuły jednego autora albo działu bez czytania całych tekstów.

### Edycja Markdown w aplikacji

**Pliki .md otwierasz i poprawiasz tam, gdzie rozmawiasz z agentem.**

- Claude Code w aplikacji: menu **⋮ → Files** (⇧⌘F)
- Po lewej rozmowa z agentem, obok podgląd i edycja plików projektu.

### Ulubione formaty plików agentów

- **Markdown (.md):** instrukcje, notatki, konspekty
- **JSON (.json):** uporządkowane dane
- **CSV (.csv):** tabele, otwierają się w Excelu
- **HTML (.html):** strony i raporty do przeglądarki

Przykład pliku JSON:

```json
{
  "szkolenie": "AI dla specjalistów",
  "miasto": "Białystok",
  "czas_min": 120,
  "czesci": [
    "Od czatu do agenta",
    "Czym jest agent",
    "Pokaz i ćwiczenie"
  ]
}
```

Przykład pliku CSV (tabela: pierwszy wiersz to nagłówki, kolejne to dane oddzielone przecinkami):

```csv
czesc,tytul,czas_min
0,Wstęp,10
1,Od czatu do agenta,10
2,Czym jest agent,15
3,Agent a software,10
```

### Lepszy kontekst = krótsze polecenie

**Bez kontekstu — długie polecenie:**

> „Przygotuj slajdy na dwugodzinne szkolenie dla menedżerów bez doświadczenia programistycznego. Pisz po polsku, prostym językiem, bez żargonu. Prowadzący jest menedżerem, nie programistą. Szkolenie ma 10 części, w części 3 omawiamy…”

**Z kontekstem — krótkie polecenie:**

> „Przygotuj slajdy do pliku @02-czym-jest-agent.md zgodnie z moim stylem graficznym”

\+ folder z materiałami:

```
ai-for-managers/
├── CLAUDE.md
├── konspekt-szczegolowy.md
├── 02-czym-jest-agent.md
└── obrazy/
```

---

## 3. Agent a software

Czym się różni aplikacja od agenta · Aplikacja jak bierki · Porównanie punkt po punkcie

### Czym się różni aplikacja od agenta?

**Aplikacja** to statyczny zespół elementów, funkcji i narzędzi. Robi dokładnie to, do czego została zbudowana.

**Agent** to dynamiczny „asystent” z instrukcjami. Dostaje cel i dobiera kroki. Agent tworzy kod i uruchamia go na potrzeby realizacji celu.

Aplikację kupujesz lub zamawiasz. Agenta budujesz i rozwijasz sam, tak jak wdrażasz pracownika.

### Aplikacja jak bierki

**W aplikacji wszystko zależy od wszystkiego.**

- Ruszysz jeden element, ruszają się inne.
- Dlatego każda zmiana to praca programisty i testy.
- Agent nie ma sztywnej konstrukcji: kroki dobiera pod cel.

### Czym się różnią

| | Aplikacja | Agent |
|---|---|---|
| Jak się z nią pracuje | przyciski, formularze, menu | chat, cele i pliki i instrukcje opisane zwykłym językiem |
| Co potrafi | tylko to, co zaprogramowano (statyczna) | dobiera kroki do sytuacji |
| Nietypowa sytuacja | błąd albo „nieobsługiwane” | próbuje sobie poradzić, czasem pyta |
| Jak ją zmienić | programista i nowa wersja: tygodnie | poprawiasz instrukcję w pliku: minuty, sam |
| Przewidywalność | większa | mniejsza |
| Kontrola | testy przed wdrożeniem | weryfikacja wyniku przez człowieka |
| Koszt przy dużej skali | szybka i tania | wolniejszy, płacisz za każde użycie |
| Czas zbudowania | tygodnie lub miesiące | godziny |

---

## 4. Z czego składa się agent — przykłady

Pliki agenta w Claude Code · Instrukcje projektu (CLAUDE.md) · Skill od środka

### Pliki agenta w Claude Code

**Agent to zwykłe pliki w folderze projektu.**

| Plik | Do czego służy |
|---|---|
| `CLAUDE.md` | instrukcje projektu, czytane na starcie |
| `.claude/skills/<nazwa>/SKILL.md` | skill: zapisana procedura |
| `.claude/settings.json` | ustawienia i uprawnienia agenta |
| `.mcp.json` | połączenia z aplikacjami (MCP) |

### Instrukcje projektu na żywym przykładzie

Instrukcje projektu są czytane na starcie każdej sesji. Opisują zasady: odbiorców, język, czego nie robić.

`CLAUDE.md` i skille (folder `.claude/skills`) to zwykłe pliki w folderze projektu.

### Skill od środka

Skill to zapisana procedura: nazwa, opis „kiedy mnie użyć”, kroki procedury, kryteria dobrego wyniku. Skill jest wczytywany tylko wtedy, gdy jest potrzebny.

`SKILL.md` · fragment:

```markdown
---
name: synchronizuj-prezentacje
description: Synchronizuje prezentację w obie strony:
  pliki md ↔ slajdy w claude.ai. Użyj, gdy zmienił
  się konspekt albo slajdy w edytorze.
---
# Synchronizacja md ↔ slajdy
1. Sprawdź, gdzie są nowsze zmiany: w md czy w slajdach.
2. Pokaż zmiany i poczekaj na zgodę.
3. Przenieś zmiany w ustaloną stronę.
4. Popraw numerację slajdów i wyślij deck.
```

---

## 5. Obsługa aplikacji

Gdzie znaleźć agenta · Nowy projekt = nowy folder · Dostęp do przeglądarki Chrome · Wtyczki: połączenia z aplikacjami · Uprawnienia: co sam, o co pyta · Twoje dane a trenowanie modeli

### Od czego zacząć

**Agent to osobny tryb w aplikacji Claude.**

- W aplikacji Claude przełączasz się na zakładkę **Code**.

### Nowy projekt = nowy folder

**Każdy projekt to osobny folder na dysku.**

- Claude Code: lista folderów → **Open folder…**

**Folder wybrany: agent pracuje na jego plikach.**

- Nazwę folderu widać nad polem polecenia.
- Do folderu wrzucasz materiały, instrukcje i skille.

### Dostęp do Chrome

**Agent może czytać strony i klikać w Twojej przeglądarce.**

- Rozszerzenie **Claude in Chrome**
- Ustawienia → Claude in Chrome → **Enable Claude in Chrome**
- Osobno ustawiasz, na których stronach agent może działać (Site permissions).

### Wtyczki

**Wtyczki łączą agenta z aplikacjami, których używasz.**

- Ustawienia → **Connectors** → Discover
- Np. Google Drive, Gmail, Google Calendar, Canva
- Dodajesz jednym kliknięciem (+).

### Uprawnienia: co sam, o co pyta

**Ty decydujesz, ile agent może zrobić bez pytania.**

- Claude Code: **Manual** (zawsze pyta) → **Accept edits** → **Auto** → **Bypass permissions**
- Tryb **Plan**: najpierw plan, potem zmiany.

Tryby idą od „pytaj o wszystko” do „działaj samodzielnie”.

### Wyłącz trenowanie na Twoich danych

W aplikacji Claude: **Settings → Privacy** → wyłącz **Help improve our AI models**.

Wtedy Twoje czaty i sesje w Claude Code nie są używane do trenowania modeli.

---

## 6. Tips and tricks: jak prowadzić pracę z agentem

Najpierw plan, potem wykonanie · Poprawiaj instrukcje, oceniaj wyniki · Powiedz, po czym poznać gotową pracę · Otwarta droga, zamknięta meta · Przykłady przekazują ukrytą wiedzę · Sprawdzaj pracę agenta · Kiedy otworzyć nowy czat · Kompaktuj długą rozmowę · Agenty bywają niestabilne

### Najpierw plan, potem wykonanie

- dziel duże zadania na etapy
- **używaj trybu planowania**
- kontekst w plikach, nie w długich poleceniach
- staraj się pamiętać co gdzie jest w folderze
- struktura pracy jest bardzo ważna

Jak włączyć tryb planowania: w Claude Code wpisz `/plan`.

### Poprawiaj instrukcje, oceniaj wyniki

- Sukces? To może czas na skill.
- Coś nie działa? **Zapytaj dlaczego nie działa, popraw instrukcje, dane albo skillsy.**
- Określ kryteria „dobrze zrobione”.

### Nie dawaj agentowi tylko zadania

Powiedz mu również, po czym poznać, że praca jest gotowa.

- **Słabe polecenie:** „Oceń prace studentów.”
- **Lepsze polecenie:** „Oceń prace według podanych kryteriów. Jako punkt odniesienia wykorzystaj wzorcowo wykonaną pracę.”

Agent działa lepiej, gdy otrzymuje nie tylko cel, ale również kryterium poprawnego wykonania.

### Otwarta droga, zamknięta meta

Agent może mieć swobodę wyboru sposobu działania. Nie powinien jednak samodzielnie decydować, co oznacza sukces.

**Otwarta droga:**

- agent wybiera sposób wykonania,
- korzysta z dostępnych narzędzi,
- może poprawiać własne rezultaty.

**Zamknięta meta:**

- istnieje wzorzec,
- są kryteria akceptacji,
- wynik można sprawdzić.

**Agent może mieć swobodę tworzenia, jeśli nie ma swobody ogłaszania sukcesu.**

### Przykłady przekazują ukrytą wiedzę

Menedżer od dawna opisuje faktury według zasad księgowej. Ma wiele poprawnie opisanych przykładów. Zamiast tworzyć rozbudowaną instrukcję, może powiedzieć:

> „Opisz nowe faktury tak jak wcześniejsze, zgodnie z zasadami księgowej.”

Agent otrzymuje wtedy:

- nowe faktury,
- poprawne przykłady z przeszłości,
- aktualne zasady,
- oczekiwany format wyniku.

**Przykłady stają się dla agenta pamięcią organizacji.**

### Sprawdzaj pracę agenta

- **Sprawdź pliki, które powstały:** otwórz je i przeczytaj.
- **Zapytaj, jak to zrobił i dlaczego.**

### Kiedy otworzyć nowy czat

- **Kontynuuj:** to samo zadanie, ten sam kontekst i cel. Po osiągnięciu celu warto pomyśleć o skillach.
- **Nowa sesja:** zmiana tematu, długa rozmowa, agent „gubi wątek”, potrzebne świeże spojrzenie.

### Kompaktuj długą rozmowę

- Wpisz `/compact`.
- Agent streszcza dotychczasową rozmowę i zwalnia miejsce w kontekście.
- Przydaje się, gdy rozmowa jest długa, a zadanie to samo.

### Agenty bywają niestabilne

- Interfejs często się zmienia.
- Zewnętrzne connectory przestają działać.
- Czasem coś nie działa i nie wiadomo dlaczego.
- **Co pomaga:** zrestartuj aplikację albo zmień model.

---

## 7. Od rozmowy do skilla i automatyzacji

Schodki · Przykład: pisma urzędowe · Automatyzacja = skill · Co delegować, a gdzie zostaje człowiek

**Automatyzacja w tym szkoleniu** to nie Zapier czy Make. Powtarzalny proces opisujemy raz w **skillu** (zapisanej procedurze), a potem uruchamiamy go ręcznie albo automatycznie, zamiast za każdym razem tłumaczyć agentowi wszystko od nowa.

### Schodki

1. folder z danymi źródłowymi
2. pierwsze polecenia / eksperymenty
3. potrzeby powtarzalne (skille)
4. tworzenie skilla na końcu dobrego czatu
5. ponowne lub cykliczne uruchamianie

### Przykład: pisma urzędowe

Ten sam proces na schodkach:

1. pojedyncza prośba
2. folder ze wzorami, najlepiej w Markdown
3. zasady w `CLAUDE.md`
4. skill „pismo urzędowe xyz”
5. cykliczne uruchamianie

### Automatyzacja = skill

Proces opisany raz w skillu → uruchamiasz go, kiedy chcesz, albo automatycznie. Bez tłumaczenia agentowi wszystkiego od nowa.

### Co delegować, a gdzie zostaje człowiek

- **Delegować:** szkice, zestawienia, porządkowanie, research, pierwsze wersje.
- **Człowiek:** decyzje, odpowiedzialność, wysyłka na zewnątrz, dane wrażliwe.
- **Ryzyka:** zmyślanie faktów, dane firmowe i RODO.

---

## 8. Przykłady zaawansowane

Jak powstała ta prezentacja · Baza wiedzy z moich książek · Dashboard z wyników badań

Co da się zbudować, gdy agent ma dobry kontekst i skille.

### Jak powstała ta prezentacja

- Treść w plikach Markdown: konspekt i jeden plik na każdą część.
- Claude Code wprowadza zmiany w plikach i buduje z nich slajdy.
- Skill **synchronizuj-prezentacje** sprawdza, gdzie są nowsze zmiany: w plikach czy w slajdach.

- Po lewej rozmowa z Claude Code, po prawej gotowy deck w claude.ai.
- Slajdy można poprawiać też w przeglądarce.
- Ten sam skill **synchronizuj-prezentacje** przenosi takie zmiany z powrotem do plików md.

### Baza wiedzy z moich książek

- Pytanie: jakie są podejścia do inwestowania?
- Agent pyta bazę książek po polsku i po angielsku, a potem łączy odpowiedzi.
- Przy każdym punkcie podaje źródło: książkę i autora.

**Skąd ta odpowiedź?**

- Odpowiedź powstała z fragmentów 9 książek.
- Agent wypisuje książki, autorów i użyte rozdziały.
- Mówi też wprost, co dopisał sam.

### Dashboard z wyników badań

- 55 plików PDF i JPG z wynikami badań z 10 lat (2015–2025).
- Z plików powstała tabela CSV: 550 wyników, 95 parametrów.
- Na tej podstawie powstał dashboard z trendami.

**Wykresy badań**

- Małe wykresy dla parametrów, które warto widzieć w czasie.
- Pod każdym wykresem krótki komentarz.

**Źródła: zwykłe pliki**

- Każdy wynik prowadzi do pliku Markdown albo CSV.
- Osobne dane trzymane są w osobnym folderze i się nie mieszają.
- **Do obserwacji trendów, nie do diagnozy.**

---

## 9. Pokaz na żywo i ćwiczenie

Pokaz na żywo · Zadanie dla uczestników

### Zadanie dla uczestników (1/2)

**Spróbuj w którymś zadaniu trybu planowania /plan**

1. Stwórz folder swojego projektu.
2. Zainstaluj wtyczkę do Chrome i zleć agentowi przeczytanie dzisiejszych newsów na gazeta.pl
3. Zleć agentowi „Pobierz plik: **matyszewski.co/szkolenie.md**”
4. Poproś agenta o znalezienie błędów ortograficcznych i stylistycznych w tym pliku.
5. Poproś agenta o stworzenie pliku notatki.md zapisz tam znalezione błędy

### Zadanie dla uczestników (2/2)

**Pytanie do zadań: Kiedy otwieramy nowy czat do nowego zadania?**

6. Poproś agenta: „Zrób z pliku szkolenie.md prezentację” — i opisz własnymi słowami, jak ma wyglądać (kolory, styl, nastrój).
7. Zmień coś w pliku tekstowym szkolenie.md (np. dopisz albo usuń jeden punkt).
8. Poproś agenta o zaktualizowanie prezentacji po tej zmianie.
9. Poproś agenta o zbudowanie z tej prezentacji strony HTML.
10. Połącz agenta z Chrome i poproś go o wysłanie Twojego feedbacku o tym szkoleniu przez formularz: **matyszewski.co/ankieta**

---

## 10. Zakończenie

Co dalej · Trzy rzeczy do zapamiętania · Pytania

### Co dalej

Integracje · Subagenci · Zadania cykliczne · Zdalne sterowanie · Prototypy oprogramowania

### Trzy rzeczy do zapamiętania

1. Agent = model + cel + kontekst + narzędzia.
2. Kontekst zapisuj w plikach, procesy w skillach.
3. Eksperymentuj i sprawdzaj wyniki zanim osiągniesz biegłość w działaniu.

### Dziękuję

**Pytania?** · [matyszewski.co](https://matyszewski.co)

Ankieta po szkoleniu: [matyszewski.co/ankieta](https://matyszewski.co/ankieta)
