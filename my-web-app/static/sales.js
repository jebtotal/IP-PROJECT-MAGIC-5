const config = window.salesConfig;
const salesBody = document.querySelector("#sales-body");
const salesMessage = document.querySelector("#sales-message");
const saleSearch = document.querySelector("#sales-search");
const saleAdd = document.querySelector("#sale-add");
const salesTabs = document.querySelector("#sales-tabs");
const listPanel = document.querySelector("#sales-list-panel");
const detailsPanel = document.querySelector("#sale-details-panel");
const saleDialog = document.querySelector("#sale-dialog");
const saleForm = document.querySelector("#sale-form");
const saleFormError = document.querySelector("#sale-form-error");
const saleSave = document.querySelector("#sale-save");
const detailDialog = document.querySelector("#detail-dialog");
const detailForm = document.querySelector("#detail-form");
const detailFormError = document.querySelector("#detail-form-error");
const detailSave = document.querySelector("#detail-save");
const paymentDialog = document.querySelector("#payment-dialog");
const paymentForm = document.querySelector("#payment-form");
const paymentFormError = document.querySelector("#payment-form-error");
const paymentSave = document.querySelector("#payment-save");
let currentStatus = "active";
let currentActions = {
  sales: {create: false, edit: false, delete: false},
  details: {view: false, create: false, edit: false, delete: false},
  payments: {create: false, edit: false, delete: false},
};
let lookups = {customers: [], employees: [], products: []};
let selectedSale = null;
let editingSale = null;
let editingDetail = null;
let editingPayment = null;
let searchTimer;

async function request(url, options = {}) {
  const headers = {"Content-Type": "application/json", ...options.headers};
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  const response = await fetch(url, {...options, headers});
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || "Request could not be completed.");
  return result;
}

function showToast(message, type = "success") {
  const toast = document.createElement("p");
  toast.className = `toast-message toast-${type}`;
  toast.textContent = message;
  document.querySelector("#toast-container").appendChild(toast);
  window.setTimeout(() => toast.remove(), 3500);
}

function cell(row, value, label, title = "") {
  const item = document.createElement("td");
  item.dataset.label = label;
  item.textContent = value === undefined || value === null || value === "" ? "—" : value;
  if (title) item.title = title;
  row.appendChild(item);
  return item;
}

function button(container, label, handler, danger = false) {
  const item = document.createElement("button");
  item.type = "button";
  item.className = danger ? "btn btn-danger" : "btn btn-secondary";
  item.textContent = label;
  item.addEventListener("click", handler);
  container.appendChild(item);
}

function money(value) {
  const number = Number(value);
  return Number.isFinite(number)
    ? `$${number.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`
    : "—";
}

function todayLocal() {
  const date = new Date();
  return [
    date.getFullYear(),
    String(date.getMonth() + 1).padStart(2, "0"),
    String(date.getDate()).padStart(2, "0"),
  ].join("-");
}

function fillSelect(select, items, valueKey, labelFor) {
  select.replaceChildren();
  const prompt = document.createElement("option");
  prompt.value = "";
  prompt.textContent = "Choose...";
  select.appendChild(prompt);
  for (const item of items) {
    const option = document.createElement("option");
    option.value = item[valueKey];
    option.textContent = labelFor(item);
    select.appendChild(option);
  }
}

async function loadLookups() {
  try {
    lookups = await request("/api/sales/lookups");
  } catch (error) {
    salesMessage.textContent = error instanceof Error ? error.message : "Sales choices could not be loaded.";
  }
}

function updateCounts(counts) {
  if (!config.isAdmin || !counts) return;
  for (const status of ["active", "inactive", "all"]) {
    const counter = document.querySelector(`[data-count="${status}"]`);
    if (counter) counter.textContent = counts[status] ?? 0;
  }
}

function renderSales(records) {
  salesBody.replaceChildren();
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    cell(row, record.transNo, "Transaction");
    cell(row, record.salesDate, "Date");
    cell(row, record.customerName || record.custNo, "Customer");
    cell(row, record.employeeName || record.empNo, "Employee");
    cell(row, money(record.totalAmount), "Total");
    cell(row, money(record.totalPaid), "Paid");
    cell(row, money(record.balance), "Balance");
    const statusCell = cell(row, "", "Payment Status");
    const badge = document.createElement("span");
    badge.className = `status-badge ${record.paymentStatus === "paid" ? "status-approved" : "status-pending"}`;
    badge.textContent = record.paymentStatus || "unpaid";
    statusCell.replaceChildren(badge);
    if (config.isAdmin) cell(row, record.stamp, "Stamp", record.stamp || "");
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (currentActions.details.view) {
      button(actions, "Details", () => openSale(record));
    }
    if (record.isDeleted) {
      if (config.isAdmin && currentActions.sales.delete) {
        button(actions, "Restore", () => changeSaleStatus(record, "restore"));
      }
    } else {
      if (currentActions.sales.edit) button(actions, "Edit", () => openSaleDialog(record));
      if (currentActions.sales.delete) {
        button(actions, "Delete", () => changeSaleStatus(record, "delete"), true);
      }
    }
    actionCell.appendChild(actions);
    row.appendChild(actionCell);
    salesBody.appendChild(row);
  }
}

