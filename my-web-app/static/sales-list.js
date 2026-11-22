const config = window.salesListConfig;
const searchInput = document.querySelector("#sales-search");
const salesBody = document.querySelector("#sales-body");
const salesMessage = document.querySelector("#sales-message");
const customerBalancesBody = document.querySelector("#sales-customer-balances-body");
const customerBalancesMessage = document.querySelector("#sales-customer-balances-message");
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
const saleDetailsDialog = document.querySelector("#sale-details-dialog");
const saleDetailsTitle = document.querySelector("#sale-details-title");
const saleDetailsDate = document.querySelector("#sale-details-date");
const saleDetailsMessage = document.querySelector("#sale-details-message");
const saleDetailsBody = document.querySelector("#sale-details-body");
const saleDetailAdd = document.querySelector("#sale-detail-add");
const saleDetailFormWrap = document.querySelector("#sale-detail-form-wrap");
const saleDetailForm = document.querySelector("#sale-detail-form");
const saleDetailProduct = document.querySelector("#sale-detail-product");
const saleDetailQuantity = document.querySelector("#sale-detail-quantity");
const saleDetailUnitPrice = document.querySelector("#sale-detail-unit-price");
const saleDetailFormError = document.querySelector("#sale-detail-form-error");
const saleDetailSave = document.querySelector("#sale-detail-save");
const saleDetailCancel = document.querySelector("#sale-detail-cancel");
const salePaymentAdd = document.querySelector("#sale-payment-add");
const salePaymentFormWrap = document.querySelector("#sale-payment-form-wrap");
const salePaymentForm = document.querySelector("#sale-payment-form");
const salePaymentDate = document.querySelector("#sale-payment-date");
const salePaymentAmount = document.querySelector("#sale-payment-amount");
const salePaymentSave = document.querySelector("#sale-payment-save");
const salePaymentFormError = document.querySelector("#sale-payment-form-error");
const salePaymentMessage = document.querySelector("#sale-payment-message");
const salePaymentsBody = document.querySelector("#sale-payments-body");
const salePaymentTotal = document.querySelector("#sale-payment-total");
const salePaymentPaid = document.querySelector("#sale-payment-paid");
const salePaymentBalance = document.querySelector("#sale-payment-balance");
const salePaymentStatus = document.querySelector("#sale-payment-status");
let currentStatus = "active";
let currentActions = {create: false};
let currentSaleDetails = null;
let currentSalePayments = null;
let currentTransactionNo = null;
let editingProductCode = null;
let salesRecords = [];
let customerBalanceRecords = [];
let saleDetailActions = null;
let loadedStatus = null;
let saleOptionsLoaded = false;

async function request(url, options = {}) {
  const headers = {
    "Accept": "application/json",
    "Content-Type": "application/json",
    ...options.headers,
  };
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  const method = (options.method || "GET").toUpperCase();
  let response;
  for (let attempt = 0; ; attempt += 1) {
    try {
      response = await fetch(url, {...options, headers});
    } catch {
      if (method === "GET" && attempt === 0) {
        await new Promise((resolve) => window.setTimeout(resolve, 250));
        continue;
      }
      throw new Error("The server is temporarily unreachable. Please try again shortly.");
    }
    if (
      method === "GET" &&
      attempt === 0 &&
      [502, 503, 504].includes(response.status)
    ) {
      await new Promise((resolve) => window.setTimeout(resolve, 250));
      continue;
    }
    break;
  }
  let result;
  try {
    result = await response.json();
  } catch {
    const redirectedToLogin = response.redirected &&
      new URL(response.url, window.location.href).pathname === "/login";
    if (redirectedToLogin) {
      throw new Error("Your session may have expired. Reload the page and sign in again.");
    }
    throw new Error(
      `The server returned a non-JSON response (HTTP ${response.status}). Try again, and contact an administrator if it continues.`,
    );
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

function renderSales(records, detailActions) {
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
    addCell(row, formatBalanceAmount(record.totalAmount), "Total");
    addCell(row, formatBalanceAmount(record.totalPaid), "Paid");
    addCell(row, formatBalanceAmount(record.balance), "Balance");
    addCell(
      row,
      record.paymentStatus ? record.paymentStatus[0].toUpperCase() + record.paymentStatus.slice(1) : "—",
      "Payment Status",
    );
    const detailsCell = addCell(row, "", "Details");
    if (!record.isDeleted) {
      const detailsButton = document.createElement("button");
      detailsButton.type = "button";
      detailsButton.className = "btn btn-secondary sales-detail-open";
      detailsButton.dataset.transactionNo = record.transNo;
      detailsButton.textContent = detailActions?.view ? "Details / payments" : "Payments";
      detailsCell.appendChild(detailsButton);
    } else {
      detailsCell.textContent = "—";
    }
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      addCell(row, record.stamp, "Stamp");
    }
    const actions = document.createElement("td");
    actions.dataset.label = "Actions";
    if (record.isDeleted) {
      if (currentActions.restore) {
        const restoreButton = document.createElement("button");
        restoreButton.type = "button";
        restoreButton.className = "btn btn-secondary";
        restoreButton.dataset.restoreSale = record.transNo;
        restoreButton.textContent = "Restore";
        actions.appendChild(restoreButton);
      }
    } else if (currentActions.delete) {
      const deleteButton = document.createElement("button");
      deleteButton.type = "button";
      deleteButton.className = "btn btn-secondary";
      deleteButton.dataset.deleteSale = record.transNo;
      deleteButton.textContent = "Delete";
      actions.appendChild(deleteButton);
    }
    if (!actions.childElementCount) actions.textContent = "—";
    row.appendChild(actions);
    salesBody.appendChild(row);
  }
}

