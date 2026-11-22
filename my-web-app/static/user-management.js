const addForm = document.querySelector("#add-user-form");
const addMessage = document.querySelector("#add-user-message");
const usersMessage = document.querySelector("#users-message");
const usersTable = document.querySelector("#users-table");
const userTabs = document.querySelector("#user-tabs");
const userSearch = document.querySelector("#user-search");
const rightsDialog = document.querySelector("#rights-dialog");
const rightsForm = document.querySelector("#rights-form");
const rightsMatrix = document.querySelector("#rights-matrix");
const rightsMessage = document.querySelector("#rights-message");
const rightsUser = document.querySelector("#rights-user");
const editUserDialog = document.querySelector("#edit-user-dialog");
const editUserForm = document.querySelector("#edit-user-form");
const editUserName = document.querySelector("#edit-user-name");
const editUserMessage = document.querySelector("#edit-user-message");
const rightsModules = [
  {code: "customers", name: "Customer"},
  {code: "products", name: "Product"},
  {code: "hr", name: "Human Resources"},
  {code: "sales", name: "Sales"},
  {code: "reports", name: "Reports"},
];
const rightResourceLabels = {
  customers: "Customers",
  products: "Products",
  jobs: "Job",
  departments: "Department",
  employees: "Employee",
  job_history: "Job History",
  hr: "Human Resources",
  sales: "Sale",
  sale_details: "Sale Detail",
  reports: "Reports",
  top_customers: "Top Customers",
  top_products: "Top Products",
  active_employees: "Active Employees",
  all_employees: "All Employees",
  employee_job_history: "Employee Job History",
  top_sales: "Top Sales",
  products_master: "Product Master List",
  price_history: "Price",
};
let rightsTarget = null;
let editUserTarget = null;
let currentUserStatus = "active";
let userSearchTimer;

function showMessage(element, message) {
  element.textContent = message;
}

async function request(url, options = {}) {
  const headers = {"Content-Type": "application/json", ...options.headers};
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  if (csrfToken) headers["X-CSRF-Token"] = csrfToken;
  const response = await fetch(url, {...options, headers});
  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error || "Request could not be completed.");
  }
  return result;
}

function addCell(row, value, label, title = "") {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value;
  if (title) cell.title = title;
  row.appendChild(cell);
  return cell;
}

function addBadge(cell, value, className) {
  const badge = document.createElement("span");
  badge.className = className;
  badge.textContent = value;
  cell.replaceChildren(badge);
}

function renderRights(catalog, selected) {
  rightsMatrix.replaceChildren();
  for (const module of rightsModules) {
    const moduleRights = catalog.filter((right) => right.module_code === module.code);
    const section = document.createElement("fieldset");
    section.className = "rights-group";
    const legend = document.createElement("legend");
    const moduleToggle = document.createElement("input");
    moduleToggle.type = "checkbox";
    moduleToggle.setAttribute("aria-label", `${module.name} View`);
    moduleToggle.dataset.viewToggle = module.code;
    const viewRight = moduleRights.find((right) => right.right_code === `${module.code}.view`);
    moduleToggle.disabled = !viewRight;
    legend.append(moduleToggle, document.createTextNode(` ${module.name}`));
    section.appendChild(legend);

    const updateModuleToggle = () => {
      const viewCheckbox = [...section.querySelectorAll("input[data-right]")]
        .find((checkbox) => checkbox.dataset.right === viewRight?.right_code);
      moduleToggle.checked = Boolean(viewCheckbox?.checked);
    };

    moduleToggle.addEventListener("change", () => {
      const viewCheckbox = [...section.querySelectorAll("input[data-right]")]
        .find((checkbox) => checkbox.dataset.right === viewRight?.right_code);
      if (viewCheckbox) viewCheckbox.checked = moduleToggle.checked;
    });

    const controls = document.createElement("div");
    controls.className = "rights-group-controls";
    for (const value of ["All", "None"]) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "btn btn-secondary";
      button.textContent = value;
      button.addEventListener("click", () => {
        section.querySelectorAll("input[data-right]").forEach((checkbox) => {
          checkbox.checked = value === "All";
        });
        updateModuleToggle();
      });
      controls.appendChild(button);
    }
    section.appendChild(controls);

    for (const right of moduleRights) {
      const label = document.createElement("label");
      label.className = "rights-option";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      const resource = rightResourceLabels[right.resource_code] ||
        right.resource_code.replaceAll("_", " ");
      const action = right.action[0].toUpperCase() + right.action.slice(1);
      const rightLabel = right.action === "view"
        ? `${resource} ${action}`
        : `${action} ${resource}`;
      checkbox.setAttribute("aria-label", `${module.name}: ${rightLabel}`);
      checkbox.dataset.right = right.right_code;
      checkbox.checked = selected.includes(right.right_code);
      checkbox.addEventListener("change", updateModuleToggle);
      label.append(checkbox, document.createTextNode(rightLabel));
      section.appendChild(label);
    }
    updateModuleToggle();
    rightsMatrix.appendChild(section);
  }
}