async function loadSales() {
  salesMessage.textContent = "";
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
    search: saleSearch.value.trim(),
  });
  try {
    const result = await request(`/api/sales?${params}`);
    currentActions = result.actions;
    saleAdd.hidden = !currentActions.sales.create;
    renderSales(result.records);
    updateCounts(result.counts);
  } catch (error) {
    salesMessage.textContent = error instanceof Error ? error.message : "Sales could not be loaded.";
    salesBody.replaceChildren();
  }
}

function openSaleDialog(record = null) {
  editingSale = record;
  saleFormError.textContent = "";
  document.querySelector("#sale-dialog-title").textContent = record ? "Edit Sale" : "New Sale";
  saleSave.textContent = record ? "Save Changes" : "Create Sale";
  fillSelect(document.querySelector("#sale-customer"), lookups.customers, "custNo", (item) => `${item.custNo} — ${item.custName || ""}`);
  fillSelect(document.querySelector("#sale-employee"), lookups.employees, "empNo", (item) => `${item.empNo} — ${item.name}`);
  document.querySelector("#sale-date").value = record?.salesDate || todayLocal();
  document.querySelector("#sale-customer").value = record?.custNo || "";
  document.querySelector("#sale-employee").value = record?.empNo || "";
  saleDialog.showModal();
}

async function saveSale(event) {
  event.preventDefault();
  saleFormError.textContent = "";
  saleSave.disabled = true;
  const reopenDetails = Boolean(editingSale && !detailsPanel.hidden);
  const body = {
    salesDate: document.querySelector("#sale-date").value,
    custNo: document.querySelector("#sale-customer").value,
    empNo: document.querySelector("#sale-employee").value,
  };
  try {
    const url = editingSale
      ? `/api/sales/${encodeURIComponent(editingSale.transNo)}`
      : "/api/sales";
    const result = await request(url, {
      method: editingSale ? "PATCH" : "POST",
      body: JSON.stringify(body),
    });
    saleDialog.close();
    showToast(result.message);
    await loadSales();
    if (reopenDetails) await openSale({...editingSale, ...body});
  } catch (error) {
    saleFormError.textContent = error instanceof Error ? error.message : "Sale could not be saved.";
  } finally {
    saleSave.disabled = false;
  }
}

async function changeSaleStatus(record, action) {
  const prompt = action === "delete"
    ? `Move sale ${record.transNo} to Inactive?`
    : `Restore sale ${record.transNo}?`;
  if (!(await window.confirmAction(prompt))) return;
  try {
    const result = await request(`/api/sales/${encodeURIComponent(record.transNo)}/${action}`, {method: "PATCH"});
    showToast(result.message);
    await loadSales();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Sale status could not be changed.", "error");
  }
}

async function openSale(record) {
  selectedSale = record;
  listPanel.hidden = true;
  detailsPanel.hidden = false;
  document.querySelector("#sale-detail-title").textContent = `Transaction ${record.transNo}`;
  document.querySelector("#sale-detail-subtitle").textContent = `${record.salesDate || ""} · ${record.customerName || record.custNo || ""}`;
  document.querySelector("#details-message").textContent = "Loading sale details...";
  try {
    const status = record.isDeleted ? "?status=inactive" : "";
    const result = await request(`/api/sales/${encodeURIComponent(record.transNo)}${status}`);
    selectedSale = {...result.sale, isDeleted: result.sale.isDeleted};
    currentActions = result.actions;
    document.querySelector("#sale-detail-title").textContent = `Transaction ${result.sale.transNo}`;
    document.querySelector("#sale-detail-subtitle").textContent = `${result.sale.salesDate || ""} · ${record.customerName || result.sale.custNo || ""} · ${record.employeeName || result.sale.empNo || ""}`;
    document.querySelector("#sale-total").textContent = money(result.totalAmount);
    document.querySelector("#sale-paid").textContent = money(result.totalPaid);
    document.querySelector("#sale-balance").textContent = money(result.balance);
    document.querySelector("#sale-payment-status").textContent = result.paymentStatus;
    document.querySelector("#sale-edit").hidden = !result.actions.sales.edit || result.sale.isDeleted;
    document.querySelector("#detail-add").hidden = !result.actions.details.create || result.sale.isDeleted;
    document.querySelector("#payment-add").hidden = !result.actions.payments.create || result.sale.isDeleted;
    renderDetails(result.lines, result.is_admin);
    renderPayments(result.payments, result.is_admin);
    document.querySelector("#details-message").textContent = result.lines.length ? "" : "No sale details have been added.";
  } catch (error) {
    document.querySelector("#details-message").textContent = error instanceof Error ? error.message : "Sale details could not be loaded.";
  }
}