function formatBalanceAmount(value) {
  return value === null || value === undefined ? "—" : formatPrice(value);
}

function renderCustomerBalances(records) {
  customerBalancesBody.replaceChildren();
  const search = searchInput.value.trim().toLocaleLowerCase();
  const visibleRecords = records.filter((record) =>
    !search ||
    String(record.customerNo || "").toLocaleLowerCase().includes(search) ||
    String(record.customerName || "").toLocaleLowerCase().includes(search)
  );
  for (const record of visibleRecords) {
    const row = document.createElement("tr");
    addCell(
      row,
      `${record.customerName || record.customerNo} (${record.customerNo})`,
      "Customer",
    );
    addCell(row, formatBalanceAmount(record.totalAmount), "Sales Total");
    addCell(row, formatBalanceAmount(record.totalPaid), "Paid");
    addCell(row, formatBalanceAmount(record.balance), "Balance");
    const status = record.status
      ? record.status[0].toUpperCase() + record.status.slice(1)
      : "—";
    addCell(row, status, "Status");
    customerBalancesBody.appendChild(row);
  }
  customerBalancesMessage.textContent = visibleRecords.length
    ? ""
    : search
      ? "No customer balances match this search."
      : "No active customers were found.";
}

function filterSalesRecords() {
  const search = searchInput.value.trim().toLocaleLowerCase();
  if (!search) return salesRecords;
  return salesRecords.filter((record) =>
    [
      record.transNo,
      record.salesDate,
      record.customerName,
      record.salespersonName,
      record.custNo,
      record.empNo,
    ].some((value) => String(value || "").toLocaleLowerCase().includes(search))
  );
}

