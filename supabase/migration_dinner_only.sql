-- Kör denna EN GÅNG i Supabase SQL Editor för en befintlig Veckomat-databas.
alter table public.meal_plans add column if not exists custom_text text;
