-- شغّل الملف ده مرة واحدة بس من: Supabase Dashboard -> SQL Editor -> New query
-- (انسخ المحتوى كله واعمل Run)

create table if not exists public.academy_names (
  name text primary key,
  updated_at timestamptz not null default now()
);

alter table public.academy_names enable row level security;

-- أي حد (حتى لو مش مسجل دخول) يقدر يقرأ القائمة -- ده اللي شاشة
-- "إنشاء حساب جديد" محتاجاه قبل ما المستخدم يسجل دخول أصلًا.
create policy "academy_names_public_read"
  on public.academy_names
  for select
  using (true);

-- محدش يقدر يكتب/يعدل/يمسح مباشرة من التطبيق. الكتابة الوحيدة المسموحة
-- هي من الـ Edge Function (sync-academy-names) اللي بتستخدم الـ service role
-- key، وده بيتجاوز RLS تلقائيًا فمش محتاجين policy للكتابة أصلًا.
