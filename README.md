

# Instalacja i uruchomienie skryptu (od autora) 

 ## Installation

Requirements:

```sh
python -m venv ./venv
source .venv/bin/activate
```

Next, run

```sh
pip install -r requirements.txt
```

to get the dependencies.

Finally run the api with

```sh
python api.py
```

## Example

Flask will run on http://127.0.0.1:5000/.

```sh
$ curl 127.0.0.1:5000/
[{"id":1,"name":"Monday"},{"id":2,"name":"Tuesday"},{"id":3,"name":"Wednesday"},{"id":4,"name":"Thursday"},{"id":5,"name":"Friday"},{"id":6,"name":"Saturday"},{"id":7,"name":"Sunday"}]
```

To return a single day pass in a number with Monday starting at 1.

```sh
$ curl 127.0.0.1:5000/2
{"day":{"id":2,"name":"Tuesday"}}
```

Days will also accept a post message.

```sh
$ curl -X POST 127.0.0.1:5000/
{"success":true}
```
  
# Raport z konfiguracji dwóch instancji EC2

### Opis przygotowanej konfiguracji

### Instancje EC2

#### Maszyna BUILD:
- Używana do budowania pakietów aplikacji w formacie Wheel.
- Security group jest odpwoiednio skofnigurowane aby udostępniało ruch HTTTP na porcie 5000 i 5001
- System operacyjny: Amazon Linux 2.
- Zainstalowane pakiety: Python3, Git, pip, wheel.
- Aplikacja budowana w katalogu `/home/ec2-user/app/`, z plikiem .whl w katalogu `dist/`.
- Zawiera plik buid_script.sh wykonujący klonowanie, tworzenie pliku wheel i utworzenie relase zawierjącym kod aplkiacji wraz z plikiem .whl.
  
#### Maszyna TEST:
- Używana do uruchamiania testowej wersji aplikacji zbudowanej na maszynie BUILD.
- Security group jest odpwoiednio skofnigurowane aby udostępniało ruch HTTTP na porcie 5000 i 5001
- System operacyjny: Amazon Linux 2.
- Zainstalowane pakiety: Python3, pip, wheel.
- Aplikacja zainstalowana z pliku .whl w katalogu `/home/ec2-user/`.
- Zawiera plik all_install.sh wykonujący pobranie, rozpakowanie kodu źródłowego wraz z plikiem wheel i niezbędnymi pakietami.
- Zawiera plik tests.sh wykonujący test dymny i dwa kolejne sprawdzające działanie aplkiacji.

## Zrzuty ekranu

- **Zrzut 1**: Tworzenie instancji EC2 (BUILD i TEST)
- **Zrzut 2**: Połączenie z maszyną BUILD
- **Zrzut 3**: Budowanie pakietu aplikacji na maszynie BUILD

## Sposób realizacji zadań

### Maszyna BUILD

#### Tworzenie instancji EC2:
- Tworzymy nową instancję EC2 z Amazon Linux 2.
- Konfigurujemy grupy zabezpieczeń, aby umożliwić połączenie SSH.

#### Instalacja wymaganych narzędzi:
- Po przez skrypt build_script.sh instalujemy wymagane pakiety zawarte w setup.py i requirements.txt
```sh
pip install --upgrade pip
pip install -r requirements.txt
pip install wheel
```

#### Pobranie kodu źródłowego aplikacji:
- Klonujemy repozytorium GitHub i usuwamy poprzednie pliki budowania:
```sh
REPO_URL="https://github.com/BlueNovember1/python-api.git"  # Twoje repozytorium
BUILD_DIR="/home/ec2-user/build"
VERSION="v$(date +'%Y%m%d%H%M')"  # automatyczna nazwa wersji bazująca na dacie i czasie

echo ">>> Klonowanie repozytorium..."
rm -rf $BUILD_DIR  # usuń poprzednie pliki budowania
git clone $REPO_URL $BUILD_DIR
```

#### Budowanie pakietu:
- Budujemy pakiet Wheel za pomocą polecenia:
```sh
python3 /home/ec2-user/build/setup.py bdist_wheel
```

#### Przesyłanie pliku .whl na maszynę TEST:
- Używamy SCP do przesłania pliku .whl na maszynę TEST:
    
