const config = window.recordListConfig;
const searchInput = document.querySelector("#record-search");
const recordTableHead = document.querySelector("#record-head");
const recordTableBody = document.querySelector("#record-body");
const recordMessage = document.querySelector("#records-message");
const recordAddButton = document.querySelector("#record-add");
const recordDialog = document.querySelector("#record-dialog");
const recordForm = document.querySelector("#record-form");
const recordFields = document.querySelector("#record-fields");
const recordFormError = document.querySelector("#record-form-error");
const recordTitle = document.querySelector("#record-dialog-title");
const recordSave = document.querySelector("#record-save");
const recordTabs = document.querySelector("#record-tabs");
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

function addCell(row, value, label, title = "") {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value || "—";
  if (title) cell.title = title;
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

function renderHeader() {
  const row = document.createElement("tr");
  for (const field of config.fields) {
    const heading = document.createElement("th");
    heading.scope = "col";
    heading.textContent = field.label;
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
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      addCell(row, record.stamp, "Stamp", record.stamp || "");
    }
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
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

async function loadRecords() {
  recordMessage.textContent = "";
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
    search: searchInput.value.trim(),
  });
  try {
    const result = await request(`/api/records/${config.module}?${params}`);
    currentActions = result.actions;
    recordAddButton.hidden = !currentActions.create;
    renderRecords(result.records);
    updateCounts(result.counts);
  } catch (error) {
    recordMessage.textContent = error instanceof Error
      ? error.message
      : `${config.title} could not be loaded.`;
    recordTableBody.replaceChildren();
  }
}

function buildFields() {
  recordFields.replaceChildren();
  for (const field of config.fields) {
    const label = document.createElement("label");
    label.className = "record-field";
    label.appendChild(document.createTextNode(field.label));
    let input;
    if (field.options) {
      input = document.createElement("select");
      const prompt = document.createElement("option");
      prompt.value = "";
      prompt.textContent = "Choose...";
      input.appendChild(prompt);
      for (const option of field.options) {
        const item = document.createElement("option");
        item.value = option;
        item.textContent = option;
        input.appendChild(item);
      }
    } else {
      input = document.createElement("input");
      input.type = "text";
      input.maxLength = field.maxlength;
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
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(loadRecords, 180);
});
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