function readRights() {
  return [...rightsMatrix.querySelectorAll("input[data-right]:checked")]
    .map((checkbox) => checkbox.dataset.right);
}

async function openRights(user) {
  rightsTarget = user;
  rightsUser.textContent = `${user.full_name || user.email} (${user.role})`;
  rightsMessage.textContent = "";
  try {
    const result = await request(`/api/users/${user.id}/permissions`);
    renderRights(result.catalog, result.selected);
    rightsDialog.showModal();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "Rights could not be loaded.");
  }
}

function setAllRights(value) {
  rightsMatrix.querySelectorAll("input[data-right]").forEach((checkbox) => {
    checkbox.checked = value;
  });
  rightsMatrix.querySelectorAll("input[data-view-toggle]").forEach((checkbox) => {
    checkbox.checked = value && !checkbox.disabled;
  });
}

document.querySelector("#rights-all").addEventListener("click", () => setAllRights(true));
document.querySelector("#rights-none").addEventListener("click", () => setAllRights(false));
document.querySelector("#rights-cancel").addEventListener("click", () => rightsDialog.close());
rightsForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const saveButton = document.querySelector("#rights-save");
  saveButton.disabled = true;
  rightsMessage.textContent = "";
  try {
    await request(`/api/users/${rightsTarget.id}/permissions`, {
      method: "PATCH",
      body: JSON.stringify({rights: readRights()}),
    });

    rightsDialog.close();
    showMessage(usersMessage, "Rights updated successfully.");
  } catch (error) {
    showMessage(rightsMessage, error instanceof Error ? error.message : "Rights could not be updated.");
  } finally {
    saveButton.disabled = false;
  }
});

document.querySelector("#edit-user-cancel").addEventListener("click", () => editUserDialog.close());
editUserForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const fullName = editUserName.value.trim();
  if (!fullName) {
    editUserMessage.textContent = "Enter a full name.";
    return;
  }

  const saveButton = document.querySelector("#edit-user-save");
  saveButton.disabled = true;
  editUserMessage.textContent = "";
  try {
    await request(`/api/users/${editUserTarget.id}`, {
      method: "PATCH",
      body: JSON.stringify({full_name: fullName}),
    });
    editUserDialog.close();
    await loadUsers();
    showMessage(usersMessage, "User updated successfully.");
  } catch (error) {
    editUserMessage.textContent =
      error instanceof Error ? error.message : "User could not be updated.";
  } finally {
    saveButton.disabled = false;
  }
});

function renderUsers(users) {
  usersTable.replaceChildren();
  for (const user of users) {
    const row = document.createElement("tr");
    if (user.isDeleted) row.classList.add("record-deleted");
    addCell(row, user.full_name || "—", "Name", user.full_name || "");
    addCell(row, user.email || "—", "Email", user.email || "");
    const roleCell = addCell(row, "", "Role");
    const roleClass = {
      user: "role-user-badge",
      admin: "role-admin-badge",
      superadmin: "role-superadmin-badge",
    }[user.role] || "";
    addBadge(roleCell, user.role, `status-badge ${roleClass}`.trim());
    const accountStatusCell = addCell(row, "", "Account Status");
    const statusClass = {
      approved: "status-approved",
      pending: "status-pending",
      blocked: "status-blocked",
    }[user.status] || "";
    addBadge(accountStatusCell, user.status, `status-badge ${statusClass}`.trim());
    const statusCell = addCell(row, "", "Status");
    addBadge(
      statusCell,
      user.isDeleted ? "Inactive" : "Active",
      `status-badge ${user.isDeleted ? "status-inactive" : "status-approved"}`,
    );
    addCell(row, user.stamp || "—", "Stamp", user.stamp || "");

    const actionsCell = document.createElement("td");
    actionsCell.dataset.label = "Actions";
    if (window.isAdmin && user.role !== "user") {
      actionsCell.textContent = "—";
      row.appendChild(actionsCell);
      usersTable.appendChild(row);
      continue;
    }
    if (user.isDeleted) {
      const restoreButton = document.createElement("button");
      restoreButton.type = "button";
      restoreButton.className = "btn btn-secondary";
      restoreButton.textContent = "Restore";
      restoreButton.addEventListener("click", () => restoreUser(user));
      actionsCell.appendChild(restoreButton);
      row.appendChild(actionsCell);
      usersTable.appendChild(row);
      continue;
    }
    const actions = document.createElement("div");
    actions.className = "table-actions";
    const editButton = document.createElement("button");
    editButton.type = "button";
    editButton.className = "btn btn-secondary";
    editButton.textContent = "Edit";
    editButton.addEventListener("click", () => editUser(user));
    actions.appendChild(editButton);

    if (user.role !== "superadmin") {
      const rightsButton = document.createElement("button");
      rightsButton.type = "button";
      rightsButton.className = "btn btn-secondary";
      rightsButton.textContent = "Rights";
      rightsButton.addEventListener("click", () => openRights(user));
      actions.appendChild(rightsButton);
    }

    if (user.status === "pending" && window.isAdmin) {
      const approvalNote = document.createElement("span");
      approvalNote.textContent = "Awaiting Superadmin approval";
      actions.appendChild(approvalNote);
    } else {
      const statusButton = document.createElement("button");
      statusButton.type = "button";
      statusButton.className = "btn btn-secondary";
      statusButton.textContent = user.status === "pending"
        ? "Approve"
        : user.blocked || user.status === "blocked" ? "Unblock" : "Block";
      statusButton.disabled = user.isLastSuperadmin && !user.blocked;
      if (statusButton.disabled) statusButton.title = "The last active Superadmin cannot be blocked.";
      statusButton.addEventListener("click", () => updateStatus(user));
      actions.appendChild(statusButton);
    }

    if (window.isSuperadmin && user.role === "user") {
      const adminButton = document.createElement("button");
      adminButton.type = "button";
      adminButton.className = "btn btn-secondary";
      adminButton.textContent = "Make Admin";
      adminButton.addEventListener("click", () => updateRole(user, "admin"));
      actions.appendChild(adminButton);
    }

    if (window.isSuperadmin && user.role === "admin") {
      const userButton = document.createElement("button");
      userButton.type = "button";
      userButton.className = "btn btn-secondary";
      userButton.textContent = "Make User";
      userButton.addEventListener("click", () => updateRole(user, "user"));
      actions.appendChild(userButton);
    }

    if (window.isSuperadmin) {
      const removeButton = document.createElement("button");
      removeButton.type = "button";
      removeButton.className = "btn btn-danger";
      removeButton.textContent = "Remove";
      removeButton.disabled = user.isLastSuperadmin || user.isOnlySuperadmin;
      if (removeButton.disabled) removeButton.title = "The last Superadmin cannot be removed.";
      removeButton.addEventListener("click", () => removeUser(user));
      actions.appendChild(removeButton);
    }
    if (actions.childElementCount) {
      actionsCell.appendChild(actions);
    } else {
      actionsCell.textContent = "—";
    }
    row.appendChild(actionsCell);
    usersTable.appendChild(row);
  }
}

