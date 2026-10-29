-- ============================================================================
-- SKEMA DATABASE SUPABASE (POSTGRESQL) & KEAMANAN RLS
-- APLIKASI SISTEM INFORMASI POIN PELANGGARAN SISWA (SIPPS) SMP NEGERI 71 BANDUNG
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. TABEL PENGATURAN SISTEM & MODE MAINTENANCE
CREATE TABLE IF NOT EXISTS public.sipps_settings (
  id int8 PRIMARY KEY DEFAULT 1,
  app_name text NOT NULL DEFAULT 'SIPPS SMP Negeri 71 Bandung',
  school_name text NOT NULL DEFAULT 'SMP Negeri 71 Bandung',
  school_address text DEFAULT 'Jl. Pendidikan Raya No. 71, Kota Bandung, Jawa Barat 40111 • Telp. (022) 7100071',
  kepsek_name text DEFAULT 'Drs. H. Ahmad Suryana, M.Pd.',
  kepsek_nip text DEFAULT '19680512 199403 1 005',
  logo_url text DEFAULT '',
  bg_url text DEFAULT '',
  kop_surat_url text DEFAULT '',
  canvas_opacity numeric DEFAULT 0.88,
  is_maintenance boolean NOT NULL DEFAULT false,
  maintenance_message text DEFAULT 'Sistem Sedang Diperbaiki. Kami sedang melakukan pemeliharaan berkala dan sinkronisasi data.',
  updated_at timestamptz DEFAULT now()
);

INSERT INTO public.sipps_settings (id, app_name, school_name, is_maintenance)
VALUES (1, 'SIPPS SMP Negeri 71 Bandung', 'SMP Negeri 71 Bandung', false)
ON CONFLICT (id) DO NOTHING;

-- 2. TABEL AKUN PETUGAS / GURU BK (LOGIN NON-ADMIN HYBRID)
CREATE TABLE IF NOT EXISTS public.sipps_staff (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nip text UNIQUE NOT NULL,
  nama text NOT NULL,
  username text UNIQUE NOT NULL,
  password text NOT NULL,
  role text NOT NULL DEFAULT 'bk',
  jabatan text DEFAULT 'Guru BK',
  created_at timestamptz DEFAULT now()
);

-- 3. TABEL MASTER IDENTITAS SISWA & AKSES WALI MURID / SISWA
CREATE TABLE IF NOT EXISTS public.sipps_siswa (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nisn text UNIQUE NOT NULL,
  nis text,
  nama_siswa text NOT NULL,
  kelas text NOT NULL,
  jenis_kelamin text DEFAULT 'L',
  nama_wali text,
  no_hp_wali text,
  password_siswa text NOT NULL DEFAULT 'siswa123',
  password_wali text NOT NULL DEFAULT 'wali123',
  total_poin int4 NOT NULL DEFAULT 0,
  status_pembinaan text DEFAULT 'Aman / Disiplin Baik',
  created_at timestamptz DEFAULT now()
);

-- 4. TABEL KATALOG ATURAN & BUKU SAKU TATA TERTIB
CREATE TABLE IF NOT EXISTS public.sipps_aturan (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kode_aturan text UNIQUE NOT NULL,
  kategori text NOT NULL DEFAULT 'Ringan',
  nama_pelanggaran text NOT NULL,
  poin int4 NOT NULL DEFAULT 10,
  sanksi_tindak_lanjut text,
  created_at timestamptz DEFAULT now()
);

-- 5. TABEL POIN & RIWAYAT PELANGGARAN SISWA
CREATE TABLE IF NOT EXISTS public.sipps_pelanggaran (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tanggal date NOT NULL DEFAULT CURRENT_DATE,
  siswa_id uuid REFERENCES public.sipps_siswa(id) ON DELETE CASCADE,
  nisn text NOT NULL,
  nama_siswa text NOT NULL,
  kelas text NOT NULL,
  aturan_id uuid REFERENCES public.sipps_aturan(id) ON DELETE SET NULL,
  kode_aturan text,
  nama_pelanggaran text NOT NULL,
  kategori text DEFAULT 'Ringan',
  poin int4 NOT NULL DEFAULT 0,
  pelapor text,
  catatan_tindak_lanjut text,
  status_penanganan text DEFAULT 'Tercatat',
  created_at timestamptz DEFAULT now()
);

-- 6. TABEL PESAN & NOTIFIKASI REAL-TIME (DENGAN FILTER KELAS & NAMA)
CREATE TABLE IF NOT EXISTS public.sipps_notifikasi (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  judul text NOT NULL,
  isi_pesan text NOT NULL,
  tipe text DEFAULT 'Pengumuman',
  target_role text DEFAULT 'Semua',
  target_kelas text DEFAULT 'Semua Kelas',
  target_nisn text DEFAULT '',
  target_nama text DEFAULT '',
  pengirim text DEFAULT 'Administrator',
  is_read boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ============================================================================
-- TRIGGER OTOMATIS HITUNG AKUMULASI POIN & STATUS PEMBINAAN SISWA
-- ============================================================================
CREATE OR REPLACE FUNCTION public.fn_recalculate_poin_siswa()
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

  IF v_total >= 75 THEN
    v_status := 'Panggilan Orang Tua / Skorsing';
  ELSIF v_total >= 50 THEN
    v_status := 'Peringatan BK II';
  ELSIF v_total >= 30 THEN
    v_status := 'Peringatan BK I';
  ELSIF v_total >= 10 THEN
    v_status := 'Pembinaan Wali Kelas';
  ELSE
    v_status := 'Aman / Disiplin Baik';
  END IF;

  UPDATE public.sipps_siswa
  SET total_poin = v_total,
      status_pembinaan = v_status
  WHERE nisn = v_nisn;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_recalculate_poin_siswa ON public.sipps_pelanggaran;
CREATE TRIGGER trg_recalculate_poin_siswa
AFTER INSERT OR UPDATE OR DELETE ON public.sipps_pelanggaran
FOR EACH ROW EXECUTE FUNCTION public.fn_recalculate_poin_siswa();

-- ============================================================================
-- KONFIGURASI ROW LEVEL SECURITY (RLS) UNTUK ARSITEKTUR HYBRID LOGIN
-- Mengizinkan role `authenticated` (Admin via Supabase Auth) dan `anon`
-- (Guru BK, Wali Murid, Siswa yang divalidasi via Tabel Database) beroperasi
-- tanpa kendala permission denied.
-- ============================================================================
ALTER TABLE public.sipps_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sipps_staff ENABLE ROW LEVEL SECURITY;
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

-- AKTIFKAN SUPABASE REALTIME UNTUK SINKRONISASI LANGSUNG
ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_siswa;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_aturan;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_pelanggaran;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sipps_notifikasi;