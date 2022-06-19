# Flutter Chat Example

Simple chat app to demonstrate the realtime capability of Supabase with Flutter.

With [WALRUS](https://github.com/supabase/walrus), Supabase now can have row level security enabled with its realtime feature. This repo utilizes row level security on realtime to securely exchange private messages with other users using the app.

## SQL

```sql
-- *** Table definitions ***

create table if not exists public.profiles (
    id uuid references auth.users on delete cascade not null primary key,
    username varchar(18) not null unique,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,

    -- username should be 3 to 24 characters long containing alphabets, numbers and underscores
    constraint username_validation check (username ~* '^[A-Za-z0-9_]{3,24}$')
);
comment on table public.users is 'Holds all of users profile information';

create table if not exists public.rooms (
    id uuid not null primary key default uuid_generate_v4(),
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.rooms is 'Holds chat rooms';

create table if not exists public.user_room (
    user_id uuid references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null,
    PRIMARY KEY (profile_id, room_id)
);
comment on table public.user_room is 'Relational table of users and rooms.';

create table if not exists public.messages (
    id uuid not null primary key DEFAULT uuid_generate_v4(),
    profile_id uuid references public.profiles(id) on delete cascade not null,
    room_id uuid references public.rooms on delete cascade not null,
    content text not null,
    created_at timestamp with time zone default timezone('utc' :: text, now()) not null
);
comment on table public.messages is 'Holds individual messages within a chat room.';


-- *** Security definer functions ***

-- Returns true if the signed in user is a participant of the room
create or replace function is_room_participant(room_id uuid)
returns boolean as $$
  select exists(
    select 1
    from room_participants
    where room_id = is_room_participant.room_id and profile_id = auth.uid()
  );
$$ language sql security definer;


-- *** Row level security polities ***


alter table public.profiles enable row level security;
create policy "Public profiles are viewable by everyone." on public.users for select using (true);


alter table public.rooms enable row level security;
create policy "Users can view rooms that they have joined" on public.rooms for select using (is_room_participant(id));


alter table public.user_room enable row level security;
create policy "Participants of the room can add people." on public.user_room for insert with check (is_room_participant(room_id));


alter table public.messages enable row level security;
create policy "Users can view messages on rooms they are in." on public.messages for select using (is_room_participant(room_id));
create policy "Users can insert messages on rooms they are in." on public.messages for insert with check (is_room_participant(room_id));

-- *** Add tables to the publication to enable realtime ***

alter publication supabase_realtime add table public.user_room;
alter publication supabase_realtime add table public.messages;

-- *** Views and functions ***


-- Returns list of rooms as well as the participants as array of uuid
-- Used to determine if there is a room with given pair of users in create_new_room()
create or replace view room_participants
as
    select rooms.id as room_id, array_agg(user_room.profile_id) as users
    from rooms
    left join user_room on rooms.id = user_room.room_id
    group by rooms.id;

-- Creates a new room with the user and another user in it.
-- Will return the room_id of the created room
-- Will return a room_id if there were already a room with those participants
create or replace function create_new_room(opponent_uid uuid) returns uuid as $$
    declare
        new_room_id uuid;
    begin
        -- Check if room with both participants already exist
        select room_id from room_participants
        into new_room_id
        where opponent_uid=any(users)
        and auth.uid()=any(users);


        if not found then
            -- Create a new room
            insert into public.rooms () values()
            returning id into new_room_id;

            -- Insert the caller user into the new room
            insert into public.user_room (user_id, room_id)
            values (auth.uid(), new_room_id);

            -- Insert the opponent user into the new room
            insert into public.user_room (user_id, room_id)
            values (opponent_uid, new_room_id);
        end if;

        return new_room_id;
    end
$$ language plpgsql security definer;
```
