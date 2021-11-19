# SupaChat

## SQL

```sql
create table if not exists public.users (
    id uuid references auth.users on delete cascade not null primary key,
    name varchar(18) not null unique,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    constraint username_validation check (name ~* '^[A-Za-z0-9_]{3,24}$')
);
comment on table public.users is 'Holds all of users profile information';

alter table public.users enable row level security;
create policy "Public profiles are viewable by everyone." on public.users for select using (true);
create policy "Can insert user" on public.users for insert with check (auth.uid() = id);
create policy "Can update user" on public.users for update using (auth.uid() = id) with check (auth.uid() = id);
create policy "Can delete user" on public.users for delete using (auth.uid() = id);


create table if not exists public.rooms (
    id uuid not null primary key DEFAULT uuid_generate_v4 (),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.rooms is 'Holds chat rooms';

alter table public.rooms enable row level security;
create policy "rooms are viewable by everyone. " on public.rooms for select using (
    exists(
        select 1
        from user_room
        where rooms.id = user_room.room_id
        and user_room.user_id = auth.uid()
    )
);


create table if not exists public.user_room (
    user_id uuid references public.users on delete cascade not null,
    room_id uuid references public.rooms on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    PRIMARY KEY (user_id, room_id)
);
comment on table public.user_room is 'Relational table of users and rooms.';

alter table public.user_room enable row level security;
create policy "Only the participants can view who is in the room" on public.user_room for select using (
    exists(
        select 1
        from rooms
        where rooms.id = user_room.room_id
        and user_room.user_id = auth.uid()
    )
);


create table if not exists public.messages (
    id uuid not null primary key DEFAULT uuid_generate_v4 (),
    user_id uuid references public.users on delete cascade not null,
    room_id uuid references public.rooms on delete cascade not null,
    text text not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';

alter table public.messages enable row level security;
create policy "Users can view messages on rooms they are in." on public.messages for select using (
    exists(
        select 1
        from user_room
        where messages.room_id = user_room.room_id
        and user_room.user_id = auth.uid()
    )
);
create policy "Users can insert messages on rooms they are in." on public.messages for insert with check (
    auth.uid() = user_id
    && exists(
        select 1
        from user_room
        where messages.room_id = user_room.room_id
        and user_room.user_id = auth.uid()
    )
);
```
