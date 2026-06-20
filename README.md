# FVIU Test App

Тестовое iOS-приложение по ТЗ: `AI Chat`, `AI Video Generator` и `Premium Flow` через `Apphud`. Основной фокус был не только на повторении экранов из `Figma`, но и на понятной структуре проекта: feature-based модули, единая навигация, изолированные сервисы и читаемая обработка состояний.

## Stack

- `SwiftUI`
- `iOS 16+`
- `MVVM`
- `Async/await`
- `URLSession`
- `Apphud SDK` через `Swift Package Manager`

## Project Structure

- `Core` - сетевой слой, dependency injection, navigation, app state, Apphud/subscription слой, работа с photo-library permissions и конфигурация приложения.
- `Features` - отдельные feature-модули: `Chat`, `VideoGenerator`, `Paywall`, `Settings`.
- `Shared` - design tokens, переиспользуемые UI-компоненты, state views и английские тексты интерфейса.

## What Is Implemented

### AI Text Chat

- Экран `Chat` по логике макета.
- Поле ввода с фокусом на клавиатуру.
- Кнопка отправки появляется после начала ввода.
- Обработка состояний `loading / success / error`.
- Реальный API-запрос через `ChatService` и `NetworkClient`.
- Локальная история чатов через `UserDefaults`.
- Empty-state и группировка истории по реальным датам.

### AI Video Generator

- Каталог шаблонов с категориями.
- Экран выбранного шаблона с горизонтальной snapping-каруселью.
- Поддержка шаблонов с одним или двумя фото.
- Интеграция `PhotosPicker`.
- Обработка доступа к галерее и повторный fallback-alert после отказа.
- Состояние загрузки выбранного фото.
- Удаление и замена выбранного фото.
- Изменяемые настройки `Format` и `Quality`.
- Неактивная кнопка `Create`, пока не выбраны нужные фото.
- Реальный generation flow через `VideoService` и `NetworkClient`.
- Экран загрузки, error-state и result-screen.
- Действия `Replace`, `Share`, `Download`.
- Локальная история видео через `UserDefaults`.

### Monetization / Apphud

- `Apphud SDK` подключен через `SPM`.
- Работа с Apphud изолирована в `ApphudManager`.
- `SubscriptionManager` отвечает за загрузку paywall, purchase, restore и проверку активной подписки.
- Premium-доступ закрывается централизованно через `AppState`.
- `Chat`, `Chat History`, `Video Generator`, `Video History` и экран template detail требуют premium-доступ.
- После purchase/restore доступ обновляется без перезапуска приложения.
- `Paywall` показывает два продукта и использует продукты из Apphud, когда они доступны.

## API Integration

- `Chat`: `POST https://nebulaapps.site/dola/chats/{chat_id}/messages`
- `Video create`: `POST https://nebulaapps.site/pixverse/api/v1/text2video`
- `Video status`: `GET https://nebulaapps.site/pixverse/api/v1/status`
- Авторизация отправляется как `Authorization: Bearer <token>`.
- `user_id` и `app_id` отправляются согласно Swagger-документации из ТЗ.

## Apphud Configuration

- `Bundle ID`: `com.labs.fviu`
- `Paywall ID`: `main`
- Apphud token находится в `AppConfig`, потому что он был выдан как часть тестовых данных.

## Build

Открыть `FVIUTestApp.xcodeproj` в `Xcode` и запустить схему `FVIUTestApp`.

Команда, которой проверялась сборка:

```bash
xcodebuild -project FVIUTestApp.xcodeproj -scheme FVIUTestApp -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

## Manual QA Checklist

- Открыть `Chat` без premium-доступа: должен появиться `Paywall`.
- Выполнить purchase или restore в настроенном Apphud sandbox: `Chat` и `Video Generator` должны открыться без перезапуска приложения.
- Открыть `Paywall`: close button появляется с небольшой задержкой.
- Нажать `Cancel Anytime`: должен открыться экран управления подписками Apple.
- Отправить prompt в `Chat`: должны отработать loading, success/error и сохранение в history.
- Открыть `Chat History`: empty-state и группировка по датам должны отображаться корректно.
- Открыть `Video Generator` без premium-доступа: должен появиться `Paywall`.
- Выбрать категорию и шаблон видео.
- Выбрать одно или два фото в зависимости от шаблона.
- Изменить `Format` и `Quality`.
- Нажать `Create`: должны отработать loading, result и error-state.
- Нажать `Replace`: должен вернуться flow генерации.
- Нажать `Download`: приложение должно запросить/использовать доступ к галерее и показать notification о сохранении.
- Нажать `Share`: должен открыться native share sheet.
- Открыть `Video History`: локальные результаты должны отображаться в истории.

## Notes For Reviewer

- Предоставленный video API может возвращать фиксированный ответ без реального downloadable video file. В приложении реализован request/status flow, но для demo save используется preview/fallback asset.
- У `Paywall` есть fallback-offer на случай, если Apphud products не загрузятся в simulator или sandbox. Это сделано, чтобы приложение оставалось рабочим во время проверки.
- Tokens и test data находятся в `AppConfig`, потому что они были выданы в ТЗ. В production их нужно выносить из source control.
