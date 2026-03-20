-- Run ALL of these in Supabase SQL Editor

-- 1. Update reports table
alter table reports add column if not exists shift_id uuid;
alter table reports add column if not exists merged_with uuid[];
alter table reports add column if not exists is_merged boolean default false;

-- 2. Create shifts table
create table if not exists shifts (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  date date default current_date,
  started_at timestamptz default now(),
  ended_at timestamptz,
  is_active boolean default true,
  created_by text default 'מפעיל',
  notes text
);
alter table shifts enable row level security;
create policy "Allow all shifts" on shifts for all using (true);
grant all on shifts to anon;
grant all on shifts to authenticated;

-- 3. Update existing tables
alter table reports add column if not exists priority text default 'רגיל';
alter table reports add column if not exists assigned_unit text;
alter table reports add column if not exists status text default 'חדש';

-- 4. Comments table
create table if not exists report_comments (
  id uuid primary key default uuid_generate_v4(),
  report_id uuid references reports(id) on delete cascade,
  content text not null,
  created_by text default 'מפעיל',
  created_at timestamptz default now()
);
alter table report_comments enable row level security;
create policy "Allow all comments" on report_comments for all using (true);
grant all on report_comments to anon;
grant all on report_comments to authenticated;

-- 5. Event log table
create table if not exists event_log (
  id uuid primary key default uuid_generate_v4(),
  entry_type text default 'manual',
  content text not null,
  created_by text default 'מפעיל',
  related_report_id uuid references reports(id) on delete set null,
  shift_id uuid references shifts(id) on delete set null,
  created_at timestamptz default now()
);
alter table event_log enable row level security;
create policy "Allow all logs" on event_log for all using (true);
grant all on event_log to anon;
grant all on event_log to authenticated;

-- 6. Enable realtime
alter publication supabase_realtime add table shifts;
alter publication supabase_realtime add table report_comments;
alter publication supabase_realtime add table event_log;

-- 7. Fix existing statuses
update reports set status = 'חדש' where status = 'פתוח' or status is null;
update reports set status = 'הושלם' where status = 'סגור' or status = 'בטיפול';
update reports set priority = 'רגיל' where priority is null;
