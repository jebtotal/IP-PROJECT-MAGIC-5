const config = window.jobHistoryConfig;
const searchInput = document.querySelector("#history-search");
const historyBody = document.querySelector("#history-body");
const historyMessage = document.querySelector("#history-message");
const addButton = document.querySelector("#history-add");
const historyDialog = document.querySelector("#history-dialog");
const historyForm = document.querySelector("#history-form");
const historyDate = document.querySelector("#history-effective-date");
const historyJob = document.querySelector("#history-job");
const historyDepartment = document.querySelector("#history-department");
const historySalary = document.querySelector("#history-salary");
const historyTitle = document.querySelector("#history-dialog-title");
const historyError = document.querySelector("#history-form-error");
const saveButton = document.querySelector("#history-save");
const historyTabs = document.querySelector("#history-tabs");
let currentStatus = "active";
let currentActions = config.actions;
let editingRecord = null;
let searchTimer;
const jobLabels = new Map(
  config.jobs.map((job) => [
    job.jobcode,
    job.jobdesc ? `${job.jobcode} · ${job.jobdesc}` : job.jobcode,
  ]),
);
const departmentLabels = new Map(
  config.departments.map((department) => [
    department.deptcode,
    department.deptname
      ? `${department.deptcode} · ${department.deptname}`
      : department.deptcode,
  ]),
);

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

function addCell(row, value, label) {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value === null || value === undefined || value === "" ? "—" : value;
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

function renderHistory(records) {
  historyBody.replaceChildren();
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    addCell(row, record.effDate, "Effective Date");
    addCell(row, jobLabels.get(record.jobCode) || record.jobCode, "Job");
    addCell(row, departmentLabels.get(record.deptCode) || record.deptCode, "Department");
    addCell(row, record.salary, "Salary");
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      addCell(row, record.stamp, "Stamp");
    }
    const actionCell = document.createElement("td");
    actionCell.dataset.label = "Actions";
    const actions = document.createElement("div");
    actions.className = "table-actions";
    if (!record.isDeleted && currentActions.edit) {
      addActionButton(actions, "Edit", () => openDialog(record));
    }
    if (!record.isDeleted && currentActions.delete) {
      addActionButton(actions, "Delete", () => deleteHistory(record), true);
    }
    actionCell.textContent = actions.childElementCount ? "" : "—";
    if (actions.childElementCount) actionCell.appendChild(actions);
    row.appendChild(actionCell);
    historyBody.appendChild(row);
  }
}

function updateCounts(counts) {
  if (!config.isAdmin || !counts) return;
  for (const status of ["active", "inactive", "all"]) {
    const counter = document.querySelector(`[data-count="${status}"]`);
    if (counter) counter.textContent = counts[status] ?? 0;
  }
}

function historyUrl() {
  return `/api/hr/employees/${encodeURIComponent(config.employeeNo)}/job-history`;
}

async function loadHistory() {
  historyMessage.textContent = "";
  const params = new URLSearchParams({
    status: config.isAdmin ? currentStatus : "active",
    search: searchInput.value.trim(),
  });
  try {
    const result = await request(`${historyUrl()}?${params}`);
    currentActions = result.actions;
    addButton.hidden = !currentActions.create;
    renderHistory(result.records);
    updateCounts(result.counts);
  } catch (error) {
    historyMessage.textContent = error instanceof Error ? error.message : "Job History could not be loaded.";
    historyBody.replaceChildren();
  }
}

function openDialog(record = null) {
  editingRecord = record;
  historyError.textContent = "";
  historyTitle.textContent = record ? "Edit job history" : "Add job history";
  saveButton.textContent = record ? "Save changes" : "Add job history";
  historyDate.value = record?.effDate || "";
  historyJob.value = record?.jobCode || "";
  historyDepartment.value = record?.deptCode || "";
  historySalary.value = record?.salary ?? "";
  historyDialog.showModal();
  historyDate.focus();
}

async function saveHistory(event) {
  event.preventDefault();
  historyError.textContent = "";
  saveButton.disabled = true;
  const url = editingRecord
    ? `${historyUrl()}/${encodeURIComponent(editingRecord.effDate)}`
    : historyUrl();
  try {
    const result = await request(url, {
      method: editingRecord ? "PATCH" : "POST",
      body: JSON.stringify({
        effDate: historyDate.value,
        jobCode: historyJob.value,
        deptCode: historyDepartment.value,
        salary: historySalary.value,
      }),
    });
    historyDialog.close();
    showToast(result.message);
    await loadHistory();
  } catch (error) {
    historyError.textContent = error instanceof Error ? error.message : "Job History could not be saved.";
  } finally {
    saveButton.disabled = false;
  }
}

async function deleteHistory(record) {
  if (!(await window.confirmAction(`Move the ${record.effDate} job-history record to Inactive?`))) return;
  try {
    const result = await request(
      `${historyUrl()}/${encodeURIComponent(record.effDate)}/delete`,
      {method: "PATCH"},
    );
    showToast(result.message);
    await loadHistory();
  } catch (error) {
    showToast(error instanceof Error ? error.message : "Job History could not be deleted.", "error");
  }
}

addButton.addEventListener("click", () => openDialog());
document.querySelector("#history-cancel").addEventListener("click", () => historyDialog.close());
document.querySelectorAll('[data-dialog-close="history-dialog"]').forEach((button) => {
  button.addEventListener("click", () => historyDialog.close());
});
historyForm.addEventListener("submit", saveHistory);
searchInput.addEventListener("input", () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(loadHistory, 180);
});
historyTabs?.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentStatus = tab.dataset.status;
  historyTabs.querySelectorAll(".record-tab").forEach((button) => {
    button.classList.toggle("is-active", button === tab);
    button.setAttribute("aria-selected", String(button === tab));
  });
  loadHistory();
});

loadHistory();
