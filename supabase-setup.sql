-- GJShop backend: run in a NEW dedicated Supabase project.
-- After creating your Auth user, add their UUID to gjshop_admins manually via SQL editor.
create table if not exists public.gjshop_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.gjshop_admins enable row level security;
revoke all on public.gjshop_admins from anon;
grant select on public.gjshop_admins to authenticated;
drop policy if exists "admins can read own role" on public.gjshop_admins;
create policy "admins can read own role" on public.gjshop_admins for select to authenticated
using (user_id = (select auth.uid()));

create table if not exists public.gjshop_products (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 2 and 160),
  category text not null check (char_length(category) between 2 and 80),
  retailer text not null check (char_length(retailer) between 2 and 80),
  image_url text,
  product_url text not null,
  description text,
  price_inr numeric(12,2) check (price_inr >= 0),
  published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint product_url_https check (product_url ~ '^https://[^[:space:]]+$'),
  constraint image_url_https check (image_url is null or image_url ~ '^https://[^[:space:]]+$')
);
create index if not exists gjshop_products_published_idx on public.gjshop_products(published,created_at desc);
alter table public.gjshop_products enable row level security;
grant select on public.gjshop_products to anon, authenticated;
grant insert, update, delete on public.gjshop_products to authenticated;
drop policy if exists "public read published" on public.gjshop_products;
create policy "public read published" on public.gjshop_products for select to anon, authenticated
using (published = true);
drop policy if exists "admins read all" on public.gjshop_products;
create policy "admins read all" on public.gjshop_products for select to authenticated
using (exists (select 1 from public.gjshop_admins a where a.user_id = (select auth.uid())));
drop policy if exists "admins insert" on public.gjshop_products;
create policy "admins insert" on public.gjshop_products for insert to authenticated
with check (exists (select 1 from public.gjshop_admins a where a.user_id = (select auth.uid())));
drop policy if exists "admins update" on public.gjshop_products;
create policy "admins update" on public.gjshop_products for update to authenticated
using (exists (select 1 from public.gjshop_admins a where a.user_id = (select auth.uid())))
with check (exists (select 1 from public.gjshop_admins a where a.user_id = (select auth.uid())));
drop policy if exists "admins delete" on public.gjshop_products;
create policy "admins delete" on public.gjshop_products for delete to authenticated
using (exists (select 1 from public.gjshop_admins a where a.user_id = (select auth.uid())));
-- Bootstrap ONLY via SQL editor after creating your admin user:
-- insert into public.gjshop_admins(user_id) values ('REPLACE-WITH-AUTH-USER-UUID');
