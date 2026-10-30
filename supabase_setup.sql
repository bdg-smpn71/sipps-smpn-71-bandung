-- ============================================================================
-- SKEMA DATABASE SUPABASE (POSTGRESQL), TRIGGER OTOMATIS & KEAMANAN RLS TERBARU
-- APLIKASI SISTEM INFORMASI POIN PELANGGARAN SISWA (SIPPS) SMP NEGERI 71 BANDUNG
-- Mendukung Penuh: Supabase Publishable Key (sb_publishable_...) & Anon Key
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. TABEL PENGATURAN SISTEM, VISUAL, FOTO PROFIL ADMIN & MODE MAINTENANCE
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_settings (
  id int8 PRIMARY KEY DEFAULT 1,
  app_name text NOT NULL DEFAULT 'SIPPS SMPN 71 Bandung',
  school_name text NOT NULL DEFAULT 'SMP Negeri 71 Bandung',
  school_address text DEFAULT 'Jl. Manglayang 1 No.1, Pasir Biru, Kec. Cibiru, Kota Bandung, Jawa Barat 40615',
  kepsek_name text DEFAULT 'Nur''aeni Puspitasari, S.S., M.Ak.',
  kepsek_nip text DEFAULT '198202102009022004',
  logo_url text DEFAULT '',
  bg_url text DEFAULT '',
  kop_surat_url text DEFAULT '',
  admin_avatar_url text DEFAULT '',
  canvas_opacity numeric DEFAULT 0.88,
  is_maintenance boolean NOT NULL DEFAULT false,
  maintenance_message text DEFAULT 'Mohon maaf atas ketidaknyamanan ini, kami sedang melakukan peningkatan layanan untuk Anda.',
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS school_address text DEFAULT 'Jl. Manglayang 1 No.1, Pasir Biru, Kec. Cibiru, Kota Bandung, Jawa Barat 40615';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS kepsek_name text DEFAULT 'Nur''aeni Puspitasari, S.S., M.Ak.';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS kepsek_nip text DEFAULT '198202102009022004';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS logo_url text DEFAULT '';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS bg_url text DEFAULT '';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS kop_surat_url text DEFAULT '';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS admin_avatar_url text DEFAULT '';
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS canvas_opacity numeric DEFAULT 0.88;
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS is_maintenance boolean NOT NULL DEFAULT false;
ALTER TABLE public.sipps_settings ADD COLUMN IF NOT EXISTS maintenance_message text DEFAULT 'Mohon maaf atas ketidaknyamanan ini, kami sedang melakukan peningkatan layanan untuk Anda.';

INSERT INTO public.sipps_settings (
  id, app_name, school_name, school_address, kepsek_name, kepsek_nip, canvas_opacity, is_maintenance, maintenance_message
)
VALUES (
  1,
  'SIPPS SMPN 71 Bandung',
  'SMP Negeri 71 Bandung',
  'Jl. Manglayang 1 No.1, Pasir Biru, Kec. Cibiru, Kota Bandung, Jawa Barat 40615',
  'Nur''aeni Puspitasari, S.S., M.Ak.',
  '198202102009022004',
  0.88,
  false,
  'Mohon maaf atas ketidaknyamanan ini, kami sedang melakukan peningkatan layanan untuk Anda.'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 2. TABEL AKUN PETUGAS / GURU BK (LOGIN HYBRID & PENGATURAN PROFIL BK)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_staff (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  nip text UNIQUE NOT NULL,
  nama text NOT NULL,
  username text UNIQUE NOT NULL,
  password text NOT NULL DEFAULT 'bk123',
  role text NOT NULL DEFAULT 'bk',
  jabatan text DEFAULT 'Guru BK',
  avatar_url text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_staff ADD COLUMN IF NOT EXISTS jabatan text DEFAULT 'Guru BK';
ALTER TABLE public.sipps_staff ADD COLUMN IF NOT EXISTS avatar_url text DEFAULT '';

-- ============================================================================
-- 3. TABEL MASTER DATA KELAS (SINKRONISASI ROMBONGAN BELAJAR & WALI KELAS)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_kelas (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  kode_kelas text UNIQUE NOT NULL,
  nama_kelas text NOT NULL,
  tingkat text NOT NULL DEFAULT 'VII',
  wali_kelas text DEFAULT '',
  nip_wali_kelas text DEFAULT '',
  kapasitas int4 DEFAULT 36,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_kelas ADD COLUMN IF NOT EXISTS wali_kelas text DEFAULT '';
ALTER TABLE public.sipps_kelas ADD COLUMN IF NOT EXISTS nip_wali_kelas text DEFAULT '';
ALTER TABLE public.sipps_kelas ADD COLUMN IF NOT EXISTS kapasitas int4 DEFAULT 36;

-- ============================================================================
-- 4. TABEL MASTER IDENTITAS SISWA (HANYA NISN) & AKSES LOGIN SISWA / WALI
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_siswa (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  nisn text UNIQUE NOT NULL,
  nama_siswa text NOT NULL,
  kelas text NOT NULL,
  jenis_kelamin text DEFAULT 'L',
  nama_wali text DEFAULT '-',
  no_hp_wali text DEFAULT '-',
  password_siswa text NOT NULL DEFAULT 'siswa123',
  password_wali text NOT NULL DEFAULT 'wali123',
  avatar_url text DEFAULT '',
  total_poin int4 NOT NULL DEFAULT 0,
  status_pembinaan text DEFAULT 'Aman / Disiplin Baik',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_siswa DROP COLUMN IF EXISTS nis;
ALTER TABLE public.sipps_siswa ADD COLUMN IF NOT EXISTS avatar_url text DEFAULT '';
ALTER TABLE public.sipps_siswa ADD COLUMN IF NOT EXISTS password_siswa text NOT NULL DEFAULT 'siswa123';
ALTER TABLE public.sipps_siswa ADD COLUMN IF NOT EXISTS password_wali text NOT NULL DEFAULT 'wali123';
ALTER TABLE public.sipps_siswa ADD COLUMN IF NOT EXISTS total_poin int4 NOT NULL DEFAULT 0;
ALTER TABLE public.sipps_siswa ADD COLUMN IF NOT EXISTS status_pembinaan text DEFAULT 'Aman / Disiplin Baik';

-- ============================================================================
-- 5. TABEL KATALOG ATURAN & BUKU SAKU TATA TERTIB
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_aturan (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  kode_aturan text UNIQUE NOT NULL,
  kategori text NOT NULL DEFAULT 'Ringan',
  nama_pelanggaran text NOT NULL,
  poin int4 NOT NULL DEFAULT 5,
  sanksi_tindak_lanjut text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- 6. TABEL POIN & RIWAYAT PELANGGARAN SISWA (DENGAN FILTER KELAS & SISWA)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_pelanggaran (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  tanggal date NOT NULL DEFAULT CURRENT_DATE,
  siswa_id text,
  nisn text NOT NULL,
  nama_siswa text NOT NULL,
  kelas text NOT NULL,
  aturan_id text,
  kode_aturan text DEFAULT 'R-01',
  nama_pelanggaran text NOT NULL,
  kategori text DEFAULT 'Ringan',
  poin int4 NOT NULL DEFAULT 5,
  pelapor text DEFAULT 'Guru BK',
  catatan_tindak_lanjut text DEFAULT '',
  status_penanganan text DEFAULT 'Tercatat',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_pelanggaran ADD COLUMN IF NOT EXISTS kode_aturan text DEFAULT 'R-01';
ALTER TABLE public.sipps_pelanggaran ADD COLUMN IF NOT EXISTS kategori text DEFAULT 'Ringan';
ALTER TABLE public.sipps_pelanggaran ADD COLUMN IF NOT EXISTS pelapor text DEFAULT 'Guru BK';
ALTER TABLE public.sipps_pelanggaran ADD COLUMN IF NOT EXISTS catatan_tindak_lanjut text DEFAULT '';
ALTER TABLE public.sipps_pelanggaran ADD COLUMN IF NOT EXISTS status_penanganan text DEFAULT 'Tercatat';

-- ============================================================================
-- 7. TABEL LIVE CHATTING PESAN & NOTIFIKASI REAL-TIME
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.sipps_notifikasi (
  id text PRIMARY KEY DEFAULT (gen_random_uuid())::text,
  judul text NOT NULL,
  isi_pesan text NOT NULL,
  tipe text DEFAULT 'Pengumuman Chat',
  target_role text DEFAULT 'Semua',
  target_kelas text DEFAULT 'Semua Kelas',
  target_nisn text DEFAULT '',
  target_nama text DEFAULT '',
  pengirim text DEFAULT 'Administrator',
  pengirim_role text DEFAULT 'admin',
  pengirim_id text DEFAULT '',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.sipps_notifikasi ADD COLUMN IF NOT EXISTS pengirim_role text DEFAULT 'admin';
ALTER TABLE public.sipps_notifikasi ADD COLUMN IF NOT EXISTS pengirim_id text DEFAULT '';
ALTER TABLE public.sipps_notifikasi ADD COLUMN IF NOT EXISTS target_nisn text DEFAULT '';
ALTER TABLE public.sipps_notifikasi ADD COLUMN IF NOT EXISTS target_nama text DEFAULT '';

-- ============================================================================
-- MIGRASI AMAN KOLOM ID KE TEXT (AGAR KOMPATIBEL DENGAN UUID & IMPORT EXCEL)
-- ============================================================================
DO $$
BEGIN
  ALTER TABLE public.sipps_pelanggaran DROP CONSTRAINT IF EXISTS sipps_pelanggaran_siswa_id_fkey;
  ALTER TABLE public.sipps_pelanggaran DROP CONSTRAINT IF EXISTS sipps_pelanggaran_aturan_id_fkey;

  ALTER TABLE public.sipps_staff ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_staff ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;

  ALTER TABLE public.sipps_kelas ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_kelas ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;

  ALTER TABLE public.sipps_siswa ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_siswa ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;

  ALTER TABLE public.sipps_aturan ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_aturan ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;

  ALTER TABLE public.sipps_pelanggaran ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_pelanggaran ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;
  ALTER TABLE public.sipps_pelanggaran ALTER COLUMN siswa_id TYPE text USING siswa_id::text;
  ALTER TABLE public.sipps_pelanggaran ALTER COLUMN aturan_id TYPE text USING aturan_id::text;

  ALTER TABLE public.sipps_notifikasi ALTER COLUMN id TYPE text USING id::text;
  ALTER TABLE public.sipps_notifikasi ALTER COLUMN id SET DEFAULT (gen_random_uuid())::text;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- ============================================================================
-- TRIGGER OTOMATIS SINKRONISASI TOTAL POIN & STATUS PEMBINAAN SISWA
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_recalc_poin_siswa()
RETURNS TRIGGER AS $$
DECLARE
  v_nisn text;
  v_total int4;
  v_status text;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_nisn := OLD.nisn;
  ELSE
    v_nisn := NEW.nisn;
  END IF;

  SELECT COALESCE(SUM(poin), 0) INTO v_total
  FROM public.sipps_pelanggaran
  WHERE nisn = v_nisn;

  IF v_total > 40 THEN
    v_status := 'Panggilan Orang Tua';
  ELSIF v_total > 20 THEN
    v_status := 'Peringatan Sedang';
  ELSIF v_total > 0 THEN
    v_status := 'Peringatan Ringan';
  ELSE
    v_status := 'Aman / Disiplin Baik';
  END IF;

  UPDATE public.sipps_siswa
  SET total_poin = v_total,
      status_pembinaan = v_status
  WHERE nisn = v_nisn;

  IF (TG_OP = 'UPDATE' AND OLD.nisn IS DISTINCT FROM NEW.nisn) THEN
    SELECT COALESCE(SUM(poin), 0) INTO v_total
    FROM public.sipps_pelanggaran
    WHERE nisn = OLD.nisn;

    IF v_total > 40 THEN
      v_status := 'Panggilan Orang Tua';
    ELSIF v_total > 20 THEN
      v_status := 'Peringatan Sedang';
    ELSIF v_total > 0 THEN
      v_status := 'Peringatan Ringan';
    ELSE
      v_status := 'Aman / Disiplin Baik';
    END IF;

    UPDATE public.sipps_siswa
    SET total_poin = v_total,
        status_pembinaan = v_status
    WHERE nisn = OLD.nisn;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_poin_siswa ON public.sipps_pelanggaran;
CREATE TRIGGER trg_sync_poin_siswa
AFTER INSERT OR UPDATE OR DELETE ON public.sipps_pelanggaran
FOR EACH ROW EXECUTE FUNCTION public.fn_recalc_poin_siswa();

-- ============================================================================
-- INDEXING DATABASE UNTUK PERFORMA MAKSIMAL, CEPAT & BEBAS LAG
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_sipps_siswa_kelas ON public.sipps_siswa(kelas);
CREATE INDEX IF NOT EXISTS idx_sipps_siswa_nisn ON public.sipps_siswa(nisn);
CREATE INDEX IF NOT EXISTS idx_sipps_kelas_kode ON public.sipps_kelas(kode_kelas);
CREATE INDEX IF NOT EXISTS idx_sipps_staff_username ON public.sipps_staff(username);
CREATE INDEX IF NOT EXISTS idx_sipps_pelanggaran_nisn ON public.sipps_pelanggaran(nisn);
CREATE INDEX IF NOT EXISTS idx_sipps_pelanggaran_kelas ON public.sipps_pelanggaran(kelas);
CREATE INDEX IF NOT EXISTS idx_sipps_pelanggaran_tanggal ON public.sipps_pelanggaran(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_sipps_notifikasi_target ON public.sipps_notifikasi(target_kelas, target_nisn);
CREATE INDEX IF NOT EXISTS idx_sipps_notifikasi_created ON public.sipps_notifikasi(created_at DESC);

-- ============================================================================
-- HAK AKSES TABEL & ROW LEVEL SECURITY (RLS) UNTUK HYBRID LOGIN & PUBLISHABLE KEY
-- ============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

ALTER TABLE public.sipps_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_kelas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_siswa ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_aturan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_pelanggaran ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_notifikasi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Hybrid Access sipps_settings" ON public.sipps_settings;
CREATE POLICY "Hybrid Access sipps_settings" ON public.sipps_settings
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_staff" ON public.sipps_staff;
CREATE POLICY "Hybrid Access sipps_staff" ON public.sipps_staff
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_kelas" ON public.sipps_kelas;
CREATE POLICY "Hybrid Access sipps_kelas" ON public.sipps_kelas
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_siswa" ON public.sipps_siswa;
CREATE POLICY "Hybrid Access sipps_siswa" ON public.sipps_siswa
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_aturan" ON public.sipps_aturan;
CREATE POLICY "Hybrid Access sipps_aturan" ON public.sipps_aturan
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_pelanggaran" ON public.sipps_pelanggaran;
CREATE POLICY "Hybrid Access sipps_pelanggaran" ON public.sipps_pelanggaran
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Hybrid Access sipps_notifikasi" ON public.sipps_notifikasi;
CREATE POLICY "Hybrid Access sipps_notifikasi" ON public.sipps_notifikasi
FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);

-- ============================================================================
-- DATA AWAL DEFAULT: AKUN ADMIN, GURU BK & MASTER KELAS SMP NEGERI 71 BANDUNG
-- ============================================================================
INSERT INTO public.sipps_staff (nip, nama, username, password, role, jabatan)
VALUES
  ('198001012005011001', 'admin', 'admin@smpn71.sch.id', 'admin123', 'admin', 'Administrator Sistem'),
  ('199805032025212115', 'Aimi Kulsum, S.Hum., Gr', '199805032025212115', 'bk123', 'bk', 'Koordinator Guru BK'),
  ('199405052023212024', 'Nisa Anisa Respati, S.Pd., Gr', '199405052023212024', 'wakasek123', 'bk', 'Wakasek Kesiswaan')
ON CONFLICT (nip) DO UPDATE SET
  nama = EXCLUDED.nama,
  jabatan = EXCLUDED.jabatan;

INSERT INTO public.sipps_kelas (kode_kelas, nama_kelas, tingkat, wali_kelas, nip_wali_kelas, kapasitas)
VALUES
  ('IX-A', '9A', 'IX', 'Dippa Restu Putra Utama, S.Pd., Gr', '199801212024211001', 33),
  ('IX-B', '9B', 'IX', 'Eva Devalusiana, S.Pd., Gr', '198304052023212020', 33),
  ('IX-C', '9C', 'IX', 'Nisa Anisa Respati, S.Pd., Gr', '199405052023212024', 33),
  ('VII-A', '7A', 'VII', 'Yeni Febrianti, S.Pd., Gr', '4550770671230292', 34),
  ('VII-B', '7B', 'VII', 'Febby Febrianti, S.Pd., Gr', '1547777678230092', 34),
  ('VII-C', '7C', 'VII', 'Aimi Kulsum, S.Hum., Gr', '199805032025212115', 34),
  ('VII-D', '7D', 'VII', 'Yandi Imanudin, S.Pd', '197201302024211001', 34),
  ('VIII-A', '8A', 'VIII', 'Intan Permatasari, S.Pd., Gr', '199406102024212005', 36)
ON CONFLICT (kode_kelas) DO NOTHING;

-- ============================================================================
-- AKTIFKAN SUPABASE REALTIME SECARA AMAN PADA SELURUH TABEL SIPPS
-- ============================================================================
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_settings;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_staff;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_kelas;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_siswa;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_aturan;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_pelanggaran;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_notifikasi;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
