// Toast Alert Helper
    function showToast(msg, type = 'info') {
      const container = document.getElementById('toastContainer');
      const toast = document.createElement('div');
      const colors = {
        success: 'bg-emerald-600 text-white shadow-emerald-600/30',
        error: 'bg-red-600 text-white shadow-red-600/30',
        info: 'bg-brand-600 text-white shadow-brand-600/30',
        warning: 'bg-amber-500 text-white shadow-amber-500/30'
      };
      toast.className = `px-4 py-3 rounded-2xl font-bold text-xs tracking-wide shadow-2xl flex items-center gap-3 pointer-events-auto transition-all duration-500 ease-out transform translate-y-2 opacity-0 ${colors[type] || colors.info}`;
      toast.innerHTML = `<span>${msg}</span>`;
      container.appendChild(toast);
      requestAnimationFrame(() => toast.classList.remove('translate-y-2', 'opacity-0'));
      setTimeout(() => {
        toast.classList.add('opacity-0', 'translate-y-2');
        setTimeout(() => toast.remove(), 500);
      }, 3000);
    }

    // Modal Confirmation Dialog
    let confirmCallback = null;
    function showConfirmModal(title, msg, onConfirm) {
      document.getElementById('confirmTitle').textContent = title;
      document.getElementById('confirmMessage').textContent = msg;
      confirmCallback = onConfirm;
      document.getElementById('confirmModal').classList.add('active');
    }
    document.getElementById('confirmOkBtn').addEventListener('click', () => {
      document.getElementById('confirmModal').classList.remove('active');
      if (confirmCallback) confirmCallback();
    });
    document.getElementById('confirmCancelBtn').addEventListener('click', () => {
      document.getElementById('confirmModal').classList.remove('active');
    });

    // Theme Toggle
    function toggleTheme() {
      const isDark = document.documentElement.classList.toggle('dark');
      localStorage.setItem('hope_erp_theme', isDark ? 'dark' : 'light');
      showToast(isDark ? 'Dark Mode Active' : 'Light Mode Active', 'info');
    }

    // Permissions System
    const ALL_PERMS = {
      'customers.view': 'View Customers', 'customers.add': 'Add Customer', 'customers.edit': 'Edit Customer', 'customers.delete': 'Delete Customer',
      'products.view': 'View Products', 'products.add': 'Add Product', 'products.edit': 'Edit Product', 'products.delete': 'Delete Product',
      'hr.view': 'View HR', 'hr.jobAdd': 'Add Job', 'hr.jobEdit': 'Edit Job', 'hr.jobDelete': 'Delete Job', 'hr.deptAdd': 'Add Department', 'hr.deptEdit': 'Edit Department', 'hr.deptDelete': 'Delete Department', 'hr.empAdd': 'Add Employee', 'hr.empEdit': 'Edit Employee', 'hr.empDelete': 'Delete Employee',
      'sales.view': 'View Sales', 'sales.add': 'Add Sale', 'sales.edit': 'Edit Sale', 'sales.delete': 'Delete Sale',
      'reports.view': 'View Reports'
    };

    const PERM_GROUPS = [
      { key: 'customers', label: 'Customer Management', view: 'customers.view', items: ['customers.add','customers.edit','customers.delete'] },
      { key: 'products', label: 'Product Management', view: 'products.view', items: ['products.add','products.edit','products.delete'] },
      { key: 'hr', label: 'Human Resources', view: 'hr.view', items: ['hr.jobAdd','hr.jobEdit','hr.jobDelete','hr.deptAdd','hr.deptEdit','hr.deptDelete','hr.empAdd','hr.empEdit','hr.empDelete'] },
      { key: 'sales', label: 'Sales', view: 'sales.view', items: ['sales.add','sales.edit','sales.delete'] },
      { key: 'reports', label: 'Reports', view: 'reports.view', items: [] }
    ];

    function fullPerms() { const p = {}; Object.keys(ALL_PERMS).forEach(k => p[k] = true); return p; }
    function sampleUserPerms() {
      const p = {}; Object.keys(ALL_PERMS).forEach(k => p[k] = false);
      ['customers.view','customers.add','customers.edit','products.view','hr.view','sales.view','reports.view'].forEach(k => p[k] = true);
      return p;
    }

    const DEFAULT_USERS = [
      { email: 'superadmin@hope.com', firstName: 'Sarah', lastName: 'Chen', role: 'superadmin', status: 'active', perms: fullPerms() },
      { email: 'admin@hope.com', firstName: 'Lisa', lastName: 'Park', role: 'admin', status: 'active', perms: fullPerms() },
      { email: 'user@hope.com', firstName: 'Alex', lastName: 'Rivera', role: 'user', status: 'active', perms: sampleUserPerms() }
    ];

    let memoryUsers = null;
    function getUsers() {
      try {
        const s = localStorage.getItem('pentad_erp_users_v6');
        if (s) return JSON.parse(s);
        localStorage.setItem('pentad_erp_users_v6', JSON.stringify(DEFAULT_USERS));
        return [...DEFAULT_USERS];
      } catch(e) { if (!memoryUsers) memoryUsers = [...DEFAULT_USERS]; return memoryUsers; }
    }
    function saveUsers(u) { try { localStorage.setItem('pentad_erp_users_v6', JSON.stringify(u)); } catch(e) { memoryUsers = u; } }
    function findUser(email) { return getUsers().find(u => u.email.toLowerCase() === email.toLowerCase()); }
    function upsertUser(u) {
      const list = getUsers();
      const idx = list.findIndex(x => x.email.toLowerCase() === u.email.toLowerCase());
      if (idx >= 0) list[idx] = u; else list.push(u);
      saveUsers(list);
    }

    let currentUser = null;
    function can(perm) {
      if (!currentUser) return false;
      if (currentUser.role === 'superadmin' || currentUser.role === 'admin') return true;
      const u = findUser(currentUser.email);
      if (!u || !u.perms) return false;
      const p = Object.keys(u.perms).length ? u.perms : sampleUserPerms();
      return !!p[perm];
    }
    function canModule(m) { return can(m + '.view'); }

    // Modal Helpers
    function openModal(id) {
      const routes = {
        login: document.body.dataset.loginUrl,
        register: document.body.dataset.registerUrl,
        setPassword: document.body.dataset.setPasswordUrl
      };
      if (routes[id]) {
        window.location.assign(routes[id]);
        return;
      }

      const el = document.getElementById(id + 'Modal');
      if (el) { el.classList.add('active'); document.body.style.overflow = 'hidden'; }
    }
    function closeModal(id) {
      const el = document.getElementById(id + 'Modal');
      if (el) { el.classList.remove('active'); document.body.style.overflow = ''; }
    }
    function switchModal(from, to) { closeModal(from); setTimeout(() => openModal(to), 150); }
    function togglePasswordVisibility(id, btn) {
      const inp = document.getElementById(id);
      const show = inp.type === 'password';
      inp.type = show ? 'text' : 'password';
      const ic = btn.querySelector('i');
      ic.classList.toggle('fa-eye', show);
      ic.classList.toggle('fa-eye-slash', !show);
      btn.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    }

    async function logout() {
      try {
        const response = await fetch('/api/logout', { method: 'POST' });
        if (!response.ok) throw new Error('Sign out could not be completed.');
        window.location.assign('/');
      } catch (error) {
        showToast(error instanceof Error ? error.message : 'Sign out could not be completed.', 'error');
      }
    }

    // Dashboard State
    function showDashboard() {
      document.getElementById('landing').classList.add('hidden');
      document.getElementById('dashboard').classList.remove('hidden');
      renderSidebar();
      renderDashboardHome();
      updateUserInfo();
    }

    function updateUserInfo() {
      if (!currentUser) return;
      document.getElementById('userName').textContent = currentUser.name;
      document.getElementById('userRoleLabel').textContent = currentUser.role;
      document.getElementById('userAvatar').textContent = (currentUser.firstName[0] || 'U').toUpperCase();
      document.getElementById('roleBadge').textContent = currentUser.role;
    }

    function toggleMobileSidebar() {
      document.getElementById('sidebar').classList.toggle('-translate-x-full');
    }

    function renderSidebar() {
      const nav = document.getElementById('sidebarNav');
      const role = currentUser.role;

      const items = [
        { id: 'dashboard', icon: 'fa-chart-pie', label: 'Executive Analytics' },
        { id: 'customers', icon: 'fa-address-book', label: 'Customer CRM', module: 'customers' },
        { id: 'products', icon: 'fa-boxes-stacked', label: 'Product Catalog', module: 'products' },
        { id: 'hr', icon: 'fa-id-card', label: 'Human Resources', module: 'hr' },
        { id: 'sales', icon: 'fa-cart-shopping', label: 'Sales Operations', module: 'sales' },
        { id: 'reports', icon: 'fa-file-signature', label: 'Executive Reports', module: 'reports' },
        { id: 'users', icon: 'fa-shield-halved', label: 'User Management', adminOnly: true },
      ];

      let html = '';
      items.forEach(item => {
        if (item.adminOnly && role !== 'superadmin' && role !== 'admin') return;
        if (item.module && role === 'user' && !canModule(item.module)) return;

        html += `
          <button onclick="navigateTo('${item.id}')" data-id="${item.id}" class="nav-btn w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold transition-all">
            <i class="fa-solid ${item.icon} w-4 text-center"></i>
            <span>${item.label}</span>
          </button>`;
      });

      nav.innerHTML = html;
      setActiveNavItem('dashboard');
    }

    function setActiveNavItem(id) {
      document.querySelectorAll('.nav-btn').forEach(btn => {
        if (btn.getAttribute('data-id') === id) {
          btn.className = 'nav-btn w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold bg-gradient-to-r from-brand-600 to-indigo-600 text-white shadow-lg shadow-brand-600/25';
        } else {
          btn.className = 'nav-btn w-full flex items-center gap-3 px-4 py-3 rounded-2xl text-xs font-bold text-gray-400 hover:bg-slate-900 hover:text-white transition-all';
        }
      });
    }

    function navigateTo(page) {
      setActiveNavItem(page);
      const titles = { dashboard: 'Dashboard', customers: 'Customer Management', products: 'Product Management', hr: 'Human Resources', sales: 'Sales Management', reports: 'Reports', users: 'User Management' };
      document.getElementById('pageTitle').textContent = titles[page] || page;

      if (page === 'dashboard') renderDashboardHome();
      else if (page === 'customers') renderCustomers();
      else if (page === 'products') renderProducts();
      else if (page === 'hr') renderHR();
      else if (page === 'sales') renderSales();
      else if (page === 'reports') renderReports();
      else if (page === 'users') renderUserManagement();

      document.getElementById('sidebar').classList.add('-translate-x-full');
    }

    // Data Stores
    const DEFAULT_CUSTOMERS = [
      { custNo: 'C-001', custName: 'Acme Corporation', address: '123 Main St, Metro City', payterms: 'Net 30', isDeleted: false, stamp: 'CREATED system 2026-10-01' },
      { custNo: 'C-002', custName: 'Globex Industries', address: '456 Oak Ave, Harbor Town', payterms: 'Net 45', isDeleted: false, stamp: 'CREATED system 2026-10-02' }
    ];

    let memoryCustomers = null;
    function getCustomers() {
      try {
        const s = localStorage.getItem('hope_customers_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_customers_v5', JSON.stringify(DEFAULT_CUSTOMERS));
        return [...DEFAULT_CUSTOMERS];
      } catch(e) { if (!memoryCustomers) memoryCustomers = [...DEFAULT_CUSTOMERS]; return memoryCustomers; }
    }
    function saveCustomers(l) { try { localStorage.setItem('hope_customers_v5', JSON.stringify(l)); } catch(e) { memoryCustomers = l; } }

    function makeStamp(act) {
      const now = new Date();
      return `${act} ${currentUser ? currentUser.firstName : 'user'} ${now.toISOString().slice(0,10)}`;
    }

    // Dashboard Executive Home
    function renderDashboardHome() {
      const area = document.getElementById('contentArea');
      const role = currentUser.role;
      const msg = { superadmin: 'You have full system access. You can manage all modules and assign roles to any user.', admin: 'You can manage most modules and user rights (except Superadmin accounts).', user: 'You have access to the core modules assigned to you. Contact an Admin for elevated permissions.' }[role];
      const allC = getCustomers(), inactive = allC.filter(c => c.isDeleted).length;
      const stat = (l, ic, col, v, sub) => `<div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80 glow-hover"><div class="flex items-center justify-between text-gray-400 text-[10px] font-black uppercase tracking-wider mb-2"><span>${l}</span><i class="fa-solid ${ic} ${col}"></i></div><div class="text-3xl font-black text-gray-900 dark:text-white">${v}</div><p class="text-[11px] font-bold text-emerald-500 mt-2">${sub}</p></div>`;
      const qn = (id, ic, col, l) => `<button onclick="navigateTo('${id}')" class="w-full p-3.5 rounded-2xl bg-gray-50 dark:bg-slate-950/60 hover:bg-brand-500/10 text-left flex items-center justify-between transition-all"><span class="text-xs font-bold text-gray-700 dark:text-gray-300"><i class="fa-solid ${ic} ${col} mr-2"></i> ${l}</span><i class="fa-solid fa-chevron-right text-[10px] text-gray-400"></i></button>`;
      area.innerHTML = `
        <div class="p-7 rounded-3xl mb-8 bg-gradient-to-r from-brand-700 to-indigo-600 text-white shadow-xl shadow-brand-600/20">
          <h2 class="text-2xl font-black">Welcome back, ${currentUser.firstName}!</h2>
          <p class="text-sm text-white/80 mt-1">${msg}</p>
        </div>
        <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          ${stat('Total Customers','fa-address-book','text-brand-500',allC.length-inactive,inactive+' inactive')}
          ${stat('Products','fa-boxes-stacked','text-amber-500',getProducts().filter(p=>!p.isDeleted).length,'Active Catalog')}
          ${stat('Open Orders','fa-cart-shopping','text-indigo-500',getSales().filter(x=>!x.isDeleted).length,'Sales Pipeline')}
          ${stat('Revenue (MTD)','fa-sack-dollar','text-emerald-500','$84,250.00','↑ +18.4% expansion')}
        </div>
        <div class="grid lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
            <div class="flex items-center justify-between mb-6"><h3 class="font-bold text-sm text-gray-900 dark:text-white">Revenue Performance Analytics</h3><span class="text-[10px] font-black uppercase tracking-wider px-3 py-1 rounded-full bg-brand-500/10 text-brand-500">2026 Fiscal</span></div>
            <div class="h-64 relative"><canvas id="revenueChart" class="w-full h-full"></canvas></div>
          </div>
          <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80 flex flex-col justify-between">
            <div><h3 class="font-bold text-sm text-gray-900 dark:text-white mb-4">Quick Navigation</h3><div class="space-y-3">
              ${qn('customers','fa-address-book','text-brand-500','View Customers')}${qn('products','fa-boxes-stacked','text-amber-500','Manage Products')}${qn('hr','fa-id-card','text-indigo-500','Human Resources')}${qn('sales','fa-cart-shopping','text-emerald-500','Sales Pipeline')}${qn('reports','fa-file-signature','text-purple-500','Reports')}${role !== 'user' ? qn('users','fa-shield-halved','text-sky-500','Manage Users') : ''}
            </div></div>
            <div class="mt-6 p-4 rounded-2xl bg-slate-950 text-white border border-gray-800"><div class="text-[10px] font-black text-brand-400 uppercase tracking-widest">Active Security</div><div class="text-xs font-bold mt-1">Audit-backed Soft Delete Enabled</div></div>
          </div>
        </div>`;
      setTimeout(renderDashboardRevenueChart, 50);
    }

    function renderDashboardRevenueChart() {
      const cvs = document.getElementById('revenueChart');
      if (!cvs) return;
      const ctx = cvs.getContext('2d');
      const dpr = window.devicePixelRatio || 1;
      const rect = cvs.getBoundingClientRect();
      cvs.width = rect.width * dpr;
      cvs.height = rect.height * dpr;
      ctx.scale(dpr, dpr);

      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      const data = [35, 42, 58, 65, 72, 68, 80, 85, 92, 84, 95, 110];

      const width = rect.width;
      const height = rect.height;
      const padding = 30;
      const chartW = width - padding * 2;
      const chartH = height - padding * 2;

      ctx.clearRect(0, 0, width, height);

      ctx.strokeStyle = document.documentElement.classList.contains('dark') ? '#1e293b' : '#e2e8f0';
      ctx.lineWidth = 1;
      for (let i = 0; i <= 4; i++) {
        const y = padding + (chartH / 4) * i;
        ctx.beginPath();
        ctx.moveTo(padding, y);
        ctx.lineTo(width - padding, y);
        ctx.stroke();
      }

      const barWidth = (chartW / months.length) * 0.5;
      months.forEach((m, i) => {
        const x = padding + (i * (chartW / months.length)) + (chartW / months.length - barWidth) / 2;
        const valH = (data[i] / 120) * chartH;
        const y = height - padding - valH;

        const grad = ctx.createLinearGradient(0, y, 0, height - padding);
        grad.addColorStop(0, '#6366f1');
        grad.addColorStop(1, '#4338ca');

        ctx.fillStyle = grad;
        ctx.beginPath();
        ctx.roundRect(x, y, barWidth, valH, [8, 8, 0, 0]);
        ctx.fill();

        ctx.fillStyle = document.documentElement.classList.contains('dark') ? '#64748b' : '#94a3b8';
        ctx.font = '10px Plus Jakarta Sans, sans-serif';
        ctx.textAlign = 'center';
        ctx.fillText(m, x + barWidth / 2, height - 10);
      });
    }

    // Customer Module Views
    function renderCustomersBasic() {
      const area = document.getElementById('contentArea');
      const list = getCustomers().filter(c => !c.isDeleted);

      const rows = list.map(c => `
        <tr>
          <td class="p-4 font-bold text-gray-900 dark:text-white">${c.custNo}</td>
          <td class="p-4 font-semibold">${c.custName}</td>
          <td class="p-4 text-gray-500">${c.address}</td>
          <td class="p-4"><span class="px-3 py-1 rounded-full text-[10px] font-bold bg-gray-100 dark:bg-slate-950">${c.payterms}</span></td>
          <td class="p-4 text-right space-x-2">
            ${can('customers.edit') ? `<button onclick="openEditCustomer('${c.custNo}')" class="px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-800 hover:bg-gray-100 font-bold text-xs">Edit</button>` : ''}
            ${can('customers.delete') ? `<button onclick="softDeleteCustomer('${c.custNo}')" class="px-3 py-1.5 rounded-xl bg-red-500/10 text-red-500 hover:bg-red-500/20 font-bold text-xs">Delete</button>` : ''}
          </td>
        </tr>
      `).join('');

      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-base font-bold text-gray-900 dark:text-white">Customer Management</h2>
            ${can('customers.add') ? `<button onclick="openAddCustomer()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add Customer</button>` : ''}
          </div>

          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60">
            <table class="w-full text-left text-xs">
              <thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold">
                <tr>
                  <th class="p-4">Cust No</th>
                  <th class="p-4">Customer Name</th>
                  <th class="p-4">Address</th>
                  <th class="p-4">Terms</th>
                  <th class="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows}</tbody>
            </table>
          </div>
        </div>
      `;
    }

    function openAddCustomer() {
      document.getElementById('customerModalTitle').textContent = 'Add Customer';
      document.getElementById('custEditNo').value = '';
      document.getElementById('custNo').value = '';
      document.getElementById('custNo').readOnly = false;
      document.getElementById('custName').value = '';
      document.getElementById('custAddress').value = '';
      document.getElementById('custPayterms').value = '';
      openModal('customer');
    }
    function openEditCustomer(custNo) {
      const c = getCustomers().find(x => x.custNo === custNo);
      if (!c) return;
      document.getElementById('customerModalTitle').textContent = 'Edit Customer';
      document.getElementById('custEditNo').value = c.custNo;
      document.getElementById('custNo').value = c.custNo;
      document.getElementById('custNo').readOnly = true;
      document.getElementById('custName').value = c.custName;
      document.getElementById('custAddress').value = c.address;
      document.getElementById('custPayterms').value = c.payterms;
      openModal('customer');
    }
    function closeCustomerModal() { closeModal('customer'); }

    function saveCustomer(e) {
      e.preventDefault();
      const editNo = document.getElementById('custEditNo').value;
      const custNo = document.getElementById('custNo').value.trim();
      const custName = document.getElementById('custName').value.trim();
      const address = document.getElementById('custAddress').value.trim();
      const payterms = document.getElementById('custPayterms').value.trim();

      const list = getCustomers();
      if (editNo) {
        const idx = list.findIndex(c => c.custNo === editNo);
        if (idx >= 0) list[idx] = { ...list[idx], custName, address, payterms, stamp: makeStamp('EDITED') };
      } else {
        const inp = document.getElementById('custNo');
        if (list.some(c => c.custNo.toLowerCase() === custNo.toLowerCase())) {
          inp.classList.add('ring-2', 'ring-red-500'); inp.addEventListener('input', () => inp.classList.remove('ring-2', 'ring-red-500'), { once: true });
          return showToast(`Customer No. ${custNo} already exists.`, 'error');
        }
        list.push({ custNo, custName, address, payterms, isDeleted: false, stamp: makeStamp('CREATED') });
      }
      saveCustomers(list);
      closeCustomerModal();
      renderCustomers();
      showToast('Customer saved.', 'success');
    }

    function softDeleteCustomer(custNo) {
      showConfirmModal('Delete Customer', `Mark ${custNo} as deleted?`, () => {
        const list = getCustomers();
        const idx = list.findIndex(c => c.custNo === custNo);
        if (idx >= 0) { list[idx].isDeleted = true; saveCustomers(list); renderCustomers(); showToast('Customer deleted.', 'warning'); }
      });
    }

    // Product & Price History Stores
    const DEFAULT_PRODUCTS = [
      { prodCode: 'P-001', description: 'Industrial Widget A', unit: 'pcs', isDeleted: false },
      { prodCode: 'P-002', description: 'Steel Bracket Heavy', unit: 'pcs', isDeleted: false }
    ];
    const DEFAULT_PRICES = [
      { prodCode: 'P-001', effDate: '2026-01-01', unitPrice: 12.50, isDeleted: false },
      { prodCode: 'P-002', effDate: '2026-01-15', unitPrice: 45.00, isDeleted: false }
    ];

    let memoryProducts = null, memoryPrices = null;
    function getProducts() {
      try {
        const s = localStorage.getItem('hope_products_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_products_v5', JSON.stringify(DEFAULT_PRODUCTS));
        return [...DEFAULT_PRODUCTS];
      } catch(e) { if (!memoryProducts) memoryProducts = [...DEFAULT_PRODUCTS]; return memoryProducts; }
    }
    function saveProducts(l) { try { localStorage.setItem('hope_products_v5', JSON.stringify(l)); } catch(e) { memoryProducts = l; } }

    function getPrices() {
      try {
        const s = localStorage.getItem('hope_prices_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_prices_v5', JSON.stringify(DEFAULT_PRICES));
        return [...DEFAULT_PRICES];
      } catch(e) { if (!memoryPrices) memoryPrices = [...DEFAULT_PRICES]; return memoryPrices; }
    }
    function savePrices(l) { try { localStorage.setItem('hope_prices_v5', JSON.stringify(l)); } catch(e) { memoryPrices = l; } }

    function latestUnitPrice(prodCode) {
      let prices = getPrices().filter(p => p.prodCode === prodCode && !p.isDeleted);
      prices.sort((a,b) => b.effDate.localeCompare(a.effDate));
      return prices.length ? Number(prices[0].unitPrice) : 0;
    }

    function renderProducts() {
      const area = document.getElementById('contentArea');
      const list = getProducts().filter(p => !p.isDeleted);

      const rows = list.map(p => `
        <tr>
          <td class="p-4 font-bold text-gray-900 dark:text-white">${p.prodCode}</td>
          <td class="p-4 font-semibold">${p.description}</td>
          <td class="p-4 text-gray-500">${p.unit}</td>
          <td class="p-4 font-bold text-brand-500">$${latestUnitPrice(p.prodCode).toFixed(2)}</td>
          <td class="p-4 text-right space-x-2">
            <button onclick="openPriceHistory('${p.prodCode}')" class="px-3 py-1.5 rounded-xl bg-brand-500/10 text-brand-500 font-bold text-xs">Price Logs</button>
            ${can('products.edit') ? `<button onclick="openEditProduct('${p.prodCode}')" class="px-3 py-1.5 rounded-xl border font-bold text-xs">Edit</button>` : ''}
            ${can('products.delete') ? `<button onclick="softDeleteProduct('${p.prodCode}')" class="px-3 py-1.5 rounded-xl bg-red-500/10 text-red-500 font-bold text-xs">Delete</button>` : ''}
          </td>
        </tr>
      `).join('');

      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-base font-bold text-gray-900 dark:text-white">Product Catalog</h2>
            ${can('products.add') ? `<button onclick="openAddProduct()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add Product</button>` : ''}
          </div>

          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60">
            <table class="w-full text-left text-xs">
              <thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold">
                <tr>
                  <th class="p-4">Code</th>
                  <th class="p-4">Description</th>
                  <th class="p-4">Unit</th>
                  <th class="p-4">Current Price</th>
                  <th class="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows}</tbody>
            </table>
          </div>
        </div>
      `;
    }

    function openAddProduct() {
      document.getElementById('productModalTitle').textContent = 'Add Product';
      document.getElementById('prodEditCode').value = '';
      document.getElementById('prodCode').value = ''; document.getElementById('prodCode').readOnly = false;
      document.getElementById('prodDesc').value = ''; document.getElementById('prodUnit').value = '';
      openModal('product');
    }
    function openEditProduct(code) {
      const p = getProducts().find(x => x.prodCode === code);
      if (!p) return;
      document.getElementById('productModalTitle').textContent = 'Edit Product';
      document.getElementById('prodEditCode').value = p.prodCode;
      document.getElementById('prodCode').value = p.prodCode; document.getElementById('prodCode').readOnly = true;
      document.getElementById('prodDesc').value = p.description; document.getElementById('prodUnit').value = p.unit;
      openModal('product');
    }
    function closeProductModal() { closeModal('product'); }

    function saveProduct(e) {
      e.preventDefault();
      const editCode = document.getElementById('prodEditCode').value;
      const prodCode = document.getElementById('prodCode').value.trim();
      const description = document.getElementById('prodDesc').value.trim();
      const unit = document.getElementById('prodUnit').value.trim();

      const list = getProducts();
      if (editCode) {
        const idx = list.findIndex(p => p.prodCode === editCode);
        if (idx >= 0) list[idx] = { ...list[idx], description, unit };
      } else {
        list.push({ prodCode, description, unit, isDeleted: false });
      }
      saveProducts(list);
      closeProductModal();
      renderProducts();
      showToast('Product catalog updated.', 'success');
    }

    function softDeleteProduct(code) {
      showConfirmModal('Delete Product', `Delete product ${code}?`, () => {
        const list = getProducts();
        const idx = list.findIndex(p => p.prodCode === code);
        if (idx >= 0) { list[idx].isDeleted = true; saveProducts(list); renderProducts(); showToast('Product deleted.', 'warning'); }
      });
    }

    let selectedProdCode = null;
    function openPriceHistory(code) {
      selectedProdCode = code;
      document.getElementById('priceHistTitle').textContent = `Price Logs — ${code}`;
      renderPriceHistoryContent();
      openModal('priceHist');
    }
    function closePriceHistModal() { closeModal('priceHist'); }

    function renderPriceHistoryContent() {
      const prices = getPrices().filter(p => p.prodCode === selectedProdCode && !p.isDeleted);
      prices.sort((a,b) => b.effDate.localeCompare(a.effDate));

      document.getElementById('priceHistToolbar').innerHTML = `
        <span class="text-xs font-bold text-gray-400">${prices.length} record(s)</span>
        <button onclick="openAddPrice('${selectedProdCode}')" class="px-3 py-1.5 rounded-xl bg-brand-600 text-white font-bold text-xs shadow">+ Add Price</button>
      `;

      document.getElementById('priceHistBody').innerHTML = prices.map(pr => `
        <tr>
          <td class="p-3 font-semibold">${pr.effDate}</td>
          <td class="p-3 font-bold text-emerald-500">$${Number(pr.unitPrice).toFixed(2)}</td>
          <td class="p-3"><span class="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-500">Active</span></td>
          <td class="p-3 text-gray-500 text-[10px]">—</td>
          <td class="p-3 text-right">
            <button onclick="softDeletePrice('${pr.prodCode}','${pr.effDate}')" class="px-2 py-1 rounded bg-red-500/10 text-red-500 font-bold text-[10px]">Delete</button>
          </td>
        </tr>
      `).join('');
    }

    function openAddPrice(code) {
      document.getElementById('priceProdCode').value = code;
      document.getElementById('priceEffDate').value = new Date().toISOString().slice(0,10);
      document.getElementById('priceUnitPrice').value = '';
      openModal('price');
    }
    function closePriceModal() { closeModal('price'); }

    function savePrice(e) {
      e.preventDefault();
      const prodCode = document.getElementById('priceProdCode').value;
      const effDate = document.getElementById('priceEffDate').value;
      const unitPrice = parseFloat(document.getElementById('priceUnitPrice').value);

      const list = getPrices();
      list.push({ prodCode, effDate, unitPrice, isDeleted: false });
      savePrices(list);
      closePriceModal();
      renderPriceHistoryContent();
      renderProducts();
      showToast('Price log added.', 'success');
    }

    function softDeletePrice(code, date) {
      const list = getPrices();
      const idx = list.findIndex(p => p.prodCode === code && p.effDate === date);
      if (idx >= 0) { list[idx].isDeleted = true; savePrices(list); renderPriceHistoryContent(); renderProducts(); }
    }

    // HR Module Stores
    const DEFAULT_EMPLOYEES = [
      { empNo: 'E-001', lastName: 'Santos', firstName: 'Maria', gender: 'F', birthDate: '1990-05-12', hireDate: '2020-03-01', sepDate: '', isDeleted: false }
    ];
    const DEFAULT_JOBS = [{ jobCode: 'J-001', jobDesc: 'Software Engineer' }, { jobCode: 'J-002', jobDesc: 'HR Manager' }, { jobCode: 'J-003', jobDesc: 'Sales Executive' }];
    const DEFAULT_DEPTS = [{ deptCode: 'D-001', deptName: 'Engineering' }, { deptCode: 'D-002', deptName: 'Human Resources' }, { deptCode: 'D-003', deptName: 'Sales' }];
    const DEFAULT_JOBHIST = [{ empNo: 'E-001', jobCode: 'J-001', effDate: '2020-03-01', salary: 52000, deptCode: 'D-001', isDeleted: false }];

    let memoryEmps = null, memoryJH = null;
    function getEmployees() {
      try {
        const s = localStorage.getItem('hope_emps_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_emps_v5', JSON.stringify(DEFAULT_EMPLOYEES));
        return [...DEFAULT_EMPLOYEES];
      } catch(e) { if (!memoryEmps) memoryEmps = [...DEFAULT_EMPLOYEES]; return memoryEmps; }
    }
    function saveEmployees(l) { try { localStorage.setItem('hope_emps_v5', JSON.stringify(l)); } catch(e) { memoryEmps = l; } }

    function getJobHist() {
      try {
        const s = localStorage.getItem('hope_jh_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_jh_v5', JSON.stringify(DEFAULT_JOBHIST));
        return [...DEFAULT_JOBHIST];
      } catch(e) { if (!memoryJH) memoryJH = [...DEFAULT_JOBHIST]; return memoryJH; }
    }
    function saveJobHist(l) { try { localStorage.setItem('hope_jh_v5', JSON.stringify(l)); } catch(e) { memoryJH = l; } }

    const _S = (k, d) => { try { const v = localStorage.getItem(k); if (v) return JSON.parse(v); localStorage.setItem(k, JSON.stringify(d)); } catch(e) {} return d.map(x => ({...x})); };
    const _W = (k, l) => { try { localStorage.setItem(k, JSON.stringify(l)); } catch(e) {} };
    const getJobs = () => _S('pentad_jobs_v1', DEFAULT_JOBS), getDepts = () => _S('pentad_depts_v1', DEFAULT_DEPTS);
    let hrTab = 'emp';
    const gid = id => document.getElementById(id);

    function renderHR() {
      const area = gid('contentArea');
      const btn = (cls, fn, t) => `<button onclick="${fn}" class="px-3 py-1.5 rounded-xl ${cls} font-bold text-xs">${t}</button>`;
      const act = (perm, fn, t, cls) => can(perm) ? btn(cls, fn, t) : '';
      const E = 'border border-gray-200 dark:border-gray-800', D = 'bg-red-500/10 text-red-500';
      let add = '', heads = [], rows = '';
      if (hrTab === 'emp') {
        add = can('hr.empAdd') ? `<button onclick="openAddEmp()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add Employee</button>` : '';
        heads = ['Emp No','Full Name','Gender','Hire Date'];
        rows = getEmployees().filter(e => !e.isDeleted).map(e => `<tr><td class="p-4 font-bold text-gray-900 dark:text-white">${e.empNo}</td><td class="p-4 font-semibold">${e.lastName}, ${e.firstName}</td><td class="p-4">${e.gender}</td><td class="p-4 text-gray-500">${e.hireDate}</td><td class="p-4 text-right space-x-2">${btn('border border-gray-200 dark:border-gray-800',`openProfile('${e.empNo}')`,'Profile')}${btn('bg-brand-500/10 text-brand-500',`openJobHistory('${e.empNo}')`,'Job History')}${act('hr.empEdit',`openEditEmp('${e.empNo}')`,'Edit',E)}${act('hr.empDelete',`softDeleteEmp('${e.empNo}')`,'Delete',D)}</td></tr>`).join('');
      } else {
        const j = hrTab === 'job', k = j ? 'job' : 'dept', c = j ? 'jobCode' : 'deptCode', n = j ? 'jobDesc' : 'deptName', P = j ? 'hr.job' : 'hr.dept';
        add = can(P + 'Add') ? `<button onclick="openSimple('${k}')" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add ${j ? 'Job' : 'Department'}</button>` : '';
        heads = [j ? 'Job Code' : 'Dept Code', j ? 'Job Description' : 'Department Name'];
        rows = (j ? getJobs() : getDepts()).filter(x => !x.isDeleted).map(x => `<tr><td class="p-4 font-bold text-gray-900 dark:text-white">${x[c]}</td><td class="p-4 font-semibold">${x[n]}</td><td class="p-4 text-right space-x-2">${act(P+'Edit',`openSimple('${k}','${x[c]}')`,'Edit',E)}${act(P+'Delete',`delSimple('${k}','${x[c]}')`,'Delete',D)}</td></tr>`).join('');
      }
      const tabs = [['emp','Employees'],['job','Jobs'],['dept','Departments']].map(([k, l]) => `<button onclick="hrTab='${k}';renderHR()" class="px-4 py-2 rounded-xl text-xs font-bold ${hrTab===k?'bg-brand-600 text-white':'bg-gray-100 dark:bg-slate-950 text-gray-500'}">${l}</button>`).join('');
      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex flex-wrap items-center justify-between gap-4 mb-6"><div class="flex items-center gap-2">${tabs}</div>${add}</div>
          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60">
            <table class="w-full text-left text-xs"><thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold"><tr>${heads.map(h => `<th class="p-4">${h}</th>`).join('')}<th class="p-4 text-right">Actions</th></tr></thead>
            <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows || `<tr><td colspan="9" class="p-6 text-center text-gray-400">No records found.</td></tr>`}</tbody></table>
          </div>
        </div>`;
    }

    function openSimple(kind, code) {
      const j = kind === 'job', r = (j ? getJobs() : getDepts()).find(x => x[j ? 'jobCode' : 'deptCode'] === code);
      gid('smKind').value = kind; gid('smEdit').value = code || '';
      gid('smTitle').textContent = (code ? 'Edit ' : 'Add ') + (j ? 'Job' : 'Department');
      gid('smNameLbl').textContent = j ? 'Job Description' : 'Department Name';
      gid('smCode').value = r ? r[j ? 'jobCode' : 'deptCode'] : ''; gid('smCode').readOnly = !!code;
      gid('smName').value = r ? r[j ? 'jobDesc' : 'deptName'] : '';
      openModal('simple');
    }
    function saveSimple(e) {
      e.preventDefault();
      const j = gid('smKind').value === 'job', l = j ? getJobs() : getDepts(), c = j ? 'jobCode' : 'deptCode', n = j ? 'jobDesc' : 'deptName';
      const code = gid('smCode').value.trim(), name = gid('smName').value.trim(), i = l.findIndex(x => x[c] === code);
      if (gid('smEdit').value) l[i][n] = name;
      else { if (i >= 0) return showToast('Code already exists.', 'error'); l.push({ [c]: code, [n]: name, isDeleted: false }); }
      _W(j ? 'pentad_jobs_v1' : 'pentad_depts_v1', l); closeModal('simple'); renderHR(); showToast('Saved.', 'success');
    }
    function delSimple(kind, code) {
      showConfirmModal('Delete ' + (kind === 'job' ? 'Job' : 'Department'), `Mark ${code} as deleted?`, () => {
        const j = kind === 'job', l = j ? getJobs() : getDepts(), x = l.find(y => y[j ? 'jobCode' : 'deptCode'] === code);
        x.isDeleted = true; _W(j ? 'pentad_jobs_v1' : 'pentad_depts_v1', l); renderHR(); showToast('Deleted.', 'warning');
      });
    }

    function openAddEmp() {
      document.getElementById('empModalTitle').textContent = 'Add Employee';
      document.getElementById('empEditNo').value = '';
      document.getElementById('empNo').value = ''; document.getElementById('empNo').readOnly = false;
      document.getElementById('empFirst').value = ''; document.getElementById('empLast').value = '';
      document.getElementById('empBirth').value = ''; document.getElementById('empHire').value = '';
      openModal('emp');
    }
    function openEditEmp(no) {
      const e = getEmployees().find(x => x.empNo === no);
      if (!e) return;
      document.getElementById('empModalTitle').textContent = 'Edit Employee';
      document.getElementById('empEditNo').value = e.empNo;
      document.getElementById('empNo').value = e.empNo; document.getElementById('empNo').readOnly = true;
      document.getElementById('empFirst').value = e.firstName; document.getElementById('empLast').value = e.lastName;
      document.getElementById('empGender').value = e.gender;
      document.getElementById('empBirth').value = e.birthDate; document.getElementById('empHire').value = e.hireDate;
      document.getElementById('empSep').value = e.sepDate || '';
      openModal('emp');
    }
    function closeEmpModal() { closeModal('emp'); }

    function saveEmployee(ev) {
      ev.preventDefault();
      const editNo = document.getElementById('empEditNo').value;
      const empNo = document.getElementById('empNo').value.trim();
      const firstName = document.getElementById('empFirst').value.trim();
      const lastName = document.getElementById('empLast').value.trim();
      const gender = document.getElementById('empGender').value;
      const birthDate = document.getElementById('empBirth').value;
      const hireDate = document.getElementById('empHire').value;
      const sepDate = document.getElementById('empSep').value;

      const list = getEmployees();
      if (editNo) {
        const i = list.findIndex(x => x.empNo === editNo);
        if (i >= 0) list[i] = { ...list[i], firstName, lastName, gender, birthDate, hireDate, sepDate };
      } else {
        list.push({ empNo, firstName, lastName, gender, birthDate, hireDate, sepDate, isDeleted: false });
      }
      saveEmployees(list);
      closeEmpModal();
      renderHR();
      showToast('Employee saved.', 'success');
    }

    function softDeleteEmp(no) {
      showConfirmModal('Delete Employee', `Delete employee ${no}?`, () => {
        const list = getEmployees();
        const i = list.findIndex(x => x.empNo === no);
        if (i >= 0) { list[i].isDeleted = true; saveEmployees(list); renderHR(); showToast('Employee deleted.', 'warning'); }
      });
    }

    let selectedEmpNo = null;
    function openJobHistory(empNo) {
      selectedEmpNo = empNo;
      document.getElementById('jhListTitle').textContent = `Job History — ${empNo}`;
      renderJhListContent();
      openModal('jhList');
    }
    function closeJhListModal() { closeModal('jhList'); }

    function renderJhListContent() {
      const list = getJobHist().filter(h => h.empNo === selectedEmpNo && !h.isDeleted);
      document.getElementById('jhListHead').innerHTML = `
        <th class="p-3">Eff Date</th><th class="p-3">Job Code</th><th class="p-3">Dept Code</th><th class="p-3">Salary</th>
      `;
      document.getElementById('jhListToolbar').innerHTML = `
        <button onclick="openAddJH('${selectedEmpNo}')" class="px-3 py-1.5 rounded-xl bg-brand-600 text-white font-bold text-xs shadow">+ Add History</button>
      `;
      document.getElementById('jhListBody').innerHTML = list.map(h => `
        <tr>
          <td class="p-3 font-bold">${h.effDate}</td>
          <td class="p-3">${h.jobCode}</td>
          <td class="p-3">${h.deptCode}</td>
          <td class="p-3 font-bold text-emerald-500">$${Number(h.salary).toLocaleString()}</td>
        </tr>
      `).join('');
    }

    function openAddJH(empNo) {
      document.getElementById('jhEmpNo').value = empNo;
      document.getElementById('jhEffDate').value = new Date().toISOString().slice(0,10);
      document.getElementById('jhSalary').value = '50000';

      document.getElementById('jhJobCode').innerHTML = getJobs().filter(j => !j.isDeleted).map(j => `<option value="${j.jobCode}">${j.jobCode} — ${j.jobDesc}</option>`).join('');
      document.getElementById('jhDeptCode').innerHTML = getDepts().filter(d => !d.isDeleted).map(d => `<option value="${d.deptCode}">${d.deptCode} — ${d.deptName}</option>`).join('');
      openModal('jhForm');
    }
    function closeJhFormModal() { closeModal('jhForm'); }

    function saveJobHistory(ev) {
      ev.preventDefault();
      const empNo = document.getElementById('jhEmpNo').value;
      const effDate = document.getElementById('jhEffDate').value;
      const salary = parseFloat(document.getElementById('jhSalary').value);
      const jobCode = document.getElementById('jhJobCode').value;
      const deptCode = document.getElementById('jhDeptCode').value;

      const list = getJobHist();
      list.push({ empNo, jobCode, effDate, salary, deptCode, isDeleted: false });
      saveJobHist(list);
      closeJhFormModal();
      renderJhListContent();
      showToast('Job assignment recorded.', 'success');
    }

    // Sales Operations Stores
    const DEFAULT_SALES = [
      { transNo: 'T-001', salesDate: '2026-10-01', custNo: 'C-001', empNo: 'E-001', isDeleted: false }
    ];
    const DEFAULT_SDETAILS = [
      { transNo: 'T-001', prodCode: 'P-001', quantity: 10, isDeleted: false }
    ];

    let memorySales = null, memorySD = null;
    function getSales() {
      try {
        const s = localStorage.getItem('hope_sales_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_sales_v5', JSON.stringify(DEFAULT_SALES));
        return [...DEFAULT_SALES];
      } catch(e) { if (!memorySales) memorySales = [...DEFAULT_SALES]; return memorySales; }
    }
    function saveSales(l) { try { localStorage.setItem('hope_sales_v5', JSON.stringify(l)); } catch(e) { memorySales = l; } }

    function getSDetails() {
      try {
        const s = localStorage.getItem('hope_sdetails_v5');
        if (s) return JSON.parse(s);
        localStorage.setItem('hope_sdetails_v5', JSON.stringify(DEFAULT_SDETAILS));
        return [...DEFAULT_SDETAILS];
      } catch(e) { if (!memorySD) memorySD = [...DEFAULT_SDETAILS]; return memorySD; }
    }
    function saveSDetails(l) { try { localStorage.setItem('hope_sdetails_v5', JSON.stringify(l)); } catch(e) { memorySD = l; } }

    function renderSales() {
      const area = document.getElementById('contentArea');
      const list = getSales().filter(s => !s.isDeleted);

      function calcSaleTotal(tNo) {
        return getSDetails().filter(d => d.transNo === tNo && !d.isDeleted)
          .reduce((acc, d) => acc + (d.quantity * latestUnitPrice(d.prodCode)), 0);
      }

      const rows = list.map(s => `
        <tr>
          <td class="p-4 font-bold text-gray-900 dark:text-white">${s.transNo}</td>
          <td class="p-4 text-gray-500">${s.salesDate}</td>
          <td class="p-4 font-semibold">${s.custNo}</td>
          <td class="p-4 font-bold text-emerald-500">$${calcSaleTotal(s.transNo).toFixed(2)}</td>
          <td class="p-4 text-right space-x-2">
            <button onclick="openSalesDetails('${s.transNo}')" class="px-3 py-1.5 rounded-xl bg-brand-500/10 text-brand-500 font-bold text-xs">Line Items</button>
            ${can('sales.delete') ? `<button onclick="softDeleteSale('${s.transNo}')" class="px-3 py-1.5 rounded-xl bg-red-500/10 text-red-500 font-bold text-xs">Delete</button>` : ''}
          </td>
        </tr>
      `).join('');

      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-base font-bold text-gray-900 dark:text-white">Sales Management</h2>
            ${can('sales.add') ? `<button onclick="openAddSale()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ New Transaction</button>` : ''}
          </div>

          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60">
            <table class="w-full text-left text-xs">
              <thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold">
                <tr>
                  <th class="p-4">Trans No</th>
                  <th class="p-4">Date</th>
                  <th class="p-4">Customer</th>
                  <th class="p-4">Total Amount</th>
                  <th class="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows}</tbody>
            </table>
          </div>
        </div>
      `;
    }

    function openAddSale() {
      document.getElementById('salesTransNo').value = '';
      document.getElementById('salesDate').value = new Date().toISOString().slice(0,10);
      document.getElementById('salesCustNo').innerHTML = getCustomers().filter(c=>!c.isDeleted).map(c=>`<option value="${c.custNo}">${c.custNo} — ${c.custName}</option>`).join('');
      document.getElementById('salesEmpNo').innerHTML = getEmployees().filter(e=>!e.isDeleted).map(e=>`<option value="${e.empNo}">${e.empNo} — ${e.firstName} ${e.lastName}</option>`).join('');
      openModal('sales');
    }
    function closeSalesModal() { closeModal('sales'); }

    function saveSale(ev) {
      ev.preventDefault();
      const transNo = document.getElementById('salesTransNo').value.trim();
      const salesDate = document.getElementById('salesDate').value;
      const custNo = document.getElementById('salesCustNo').value;
      const empNo = document.getElementById('salesEmpNo').value;

      const list = getSales();
      list.push({ transNo, salesDate, custNo, empNo, isDeleted: false });
      saveSales(list);
      closeSalesModal();
      renderSales();
      showToast('Sale order initialized.', 'success');
    }

    function softDeleteSale(tNo) {
      showConfirmModal('Delete Transaction', `Delete transaction ${tNo}?`, () => {
        const list = getSales();
        const i = list.findIndex(s => s.transNo === tNo);
        if (i >= 0) { list[i].isDeleted = true; saveSales(list); renderSales(); showToast('Transaction deleted.', 'warning'); }
      });
    }

    let selectedTransNo = null;
    function openSalesDetails(transNo) {
      selectedTransNo = transNo;
      document.getElementById('sdListTitle').textContent = `Transaction ${transNo} Line Items`;
      renderSdListContent();
      openModal('sdList');
    }
    function closeSdListModal() { closeModal('sdList'); }

    function renderSdListContent() {
      const list = getSDetails().filter(d => d.transNo === selectedTransNo && !d.isDeleted);
      let total = 0;

      document.getElementById('sdListHead').innerHTML = `
        <th class="p-3">Product</th><th class="p-3">Qty</th><th class="p-3">Unit Price</th><th class="p-3">Subtotal</th>
      `;
      document.getElementById('sdListToolbar').innerHTML = `
        <button onclick="openAddSD('${selectedTransNo}')" class="px-3 py-1.5 rounded-xl bg-brand-600 text-white font-bold text-xs shadow">+ Add Line Item</button>
      `;

      document.getElementById('sdListBody').innerHTML = list.map(d => {
        const up = latestUnitPrice(d.prodCode);
        const sub = d.quantity * up;
        total += sub;
        return `
          <tr>
            <td class="p-3 font-bold">${d.prodCode}</td>
            <td class="p-3">${d.quantity}</td>
            <td class="p-3">$${up.toFixed(2)}</td>
            <td class="p-3 font-bold text-emerald-500">$${sub.toFixed(2)}</td>
          </tr>
        `;
      }).join('');

      document.getElementById('sdListTotal').textContent = `Total Order: $${total.toFixed(2)}`;
    }

    function openAddSD(transNo) {
      document.getElementById('sdTransNo').value = transNo;
      document.getElementById('sdProdCode').innerHTML = getProducts().filter(p=>!p.isDeleted).map(p=>`<option value="${p.prodCode}">${p.prodCode} — ${p.description}</option>`).join('');
      document.getElementById('sdQty').value = 1;
      updateSdPriceHint();
      openModal('sdForm');
    }
    function closeSdFormModal() { closeModal('sdForm'); }

    function updateSdPriceHint() {
      const code = document.getElementById('sdProdCode').value;
      document.getElementById('sdPriceHint').textContent = `Unit Price: $${latestUnitPrice(code).toFixed(2)}`;
    }

    function saveSalesDetail(ev) {
      ev.preventDefault();
      const transNo = document.getElementById('sdTransNo').value;
      const prodCode = document.getElementById('sdProdCode').value;
      const quantity = parseInt(document.getElementById('sdQty').value, 10);

      const list = getSDetails();
      list.push({ transNo, prodCode, quantity, isDeleted: false });
      saveSDetails(list);
      closeSdFormModal();
      renderSdListContent();
      renderSales();
      showToast('Line item added.', 'success');
    }

    // Reports Module
    let selectedReport = 'topCustomers';

    function renderReports() {
      const area = document.getElementById('contentArea');

      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
            <div class="flex items-center gap-2">
              <button onclick="selectedReport='topCustomers'; renderReports()" class="px-3.5 py-1.5 rounded-xl text-xs font-bold ${selectedReport==='topCustomers'?'bg-brand-600 text-white':'bg-gray-100 dark:bg-slate-950 text-gray-500'}">Top Customers</button>
              <button onclick="selectedReport='products'; renderReports()" class="px-3.5 py-1.5 rounded-xl text-xs font-bold ${selectedReport==='products'?'bg-brand-600 text-white':'bg-gray-100 dark:bg-slate-950 text-gray-500'}">Products Master</button>
            </div>

            <div class="flex items-center gap-2">
              <button onclick="window.print()" class="px-3.5 py-2 rounded-xl border border-gray-200 dark:border-gray-800 font-bold text-xs flex items-center gap-2">
                <i class="fa-solid fa-print"></i> Print
              </button>
              <button onclick="window.print()" class="px-3.5 py-2 rounded-xl bg-brand-600 text-white font-bold text-xs shadow flex items-center gap-2">
                <i class="fa-solid fa-file-pdf"></i> Export PDF
              </button>
            </div>
          </div>

          <div id="reportPrintArea" class="p-6 border border-gray-200 dark:border-gray-800 rounded-2xl bg-gray-50 dark:bg-slate-950/60 text-gray-900 dark:text-gray-100">
            <div class="flex justify-between items-center pb-4 mb-4 border-b border-gray-200 dark:border-gray-800">
              <div>
                <h1 class="text-xl font-black">PENTADERP REPORT</h1>
                <p class="text-xs text-gray-500 dark:text-gray-400">Generated: ${new Date().toLocaleDateString()}</p>
              </div>
              <span class="text-xs font-extrabold uppercase px-3 py-1 bg-brand-500/10 text-brand-600 rounded-full">${selectedReport}</span>
            </div>

            ${getReportTableHTML()}
          </div>
        </div>
      `;
    }

    function getReportTableHTML() {
      if (selectedReport === 'topCustomers') {
        const custs = getCustomers().filter(c=>!c.isDeleted);
        return `
          <table class="w-full text-left text-xs">
            <thead class="bg-gray-100 dark:bg-slate-900 text-gray-600 dark:text-gray-400 font-bold uppercase">
              <tr><th class="p-3">Cust No</th><th class="p-3">Customer Name</th><th class="p-3">Terms</th></tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
              ${custs.map(c => `<tr><td class="p-3 font-bold">${c.custNo}</td><td class="p-3">${c.custName}</td><td class="p-3">${c.payterms}</td></tr>`).join('')}
            </tbody>
          </table>
        `;
      } else {
        const prods = getProducts().filter(p=>!p.isDeleted);
        return `
          <table class="w-full text-left text-xs">
            <thead class="bg-gray-100 dark:bg-slate-900 text-gray-600 dark:text-gray-400 font-bold uppercase">
              <tr><th class="p-3">Code</th><th class="p-3">Description</th><th class="p-3">Unit</th><th class="p-3">Price</th></tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
              ${prods.map(p => `<tr><td class="p-3 font-bold">${p.prodCode}</td><td class="p-3">${p.description}</td><td class="p-3">${p.unit}</td><td class="p-3 font-bold">$${latestUnitPrice(p.prodCode).toFixed(2)}</td></tr>`).join('')}
            </tbody>
          </table>
        `;
      }
    }

    // Access Control Views
    function renderUserManagement() {
      const area = document.getElementById('contentArea');
      const users = getUsers();

      const rows = users.map(u => `
        <tr>
          <td class="p-4 font-bold text-gray-900 dark:text-white">${u.firstName} ${u.lastName}</td>
          <td class="p-4 text-gray-500">${u.email}</td>
          <td class="p-4"><span class="px-2.5 py-1 rounded-full text-[10px] font-bold uppercase ${u.role==='superadmin'?'bg-amber-500/10 text-amber-500':(u.role==='admin'?'bg-brand-500/10 text-brand-500':'bg-emerald-500/10 text-emerald-500')}">${u.role}</span></td>
          <td class="p-4"><span class="px-2 py-0.5 rounded text-[10px] font-bold ${u.status==='active'?'bg-emerald-500/10 text-emerald-500':'bg-amber-500/10 text-amber-500'}">${u.status}</span></td>
          <td class="p-4 text-right space-x-2">
            ${u.role === 'user' ? `<button onclick="openUmRights('${u.email}')" class="px-3 py-1.5 rounded-xl bg-brand-500/10 text-brand-500 font-bold text-xs">Rights Matrix</button>` : ''}
            <button onclick="openEditUmUser('${u.email}')" class="px-3 py-1.5 rounded-xl border font-bold text-xs">Edit</button>
          </td>
        </tr>
      `).join('');

      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex items-center justify-between gap-4 mb-6">
            <h2 class="text-base font-bold text-gray-900 dark:text-white">User Management</h2>
            <button onclick="openAddUmUser()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add User</button>
          </div>

          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60">
            <table class="w-full text-left text-xs">
              <thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold">
                <tr>
                  <th class="p-4">Name</th>
                  <th class="p-4">Email</th>
                  <th class="p-4">Role</th>
                  <th class="p-4">Status</th>
                  <th class="p-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows}</tbody>
            </table>
          </div>
        </div>
      `;
    }

    function openAddUmUser() {
      document.getElementById('umUserTitle').textContent = 'Add User Account';
      document.getElementById('umEditEmail').value = '';
      document.getElementById('umFirst').value = ''; document.getElementById('umLast').value = '';
      document.getElementById('umEmail').value = ''; document.getElementById('umEmail').readOnly = false;
      document.getElementById('umRole').innerHTML = '<option value="user">User</option><option value="admin">Admin</option><option value="superadmin">Superadmin</option>';
      openModal('umUser');
    }
    function openEditUmUser(email) {
      const u = findUser(email);
      if (!u) return;
      document.getElementById('umUserTitle').textContent = 'Edit User Account';
      document.getElementById('umEditEmail').value = u.email;
      document.getElementById('umFirst').value = u.firstName; document.getElementById('umLast').value = u.lastName;
      document.getElementById('umEmail').value = u.email; document.getElementById('umEmail').readOnly = true;
      document.getElementById('umRole').innerHTML = '<option value="user">User</option><option value="admin">Admin</option><option value="superadmin">Superadmin</option>';
      document.getElementById('umRole').value = u.role;
      document.getElementById('umStatus').value = u.status || 'active';
      openModal('umUser');
    }
    function closeUmUserModal() { closeModal('umUser'); }

    function saveUmUser(ev) {
      ev.preventDefault();
      const editEmail = document.getElementById('umEditEmail').value;
      const firstName = document.getElementById('umFirst').value.trim();
      const lastName = document.getElementById('umLast').value.trim();
      const email = document.getElementById('umEmail').value.trim();
      const role = document.getElementById('umRole').value;
      const status = document.getElementById('umStatus').value;

      if (editEmail) {
        const u = findUser(editEmail);
        if (u) { u.firstName = firstName; u.lastName = lastName; u.role = role; u.status = status; upsertUser(u); }
      } else {
        upsertUser({ email, firstName, lastName, role, status, perms: role==='user'?sampleUserPerms():fullPerms() });
      }
      closeUmUserModal();
      renderUserManagement();
      showToast('User saved.', 'success');
    }

    let umRightsEmail = null, umRightsDraft = null;
    function openUmRights(email) {
      const u = findUser(email);
      if (!u) return;
      umRightsEmail = email;
      umRightsDraft = { ...(u.perms || sampleUserPerms()) };
      document.getElementById('umRightsTitle').textContent = `Rights — ${u.firstName} ${u.lastName}`;
      renderUmRightsForm();
      openModal('umRights');
    }
    function closeUmRightsModal() { closeModal('umRights'); }

    function renderUmRightsForm() {
      const container = document.getElementById('umRightsBody');
      container.innerHTML = PERM_GROUPS.map(g => `
        <div class="p-4 rounded-2xl border border-gray-200 dark:border-gray-800 bg-gray-50/50 dark:bg-slate-950/50">
          <div class="font-bold text-xs text-gray-900 dark:text-white mb-2">${g.label}</div>
          <div class="grid grid-cols-2 gap-2 text-xs">
            <label class="flex items-center gap-2 cursor-pointer">
              <input type="checkbox" ${umRightsDraft[g.view]?'checked':''} onchange="umRightsDraft['${g.view}']=this.checked" />
              <span>${ALL_PERMS[g.view]}</span>
            </label>
            ${g.items.map(k => `
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" ${umRightsDraft[k]?'checked':''} onchange="umRightsDraft['${k}']=this.checked" />
                <span>${ALL_PERMS[k]}</span>
              </label>
            `).join('')}
          </div>
        </div>
      `).join('');
    }

    function saveUmRights() {
      const u = findUser(umRightsEmail);
      if (u) { u.perms = { ...umRightsDraft }; upsertUser(u); }
      closeUmRightsModal();
      renderUserManagement();
      showToast('Permissions saved.', 'success');
    }

    // Pricing Billing Toggle
    function setBillingCycle(c) {
      const monthlyBtn = document.getElementById('btnMonthly');
      const annualBtn = document.getElementById('btnAnnual');

      if (c === 'monthly') {
        monthlyBtn.className = 'px-4 py-2 rounded-xl text-xs font-bold bg-brand-600 text-white shadow';
        annualBtn.className = 'px-4 py-2 rounded-xl text-xs font-bold text-gray-500 hover:text-gray-900 dark:hover:text-white';
        document.getElementById('priceStarter').textContent = '$49';
        document.getElementById('pricePro').textContent = '$149';
        document.getElementById('priceEnterprise').textContent = '$399';
      } else {
        annualBtn.className = 'px-4 py-2 rounded-xl text-xs font-bold bg-brand-600 text-white shadow';
        monthlyBtn.className = 'px-4 py-2 rounded-xl text-xs font-bold text-gray-500 hover:text-gray-900 dark:hover:text-white';
        document.getElementById('priceStarter').textContent = '$39';
        document.getElementById('pricePro').textContent = '$119';
        document.getElementById('priceEnterprise').textContent = '$319';
      }
    }


    // ===== UI/UX additions =====
    function openProfile(no) {
      const e = getEmployees().find(x => x.empNo === no); if (!e) return;
      const jobs = getJobs(), depts = getDepts();
      const hist = getJobHist().filter(h => h.empNo === no && !h.isDeleted).sort((a, b) => b.effDate.localeCompare(a.effDate));
      const nm = c => (jobs.find(j => j.jobCode === c) || {}).jobDesc || c, dn = c => (depts.find(d => d.deptCode === c) || {}).deptName || c;
      const f = (l, v) => `<div><div class="text-[10px] font-bold uppercase tracking-wider text-gray-400">${l}</div><div class="text-xs font-bold text-gray-900 dark:text-white mt-0.5">${v || '-'}</div></div>`;
      const tl = hist.length ? hist.map((h, i) => `<li class="relative pl-7 pb-5 last:pb-0"><span class="absolute left-0 top-1 w-3 h-3 rounded-full ${i ? 'bg-gray-400 dark:bg-gray-600' : 'bg-brand-500 ring-4 ring-brand-500/20'}"></span><div class="text-[10px] font-bold uppercase tracking-wider text-gray-400">${h.effDate}${i ? '' : ' &middot; Current'}</div><div class="text-xs font-bold text-gray-900 dark:text-white">${nm(h.jobCode)}</div><div class="text-[11px] text-gray-500 dark:text-gray-400">${dn(h.deptCode)} &middot; <span class="font-bold text-emerald-500">$${Number(h.salary).toLocaleString()}</span></div></li>`).join('') : '<li class="text-xs text-gray-400">No job history yet.</li>';
      gid('profileBody').innerHTML = `
        <div class="flex items-center gap-4 mb-6"><div class="w-14 h-14 rounded-2xl bg-gradient-to-tr from-brand-600 to-indigo-500 flex items-center justify-center text-white font-black text-xl shrink-0">${(e.firstName[0] || '?').toUpperCase()}</div>
          <div><h2 class="text-xl font-black text-gray-900 dark:text-white">${e.firstName} ${e.lastName}</h2><p class="text-xs text-gray-500 dark:text-gray-400">${e.empNo}${hist.length ? ' &middot; ' + nm(hist[0].jobCode) : ''}</p></div></div>
        <div class="grid grid-cols-2 gap-4 mb-6">${f('Gender', e.gender)}${f('Birth Date', e.birthDate)}${f('Hire Date', e.hireDate)}${f('Separation Date', e.sepDate)}</div>
        <h3 class="text-xs font-black uppercase tracking-wider text-gray-400 mb-3">Job Timeline</h3>
        <ul class="border-l-2 border-gray-200 dark:border-gray-800 ml-1.5 pl-0">${tl}</ul>`;
      openModal('profile');
    }

    // Empty-state row for any table body with no rows
    new MutationObserver(() => {
      document.querySelectorAll('#contentArea tbody').forEach(tb => {
        if (tb.rows.length) return;
        const n = (tb.closest('table').querySelectorAll('thead th').length) || 5;
        tb.innerHTML = `<tr><td colspan="${n}" class="p-10 text-center"><i class="fa-regular fa-folder-open text-2xl text-gray-300 dark:text-gray-700 mb-2"></i><div class="text-xs font-bold text-gray-500 dark:text-gray-400">No records found</div><div class="text-[11px] text-gray-400 mt-1">Try a different filter or add a new record.</div></td></tr>`;
      });
    }).observe(gid('contentArea'), { childList: true, subtree: true });

    // Customers: search, Active/Inactive/All filter (admins), restore
    let custFilter = 'active', custSearch = '';
    const isAdminRole = () => currentUser && (currentUser.role === 'admin' || currentUser.role === 'superadmin');
    function renderCustomers() {
      const area = gid('contentArea'), adm = isAdminRole(), all = getCustomers();
      let list = adm ? all.filter(c => custFilter === 'all' || (custFilter === 'deleted') === !!c.isDeleted) : all.filter(c => !c.isDeleted);
      const q = custSearch.toLowerCase();
      if (q) list = list.filter(c => [c.custNo, c.custName, c.address, c.payterms].some(v => String(v).toLowerCase().includes(q)));
      const B = (cls, fn, t) => `<button onclick="${fn}" class="px-3 py-1.5 rounded-xl ${cls} font-bold text-xs">${t}</button>`;
      const rows = list.map(c => `<tr class="${c.isDeleted ? 'opacity-60' : ''}">
          <td class="p-4 font-bold text-gray-900 dark:text-white">${c.custNo}</td><td class="p-4 font-semibold">${c.custName}</td><td class="p-4 text-gray-500">${c.address}</td>
          <td class="p-4"><span class="px-3 py-1 rounded-full text-[10px] font-bold bg-gray-100 dark:bg-slate-950">${c.payterms}</span></td>
          ${adm ? `<td class="p-4"><span class="px-2.5 py-1 rounded-full text-[10px] font-bold ${c.isDeleted ? 'bg-red-500/10 text-red-500' : 'bg-emerald-500/10 text-emerald-500'}">${c.isDeleted ? 'Inactive' : 'Active'}</span></td>` : ''}
          <td class="p-4 text-right space-x-2">${c.isDeleted ? (adm ? B('bg-brand-500/10 text-brand-500', `restoreCustomer('${c.custNo}')`, 'Restore') : '') :
            (can('customers.edit') ? B('border border-gray-200 dark:border-gray-800', `openEditCustomer('${c.custNo}')`, 'Edit') : '') + (can('customers.delete') ? B('bg-red-500/10 text-red-500', `softDeleteCustomer('${c.custNo}')`, 'Delete') : '')}</td></tr>`).join('');
      const n = f => all.filter(c => f === 'all' || (f === 'deleted') === !!c.isDeleted).length;
      const tabs = adm ? ['active', 'deleted', 'all'].map(f => `<button onclick="custFilter='${f}';renderCustomers()" class="px-3.5 py-1.5 rounded-xl text-xs font-bold ${custFilter === f ? 'bg-brand-600 text-white' : 'bg-gray-100 dark:bg-slate-950 text-gray-500'}">${{ active: 'Active', deleted: 'Inactive', all: 'All' }[f]} (${n(f)})</button>`).join('') : '';
      area.innerHTML = `
        <div class="glass-panel p-6 rounded-3xl bg-white/80 dark:bg-slate-900/80">
          <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
            <h2 class="text-base font-bold text-gray-900 dark:text-white">Customer Management</h2>
            <div class="flex flex-wrap items-center gap-2">${tabs}
              <input type="text" id="custSearchBox" value="${custSearch.replace(/"/g, '&quot;')}" oninput="custSearch=this.value;renderCustomers();const b=gid('custSearchBox');b.focus();b.setSelectionRange(b.value.length,b.value.length)" placeholder="Search customers..." class="px-4 py-2 rounded-xl border border-gray-200 dark:border-gray-800 bg-white/50 dark:bg-slate-950/50 text-xs outline-none focus:ring-2 focus:ring-brand-500/40" />
              ${can('customers.add') ? `<button onclick="openAddCustomer()" class="px-4 py-2.5 rounded-2xl bg-brand-600 hover:bg-brand-500 text-white font-bold text-xs shadow-lg shadow-brand-600/25">+ Add Customer</button>` : ''}</div>
          </div>
          <div class="overflow-x-auto rounded-2xl border border-gray-200/60 dark:border-gray-800/60"><table class="w-full text-left text-xs">
            <thead class="bg-gray-50 dark:bg-slate-950 text-gray-400 uppercase font-bold"><tr><th class="p-4">Cust No</th><th class="p-4">Customer Name</th><th class="p-4">Address</th><th class="p-4">Terms</th>${adm ? '<th class="p-4">Status</th>' : ''}<th class="p-4 text-right">Actions</th></tr></thead>
            <tbody class="divide-y divide-gray-200/60 dark:divide-gray-800/60">${rows}</tbody></table></div>
        </div>`;
    }
    function restoreCustomer(no) {
      const l = getCustomers(), c = l.find(x => x.custNo === no); if (!c) return;
      c.isDeleted = false; c.stamp = makeStamp('RESTORED'); saveCustomers(l); renderCustomers(); showToast('Customer restored.', 'success');
    }

    const userEmail = document.body.dataset.userEmail;
    if (userEmail) {
      const name = document.body.dataset.userName || userEmail;
      currentUser = {
        email: userEmail,
        name,
        firstName: name.split(/\s+/)[0] || 'User',
        role: 'user'
      };
      showDashboard();
    }

    // Window Resize Event
    window.addEventListener('resize', () => {
      if (!document.getElementById('dashboard').classList.contains('hidden')) {
        renderDashboardRevenueChart();
      }
    });