#### Czyszczenie i dezaktywacja środowiksa
```sh
echo ">>> Czyszczenie środowiska..."
deactivate  # wyłącz wirtualne środowisko
rm -rf venv  # usuń wirtualne środowisko
rm -rf build dist *.egg-info  # usuń pozostałe pliki
```
#### Wybór repozytorium, tworzenie wydania i link do niego
- Wybór repozytorium
```bash
echo ">>> Ustawianie repozytorium BlueNovember1/python-api jako domyślne..."
gh repo set-default BlueNovember1/python-api
```
- Tworzenie wydania (relese) z kodem źródłowym i plikiem wheel
```bash
echo ">>> Tworzenie nowego wydania na GitHub..."
gh release create $VERSION $WHEEL_FILE --notes "Release $VERSION"
```
- Link do wydania
```bash
RELEASE_URL="https://github.com/BlueNovember1/python-api/releases/tag/$VERSION"
echo ">>> Wydanie dostępne pod adresem: $RELEASE_URL"
```
### Maszyna Test
#### Tworzenie instancji EC2:
- Tworzymy nową instancję EC2 z Amazon Linux 2.
- Konfigurujemy grupy zabezpieczeń, aby umożliwić połączenie SSH.
- Tworzymy nową instancję EC2 z Amazon Linux 2, z otwartym portem 5000 i 5001 (HTTP).

#### Instalacja wymaganych narzędzi:
- Po przez skrypt install_script.sh instalujemy wymagane pakiety zawarte w setup.py i requirements.txt
```sh
pip install pip
pip install -r requirements.txt
pip install wheel
```
#### Pobieranie z relase najnowsze wydanie aplikacji
```sh
echo ">>> Pobieranie najnowszego wydania aplikacji z GitHub (plik .whl)..."
wget --header="Authorization: token $GITHUB_TOKEN" $LATEST_RELEASE_URL -O $WHL_FILE
```
```sh
echo ">>> Pobieranie pliku ZIP z kodem źródłowym z GitHub..."
wget --header="Authorization: token $GITHUB_TOKEN" $ZIP_URL -O $ZIP_FILE
```

#### Rozpakowanie kodu źródłowego
```sh
echo ">>> Rozpakowywanie pliku ZIP..."
unzip $ZIP_FILE -d $INSTALL_DIR/source_code
```
#### Instalacja aplikacji z pliku .whl:
- Tworzymy wirtualne środowisko i instalujemy aplikację:
    ```sh
    python3 -m venv venv
    source venv/bin/activate
    pip install /home/ec2-user/your-app-1.0.0-py3-none-any.whl
    ```

#### Konfiguracja systemu do uruchamiania aplikacji po restarcie:
- Tworzymy plik serwisowy systemd, aby aplikacja uruchamiała się automatycznie po restarcie:
    ```sh
    sudo tee /etc/systemd/system/python-api.service > /dev/null <<EOL
    [Unit]
    Description=Python API Application
    After=network.target

    [Service]
    User=ec2-user
    WorkingDirectory=/home/ec2-user/
    Environment="PATH=/home/ec2-user/venv/bin"
    ExecStart=/home/ec2-user/venv/bin/python3 -m flask run --host=0.0.0.0 --port=5000
    Restart=always

    [Install]
    WantedBy=multi-user.target
    EOL
    ```

#### Uruchomienie aplikacji i testowanie:
- Uruchamiamy aplikację jako usługę:
    ```sh
    sudo systemctl daemon-reload
    sudo systemctl enable python-api
    sudo systemctl start python-api
    ```
- Sprawdzamy działanie aplikacji (test dymny):
    ```sh
    curl http://localhost:5000/
    ```
    lub w celu wykonania wszytkich testów na raz
    ```bash
    bash tests.sh
    ```
    

## Wnioski

### Budowanie i uruchamianie aplikacji:
- Konfiguracja maszyn BUILD i TEST umożliwia oddzielne procesy budowania oraz testowania aplikacji, co ułatwia kontrolę jakości i pozwala na bardziej elastyczne zarządzanie środowiskami.
- Odpowiedenia konfiguracja secuirty group dla danej instacji jest niezbędnym elementem pracy na instancjach.
- Dostęp do instancji może być umożliwiony po przez klucz ssh lub wygenrowany token gitchub z odpowiednimi dostępami.
- Procesy na maszynie BUILD oraz TEST mogą być dodatkowo zautomatyzowane za pomocą skryptów CI/CD.

### Wkład poszczególnych członków grupy:
- Praca została podzielona w odpowiedni sposób aby każdy członek grupy mógł zrozumieć działanie instancji i skryptów na nich.


