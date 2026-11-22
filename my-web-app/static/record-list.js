const config = window.recordListConfig;
const searchInput = document.querySelector("#record-search");
const recordTableHead = document.querySelector("#record-head");
const recordTableBody = document.querySelector("#record-body");
const recordMessage = document.querySelector("#records-message");
const recordResultCount = document.querySelector("#record-result-count") || (() => {
  const count = document.createElement("p");
  count.id = "record-result-count";
  count.className = "table-message";
  count.setAttribute("role", "status");
  count.setAttribute("aria-live", "polite");
  document.querySelector(".record-toolbar").insertAdjacentElement("afterend", count);
  return count;
})();
const recordAddButton = document.querySelector("#record-add");
const recordDialog = document.querySelector("#record-dialog");
const recordForm = document.querySelector("#record-form");
const recordFields = document.querySelector("#record-fields");
const recordFormError = document.querySelector("#record-form-error");
const recordTitle = document.querySelector("#record-dialog-title");
const recordSave = document.querySelector("#record-save");
const recordTabs = document.querySelector("#record-tabs");
const recordFilters = document.querySelector("#record-filters");
let currentStatus = "active";
let currentActions = {create: false, edit: false, delete: false};
let editingRecord = null;
let records = [];
let loadedFilterKey = null;

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
    } catch (error) {
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

function showToast(message, type = "success") {
  const toast = document.createElement("p");
  toast.className = `toast-message toast-${type}`;
  toast.textContent = message;
  document.querySelector("#toast-container").appendChild(toast);
  window.setTimeout(() => toast.remove(), 3500);
}

function addCell(row, value, label, title = "") {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value || "—";
  if (title) cell.title = title;
  row.appendChild(cell);
  return cell;
}

function addBadge(cell, value, className) {
  const badge = document.createElement("span");
  badge.className = className;
  badge.textContent = value;
  cell.replaceChildren(badge);
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

function renderHeader() {
  const row = document.createElement("tr");
  for (const field of config.fields) {
    const heading = document.createElement("th");
    heading.scope = "col";
    heading.textContent = field.label;
    row.appendChild(heading);
  }
  if (config.module === "products") {
    const heading = document.createElement("th");
    heading.scope = "col";
    heading.textContent = "Current Price";
    row.appendChild(heading);
  }
  if (config.isAdmin) {
    for (const label of ["Status", "Stamp"]) {
      const heading = document.createElement("th");
      heading.scope = "col";
      heading.textContent = label;
      row.appendChild(heading);
    }
  }
  const actionsHeading = document.createElement("th");
  actionsHeading.scope = "col";
  actionsHeading.textContent = "Actions";
  row.appendChild(actionsHeading);
  recordTableHead.replaceChildren(row);
}

function renderRecords(records) {
  recordTableBody.replaceChildren();
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    for (const field of config.fields) {
      addCell(row, record[field.name], field.label, String(record[field.name] || ""));
    }
    if (config.module === "products") {
      const priceCell = document.createElement("td");
      priceCell.dataset.label = "Current Price";
      const currentPrice = record.currentPrice;
      priceCell.textContent =
        currentPrice !== undefined && currentPrice !== null && currentPrice !== ""
          ? `${parseFloat(currentPrice).toFixed(2)}`
          : "\u2014";
      row.appendChild(priceCell);
    }
    if (config.isAdmin) {
      const statusCell = document.createElement("td");
      statusCell.dataset.label = "Status";
      addBadge(
        statusCell,
        record.isDeleted ? "Inactive" : "Active",
        `status-badge ${record.isDeleted ? "status-inactive" : "status-approved"}`,
      );
      row.appendChild(statusCell);
      addCell(row, record.stamp, "Stamp", record.stamp || "");
    }
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (config.module === "products") {
      const priceHistoryButton = document.createElement("a");
      priceHistoryButton.className = "btn btn-secondary";
      priceHistoryButton.textContent = "Price history";
      priceHistoryButton.href =
        `/products/${encodeURIComponent(record[config.keyField])}/price-history`;
      actions.appendChild(priceHistoryButton);
    }
    if (config.module === "employees" && currentActions.profileView) {
      const profileButton = document.createElement("a");
      profileButton.className = "btn btn-secondary";
      profileButton.textContent = "Profile";
      profileButton.href =
        `/human-resources/employees/${encodeURIComponent(record[config.keyField])}`;
      actions.appendChild(profileButton);
    }
    if (config.module === "employees" && currentActions.jobHistoryView) {
      const historyButton = document.createElement("a");
      historyButton.className = "btn btn-secondary";
      historyButton.textContent = "Job history";
      historyButton.href =
        `/human-resources/employees/${encodeURIComponent(record[config.keyField])}/job-history`;
      actions.appendChild(historyButton);
    }
    if (record.isDeleted) {
      if (config.isAdmin && currentActions.delete) {
        addActionButton(actions, "Restore", () => restoreRecord(record));
      }
    } else if (currentActions.edit) {
      addActionButton(actions, "Edit", () => openRecordDialog(record));
    }
    if (!record.isDeleted && currentActions.delete) {
      addActionButton(actions, "Delete", () => deleteRecord(record), true);
    }
    if (!actions.childElementCount) {
      actionCell.textContent = "—";
    } else {
      actionCell.appendChild(actions);
    }
    row.appendChild(actionCell);
    recordTableBody.appendChild(row);
  }
}

function updateCounts(counts) {
  if (!config.isAdmin || !counts) return;
  for (const status of ["active", "inactive", "all"]) {
    const counter = document.querySelector(`[data-count="${status}"]`);
    if (counter) counter.textContent = counts[status] ?? 0;
  }
}

function recordFilterKey() {
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
  });
  recordFilters?.querySelectorAll("[data-record-filter]").forEach((filter) => {
    params.set(filter.dataset.recordFilter, filter.value);
  });
  return params.toString();
}

