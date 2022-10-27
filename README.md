# Flutter Chat Example

Simple chat app to demonstrate the realtime capability of Supabase with Flutter. You can follow along on how to build this app on [this article](https://supabase.com/blog/flutter-tutorial-building-a-chat-app).

You can also find an example using [row level security](https://supabase.com/docs/guides/auth/row-level-security) to provide chat rooms to enable 1 to 1 chats on the [`with-auth` branch](https://github.com/supabase-community/flutter-chat/tree/with_auth). 

## SQL

```sql
-- *** Table definitions ***

create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    username varchar(24) not null unique,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,

    -- username should be 3 to 24 characters long containing alphabets, numbers and underscores
    constraint username_validation check (username ~* '^[A-Za-z0-9_]{3,24}$')
);
comment on table public.profiles is 'Holds all of users profile information';

create table if not exists public.messages (
    id uuid not null primary key default uuid_generate_v4(),
    profile_id uuid default auth.uid() references public.profiles(id) on delete cascade not null,
    content varchar(500) not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';

-- *** Add tables to the publication to enable realtime ***
alter publication supabase_realtime add table public.messages;


-- Function to create a new row in profiles table upon signup
-- Also copies the username value from metadata
create or replace function handle_new_user() returns trigger as $$
    begin
        insert into public.profiles(id, username)
        values(new.id, new.raw_user_meta_data->>'username');

        return new;
    end;
$$ language plpgsql security definer;

-- Trigger to call `handle_new_user` when new user signs up
create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function handle_new_user();
```
