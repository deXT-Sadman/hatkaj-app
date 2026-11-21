# HatKaj App

![Flutter](https://img.shields.io/badge/Flutter-3-02569B?logo=flutter&logoColor=white)
![State](https://img.shields.io/badge/state-Provider-0E9F8E)
![Tests](https://img.shields.io/badge/tests-24%20passing-brightgreen)

Flutter client for **HatKaj**, a smart maintenance and service booking platform. It talks to the Laravel [`hatkaj-api`](https://github.com/deXT-Sadman/hatkaj-api).

Screenshots below are from the Android emulator running against the local API.

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/home.png" width="220" alt="Home dashboard with status counts and upcoming bookings"><br><sub><b>Home dashboard</b></sub></td>
    <td align="center"><img src="docs/screenshots/services.png" width="220" alt="Service list with icons, duration and price"><br><sub><b>Services</b></sub></td>
    <td align="center"><img src="docs/screenshots/bookings.png" width="220" alt="Bookings list with status filter chips"><br><sub><b>Bookings + filters</b></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/form.png" width="220" alt="New booking form"><br><sub><b>New booking</b></sub></td>
    <td align="center"><img src="docs/screenshots/conflict.png" width="220" alt="Slot conflict message returned by the API"><br><sub><b>Slot conflict (409)</b></sub></td>
    <td></td>
  </tr>
</table>

## Features
- **Home dashboard**: status counts (tap one to open Bookings filtered by it), the next upcoming bookings, and quick service shortcuts
- **Services** list, and a **booking form** with validation and server errors shown inline (including the 409 "slot already booked")
- **Bookings** list with pull-to-refresh, "load more" pagination and status filter chips
- **Status updates**: tap a booking's status chip to see only the transitions the API allows
- Explicit loading / empty / error / success states on every screen

## Setup
1. Start the API (`php artisan serve --host=0.0.0.0`, see the API repo).
2. Run the app:
```bash
flutter pub get
flutter run                                   # Android emulator (uses 10.0.2.2:8000)
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000   # real device: your PC's LAN IP
flutter test
```
The phone and PC must be on the same network. Android cleartext HTTP is enabled for local development only.

## Architecture
```
lib/
  core/          config (base URL), theme, ApiClient (http wrapper), ApiException
  data/          models (fromJson/toJson), repositories (one per API resource)
  presentation/  providers (ChangeNotifier), screens, widgets
```
Screens -> Providers -> Repositories -> ApiClient -> API. Each layer only knows the one below it.

| Provider | Owns |
|---|---|
| `ServicesProvider` | service list |
| `BookingsProvider` | bookings list, status filter, pagination, create and status update |
| `DashboardProvider` | per-status counts and upcoming bookings |

## Key engineering trade-offs
- **Provider over BLoC**: the app has a few small lists and one form. `ChangeNotifier` keeps it readable. BLoC would pay off with more complex event flows.
- **`ViewState` enum + `StateView` widget** make loading/empty/error/success explicit and reusable.
- **Failed refresh keeps old data** on screen and shows a snackbar instead of wiping the list.
- **Reload after mutations**: after create/status change the list is refetched, so server ordering and filters stay correct. This costs one extra request but avoids client/server drift.
- **Dashboard counts come from the server**: each status query returns `meta.total`, so numbers stay correct however many bookings exist, without downloading them all.
- **Transition rules duplicated client-side** (`BookingStatus.allowedTransitions`) only to hide invalid actions. The API remains the authority and returns 422 if they diverge.
- **Tests use fake repositories**, so provider and form logic are tested without a network.