function filterRecords() {
  const search = searchInput.value.trim().toLocaleLowerCase();
  if (!search) return records;
  return records.filter((record) =>
    config.fields.some((field) =>
      String(record[field.name] || "").toLocaleLowerCase().includes(search)
    )
  );
}

function updateResultCount(filteredCount) {
  const search = searchInput.value.trim();
  recordResultCount.textContent = search
    ? `Showing ${filteredCount} of ${records.length} results.`
    : `${records.length} results.`;
}

async function loadRecords() {
  recordMessage.textContent = "";
  recordResultCount.textContent = "";
  const requestedFilterKey = recordFilterKey();
  try {
    const result = await request(`/api/records/${config.module}?${requestedFilterKey}`);
    if (requestedFilterKey !== recordFilterKey()) return;
    currentActions = result.actions;
    recordAddButton.hidden = !currentActions.create;
    records = result.records;
    loadedFilterKey = requestedFilterKey;
    const filteredRecords = filterRecords();
    renderRecords(filteredRecords);
    updateResultCount(filteredRecords.length);
    updateCounts(result.counts);
  } catch (error) {
    if (requestedFilterKey !== recordFilterKey()) return;
    recordMessage.textContent = error instanceof Error
      ? error.message
      : `${config.title} could not be loaded.`;
    recordTableBody.replaceChildren();
    records = [];
    loadedFilterKey = requestedFilterKey;
    recordResultCount.textContent = "";
  }
}

