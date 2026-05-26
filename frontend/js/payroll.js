const user = requireAuth();
if (!user) throw new Error('redirect');
buildSidebar('payroll');
loadNotifCount();

const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const now = new Date();

if (user.role === 'admin') {
  document.getElementById('admin-tab').style.display = '';
  document.getElementById('summary-tab').style.display = '';

  document.getElementById('admin-payroll-actions').innerHTML =
    `<button class="btn btn-primary" onclick="showProcessModal()">Process Payroll</button>`;

  const mSel = document.getElementById('pr-month');
  const ySel = document.getElementById('pr-year');
  months.forEach((m, i) => mSel.innerHTML += `<option value="${i+1}" ${i===now.getMonth()?'selected':''}>${m}</option>`);
  for (let y = now.getFullYear(); y >= now.getFullYear()-3; y--) {
    ySel.innerHTML += `<option value="${y}" ${y===now.getFullYear()?'selected':''}>${y}</option>`;
  }
}

function switchTab(tab) {
  ['mine','all','summary'].forEach(t => document.getElementById(`tab-${t}`).style.display = t===tab?'':'none');
  document.querySelectorAll('.tab-btn').forEach((b,i) => b.classList.toggle('active', ['mine','all','summary'][i]===tab));
  if (tab==='all') loadAllPayroll();
  if (tab==='summary') loadSummary();
}

async function loadMyPayslips() {
  const slips = await api.get('/payroll/mine');
  const grid = document.getElementById('my-payslips-grid');
  if (!slips.length) { grid.innerHTML = `<div class="empty-state"><p>No payslips available yet</p></div>`; return; }

  grid.innerHTML = slips.map(s => {
    const monthName = months[s.month - 1];
    return `<div class="payslip-card" onclick="viewPayslip(${s.id})">
      <div class="payslip-header">
        <div class="payslip-month">${monthName} ${s.year}</div>
        <div style="margin-top:4px">${fmt.statusBadge(s.status)}</div>
      </div>
      <div class="payslip-body">
        <div class="payslip-row"><span style="color:var(--text-muted)">Base Salary</span><span>${fmt.currency(s.base_salary)}</span></div>
        <div class="payslip-row"><span style="color:var(--text-muted)">Allowances</span><span style="color:var(--success-fg)">+${fmt.currency(s.allowances)}</span></div>
        <div class="payslip-row"><span style="color:var(--text-muted)">Deductions</span><span style="color:var(--danger-fg)">-${fmt.currency(s.deductions)}</span></div>
        <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center">
          <span style="font-size:.8rem;color:var(--text-muted)">Net Pay</span>
          <span class="payslip-net">${fmt.currency(s.net_salary)}</span>
        </div>
      </div>
    </div>`;
  }).join('');
}

async function viewPayslip(id) {
  const s = await api.get(`/payroll/${id}`);
  const monthName = months[s.month - 1];
  document.getElementById('payslip-detail').innerHTML = `
    <div class="payslip-detail" id="printable-payslip">
      <div class="payslip-detail-header">
        <div class="company-logo">
          <div class="mark">HR</div>
          <div>
            <div style="font-family:var(--font-display);font-weight:700;font-size:1.1rem">HRConnect</div>
            <div style="font-size:.8rem;color:var(--text-muted)">Payroll Department</div>
          </div>
        </div>
        <div style="text-align:right">
          <div style="font-weight:600">${monthName} ${s.year}</div>
          <div style="font-size:.8rem;color:var(--text-muted)">Payslip</div>
          ${fmt.statusBadge(s.status)}
        </div>
      </div>

      <div class="detail-section">
        <h4>Employee Details</h4>
        <div class="detail-row"><span>Name</span><span>${s.first_name} ${s.last_name}</span></div>
        <div class="detail-row"><span>Job Title</span><span>${s.job_title || '-'}</span></div>
        <div class="detail-row"><span>Department</span><span>${s.department_name || '-'}</span></div>
        <div class="detail-row"><span>Email</span><span>${s.email}</span></div>
      </div>

      <div class="detail-section">
        <h4>Earnings</h4>
        <div class="detail-row"><span>Base Salary</span><span class="positive">${fmt.currency(s.base_salary)}</span></div>
        <div class="detail-row"><span>Allowances</span><span class="positive">+${fmt.currency(s.allowances)}</span></div>
        <div class="detail-row total"><span>Gross Pay</span><span>${fmt.currency(parseFloat(s.base_salary)+parseFloat(s.allowances))}</span></div>
      </div>

      <div class="detail-section">
        <h4>Deductions</h4>
        <div class="detail-row"><span>Total Deductions</span><span class="negative">-${fmt.currency(s.deductions)}</span></div>
      </div>

      <div class="net-salary-box">
        <div>
          <div style="font-size:.8rem;color:var(--text-muted);margin-bottom:4px">NET PAY</div>
          <div class="net-amount">${fmt.currency(s.net_salary)}</div>
        </div>
        <div style="text-align:right">
          <div style="font-size:.8rem;color:var(--text-muted)">Payment Status</div>
          <div style="margin-top:4px">${fmt.statusBadge(s.status)}</div>
          ${s.paid_at ? `<div style="font-size:.78rem;color:var(--text-muted);margin-top:4px">Paid ${fmt.date(s.paid_at)}</div>` : ''}
        </div>
      </div>
    </div>`;
  document.getElementById('payslip-modal').style.display = 'flex';
}

