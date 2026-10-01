# Flutter Chat Example

Simple chat app to demonstrate the realtime capability of Supabase with Flutter. You can follow along on how to build this app on [this article](https://supabase.com/blog/flutter-tutorial-building-a-chat-app).

You can also find an example using [row level security](https://supabase.com/docs/guides/auth/row-level-security) to provide chat rooms to enable 1 to 1 chats on the [`with-auth` branch](https://github.com/supabase-community/flutter-chat/tree/with_auth).

## Requirements

- Flutter 3.47 or newer
- A Supabase project, either hosted or running locally with the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)

The database schema lives in [`supabase/migrations`](supabase/migrations). It creates the `profiles` and `messages` tables, their row level security policies, the trigger that creates a profile on sign up, and adds `messages` to the realtime publication.

## Using a hosted project

1. Create a project on the [Supabase dashboard](https://supabase.com/dashboard).
2. Apply the schema, either by linking the project and pushing the migration:

   ```bash
   supabase link --project-ref your-project-ref
   supabase db push
   ```

   or by pasting the contents of the migration file into the SQL editor of the dashboard.
3. Copy the project URL and the publishable key from the API keys page of the dashboard.

Hosted projects require users to confirm their email address by default. After registering, open the confirmation link from the email and then sign in. You can turn this off under Authentication, Sign In / Providers, Email.

## Using a local project

1. Start the local stack from the root of this repository. This applies the migration automatically:

   ```bash
   supabase start
   ```

2. Copy the API URL and the publishable key that `supabase start` prints. You can show them again with `supabase status`.

The Android emulator reaches your computer through `10.0.2.2`, so use `http://10.0.2.2:54321` as the URL there. The iOS simulator can use `http://127.0.0.1:54321`.

Email confirmation is turned off locally, so registering signs you in right away.

## Running the app

The app reads its credentials from compile time environment declarations. Either put them in a `.env` file in the project root, which is ignored by git:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```

and pass the file to Flutter:

```bash
flutter run --dart-define-from-file=.env
```

or pass them directly:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key
```