function buildFields() {
  recordFields.replaceChildren();
  for (const field of config.fields) {
    const label = document.createElement("label");
    label.className = "record-field";
    label.appendChild(document.createTextNode(field.label));
    const hint = document.createElement("span");
    hint.className = "record-field-hint";
    if (field.type === "date" || field.options) {
      hint.textContent = field.required ? "Required." : "Optional.";
    } else if (field.required) {
      hint.textContent = `Required: minimum 1 character; maximum ${field.maxlength}.`;
    } else {
      hint.textContent = `Optional: up to ${field.maxlength} characters.`;
    }
    label.appendChild(hint);
    let input;
    if (field.options) {
      input = document.createElement("select");
      const prompt = document.createElement("option");
      prompt.value = "";
      prompt.textContent = "Choose...";
      input.appendChild(prompt);
      for (const option of field.options) {
        const item = document.createElement("option");
        item.value = typeof option === "string" ? option : option.value;
        item.textContent = typeof option === "string" ? option : option.label;
        input.appendChild(item);
      }
    } else {
      input = document.createElement("input");
      input.type = field.type || "text";
      if (input.type === "text") {
        input.maxLength = field.maxlength;
        if (field.required) input.minLength = 1;
      }
    }
    input.name = field.name;
    input.required = field.required;
    label.appendChild(input);
    recordFields.appendChild(label);
  }
}

function openRecordDialog(record = null) {
  editingRecord = record;
  recordFormError.textContent = "";
  recordTitle.textContent = record
    ? `Edit ${config.singular.toLowerCase()}`
    : `Add ${config.singular.toLowerCase()}`;
  recordSave.textContent = record ? "Save changes" : `Add ${config.singular.toLowerCase()}`;
  buildFields();
  for (const field of config.fields) {
    const input = recordForm.elements.namedItem(field.name);
    if (record) input.value = record[field.name] || "";
    if (record && field.name === config.keyField) input.disabled = true;
  }
  recordDialog.showModal();
  recordFields.querySelector("input, select")?.focus();
}

async function saveRecord(event) {
  event.preventDefault();
  recordFormError.textContent = "";
  recordSave.disabled = true;
  const body = {};
  for (const field of config.fields) {
    if (editingRecord && field.name === config.keyField) continue;
    body[field.name] = recordForm.elements.namedItem(field.name).value.trim();
  }
  const url = editingRecord
    ? `/api/records/${config.module}/${encodeURIComponent(editingRecord[config.keyField])}`
    : `/api/records/${config.module}`;
  try {
    const result = await request(url, {
      method: editingRecord ? "PATCH" : "POST",
      body: JSON.stringify(body),
    });
    recordDialog.close();
    showToast(result.message);
    await loadRecords();
  } catch (error) {
    recordFormError.textContent = error instanceof Error
      ? error.message
      : `${config.singular} could not be saved.`;
  } finally {
    recordSave.disabled = false;
  }
}

async function deleteRecord(record) {
  if (!(await window.confirmAction(`Move ${record[config.displayField]} to Inactive?`))) return;
  try {
    const result = await request(
      `/api/records/${config.module}/${encodeURIComponent(record[config.keyField])}/delete`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadRecords();
  } catch (error) {
    showToast(error instanceof Error ? error.message : `${config.singular} could not be deleted.`, "error");
  }
}

async function restoreRecord(record) {
  try {
    const result = await request(
      `/api/records/${config.module}/${encodeURIComponent(record[config.keyField])}/restore`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadRecords();
  } catch (error) {
    showToast(error instanceof Error ? error.message : `${config.singular} could not be restored.`, "error");
  }
}

recordAddButton.addEventListener("click", () => openRecordDialog());
document.querySelector("#record-cancel").addEventListener("click", () => recordDialog.close());
document.querySelectorAll('[data-dialog-close="record-dialog"]').forEach((button) => {
  button.addEventListener("click", () => recordDialog.close());
});
recordForm.addEventListener("submit", saveRecord);
searchInput.addEventListener("input", () => {
  if (loadedFilterKey === recordFilterKey()) {
    const filteredRecords = filterRecords();
    renderRecords(filteredRecords);
    updateResultCount(filteredRecords.length);
  }
});
recordFilters?.addEventListener("change", loadRecords);
recordTabs?.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentStatus = tab.dataset.status;
  recordTabs.querySelectorAll(".record-tab").forEach((button) => {
    button.classList.toggle("is-active", button === tab);
    button.setAttribute("aria-selected", String(button === tab));
  });
  loadRecords();
});

renderHeader();
loadRecords();
