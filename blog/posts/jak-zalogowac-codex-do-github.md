## Jak zalogowac Codex do GitHuba

Ten wpis pokazuje prosty proces logowania Codex do konta GitHub przez GitHub CLI. Taki login jest potrzebny, kiedy chcesz, zeby Codex pobral prywatne repozytorium i zainstalowal zaleznosci projektu.

## 1. Wpisz prompt w Codex

W czacie Codex wpisz:

```text
zaloguj sie na mojego githuba, pobierz projekt eeg i zainstaluj niezbedne elementy
```

Codex powinien uruchomic logowanie przez GitHub CLI. Jesli nie jest jeszcze zalogowany, otworzy przegladarke z ekranem autoryzacji GitHuba.

![Prompt w Codex i koncowy wynik logowania](assets/github-login/01-codex-prompt-result.png)

## 2. Przepisz kod z czatu Codex

Codex wyswietli w czacie jednorazowy kod urzadzenia. Ten kod trzeba wpisac w przegladarce na stronie GitHuba.

Na ekranie GitHuba zobaczysz widok podobny do:

```text
Authorize your device
Enter the code displayed in the app or on the device you're signing in to.
```

Wpisz kod dokladnie taki, jaki pokazuje Codex w czacie. Kod jest jednorazowy, wiec nie uzywaj kodu ze zrzutu ekranu ani z poprzedniej proby.

![Ekran GitHuba do wpisania kodu urzadzenia](assets/github-login/02-authorize-device-code.png)

## 3. Kliknij Continue

Po wpisaniu kodu kliknij zielony przycisk:

```text
Continue
```

GitHub przejdzie do kolejnego ekranu, na ktorym pokazuje, jaka aplikacja prosi o dostep.

## 4. Kliknij Authorize github

Na ekranie `Authorize GitHub CLI` sprawdz, czy autoryzacja dotyczy GitHub CLI i Twojego konta.

GitHub moze pokazac informacje o uprawnieniach, np. dostep do prywatnych repozytoriow. To jest potrzebne, jezeli Codex ma pobrac prywatny projekt.

![Ekran autoryzacji GitHub CLI](assets/github-login/03-authorize-github-cli.png)

Jesli wszystko sie zgadza, kliknij:

```text
Authorize github
```

## 5. Sprawdz ekran potwierdzenia

Po poprawnej autoryzacji GitHub pokaze komunikat:

```text
Congratulations, you're all set!
Your device is now connected.
```

To oznacza, ze Codex zostal polaczony z GitHubem.

![Ekran potwierdzenia polaczenia urzadzenia](assets/github-login/04-device-connected.png)

## 6. Wroc do Codex

Po autoryzacji wroc do czatu Codex. Codex powinien kontynuowac zadanie, czyli:

- sprawdzic logowanie do GitHuba,
- pobrac repozytorium `eeg`,
- wejsc do katalogu projektu,
- utworzyc lub uzyc lokalnego srodowiska,
- zainstalowac potrzebne zaleznosci,
- uruchomic test lub skrypt sprawdzajacy, czy projekt dziala.

Przykladowy koncowy komunikat Codex moze wygladac tak:

```text
Gotowe.

Zalogowalem gh do GitHuba, sklonowalem repozytorium i zainstalowalem wymagane zaleznosci.
```

## Wazne zasady bezpieczenstwa

- Wpisuj tylko kod, ktory Codex pokazuje w Twoim aktualnym czacie.
- Nie wpisuj kodu przeslanego przez obca osobe.
- Klikaj `Authorize github` tylko wtedy, gdy to Ty rozpoczales logowanie.
- Sprawdz, czy ekran autoryzacji dotyczy `GitHub CLI`.
- Jezeli GitHub pokazuje nietypowa lokalizacje, urzadzenie albo konto, przerwij logowanie i zacznij od nowa.
