# Gemini OSX (v1.0)

[English](#english) | [Русский](#russian)

---

<a name="english"></a>
## English

A native, lightweight client for the **Google Gemini API**, built for Macs running **OS X 10.9 Mavericks** and later.

Version 1.0 is written in **Objective-C** and uses native macOS frameworks. It brings a classic Messages-inspired chat interface to older Macs.

### Key Features

* **Native macOS Interface:** Chat sidebar, conversation view, model selector, and custom message bubbles.
* **Dynamic Model List:** Fetches the models currently available to your API key from Google.
* **Persistent Chat History:** Conversations are saved locally and restored when the app launches.
* **Chat Management:** Right-click a chat to rename it, delete it, or export it as a `.txt` file.
* **Automatic Draft Cleanup:** Empty chats are removed from history when you leave them or restart the app.
* **Keychain Storage:** Your Gemini API key is stored in the macOS Keychain, not in the source code.
* **No Third-Party Dependencies:** Built with native Apple frameworks, including AppKit, Foundation, and Security.

### Installation

1. Open the **[Releases](https://github.com/guzhoffivan-hue/Gemini-OSX/releases)** page and download `GeminiOSX-v1.0.dmg`.
2. Open the disk image and drag `GeminiOSX.app` to **Applications**.
3. Launch the app.

### Getting Started

1. On the first request, enter your **Google Gemini API key**. The app saves it in the macOS Keychain.
2. Choose an available model from the model selector.
3. Start a new chat and send a message.

### Network Notes

The app connects directly to the Gemini API over HTTPS. It does not include a VPN or proxy. If the API is unavailable on your network, check the network or DNS configuration you use on your Mac.

### Requirements

* OS X 10.9 Mavericks or later
* A Google Gemini API key
* Network access to the Gemini API

### Credits

* **Developer:** [.PBL](https://github.com/guzhoffivan-hue)
* **Interface inspiration:** The classic Messages app from the iOS 6 / OS X 10.8 era

---

<a name="russian"></a>
## Русский

Нативный легковесный клиент для **Google Gemini API**, созданный для Mac под управлением **OS X 10.9 Mavericks** и новее.

Версия 1.0 написана на **Objective-C** с использованием системных фреймворков macOS. Интерфейс чата вдохновлён классическими приложениями «Сообщения» для старых устройств Apple.

### Основные возможности

* **Нативный интерфейс macOS:** Боковая панель чатов, окно переписки, выбор модели и собственные бабблы сообщений.
* **Динамический список моделей:** Приложение загружает модели, доступные для вашего API-ключа.
* **Сохранение переписки:** Чаты хранятся локально и восстанавливаются при запуске приложения.
* **Управление чатами:** Нажмите правой кнопкой по чату, чтобы переименовать его, удалить или экспортировать в `.txt`.
* **Удаление пустых черновиков:** Пустой чат удаляется из истории при переходе к другому чату или после перезапуска приложения.
* **Хранение ключа в Keychain:** API-ключ сохраняется в Связке ключей macOS и не прописывается в исходном коде.
* **Без сторонних библиотек:** Используются системные фреймворки Apple, включая AppKit, Foundation и Security.

### Установка

1. Откройте страницу **[Releases](https://github.com/guzhoffivan-hue/Gemini-OSX/releases)** и скачайте `GeminiOSX-v1.0.dmg`.
2. Откройте образ и перетащите `GeminiOSX.app` в папку **Applications**.
3. Запустите приложение.

### Первый запуск

1. При первом запросе введите **Google Gemini API Key**. Приложение сохранит его в Связке ключей macOS.
2. Выберите доступную модель в списке.
3. Создайте чат и отправьте сообщение.

### Сеть

Приложение напрямую подключается к Gemini API по HTTPS. Встроенного VPN или прокси нет. Если API недоступно через вашу сеть, проверьте настройки подключения или DNS на Mac.

### Требования

* OS X 10.9 Mavericks или новее
* Google Gemini API-ключ
* Доступ к Gemini API через сеть

### Авторы и благодарности

* **Разработка:** [.PBL](https://github.com/guzhoffivan-hue)
* **Вдохновение для интерфейса:** классическое приложение «Сообщения» эпохи iOS 6 и OS X 10.8