function renderDetails(lines, isAdmin) {
  const body = document.querySelector("#details-body");
  body.replaceChildren();
  for (const line of lines) {
    const row = document.createElement("tr");
    if (line.isDeleted) row.classList.add("record-deleted");
    cell(row, line.prodCode, "Product");
    cell(row, line.description, "Description");
    cell(row, line.quantity, "Quantity");
    cell(row, money(line.unitPrice), "Unit Price");
    cell(row, money(line.lineAmount), "Line Total");
    if (isAdmin) {
      const state = line.isDeleted ? `Inactive${line.stamp ? ` · ${line.stamp}` : ""}` : `Active${line.stamp ? ` · ${line.stamp}` : ""}`;
      cell(row, state, "Status / Stamp");
    }
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (line.isDeleted) {
      if (isAdmin && currentActions.details.delete) {
        button(actions, "Restore", () => changeDetailStatus(line, "restore"));
      }
    } else {
      if (currentActions.details.edit) button(actions, "Edit", () => openDetailDialog(line));
      if (currentActions.details.delete) button(actions, "Delete", () => changeDetailStatus(line, "delete"), true);
    }
    if (actions.childElementCount) actionCell.appendChild(actions);
    else actionCell.textContent = "—";
    row.appendChild(actionCell);
    body.appendChild(row);
  }
}

function renderPayments(payments, isAdmin) {
  const body = document.querySelector("#payments-body");
  body.replaceChildren();
  for (const payment of payments) {
    const row = document.createElement("tr");
    if (payment.isDeleted) row.classList.add("record-deleted");
    cell(row, payment.orNo, "Receipt No.");
    cell(row, payment.payDate, "Payment Date");
    cell(row, money(payment.amount), "Amount");
    if (isAdmin) {
      const state = payment.isDeleted ? `Inactive${payment.stamp ? ` · ${payment.stamp}` : ""}` : `Active${payment.stamp ? ` · ${payment.stamp}` : ""}`;
      cell(row, state, "Status / Stamp");
    }
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (payment.isDeleted) {
      if (isAdmin && currentActions.payments.delete) {
        button(actions, "Restore", () => changePaymentStatus(payment, "restore"));
      }
    } else {
      if (currentActions.payments.edit) button(actions, "Edit", () => openPaymentDialog(payment));
      if (currentActions.payments.delete) button(actions, "Delete", () => changePaymentStatus(payment, "delete"), true);
    }
    if (actions.childElementCount) actionCell.appendChild(actions);
    else actionCell.textContent = "—";
    row.appendChild(actionCell);
    body.appendChild(row);
  }
}

function openDetailDialog(line = null) {
  editingDetail = line;
  detailFormError.textContent = "";
  document.querySelector("#detail-dialog-title").textContent = line ? "Edit Sale Detail" : "Add Product";
  detailSave.textContent = line ? "Save Changes" : "Add Product";
  const productSelect = document.querySelector("#detail-product");
  fillSelect(productSelect, lookups.products, "prodCode", (item) => `${item.prodCode} — ${item.description || ""} (${item.currentPrice ? money(item.currentPrice) : "No current price"})`);
  productSelect.disabled = Boolean(line);
  document.querySelector("#detail-quantity").value = line?.quantity || "";
  if (line) productSelect.value = line.prodCode;
  detailDialog.showModal();
}

