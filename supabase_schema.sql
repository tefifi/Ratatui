-- ============================================================
--  LINWINI — Schema Supabase
--  Ejecutar en el SQL Editor de Supabase
-- ============================================================

create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  nombre     text not null,
  peso_kg    numeric(5,2),
  altura_cm  numeric(5,2),
  imc        numeric(5,2) generated always as (
               peso_kg / ((altura_cm / 100.0) * (altura_cm / 100.0))
             ) stored,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table public.padecimientos (
  id     serial primary key,
  nombre text not null unique,
  label  text not null
);

create table public.usuario_padecimientos (
  usuario_id      uuid references public.profiles(id) on delete cascade,
  padecimiento_id int  references public.padecimientos(id) on delete cascade,
  primary key (usuario_id, padecimiento_id)
);

create table public.favoritos (
  id             serial primary key,
  usuario_id     uuid references public.profiles(id) on delete cascade,
  spoonacular_id int  not null,
  nombre_receta  text,
  imagen_url     text,
  kcal           numeric(6,1),
  proteina_g     numeric(5,1),
  fibra_g        numeric(5,1),
  created_at     timestamptz default now(),
  unique (usuario_id, spoonacular_id)
);

-- RLS
alter table public.profiles              enable row level security;
alter table public.usuario_padecimientos enable row level security;
alter table public.favoritos             enable row level security;
alter table public.padecimientos         enable row level security;

create policy "owner only" on public.profiles
  using (auth.uid() = id) with check (auth.uid() = id);

create policy "owner only" on public.usuario_padecimientos
  using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

create policy "owner only" on public.favoritos
  using (auth.uid() = usuario_id) with check (auth.uid() = usuario_id);

create policy "public read" on public.padecimientos
  for select using (true);

-- Trigger updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.handle_updated_at();

-- Trigger crear perfil al registrarse
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nombre)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'nombre', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Datos iniciales
insert into public.padecimientos (nombre, label) values
  ('diabetes_tipo2',      'Diabetes tipo 2'),
  ('hipertension',        'Hipertensión'),
  ('intolerante_lactosa', 'Intolerante a la lactosa'),
  ('vegano',              'Vegano'),
  ('vegetariano',         'Vegetariano'),
  ('celiaco',             'Celíaco'),
  ('hipotiroidismo',      'Hipotiroidismo');