function renderCurrentSales() {
  renderSales(filterSalesRecords(), saleDetailActions);
  renderCustomerBalances(customerBalanceRecords);
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
  });
  const requestedStatus = currentStatus;
  try {
    const result = await request(`/api/sales?${params}`);
    if (requestedStatus !== currentStatus) return;
    currentActions = result.actions;
    addButton.hidden = !currentActions.create;
    if (!result.actions.saleDetails) {
      salesMessage.textContent = "Apply the Sales Details migration to manage sale line items.";
    }
    salesRecords = result.records;
    customerBalanceRecords = result.customerBalances;
    saleDetailActions = result.actions.saleDetails;
    loadedStatus = requestedStatus;
    fillOptions(saleCustomer, "Choose customer...", result.customers, "customerNo", "customerName");
    fillOptions(saleSalesperson, "Choose salesperson...", result.salespeople, "employeeNo", "fullName");
    salesOptionsMessage.textContent = "";
    saleOptionsLoaded = true;
    addButton.disabled = false;
    renderCurrentSales();
    updateCounts(result.counts);
  } catch (error) {
    if (requestedStatus !== currentStatus) return;
    salesMessage.textContent = error instanceof Error ? error.message : "Sales could not be loaded.";
    salesBody.replaceChildren();
    customerBalancesBody.replaceChildren();
    salesRecords = [];
    customerBalanceRecords = [];
    loadedStatus = requestedStatus;
    if (!saleOptionsLoaded) void loadSaleOptions();
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
    saleOptionsLoaded = true;
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

function formatPrice(value) {
  if (value === null || value === undefined || value === "") return "No price";
  const amount = Number(value);
  return Number.isFinite(amount)
    ? new Intl.NumberFormat("en-PH", {style: "currency", currency: "PHP"}).format(amount)
    : "No price";
}

async function updateSaleStatus(transactionNo, restore) {
  const action = restore ? "restore" : "delete";
  if (!restore && !window.confirm(`Move sale ${transactionNo} to Inactive?`)) return;
  try {
    const result = await request(
      `/api/sales/${encodeURIComponent(transactionNo)}/${action}`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadSales();
  } catch (error) {
    showToast(
      error instanceof Error ? error.message : `Sale could not be ${action}d.`,
      "error",
    );
  }
}

function resetSaleDetailForm() {
  editingProductCode = null;
  saleDetailForm.reset();
  saleDetailFormError.textContent = "";
  saleDetailSave.textContent = "Add Line";
  saleDetailCancel.hidden = true;
  saleDetailUnitPrice.textContent = "—";
  fillSaleDetailProducts();
}

function fillSaleDetailProducts(selectedProduct = null) {
  const products = currentSaleDetails?.products || [];
  saleDetailProduct.replaceChildren(new Option("Choose product...", ""));
  for (const product of products) {
    const label = `${product.description || product.productCode} (${product.productCode})`;
    saleDetailProduct.add(new Option(label, product.productCode));
  }
  if (
    selectedProduct &&
    !products.some((product) => product.productCode === selectedProduct.productCode)
  ) {
    const label = `${selectedProduct.description || selectedProduct.productCode} (${selectedProduct.productCode})`;
    saleDetailProduct.add(new Option(label, selectedProduct.productCode));
  }
  if (selectedProduct) {
    saleDetailProduct.value = selectedProduct.productCode;
  }
}

function updateSaleDetailPrice() {
  const product = currentSaleDetails?.products.find(
    (item) => item.productCode === saleDetailProduct.value,
  );
  saleDetailUnitPrice.textContent = formatPrice(product?.unitPrice);
}

function renderSaleDetails() {
  const details = currentSaleDetails.details || [];
  saleDetailsBody.replaceChildren();
  for (const detail of details) {
    const row = document.createElement("tr");
    addCell(
      row,
      `${detail.description || detail.productCode} (${detail.productCode})`,
      "Product",
    );
    addCell(row, detail.quantity, "Quantity");
    addCell(row, formatPrice(detail.unitPrice), "Unit Price");
    addCell(row, formatPrice(detail.lineAmount), "Line Total");
    const actions = document.createElement("td");
    actions.dataset.label = "Actions";
    if (currentSaleDetails.actions.edit || currentSaleDetails.actions.delete) {
      if (currentSaleDetails.actions.edit) {
        const editButton = document.createElement("button");
        editButton.type = "button";
        editButton.className = "btn btn-secondary";
        editButton.dataset.editProduct = detail.productCode;
        editButton.textContent = "Edit";
        actions.appendChild(editButton);
      }
      if (currentSaleDetails.actions.delete) {
        const deleteButton = document.createElement("button");
        deleteButton.type = "button";
        deleteButton.className = "btn btn-secondary";
        deleteButton.dataset.deleteProduct = detail.productCode;
        deleteButton.textContent = "Delete";
        actions.appendChild(deleteButton);
      }
    } else {
      actions.textContent = "—";
    }
    row.appendChild(actions);
    saleDetailsBody.appendChild(row);
  }
  saleDetailAdd.hidden = !currentSaleDetails.actions.add;
  if (currentSaleDetails.actions.add && !currentSaleDetails.products.length) {
    saleDetailsMessage.textContent = "No active products have a price effective on this sale date.";
  }
  saleDetailFormWrap.hidden = true;
  resetSaleDetailForm();
}

function renderSalePayments() {
  const data = currentSalePayments;
  if (!data) return;
  salePaymentTotal.textContent = formatPrice(data.totalAmount);
  salePaymentPaid.textContent = formatPrice(data.totalPaid);
  salePaymentBalance.textContent = formatPrice(data.balance);
  salePaymentStatus.textContent = data.status || "—";
  salePaymentAdd.hidden = !data.actions.add;
  salePaymentFormWrap.hidden = true;
  salePaymentFormError.textContent = "";
  salePaymentsBody.replaceChildren();
  for (const payment of data.payments) {
    const row = document.createElement("tr");
    addCell(row, payment.receiptNo, "Receipt No");
    addCell(row, payment.paymentDate, "Payment Date");
    addCell(row, formatPrice(payment.amount), "Amount");
    salePaymentsBody.appendChild(row);
  }
  salePaymentMessage.textContent = data.payments.length
    ? ""
    : "No payments have been recorded for this transaction.";
}

async function openSaleDetails(transactionNo) {
  currentTransactionNo = transactionNo;
  currentSaleDetails = null;
  currentSalePayments = null;
  saleDetailsTitle.textContent = `Sale ${transactionNo} line items`;
  saleDetailsDate.textContent = "";
  saleDetailsMessage.textContent = "Loading line items...";
  saleDetailsBody.replaceChildren();
  saleDetailAdd.hidden = true;
  saleDetailFormWrap.hidden = true;
  salePaymentTotal.textContent = "—";
  salePaymentPaid.textContent = "—";
  salePaymentBalance.textContent = "—";
  salePaymentStatus.textContent = "—";
  salePaymentMessage.textContent = "Loading payments...";
  salePaymentAdd.hidden = true;
  salePaymentFormWrap.hidden = true;
  salePaymentsBody.replaceChildren();
  if (!saleDetailsDialog.open) saleDetailsDialog.showModal();
  const encodedTransactionNo = encodeURIComponent(transactionNo);
  const [detailsResult, paymentsResult] = await Promise.allSettled([
    request(`/api/sales/${encodedTransactionNo}/details`),
    request(`/api/sales/${encodedTransactionNo}/payments`),
  ]);
  if (currentTransactionNo !== transactionNo) return;
  if (detailsResult.status === "fulfilled") {
    currentSaleDetails = detailsResult.value;
    saleDetailsDate.textContent = `Sale date: ${currentSaleDetails.salesDate}`;
    saleDetailsMessage.textContent = currentSaleDetails.details.length
      ? ""
      : "This sale has no line items yet.";
    renderSaleDetails();
  } else {
    saleDetailsMessage.textContent = detailsResult.reason instanceof Error
      ? detailsResult.reason.message
      : "Sale details could not be loaded.";
  }
  if (paymentsResult.status === "fulfilled") {
    currentSalePayments = paymentsResult.value;
    renderSalePayments();
  } else {
    salePaymentMessage.textContent = paymentsResult.reason instanceof Error
      ? paymentsResult.reason.message
      : "Sale payments could not be loaded.";
  }
}

function editSaleDetail(productCode) {
  const detail = currentSaleDetails.details.find(
    (item) => item.productCode === productCode,
  );
  if (!detail || !currentSaleDetails.actions.edit) return;
  editingProductCode = productCode;
  saleDetailFormError.textContent = "";
  fillSaleDetailProducts(detail);
  saleDetailQuantity.value = detail.quantity;
  saleDetailSave.textContent = "Save Changes";
  saleDetailCancel.hidden = false;
  saleDetailFormWrap.hidden = false;
  updateSaleDetailPrice();
  saleDetailQuantity.focus();
}

async function saveSaleDetail(event) {
  event.preventDefault();
  if (!currentSaleDetails) return;
  saleDetailFormError.textContent = "";
  saleDetailSave.disabled = true;
  const editing = editingProductCode !== null;
  const path = `/api/sales/${encodeURIComponent(currentSaleDetails.transactionNo)}/details`;
  try {
    const result = await request(
      editing ? `${path}/${encodeURIComponent(editingProductCode)}` : path,
      {
        method: editing ? "PATCH" : "POST",
        body: JSON.stringify({
          productCode: saleDetailProduct.value,
          quantity: saleDetailQuantity.value,
        }),
      },
    );
    saleDetailsMessage.textContent = result.message;
    await openSaleDetails(currentSaleDetails.transactionNo);
    await loadSales();
  } catch (error) {
    saleDetailFormError.textContent = error instanceof Error
      ? error.message
      : "Sale line could not be saved.";
  } finally {
    saleDetailSave.disabled = false;
  }
}

async function saveSalePayment(event) {
  event.preventDefault();
  if (!currentSalePayments?.actions.add || !currentTransactionNo) return;
  salePaymentFormError.textContent = "";
  salePaymentSave.disabled = true;
  try {
    const result = await request(
      `/api/sales/${encodeURIComponent(currentTransactionNo)}/payments`,
      {
        method: "POST",
        body: JSON.stringify({
          paymentDate: salePaymentDate.value,
          amount: salePaymentAmount.value,
        }),
      },
    );
    showToast(result.message);
    await openSaleDetails(currentTransactionNo);
    await loadSales();
  } catch (error) {
    salePaymentFormError.textContent = error instanceof Error
      ? error.message
      : "Payment could not be recorded.";
  } finally {
    salePaymentSave.disabled = false;
  }
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
    await openSaleDetails(result.transactionNo);
  } catch (error) {
    saleError.textContent = error instanceof Error ? error.message : "Sale could not be created.";
  } finally {
    saleSave.disabled = false;
  }
}

addButton.addEventListener("click", openSaleDialog);
salesBody.addEventListener("click", (event) => {
  const deleteButton = event.target.closest("[data-delete-sale]");
  if (deleteButton && currentActions.delete) {
    updateSaleStatus(deleteButton.dataset.deleteSale, false);
    return;
  }
  const restoreButton = event.target.closest("[data-restore-sale]");
  if (restoreButton && currentActions.restore) {
    updateSaleStatus(restoreButton.dataset.restoreSale, true);
    return;
  }
  const button = event.target.closest("[data-transaction-no]");
  if (button) openSaleDetails(button.dataset.transactionNo);
});
document.querySelector("#sale-cancel").addEventListener("click", () => saleDialog.close());
document.querySelectorAll('[data-dialog-close="sale-dialog"]').forEach((button) => {
  button.addEventListener("click", () => saleDialog.close());
});
saleForm.addEventListener("submit", createSale);
saleDetailAdd.addEventListener("click", () => {
  if (!currentSaleDetails?.actions.add) return;
  resetSaleDetailForm();
  saleDetailFormWrap.hidden = false;
  saleDetailQuantity.focus();
});
saleDetailForm.addEventListener("submit", saveSaleDetail);
saleDetailProduct.addEventListener("change", updateSaleDetailPrice);
saleDetailCancel.addEventListener("click", () => {
  saleDetailFormWrap.hidden = true;
  resetSaleDetailForm();
});
document.querySelectorAll('[data-dialog-close="sale-details-dialog"]').forEach((button) => {
  button.addEventListener("click", () => {
    currentTransactionNo = null;
    saleDetailsDialog.close();
  });
});
saleDetailsDialog.addEventListener("close", () => {
  currentTransactionNo = null;
});
salePaymentAdd.addEventListener("click", () => {
  if (!currentSalePayments?.actions.add) return;
  salePaymentForm.reset();
  salePaymentDate.value = config.today;
  salePaymentFormError.textContent = "";
  salePaymentFormWrap.hidden = false;
  salePaymentDate.focus();
});
salePaymentForm.addEventListener("submit", saveSalePayment);
document.querySelector("#sale-payment-cancel").addEventListener("click", () => {
  salePaymentFormWrap.hidden = true;
  salePaymentForm.reset();
  salePaymentFormError.textContent = "";
});
saleDetailsBody.addEventListener("click", async (event) => {
  const editButton = event.target.closest("[data-edit-product]");
  if (editButton) {
    editSaleDetail(editButton.dataset.editProduct);
    return;
  }
  const deleteButton = event.target.closest("[data-delete-product]");
  if (!deleteButton || !currentSaleDetails?.actions.delete) return;
  const productCode = deleteButton.dataset.deleteProduct;
  if (!window.confirm(`Delete the ${productCode} line item from this sale?`)) return;
  try {
    const result = await request(
      `/api/sales/${encodeURIComponent(currentSaleDetails.transactionNo)}/details/${encodeURIComponent(productCode)}`,
      {method: "DELETE"},
    );
    saleDetailsMessage.textContent = result.message;
    const transactionNo = currentSaleDetails.transactionNo;
    await openSaleDetails(transactionNo);
    await loadSales();
  } catch (error) {
    saleDetailsMessage.textContent = error instanceof Error
      ? error.message
      : "Sale line could not be deleted.";
  }
});
searchInput.addEventListener("input", () => {
  if (loadedStatus === currentStatus) {
    renderCurrentSales();
  }
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
