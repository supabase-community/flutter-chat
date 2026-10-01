alter table public.messages
    add column attachment_path text,
    add column attachment_name text,
    alter column content set default '';

-- A message needs either text or an attachment
alter table public.messages
    add constraint content_or_attachment check (content <> '' or attachment_path is not null);

drop policy "Users can send messages as themselves" on public.messages;

create policy "Users can send messages as themselves"
    on public.messages for insert
    to authenticated
    with check (
        (select auth.uid()) = profile_id
        and (
            attachment_path is null
            or (storage.foldername(attachment_path))[1] = (select auth.uid())::text
        )
    );

-- Private bucket for the attachments, limited to 10 MiB per file
insert into storage.buckets (id, name, public, file_size_limit)
values ('attachments', 'attachments', false, 10485760)
on conflict (id) do nothing;

create policy "Signed in users can read attachments"
    on storage.objects for select
    to authenticated
    using (bucket_id = 'attachments');

-- Files are stored under a folder named after the id of the uploader
create policy "Users can upload attachments to their own folder"
    on storage.objects for insert
    to authenticated
    with check (
        bucket_id = 'attachments'
        and (storage.foldername(name))[1] = (select auth.uid())::text
    );
