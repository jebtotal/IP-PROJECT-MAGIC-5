const config = window.priceHistoryConfig;
const searchInput = document.querySelector("#price-search");
const pricesBody = document.querySelector("#prices-body");
const pricesMessage = document.querySelector("#prices-message");
const addButton = document.querySelector("#price-add");
const priceDialog = document.querySelector("#price-dialog");
const priceForm = document.querySelector("#price-form");
const priceDate = document.querySelector("#price-effective-date");
const priceAmount = document.querySelector("#price-unit-price");
const priceTitle = document.querySelector("#price-dialog-title");
const priceError = document.querySelector("#price-form-error");
const saveButton = document.querySelector("#price-save");
const priceTabs = document.querySelector("#price-tabs");
let currentStatus = "active";
let currentActions = {create: false, edit: false, delete: false};
let editingRecord = null;
let searchTimer;

async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: {"Content-Type": "application/json", ...options.headers},
    ...options,
  });
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

function addCell(row, value, label) {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value || "—";
  row.appendChild(cell);
  return cell;
}

function addActionButton(actions, label, handler, danger = false) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = danger ? "btn btn-danger" : "btn btn-secondary";
  button.textContent = label;
  button.addEventListener("click", handler);
  actions.appendChild(button);
}

function renderPrices(records) {
  pricesBody.replaceChildren();
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    addCell(row, record.effDate, "Effective Date");
    addCell(row, record.unitPrice, "Unit Price");
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      addCell(row, record.stamp, "Stamp");
    }

    const actionsCell = document.createElement("td");
    actionsCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (record.isDeleted) {
      if (config.isAdmin && currentActions.delete) {
        addActionButton(actions, "Restore", () => restorePrice(record));
      }
    } else {
      if (currentActions.edit) {
        addActionButton(actions, "Edit", () => openPriceDialog(record));
      }
      if (currentActions.delete) {
        addActionButton(actions, "Delete", () => deletePrice(record), true);
      }
    }
    if (!actions.childElementCount) {
      actionsCell.textContent = "—";
    } else {
      actionsCell.appendChild(actions);
    }
    row.appendChild(actionsCell);
    pricesBody.appendChild(row);
  }
}

function updateCounts(counts) {
  if (!config.isAdmin || !counts) return;
  for (const status of ["active", "inactive", "all"]) {
    const counter = document.querySelector(`[data-count="${status}"]`);
    if (counter) counter.textContent = counts[status] ?? 0;
  }
}

async function loadPrices() {
  pricesMessage.textContent = "";
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
    search: searchInput.value.trim(),
  });
  try {
    const result = await request(
      `/api/products/${encodeURIComponent(config.productCode)}/price-history?${params}`,
    );
    currentActions = result.actions;
    addButton.hidden = !currentActions.create;
    renderPrices(result.records);
    updateCounts(result.counts);
  } catch (error) {
    pricesMessage.textContent = error instanceof Error
      ? error.message
      : "Price history could not be loaded.";
    pricesBody.replaceChildren();
  }
}

function openPriceDialog(record = null) {
  editingRecord = record;
  priceError.textContent = "";
  priceTitle.textContent = record ? "Edit price" : "Add price";
  saveButton.textContent = record ? "Save changes" : "Add price";
  priceDate.value = record?.effDate || "";
  priceAmount.value = record?.unitPrice || "";
  priceDialog.showModal();
  priceDate.focus();
}

async function savePrice(event) {
  event.preventDefault();
  priceError.textContent = "";
  saveButton.disabled = true;
  const url = editingRecord
    ? `/api/products/${encodeURIComponent(config.productCode)}/price-history/${encodeURIComponent(editingRecord.effDate)}`
    : `/api/products/${encodeURIComponent(config.productCode)}/price-history`;
  try {
    const result = await request(url, {
      method: editingRecord ? "PATCH" : "POST",
      body: JSON.stringify({
        effDate: priceDate.value,
        unitPrice: priceAmount.value,
      }),
    });
    priceDialog.close();
    showToast(result.message);
    await loadPrices();
  } catch (error) {
    priceError.textContent = error instanceof Error
      ? error.message
      : "Price could not be saved.";
  } finally {
    saveButton.disabled = false;
  }
}

async function deletePrice(record) {
  if (!(await window.confirmAction(`Move the ${record.effDate} price to Inactive?`))) return;
  try {
    const result = await request(
      `/api/products/${encodeURIComponent(config.productCode)}/price-history/${encodeURIComponent(record.effDate)}/delete`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadPrices();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Price could not be deleted.", "error");
  }
}

async function restorePrice(record) {
  try {
    const result = await request(
      `/api/products/${encodeURIComponent(config.productCode)}/price-history/${encodeURIComponent(record.effDate)}/restore`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadPrices();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Price could not be restored.", "error");
  }
}

addButton.addEventListener("click", () => openPriceDialog());
document.querySelector("#price-cancel").addEventListener("click", () => priceDialog.close());
document.querySelectorAll('[data-dialog-close="price-dialog"]').forEach((button) => {
  button.addEventListener("click", () => priceDialog.close());
});
priceForm.addEventListener("submit", savePrice);
searchInput.addEventListener("input", () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(loadPrices, 180);
});
priceTabs?.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentStatus = tab.dataset.status;
  priceTabs.querySelectorAll(".record-tab").forEach((button) => {
    button.classList.toggle("is-active", button === tab);
    button.setAttribute("aria-selected", String(button === tab));
  });
  loadPrices();
});

loadPrices();
