-- ============================================================
-- HR Management System — PostgreSQL Schema
-- ============================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── DEPARTMENTS ─────────────────────────────────────────────
CREATE TABLE departments (
  id          SERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL UNIQUE,
  manager_id  INT,          -- set FK after employees table
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── EMPLOYEES ───────────────────────────────────────────────
CREATE TABLE employees (
  id             SERIAL PRIMARY KEY,
  first_name     VARCHAR(80)  NOT NULL,
  last_name      VARCHAR(80)  NOT NULL,
  email          VARCHAR(150) NOT NULL UNIQUE,
  password_hash  TEXT         NOT NULL,
  role           VARCHAR(20)  NOT NULL DEFAULT 'employee'
                   CHECK (role IN ('admin','manager','employee')),
  department_id  INT REFERENCES departments(id) ON DELETE SET NULL,
  manager_id     INT REFERENCES employees(id)   ON DELETE SET NULL,
  job_title      VARCHAR(120),
  salary         NUMERIC(12,2) DEFAULT 0,
  hire_date      DATE,
  phone          VARCHAR(30),
  address        TEXT,
  date_of_birth  DATE,
  photo_url      VARCHAR(300),
  is_active      BOOLEAN DEFAULT TRUE,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Back-fill the FK now that employees exists
ALTER TABLE departments
  ADD CONSTRAINT fk_dept_manager
  FOREIGN KEY (manager_id) REFERENCES employees(id) ON DELETE SET NULL;

-- ─── ATTENDANCE ──────────────────────────────────────────────
CREATE TABLE attendance (
  id           SERIAL PRIMARY KEY,
  employee_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  work_date    DATE NOT NULL,
  clock_in     TIMESTAMPTZ,
  clock_out    TIMESTAMPTZ,
  status       VARCHAR(20) DEFAULT 'present'
                 CHECK (status IN ('present','absent','late','half-day','on-leave')),
  notes        TEXT,
  UNIQUE (employee_id, work_date)
);

-- ─── LEAVE REQUESTS ──────────────────────────────────────────
CREATE TABLE leave_requests (
  id           SERIAL PRIMARY KEY,
  employee_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  approved_by  INT REFERENCES employees(id) ON DELETE SET NULL,
  leave_type   VARCHAR(40) NOT NULL
                 CHECK (leave_type IN ('annual','sick','maternity','paternity','unpaid','other')),
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  reason       TEXT,
  status       VARCHAR(20) DEFAULT 'pending'
                 CHECK (status IN ('pending','approved','rejected','cancelled')),
  approved_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PAYROLL ─────────────────────────────────────────────────
CREATE TABLE payroll (
  id            SERIAL PRIMARY KEY,
  employee_id   INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  month         SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year          SMALLINT NOT NULL,
  base_salary   NUMERIC(12,2) NOT NULL,
  allowances    NUMERIC(12,2) DEFAULT 0,
  deductions    NUMERIC(12,2) DEFAULT 0,
  net_salary    NUMERIC(12,2) GENERATED ALWAYS AS (base_salary + allowances - deductions) STORED,
  status        VARCHAR(20) DEFAULT 'pending'
                  CHECK (status IN ('pending','processed','paid')),
  paid_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (employee_id, month, year)
);

-- ─── DOCUMENTS ───────────────────────────────────────────────
CREATE TABLE documents (
  id            SERIAL PRIMARY KEY,
  employee_id   INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  doc_type      VARCHAR(60) NOT NULL
                  CHECK (doc_type IN ('contract','certificate','id','offer_letter','other')),
  file_path     VARCHAR(400) NOT NULL,
  original_name VARCHAR(200) NOT NULL,
  file_size     INT,
  uploaded_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── PERFORMANCE REVIEWS ─────────────────────────────────────
CREATE TABLE performance_reviews (
  id           SERIAL PRIMARY KEY,
  employee_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  reviewer_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  rating       SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comments     TEXT,
  review_date  DATE NOT NULL DEFAULT CURRENT_DATE,
  period       VARCHAR(40),   -- e.g. "Q1 2025"
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── NOTIFICATIONS ───────────────────────────────────────────
CREATE TABLE notifications (
  id           SERIAL PRIMARY KEY,
  employee_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  type         VARCHAR(50) NOT NULL,
  message      TEXT NOT NULL,
  link         VARCHAR(300),
  is_read      BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ─── ANNOUNCEMENTS ───────────────────────────────────────────
CREATE TABLE announcements (
  id          SERIAL PRIMARY KEY,
  created_by  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  title       VARCHAR(200) NOT NULL,
  body        TEXT NOT NULL,
  is_pinned   BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── MESSAGES ────────────────────────────────────────────────
CREATE TABLE messages (
  id           SERIAL PRIMARY KEY,
  sender_id    INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  receiver_id  INT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  body         TEXT NOT NULL,
  is_read      BOOLEAN DEFAULT FALSE,
  sent_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ─── INDEXES ─────────────────────────────────────────────────
CREATE INDEX idx_attendance_employee   ON attendance(employee_id);
CREATE INDEX idx_attendance_date       ON attendance(work_date);
CREATE INDEX idx_leave_employee        ON leave_requests(employee_id);
CREATE INDEX idx_leave_status          ON leave_requests(status);
CREATE INDEX idx_payroll_employee      ON payroll(employee_id);
CREATE INDEX idx_notifications_emp     ON notifications(employee_id, is_read);
CREATE INDEX idx_messages_receiver     ON messages(receiver_id, is_read);
CREATE INDEX idx_employees_department  ON employees(department_id);

-- ─── TRIGGER: auto-update updated_at ─────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_employees_updated_at
  BEFORE UPDATE ON employees
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
