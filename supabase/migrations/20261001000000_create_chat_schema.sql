create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    username varchar(24) not null unique,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,

    -- username should be 3 to 24 characters long containing alphabets, numbers and underscores
    constraint username_validation check (username ~* '^[A-Za-z0-9_]{3,24}$')
);
comment on table public.profiles is 'Holds all of users profile information';

create table if not exists public.messages (
    id uuid not null primary key default gen_random_uuid(),
    profile_id uuid default auth.uid() references public.profiles(id) on delete cascade not null,
    content varchar(500) not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';

alter table public.profiles enable row level security;
alter table public.messages enable row level security;

create policy "Signed in users can read profiles"
    on public.profiles for select
    to authenticated
    using (true);

create policy "Signed in users can read messages"
    on public.messages for select
    to authenticated
    using (true);

create policy "Users can send messages as themselves"
    on public.messages for insert
    to authenticated
    with check ((select auth.uid()) = profile_id);

-- Add the messages table to the publication to enable realtime
alter publication supabase_realtime add table public.messages;

-- Creates a profile for every new user, using the username from the sign up metadata
create or replace function public.handle_new_user() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles(id, username)
    values(new.id, new.raw_user_meta_data->>'username');

    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row
    execute function public.handle_new_user();
