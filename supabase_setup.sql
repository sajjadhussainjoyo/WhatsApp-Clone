-- Run this once in the Supabase SQL Editor.
create table if not exists public.messages (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  sender_id uuid references auth.users not null,
  content text,
  image_url text,
  receiver_name text
);

alter table public.messages enable row level security;

create policy "Users can read messages"
  on public.messages for select
  to authenticated
  using (true);

create policy "Users can send messages"
  on public.messages for insert
  to authenticated
  with check (auth.uid() = sender_id);

alter publication supabase_realtime add table public.messages;