# Popcorn Battle Game

App mobile de quiz multiplayer desenvolvido em Flutter, consumindo a API REST do backend Spring Boot.

---

## Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.12.0
- Dart SDK (incluído no Flutter)
- Android Studio ou Xcode (para emuladores/dispositivos)
- Backend Spring Boot rodando e acessível na rede

---

## Instalação

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd popcornbattlegame
```

### 2. Instale as dependências

```bash
flutter pub get
```

### 3. Configure o endereço da API

Edite o arquivo `lib/core/constants/api_constants.dart` e altere o valor de `baseUrl` para o IP e porta onde o backend está rodando:

```dart
static const String baseUrl = 'http://<IP_DO_SERVIDOR>:8080/api';
```

> O backend deve estar acessível a partir do dispositivo/emulador. Se estiver rodando localmente e testando em um dispositivo físico, use o IP da sua máquina na rede local (ex: `192.168.1.x`). Para emulador Android, use `10.0.2.2` no lugar de `localhost`.

---

## Rodando o app

### Listar dispositivos disponíveis

```bash
flutter devices
```

### Rodar em modo debug

```bash
flutter run
```

Para selecionar um dispositivo específico:

```bash
flutter run -d <device-id>
```

### Rodar no Android (emulador ou dispositivo físico)

```bash
flutter run -d android
```

### Rodar no iOS (requer macOS com Xcode)

```bash
flutter run -d ios
```

---

## Build para produção

### Android (APK)

```bash
flutter build apk --release
```

O APK gerado fica em `build/app/outputs/flutter-apk/app-release.apk`.

### Android (App Bundle para Play Store)

```bash
flutter build appbundle --release
```

### iOS (requer macOS)

```bash
flutter build ios --release
```

---

## Dependências principais

| Pacote | Uso |
|---|---|
| `http` | Requisições HTTP para a API REST |
| `shared_preferences` | Persistência local (ex: token de autenticação) |
| `cupertino_icons` | Ícones no estilo iOS |

---

## Recursos

- [Documentação oficial do Flutter](https://docs.flutter.dev/)
- [Dart packages (pub.dev)](https://pub.dev/)
