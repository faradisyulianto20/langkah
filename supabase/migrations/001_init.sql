-- Langkah: skema awal (sumber: docs/erd.md). Jalankan sekali di Supabase SQL Editor.

-- ENUM
DO $$ BEGIN
  CREATE TYPE goal_status AS ENUM ('pending', 'in_progress', 'completed');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  CREATE TYPE task_priority AS ENUM ('low', 'medium', 'high');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- TABEL
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT username_min_length CHECK (char_length(username) >= 3)
);

CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    color_hex TEXT NOT NULL DEFAULT '#00897B',
    icon TEXT DEFAULT 'tag',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_category_per_user UNIQUE(user_id, name)
);

CREATE TABLE IF NOT EXISTS public.monthly_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    target_month DATE NOT NULL,
    status goal_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.weekly_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    monthly_goal_id UUID REFERENCES public.monthly_goals(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    target_week INT NOT NULL CHECK (target_week BETWEEN 1 AND 53),
    target_year INT NOT NULL,
    status goal_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.daily_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weekly_target_id UUID REFERENCES public.weekly_targets(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    scheduled_date DATE NOT NULL DEFAULT CURRENT_DATE,
    priority task_priority NOT NULL DEFAULT 'medium',
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.backlog_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.user_stats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    current_streak INT NOT NULL DEFAULT 0,
    longest_streak INT NOT NULL DEFAULT 0,
    total_completed_steps INT NOT NULL DEFAULT 0,
    last_active_date DATE,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- INDEKS
CREATE INDEX IF NOT EXISTS idx_categories_user ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_monthly_goals_user_date ON public.monthly_goals(user_id, target_month);
CREATE INDEX IF NOT EXISTS idx_weekly_targets_user ON public.weekly_targets(user_id, target_year, target_week);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_date ON public.daily_tasks(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_completion ON public.daily_tasks(user_id, is_completed);
CREATE INDEX IF NOT EXISTS idx_backlog_items_user ON public.backlog_items(user_id);

-- TRIGGER: auto-provision saat sign up
-- Username dibuat aman: minimal 3 karakter & unik (ditambah 4 karakter id bila perlu).
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    base_name TEXT;
    final_name TEXT;
BEGIN
    base_name := COALESCE(
        NULLIF(new.raw_user_meta_data->>'username', ''),
        split_part(new.email, '@', 1)
    );
    IF char_length(base_name) < 3 THEN
        base_name := base_name || 'user';
    END IF;
    final_name := base_name;
    IF EXISTS (SELECT 1 FROM public.profiles WHERE username = final_name) THEN
        final_name := base_name || '_' || substr(replace(new.id::text, '-', ''), 1, 4);
    END IF;

    INSERT INTO public.profiles (id, username, full_name, avatar_url)
    VALUES (
        new.id,
        final_name,
        new.raw_user_meta_data->>'full_name',
        new.raw_user_meta_data->>'avatar_url'
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.user_stats (user_id) VALUES (new.id)
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.categories (user_id, name, color_hex, icon) VALUES
        (new.id, 'Coding', '#00897B', 'code'),
        (new.id, 'Fitness', '#FB8C00', 'fitness_center'),
        (new.id, 'Habit', '#1E88E5', 'alarm_on'),
        (new.id, 'Learning', '#8E24AA', 'book')
    ON CONFLICT (user_id, name) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backlog_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can all on own categories" ON public.categories;
CREATE POLICY "Users can all on own categories" ON public.categories FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can all on own monthly_goals" ON public.monthly_goals;
CREATE POLICY "Users can all on own monthly_goals" ON public.monthly_goals FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can all on own weekly_targets" ON public.weekly_targets;
CREATE POLICY "Users can all on own weekly_targets" ON public.weekly_targets FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can all on own daily_tasks" ON public.daily_tasks;
CREATE POLICY "Users can all on own daily_tasks" ON public.daily_tasks FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can all on own backlog_items" ON public.backlog_items;
CREATE POLICY "Users can all on own backlog_items" ON public.backlog_items FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can insert own stats" ON public.user_stats;
DROP POLICY IF EXISTS "Users can update own stats" ON public.user_stats;
CREATE POLICY "Users can view own stats" ON public.user_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own stats" ON public.user_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own stats" ON public.user_stats FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- BACKFILL: user yang sudah terdaftar sebelum trigger ada
INSERT INTO public.profiles (id, username)
SELECT u.id,
       CASE WHEN char_length(split_part(u.email,'@',1)) < 3
            THEN split_part(u.email,'@',1) || 'user'
            ELSE split_part(u.email,'@',1) END
         || '_' || substr(replace(u.id::text,'-',''),1,4)
FROM auth.users u
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_stats (user_id)
SELECT id FROM auth.users ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.categories (user_id, name, color_hex, icon)
SELECT u.id, c.name, c.color_hex, c.icon
FROM auth.users u
CROSS JOIN (VALUES
    ('Coding', '#00897B', 'code'),
    ('Fitness', '#FB8C00', 'fitness_center'),
    ('Habit', '#1E88E5', 'alarm_on'),
    ('Learning', '#8E24AA', 'book')
) AS c(name, color_hex, icon)
ON CONFLICT (user_id, name) DO NOTHING;

-- Refresh schema cache PostgREST (menghilangkan error PGRST205)
NOTIFY pgrst, 'reload schema';
