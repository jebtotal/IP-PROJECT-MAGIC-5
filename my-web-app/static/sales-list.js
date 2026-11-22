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
let currentStatus = "active";
let currentActions = {create: false};
let currentSaleDetails = null;
let editingProductCode = null;
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
    const detailsCell = addCell(row, "", "Details");
    if (detailActions?.view && !record.isDeleted) {
      const detailsButton = document.createElement("button");
      detailsButton.type = "button";
      detailsButton.className = "btn btn-secondary sales-detail-open";
      detailsButton.dataset.transactionNo = record.transNo;
      detailsButton.textContent = "Line items";
      detailsCell.appendChild(detailsButton);
    } else {
      detailsCell.textContent = "—";
    }
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
    if (!result.actions.saleDetails) {
      salesMessage.textContent = "Apply the Sales Details migration to manage sale line items.";
    }
    renderSales(result.records, result.actions.saleDetails);
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

function formatPrice(value) {
  if (value === null || value === undefined || value === "") return "No price";
  const amount = Number(value);
  return Number.isFinite(amount)
    ? new Intl.NumberFormat("en-PH", {style: "currency", currency: "PHP"}).format(amount)
    : "No price";
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

async function openSaleDetails(transactionNo) {
  currentSaleDetails = null;
  saleDetailsTitle.textContent = `Sale ${transactionNo} line items`;
  saleDetailsDate.textContent = "";
  saleDetailsMessage.textContent = "Loading line items...";
  saleDetailsBody.replaceChildren();
  saleDetailAdd.hidden = true;
  saleDetailFormWrap.hidden = true;
  if (!saleDetailsDialog.open) saleDetailsDialog.showModal();
  try {
    currentSaleDetails = await request(
      `/api/sales/${encodeURIComponent(transactionNo)}/details`,
    );
    saleDetailsDate.textContent = `Sale date: ${currentSaleDetails.salesDate}`;
    saleDetailsMessage.textContent = currentSaleDetails.details.length
      ? ""
      : "This sale has no line items yet.";
    renderSaleDetails();
  } catch (error) {
    saleDetailsMessage.textContent = error instanceof Error
      ? error.message
      : "Sale details could not be loaded.";
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
  button.addEventListener("click", () => saleDetailsDialog.close());
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
