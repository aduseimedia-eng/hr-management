-- ============================================================
-- HR Management System — Seed Data
-- Run AFTER schema.sql
-- Passwords are all: Password123! (bcrypt hashed)
-- ============================================================

-- Departments (no manager yet)
INSERT INTO departments (name) VALUES
  ('Engineering'),
  ('Human Resources'),
  ('Finance'),
  ('Marketing'),
  ('Operations');

-- Admin user (password: Password123!)
INSERT INTO employees (first_name, last_name, email, password_hash, role, department_id, job_title, salary, hire_date, date_of_birth, phone)
VALUES (
  'Ama', 'Owusu',
  'admin@company.com',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW',
  'admin', 2, 'HR Director', 8500.00, '2020-01-15', '1985-03-22', '+233201234567'
);

-- Manager
INSERT INTO employees (first_name, last_name, email, password_hash, role, department_id, manager_id, job_title, salary, hire_date, date_of_birth)
VALUES (
  'Kwame', 'Mensah',
  'kwame.mensah@company.com',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW',
  'manager', 1, 1, 'Engineering Manager', 7200.00, '2021-03-10', '1988-07-14'
);

-- Employees
INSERT INTO employees (first_name, last_name, email, password_hash, role, department_id, manager_id, job_title, salary, hire_date, date_of_birth)
VALUES
  ('Akosua', 'Boateng', 'akosua.boateng@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW', 'employee', 1, 2, 'Senior Developer', 5500.00, '2022-06-01', '1993-11-30'),
  ('Kofi', 'Asante', 'kofi.asante@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW', 'employee', 1, 2, 'Frontend Developer', 4800.00, '2023-01-15', '1996-05-18'),
  ('Abena', 'Frimpong', 'abena.frimpong@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW', 'employee', 3, 1, 'Finance Analyst', 4500.00, '2022-09-20', '1991-08-25'),
  ('Yaw', 'Darko', 'yaw.darko@company.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBaoEf/r.Gl6iW', 'employee', 4, 1, 'Marketing Lead', 4200.00, '2023-04-01', '1994-12-10');

-- Set department managers
UPDATE departments SET manager_id = 2 WHERE name = 'Engineering';
UPDATE departments SET manager_id = 1 WHERE name = 'Human Resources';

-- Attendance (last 7 days)
INSERT INTO attendance (employee_id, work_date, clock_in, clock_out, status) VALUES
  (1, CURRENT_DATE, NOW() - INTERVAL '7 hours', NULL, 'present'),
  (2, CURRENT_DATE, NOW() - INTERVAL '7.5 hours', NULL, 'present'),
  (3, CURRENT_DATE, NOW() - INTERVAL '6 hours', NULL, 'late'),
  (4, CURRENT_DATE, NULL, NULL, 'absent'),
  (5, CURRENT_DATE, NOW() - INTERVAL '8 hours', NULL, 'present'),
  (1, CURRENT_DATE - 1, NOW() - INTERVAL '31 hours', NOW() - INTERVAL '23 hours', 'present'),
  (2, CURRENT_DATE - 1, NOW() - INTERVAL '31.5 hours', NOW() - INTERVAL '23.5 hours', 'present'),
  (3, CURRENT_DATE - 1, NOW() - INTERVAL '30 hours', NOW() - INTERVAL '22 hours', 'present');

-- Leave requests
INSERT INTO leave_requests (employee_id, leave_type, start_date, end_date, reason, status, approved_by, approved_at) VALUES
  (3, 'annual', CURRENT_DATE + 7, CURRENT_DATE + 14, 'Family vacation', 'approved', 1, NOW()),
  (4, 'sick', CURRENT_DATE - 2, CURRENT_DATE - 1, 'Fever', 'approved', 1, NOW() - INTERVAL '2 days'),
  (5, 'annual', CURRENT_DATE + 30, CURRENT_DATE + 37, 'Holiday trip', 'pending', NULL, NULL);

-- Payroll (current month)
INSERT INTO payroll (employee_id, month, year, base_salary, allowances, deductions, status) VALUES
  (1, EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT, 8500, 500, 850, 'processed'),
  (2, EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT, 7200, 400, 720, 'processed'),
  (3, EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT, 5500, 300, 550, 'processed'),
  (4, EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT, 4800, 200, 480, 'pending'),
  (5, EXTRACT(MONTH FROM NOW())::INT, EXTRACT(YEAR FROM NOW())::INT, 4500, 200, 450, 'pending');

-- Notifications
INSERT INTO notifications (employee_id, type, message, is_read) VALUES
  (3, 'leave_approved', 'Your annual leave request has been approved.', false),
  (4, 'leave_approved', 'Your sick leave has been approved.', true),
  (1, 'birthday', 'Kofi Asante has a birthday coming up on May 18.', false),
  (2, 'payroll', 'Your payroll for this month has been processed.', false);

-- Announcement
INSERT INTO announcements (created_by, title, body, is_pinned) VALUES
  (1, 'Welcome to HRConnect!', 'We are excited to launch our new HR Management system. Please update your profiles and explore all features.', true),
  (1, 'Q2 Performance Reviews', 'Q2 performance reviews will begin next month. Managers, please prepare your review notes.', false);

-- Performance reviews
INSERT INTO performance_reviews (employee_id, reviewer_id, rating, comments, review_date, period) VALUES
  (3, 2, 5, 'Exceptional performance this quarter. Delivered the redesign project ahead of schedule.', CURRENT_DATE - 30, 'Q1 2025'),
  (4, 2, 4, 'Strong frontend skills, good collaboration. Could improve documentation.', CURRENT_DATE - 30, 'Q1 2025'),
  (5, 1, 4, 'Solid analytical skills, very reliable.', CURRENT_DATE - 30, 'Q1 2025');
