# Flutter Chat Example

Simple chat app to demonstrate the realtime capability of Supabase with Flutter.

With [WALRUS](https://github.com/supabase/walrus), Supabase now can have row level security enabled with its realtime feature. This repo utilizes row level security on realtime to securely exchange private messages with other users using the app.

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