function printPayslip() {
  const printable = document.getElementById('printable-payslip');
  if (!printable) {
    toast('Open a payslip before printing.', 'warning');
    return;
  }

  const w = window.open('', '_blank');
  if (!w) {
    toast('Allow popups to print this payslip.', 'warning');
    return;
  }

  const doc = w.document;
  doc.title = 'Payslip';

  const link = doc.createElement('link');
  link.rel = 'stylesheet';
  link.href = '../css/main.css';
  doc.head.appendChild(link);

  const style = doc.createElement('style');
  style.textContent = 'body{padding:40px;background:#fff}.payslip-detail{max-width:100%;padding:0}@media print{body{padding:0}}';
  doc.head.appendChild(style);

  doc.body.innerHTML = printable.innerHTML;
  w.focus();
  setTimeout(() => w.print(), 250);
}

async function loadAllPayroll() {
  const month  = document.getElementById('pr-month').value;
  const year   = document.getElementById('pr-year').value;
  const status = document.getElementById('pr-status').value;
  let qs = `?month=${month}&year=${year}`;
  if (status) qs += `&status=${status}`;
  const rows = await api.get(`/payroll${qs}`);
  const tbody = document.getElementById('all-payroll-tbody');
  if (!rows.length) { tbody.innerHTML = `<tr><td colspan="8"><div class="empty-state"><p>No payroll records</p></div></td></tr>`; return; }
  tbody.innerHTML = rows.map(r => `
    <tr>
      <td><div style="display:flex;align-items:center;gap:10px">${initialsAvatar(r.employee_name?.split(' ')[0]||'?',r.employee_name?.split(' ')[1]||'','sm')}<span style="font-weight:500">${r.employee_name}</span></div></td>
      <td>${r.department_name || '-'}</td>
      <td>${fmt.currency(r.base_salary)}</td>
      <td style="color:var(--success-fg)">+${fmt.currency(r.allowances)}</td>
      <td style="color:var(--danger-fg)">-${fmt.currency(r.deductions)}</td>
      <td style="font-weight:600">${fmt.currency(r.net_salary)}</td>
      <td>${fmt.statusBadge(r.status)}</td>
      <td style="display:flex;gap:6px">
        <button class="btn btn-outline btn-sm" onclick="viewPayslip(${r.id})">View</button>
        ${r.status === 'processed' ? `<button class="btn btn-success btn-sm" onclick="markPaid(${r.id})">Mark Paid</button>` : ''}
      </td>
    </tr>`).join('');
}

async function markPaid(id) {
  try {
    await api.patch(`/payroll/${id}/paid`);
    toast('Marked as paid!', 'success');
    loadAllPayroll();
  } catch(e) { toast(e.message, 'error'); }
}

async function loadSummary() {
  const rows = await api.get('/payroll/summary');
  const tbody = document.getElementById('summary-tbody');
  if (!rows.length) { tbody.innerHTML = `<tr><td colspan="6"><div class="empty-state"><p>No data</p></div></td></tr>`; return; }
  tbody.innerHTML = rows.map(r => `
    <tr>
      <td style="font-weight:500">${months[r.month-1]} ${r.year}</td>
      <td>${r.employee_count}</td>
      <td>${fmt.currency(r.total_base)}</td>
      <td style="color:var(--danger-fg)">-${fmt.currency(r.total_deductions)}</td>
      <td style="font-weight:600">${fmt.currency(r.total_net)}</td>
      <td>${r.paid_count}/${r.employee_count} paid</td>
    </tr>`).join('');
}

function showProcessModal() {
  const m = now.getMonth() + 1;
  const y = now.getFullYear();
  if (!confirm(`Process payroll for ${months[m-1]} ${y}? This will generate payslips for all active employees.`)) return;
  api.post('/payroll/process', { month: m, year: y })
    .then(r => { toast(`Payroll processed for ${r.count} employees`, 'success'); switchTab('all'); })
    .catch(e => toast(e.message, 'error'));
}

loadMyPayslips();