async function saveDetail(event) {
  event.preventDefault();
  detailFormError.textContent = "";
  detailSave.disabled = true;
  const body = {quantity: document.querySelector("#detail-quantity").value};
  let url = `/api/sales/${encodeURIComponent(selectedSale.transNo)}/details`;
  let method = "POST";
  if (editingDetail) {
    url += `/${encodeURIComponent(editingDetail.prodCode)}`;
    method = "PATCH";
  } else {
    body.prodCode = document.querySelector("#detail-product").value;
  }
  try {
    const result = await request(url, {method, body: JSON.stringify(body)});
    detailDialog.close();
    showToast(result.message);
    await openSale(selectedSale);
    await loadSales();
  } catch (error) {
    detailFormError.textContent = error instanceof Error ? error.message : "Sale detail could not be saved.";
  } finally {
    detailSave.disabled = false;
  }
}

async function changeDetailStatus(line, action) {
  const prompt = action === "delete" ? `Move ${line.prodCode} to Inactive?` : `Restore ${line.prodCode}?`;
  if (!(await window.confirmAction(prompt))) return;
  try {
    const result = await request(
      `/api/sales/${encodeURIComponent(selectedSale.transNo)}/details/${encodeURIComponent(line.prodCode)}/${action}`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await openSale(selectedSale);
    await loadSales();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Sale detail could not be changed.", "error");
  }
}

function openPaymentDialog(payment = null) {
  editingPayment = payment;
  paymentFormError.textContent = "";
  document.querySelector("#payment-dialog-title").textContent = payment ? "Edit Payment" : "Add Payment";
  paymentSave.textContent = payment ? "Save Changes" : "Add Payment";
  document.querySelector("#payment-date").value = payment?.payDate || todayLocal();
  document.querySelector("#payment-amount").value = payment?.amount || "";
  paymentDialog.showModal();
}

async function savePayment(event) {
  event.preventDefault();
  paymentFormError.textContent = "";
  paymentSave.disabled = true;
  const body = {
    payDate: document.querySelector("#payment-date").value,
    amount: document.querySelector("#payment-amount").value,
  };
  let url = `/api/sales/${encodeURIComponent(selectedSale.transNo)}/payments`;
  let method = "POST";
  if (editingPayment) {
    url += `/${encodeURIComponent(editingPayment.orNo)}`;
    method = "PATCH";
  }
  try {
    const result = await request(url, {method, body: JSON.stringify(body)});
    paymentDialog.close();
    showToast(result.message);
    await openSale(selectedSale);
    await loadSales();
  } catch (error) {
    paymentFormError.textContent = error instanceof Error ? error.message : "Payment could not be saved.";
  } finally {
    paymentSave.disabled = false;
  }
}

async function changePaymentStatus(payment, action) {
  const prompt = action === "delete" ? `Move receipt ${payment.orNo} to Inactive?` : `Restore receipt ${payment.orNo}?`;
  if (!(await window.confirmAction(prompt))) return;
  try {
    const result = await request(
      `/api/sales/${encodeURIComponent(selectedSale.transNo)}/payments/${encodeURIComponent(payment.orNo)}/${action}`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await openSale(selectedSale);
    await loadSales();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Payment could not be changed.", "error");
  }
}

saleAdd.addEventListener("click", () => openSaleDialog());
saleForm.addEventListener("submit", saveSale);
document.querySelector("#sale-cancel").addEventListener("click", () => saleDialog.close());
document.querySelector("#sale-edit").addEventListener("click", () => openSaleDialog(selectedSale));
document.querySelector("#sale-back").addEventListener("click", () => {
  detailsPanel.hidden = true;
  listPanel.hidden = false;
});
document.querySelector("#detail-add").addEventListener("click", () => openDetailDialog());
detailForm.addEventListener("submit", saveDetail);
document.querySelector("#detail-cancel").addEventListener("click", () => detailDialog.close());
document.querySelector("#payment-add").addEventListener("click", () => openPaymentDialog());
paymentForm.addEventListener("submit", savePayment);
document.querySelector("#payment-cancel").addEventListener("click", () => paymentDialog.close());
for (const buttonElement of document.querySelectorAll("[data-dialog-close]")) {
  buttonElement.addEventListener("click", () => {
    document.querySelector(`#${buttonElement.dataset.dialogClose}`)?.close();
  });
}
saleSearch.addEventListener("input", () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(loadSales, 200);
});
salesTabs?.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentStatus = tab.dataset.status;
  salesTabs.querySelectorAll("[data-status]").forEach((item) => {
    const active = item === tab;
    item.classList.toggle("is-active", active);
    item.setAttribute("aria-selected", String(active));
  });
  loadSales();
});

Promise.all([
  config.canLoadLookups ? loadLookups() : Promise.resolve(),
  loadSales(),
]);
