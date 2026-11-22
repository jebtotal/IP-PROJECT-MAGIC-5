const config = window.salesListConfig;
const searchInput = document.querySelector("#sales-search");
const salesBody = document.querySelector("#sales-body");
const salesMessage = document.querySelector("#sales-message");
const salesOptionsMessage = document.querySelector("#sales-options-message");
const addButton = document.querySelector("#sale-add");
const salesTabs = document.querySelector("#sales-tabs");
const saleDialog = document.querySelector("#sale-dialog");
const saleForm = document.querySelector("#sale-form");
const saleDate = document.querySelector("#sale-date");
const saleCustomer = document.querySelector("#sale-customer");
const saleSalesperson = document.querySelector("#sale-salesperson");
const saleError = document.querySelector("#sale-form-error");
const saleSave = document.querySelector("#sale-save");
let currentStatus = "active";
let currentActions = {create: false};
let searchTimer;

async function request(url, options = {}) {
  const headers = {"Content-Type": "application/json", ...options.headers};
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  const response = await fetch(url, {...options, headers});
  let result;
  try {
    result = await response.json();
  } catch {
    throw new Error("The server returned an invalid response.");
  }
  if (!response.ok) throw new Error(result.error || "Request could not be completed.");
  return result;
}

function showToast(message) {
  const toast = document.createElement("p");
  toast.className = "toast-message toast-success";
  toast.textContent = message;
  document.querySelector("#toast-container").appendChild(toast);
  window.setTimeout(() => toast.remove(), 3500);
}

function addCell(row, value, label) {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value || "—";
  row.appendChild(cell);
  return cell;
}

function renderSales(records) {
  salesBody.replaceChildren();
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    addCell(row, record.transNo, "Transaction No");
    addCell(row, record.salesDate, "Sale Date");
    addCell(
      row,
      record.customerName
        ? `${record.customerName} (${record.custNo})`
        : record.custNo,
      "Customer",
    );
    addCell(
      row,
      record.salespersonName
        ? `${record.salespersonName} (${record.empNo})`
        : record.empNo,
      "Salesperson",
    );
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      addCell(row, record.stamp, "Stamp");
    }
    salesBody.appendChild(row);
  }
}

function updateCounts(counts) {
  if (!config.isAdmin || !counts) return;
  for (const status of ["active", "inactive", "all"]) {
    const counter = document.querySelector(`[data-count="${status}"]`);
    if (counter) counter.textContent = counts[status] ?? 0;
  }
}

async function loadSales() {
  salesMessage.textContent = "";
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
    search: searchInput.value.trim(),
  });
  try {
    const result = await request(`/api/sales?${params}`);
    currentActions = result.actions;
    addButton.hidden = !currentActions.create;
    renderSales(result.records);
    updateCounts(result.counts);
  } catch (error) {
    salesMessage.textContent = error instanceof Error ? error.message : "Sales could not be loaded.";
    salesBody.replaceChildren();
  }
}

function fillOptions(select, placeholder, options, valueField, labelField) {
  select.replaceChildren(new Option(placeholder, ""));
  for (const option of options) {
    const label = option[labelField]
      ? `${option[labelField]} (${option[valueField]})`
      : option[valueField];
    select.add(new Option(label, option[valueField]));
  }
}

async function loadSaleOptions() {
  saleCustomer.replaceChildren(new Option("Loading customers...", ""));
  saleSalesperson.replaceChildren(new Option("Loading salespeople...", ""));
  try {
    const result = await request("/api/sales/options");
    fillOptions(saleCustomer, "Choose customer...", result.customers, "customerNo", "customerName");
    fillOptions(saleSalesperson, "Choose salesperson...", result.salespeople, "employeeNo", "fullName");
    salesOptionsMessage.textContent = "";
    addButton.disabled = false;
  } catch (error) {
    const message = error instanceof Error ? error.message : "Sale choices could not be loaded.";
    salesOptionsMessage.textContent = message;
    fillOptions(saleCustomer, message, [], "customerNo", "customerName");
    fillOptions(saleSalesperson, message, [], "employeeNo", "fullName");
    addButton.disabled = true;
  }
}

function openSaleDialog() {
  saleError.textContent = "";
  saleDate.value = config.today;
  saleDialog.showModal();
  saleDate.focus();
}

async function createSale(event) {
  event.preventDefault();
  saleError.textContent = "";
  saleSave.disabled = true;
  try {
    const result = await request("/api/sales", {
      method: "POST",
      body: JSON.stringify({
        salesDate: saleDate.value,
        customerNo: saleCustomer.value,
        employeeNo: saleSalesperson.value,
      }),
    });
    saleDialog.close();
    showToast(result.message);
    await loadSales();
  } catch (error) {
    saleError.textContent = error instanceof Error ? error.message : "Sale could not be created.";
  } finally {
    saleSave.disabled = false;
  }
}

addButton.addEventListener("click", openSaleDialog);
document.querySelector("#sale-cancel").addEventListener("click", () => saleDialog.close());
document.querySelectorAll('[data-dialog-close="sale-dialog"]').forEach((button) => {
  button.addEventListener("click", () => saleDialog.close());
});
saleForm.addEventListener("submit", createSale);
searchInput.addEventListener("input", () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(loadSales, 180);
});
salesTabs?.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentStatus = tab.dataset.status;
  salesTabs.querySelectorAll(".record-tab").forEach((button) => {
    button.classList.toggle("is-active", button === tab);
    button.setAttribute("aria-selected", String(button === tab));
  });
  loadSales();
});

addButton.disabled = true;
loadSales();
loadSaleOptions();
