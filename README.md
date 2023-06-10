# Bio-Share
Bio-Share to aplikacja mobinla na sysytem Android. Celem aplikacji jest **przeciwdziałanie zmianom klmiatu poprzez ograniczenie marnowania żywności**. Aplikacja jest narzędziem do zarządzania lodówkami publicznymi (miejscami do dzielenia się żywnością). W obecnym stanie aplikacja jest działającym prototypem.

## Jaki problem rozwiązuje aplikacja?
W wielu dużych miastach znajdują się miejsca do dzielenia się żywnością. Wiele osób jednak nie korzysta z tej możliwości. Jednym z powodów dlaczego tak się dziezje jest nie znana zawartość takich punktów. Ludzie nie chcą się fatygować do takiego punktu jeśli nie mają pewności czy znajdą tam rzeczy które potrzebują. Aplikacja Bio-Share rozwiązuje ten problem i pozwala zarządzać zawartością lodówek. Jeśli takie miejsca  staną się popularne (nie tylko dla ludzi potrzebujących) to będzie to miało realny wpływ na zmniejszenie produkcji żywności, a to ona wpływa w dużym stopniu na produkcje gazów cieplarnianych.

## Działanie aplikacji
Po rejestracji i zalogowaniu sie do aplikacji użytkownik może dodawać lub usuwać produkty (istnieje też opcja edycji) z lodówek. Każdy z użytkowników może też stworzyć własny punkt dzielenia się żywnością (ta opcja jest bardziej skierowana do fundacji/organizacji/samorządów, które już obsługują takie punkty).

## Przyszły rozwój
Aplikacja ma duży potenciał. Obecna forma to w pełni funkcjonalny prototyp. W przyszłośći planuję dodać między innymi: 
* Weryfikację adresu e-mail,
* Powiadomienia dla administratora lodówki gdy minie data ważności produktu/produktów
* Możliwość dodawania zdjęć/awatarów punktów (lodówek)

# Zagrożenia/Ryzyka aplikacji
* Brak podmiotów (osób/organizacji/fundacji) dodających punkty dzielenia się żywnośćią i zarządzających nimi

## Technologie
Aplikacja korzysta z frameorku [Flutter](https://flutter.dev/), języka PHP oraz bazy danych MariaDB

### Framework Flutter
Flutter to open-source'owy framework Google, umożliwiający tworzenie **interaktywnych, wydajnych i pięknych** aplikacji mobilnych. Główne zalety Fluttera to **szybkość i wydajność** dzięki własnemu silnikowi renderowania, jednokodowość dla platform Android i iOS. Flutter obsługuje również inne platformy, takie jak sieć web, windows czy linux. Dzięki temu w przyszłości aplikacja Bio-Share będzie dostępna na innych platwormach przy minimalnym wysiłku.

## Uruchamianie aplikacji
W zakładce "Releases" do pobrania dostępny jest plik Bio-Share.apk. Wystarczy go zainstalować na urządzeniu z systemem android (może być konieczne zezwolenie na instalacje aplikacji z nieznanych źródeł).
