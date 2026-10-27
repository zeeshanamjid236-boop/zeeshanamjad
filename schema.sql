-- CHAMPIONS DATABASE SETUP
-- Run the whole script in Supabase SQL Editor using the project's owner account.
create extension if not exists pgcrypto;

create table if not exists public.cc_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Student',
 created_at timestamptz not null default now()
);
create table if not exists public.cc_admins (
 user_id uuid primary key references auth.users(id) on delete cascade,
 created_at timestamptz not null default now()
);
create table if not exists public.cc_polls (
 id uuid primary key default gen_random_uuid(),
 question text not null,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.cc_poll_options (
 id uuid primary key default gen_random_uuid(),
 poll_id uuid not null references public.cc_polls(id) on delete cascade,
 label text not null,
 sort_order int not null default 0
);
create table if not exists public.cc_poll_votes (
 id uuid primary key default gen_random_uuid(),
 poll_id uuid not null references public.cc_polls(id) on delete cascade,
 option_id uuid not null references public.cc_poll_options(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 unique(poll_id,user_id)
);
create table if not exists public.cc_feedback (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 topic text not null,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.cc_feedback_ratings (
 id uuid primary key default gen_random_uuid(),
 feedback_id uuid not null references public.cc_feedback(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 rating int not null check(rating between 1 and 5),
 created_at timestamptz not null default now(),
 unique(feedback_id,user_id)
);
create table if not exists public.cc_groups (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 is_private boolean not null default false,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table if not exists public.cc_group_members (
 group_id uuid not null references public.cc_groups(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 joined_at timestamptz not null default now(),
 primary key(group_id,user_id)
);
create table if not exists public.cc_messages (
 id uuid primary key default gen_random_uuid(),
 group_id uuid not null references public.cc_groups(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 body text not null check(length(body) between 1 and 5000),
 created_at timestamptz not null default now()
);
create table if not exists public.cc_posts (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 kind text not null default 'Community',
 body text not null,
 user_id uuid not null references auth.users(id) on delete cascade,
 display_name text not null default 'Student',
 created_at timestamptz not null default now()
);
create table if not exists public.cc_sale_items (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 price text not null,
 details text not null,
 user_id uuid not null references auth.users(id) on delete cascade,
 display_name text not null default 'Student',
 created_at timestamptz not null default now()
);

create or replace function public.cc_is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.cc_admins where user_id=auth.uid()); $$;
create or replace function public.cc_is_group_member(gid uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.cc_group_members where group_id=gid and user_id=auth.uid()); $$;
grant execute on function public.cc_is_admin() to authenticated;
grant execute on function public.cc_is_group_member(uuid) to authenticated;

alter table public.cc_profiles enable row level security;
alter table public.cc_admins enable row level security;
alter table public.cc_polls enable row level security;
alter table public.cc_poll_options enable row level security;
alter table public.cc_poll_votes enable row level security;
alter table public.cc_feedback enable row level security;
alter table public.cc_feedback_ratings enable row level security;
alter table public.cc_groups enable row level security;
alter table public.cc_group_members enable row level security;
alter table public.cc_messages enable row level security;
alter table public.cc_posts enable row level security;
alter table public.cc_sale_items enable row level security;

create policy "profiles readable by authenticated" on public.cc_profiles for select to authenticated using(true);
create policy "users create own profile" on public.cc_profiles for insert to authenticated with check(id=auth.uid());
create policy "users update own profile" on public.cc_profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "admins list own admin status" on public.cc_admins for select to authenticated using(user_id=auth.uid());

create policy "polls visible to signed in users" on public.cc_polls for select to authenticated using(true);
create policy "admins create polls" on public.cc_polls for insert to authenticated with check(public.cc_is_admin() and created_by=auth.uid());
create policy "admins delete polls" on public.cc_polls for delete to authenticated using(public.cc_is_admin());
create policy "options visible to signed in users" on public.cc_poll_options for select to authenticated using(true);
create policy "admins add options" on public.cc_poll_options for insert to authenticated with check(public.cc_is_admin());
create policy "votes visible to signed in users" on public.cc_poll_votes for select to authenticated using(true);
create policy "users vote as themselves" on public.cc_poll_votes for insert to authenticated with check(user_id=auth.uid() and exists(select 1 from public.cc_poll_options o where o.id=option_id and o.poll_id=cc_poll_votes.poll_id));

create policy "feedback visible to signed in users" on public.cc_feedback for select to authenticated using(true);
create policy "admins create feedback" on public.cc_feedback for insert to authenticated with check(public.cc_is_admin() and created_by=auth.uid());
create policy "feedback ratings visible to signed in users" on public.cc_feedback_ratings for select to authenticated using(true);
create policy "users rate as themselves" on public.cc_feedback_ratings for insert to authenticated with check(user_id=auth.uid() and rating between 1 and 5);

create policy "public groups visible; private groups to members or creator" on public.cc_groups for select to authenticated using(not is_private or public.cc_is_group_member(id) or created_by=auth.uid() or public.cc_is_admin());
create policy "signed in users create groups" on public.cc_groups for insert to authenticated with check(created_by=auth.uid());
create policy "creators or admins delete groups" on public.cc_groups for delete to authenticated using(created_by=auth.uid() or public.cc_is_admin());
create policy "members visible to group members" on public.cc_group_members for select to authenticated using(user_id=auth.uid() or public.cc_is_group_member(group_id) or public.cc_is_admin());
create policy "users join public groups or creator joins private group" on public.cc_group_members for insert to authenticated with check(user_id=auth.uid() and (exists(select 1 from public.cc_groups g where g.id=group_id and (not g.is_private or g.created_by=auth.uid())) or public.cc_is_admin()));
create policy "users leave own group" on public.cc_group_members for delete to authenticated using(user_id=auth.uid() or public.cc_is_admin());

create policy "members read group messages" on public.cc_messages for select to authenticated using(public.cc_is_group_member(group_id));
create policy "members send as themselves" on public.cc_messages for insert to authenticated with check(user_id=auth.uid() and public.cc_is_group_member(group_id));

create policy "posts visible to signed in users" on public.cc_posts for select to authenticated using(true);
create policy "users create own posts" on public.cc_posts for insert to authenticated with check(user_id=auth.uid());
create policy "owner or admin delete posts" on public.cc_posts for delete to authenticated using(user_id=auth.uid() or public.cc_is_admin());
create policy "sale items visible to signed in users" on public.cc_sale_items for select to authenticated using(true);
create policy "users create own sale items" on public.cc_sale_items for insert to authenticated with check(user_id=auth.uid());
create policy "owner or admin delete sale items" on public.cc_sale_items for delete to authenticated using(user_id=auth.uid() or public.cc_is_admin());

-- Realtime messages are needed for live chat updates.
alter publication supabase_realtime add table public.cc_messages;
alter publication supabase_realtime add table public.cc_poll_votes;
