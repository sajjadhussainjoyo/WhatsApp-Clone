# WhatsApp UI

A Flutter-based WhatsApp-inspired messaging interface powered by Supabase. The app includes authentication, contact lists, chat screens, realtime messages, image sharing, status, and calls views.

## Features

- Email and password authentication with Supabase Auth
- WhatsApp-style Chats, Status, and Calls tabs
- Multiple profile entries with local avatar images
- Realtime message stream using Supabase Realtime
- Text messages and image messages
- Supabase Storage support for chat images
- Graceful local message fallback when the database table is not configured
- Flutter support for Android, iOS, Windows, macOS, Linux, and web

## Tech Stack

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
- [Supabase](https://supabase.com/)
- `supabase_flutter`
- `flutter_dotenv`
- `image_picker`

## Getting Started

### Prerequisites

- Flutter SDK 3.x or newer
- Dart SDK compatible with `>=3.1.5 <4.0.0`
- A Supabase project
- An Android/iOS device, emulator, or desktop Flutter target

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/<your-repository>.git
cd WhatsApp-UI
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Create `assets/.env` with the following values:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-or-publishable-key
```

Do not commit `assets/.env` or expose secret service-role keys in the Flutter app. The client should only use a public anon/publishable key.

### 4. Create the messages table

Open the Supabase SQL Editor and run the contents of [supabase_setup.sql](supabase_setup.sql). This creates:

- The `public.messages` table
- Row Level Security policies for authenticated users
- Realtime support for messages

### 5. Configure image uploads

In Supabase Storage, create a public bucket named `chat_media`. Configure the bucket policies according to your security requirements. The app uploads selected images to this bucket and displays their public URLs in chats.

### 6. Run the app

List available devices:

```bash
flutter devices
```

Run on the default device:

```bash
flutter run
```

Run on a specific device:

```bash
flutter run -d <device-id>
```

## Useful Commands

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
```

## Project Structure

```text
lib/
	main.dart                    # App entry point and Supabase initialization
	home_screen.dart             # Main tabs and contact lists
	screens/
		chat_screen.dart           # Realtime conversation and message composer
		auth/                      # Login and registration screens
assets/
	images/                      # Local profile images
	.env                         # Local Supabase configuration, not for Git
supabase_setup.sql             # Database and realtime setup
```

## Troubleshooting

### `PGRST205: Could not find the table 'public.messages'`

Run [supabase_setup.sql](supabase_setup.sql) in the Supabase SQL Editor, then restart the app. Until the table is available, the chat screen keeps messages locally for the current session.

### Image uploads fail

Confirm that the `chat_media` Storage bucket exists, is accessible to the signed-in user, and has the required insert/select policies.

### Authentication fails

Check the values in `assets/.env`, confirm that email authentication is enabled in Supabase, and verify that the user account exists.

## License

This project is for learning and demonstration purposes. Add a license file before distributing it publicly.