async function loadUsers() {
  try {
    const params = new URLSearchParams({
      status: currentUserStatus,
      search: userSearch.value.trim(),
    });
    const result = await request(`/api/users?${params}`);
    renderUsers(result.users);
    for (const status of ["active", "inactive", "all"]) {
      const count = document.querySelector(`[data-count="${status}"]`);
      if (count) count.textContent = result.counts[status] ?? 0;
    }
    showMessage(usersMessage, "");
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "Users could not be loaded.");
  }
}

async function editUser(user) {
  editUserTarget = user;
  editUserName.value = user.full_name || "";
  editUserMessage.textContent = "";
  editUserDialog.showModal();
  editUserName.focus();
}

async function updateStatus(user) {
  const status = user.status === "pending" || user.status === "blocked"
    ? "approved"
    : "blocked";
  try {
    await request(`/api/users/${user.id}/status`, {
      method: "PATCH",
      body: JSON.stringify({status}),
    });
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User status could not be updated.");
  }
}

async function updateRole(user, role) {
  try {
    await request(`/api/users/${user.id}/role`, {
      method: "PATCH",
      body: JSON.stringify({role}),
    });
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User role could not be updated.");
  }
}

async function removeUser(user) {
  if (!(await window.confirmAction(`Move ${user.email} to Inactive? A Superadmin can restore this account.`))) {
    return;
  }
  try {
    await request(`/api/users/${user.id}`, {method: "DELETE"});
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User could not be removed.");
  }
}

async function restoreUser(user) {
  try {
    await request(`/api/users/${user.id}/restore`, {method: "PATCH"});
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User could not be restored.");
  }
}

addForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  showMessage(addMessage, "");
  const submitButton = addForm.querySelector("button");
  submitButton.disabled = true;
  try {
    await request("/api/users", {
      method: "POST",
      body: JSON.stringify(Object.fromEntries(new FormData(addForm).entries())),
    });
    addForm.reset();
    showMessage(addMessage, "Approved account created. The user must set a new password at first login.");
    await loadUsers();
  } catch (error) {
    showMessage(addMessage, error instanceof Error ? error.message : "User could not be added.");
  } finally {
    submitButton.disabled = false;
  }
});

userTabs.addEventListener("click", (event) => {
  const tab = event.target.closest("[data-status]");
  if (!tab) return;
  currentUserStatus = tab.dataset.status;
  userTabs.querySelectorAll(".record-tab").forEach((button) => {
    button.classList.toggle("is-active", button === tab);
    button.setAttribute("aria-selected", String(button === tab));
  });
  loadUsers();
});

userSearch.addEventListener("input", () => {
  window.clearTimeout(userSearchTimer);
  userSearchTimer = window.setTimeout(loadUsers, 180);
});

loadUsers();
