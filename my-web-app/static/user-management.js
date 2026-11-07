const addForm = document.querySelector("#add-user-form");
const addMessage = document.querySelector("#add-user-message");
const usersMessage = document.querySelector("#users-message");
const usersTable = document.querySelector("#users-table");
const rightsDialog = document.querySelector("#rights-dialog");
const rightsForm = document.querySelector("#rights-form");
const rightsMatrix = document.querySelector("#rights-matrix");
const rightsMessage = document.querySelector("#rights-message");
const rightsUser = document.querySelector("#rights-user");
const editUserDialog = document.querySelector("#edit-user-dialog");
const editUserForm = document.querySelector("#edit-user-form");
const editUserName = document.querySelector("#edit-user-name");
const editUserMessage = document.querySelector("#edit-user-message");
const rightsModules = ["Customer", "Product", "Human Resources", "Sales", "Reports"];
const rightsActions = ["view", "create", "edit", "delete"];
let rightsTarget = null;
let editUserTarget = null;

function showMessage(element, message) {
  element.textContent = message;
}

async function request(url, options = {}) {
  const response = await fetch(url, {
    headers: {"Content-Type": "application/json", ...options.headers},
    ...options,
  });
  const result = await response.json();
  if (!response.ok) {
    throw new Error(result.error || "Request could not be completed.");
  }
  return result;
}

function addCell(row, value) {
  const cell = document.createElement("td");
  cell.textContent = value;
  row.appendChild(cell);
  return cell;
}

function addBadge(cell, value, className) {
  const badge = document.createElement("span");
  badge.className = className;
  badge.textContent = value;
  cell.replaceChildren(badge);
}

function renderRights(permissions) {
  rightsMatrix.replaceChildren();
  for (const module of rightsModules) {
    const section = document.createElement("fieldset");
    const legend = document.createElement("legend");
    const moduleToggle = document.createElement("input");
    moduleToggle.type = "checkbox";
    moduleToggle.dataset.moduleToggle = module;
    moduleToggle.checked = rightsActions.every((action) => permissions[module][action]);
    moduleToggle.indeterminate =
      !moduleToggle.checked && rightsActions.some((action) => permissions[module][action]);
    moduleToggle.addEventListener("change", () => {
      section.querySelectorAll("input[data-action]").forEach((checkbox) => {
        checkbox.checked = moduleToggle.checked;
      });
    });
    legend.append(moduleToggle, document.createTextNode(` ${module}`));
    section.appendChild(legend);
    for (const action of rightsActions) {
      const label = document.createElement("label");
      label.className = "rights-option";
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.dataset.module = module;
      checkbox.dataset.action = action;
      checkbox.checked = permissions[module][action];
      checkbox.addEventListener("change", () => {
        const values = [...section.querySelectorAll("input[data-action]")].map(
          (actionCheckbox) => actionCheckbox.checked,
        );
        moduleToggle.checked = values.every(Boolean);
        moduleToggle.indeterminate = !moduleToggle.checked && values.some(Boolean);
      });
      label.append(checkbox, document.createTextNode(action[0].toUpperCase() + action.slice(1)));
      section.appendChild(label);
    }
    rightsMatrix.appendChild(section);
  }
}

function readRights() {
  const permissions = {};
  for (const module of rightsModules) {
    permissions[module] = {};
    for (const action of rightsActions) {
      permissions[module][action] = rightsMatrix.querySelector(
        `input[data-module="${CSS.escape(module)}"][data-action="${action}"]`,
      ).checked;
    }
  }
  return permissions;
}

async function openRights(user) {
  rightsTarget = user;
  rightsUser.textContent = `${user.full_name || user.email} (${user.role})`;
  rightsMessage.textContent = "";
  try {
    const result = await request(`/api/users/${user.id}/permissions`);
    renderRights(result.permissions);
    rightsDialog.showModal();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "Rights could not be loaded.");
  }
}

function setAllRights(value) {
  rightsMatrix.querySelectorAll("input[type=checkbox]").forEach((checkbox) => {
    checkbox.checked = value;
    checkbox.indeterminate = false;
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
      body: JSON.stringify({permissions: readRights()}),
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
    addCell(row, user.full_name || "—");
    addCell(row, user.email || "—");
    const roleCell = addCell(row, "");
    const roleClass = {
      user: "role-user-badge",
      admin: "role-admin-badge",
      superadmin: "role-superadmin-badge",
    }[user.role] || "";
    addBadge(roleCell, user.role, `status-badge ${roleClass}`.trim());
    const statusCell = addCell(row, "");
    const statusClass = {
      approved: "status-approved",
      pending: "status-pending",
      blocked: "status-blocked",
    }[user.status] || "";
    addBadge(statusCell, user.status, `status-badge ${statusClass}`.trim());

    const actions = document.createElement("td");
    actions.className = "table-actions";
    const editButton = document.createElement("button");
    editButton.type = "button";
    editButton.className = "btn btn-secondary";
    editButton.textContent = "Edit";
    editButton.addEventListener("click", () => editUser(user));
    actions.appendChild(editButton);

    const rightsButton = document.createElement("button");
    rightsButton.type = "button";
    rightsButton.className = "btn btn-secondary";
    rightsButton.textContent = "Rights";
    rightsButton.addEventListener("click", () => openRights(user));
    actions.appendChild(rightsButton);

    const statusButton = document.createElement("button");
    statusButton.type = "button";
    statusButton.className = "btn btn-secondary";
    statusButton.textContent =
      user.status === "pending" ? "Approve" :
      user.status === "blocked" ? "Unblock" : "Block";
    statusButton.addEventListener("click", () => updateStatus(user));
    actions.appendChild(statusButton);

    if (window.isSuperadmin && user.role !== "admin") {
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
      removeButton.addEventListener("click", () => removeUser(user));
      actions.appendChild(removeButton);
    }
    row.appendChild(actions);
    usersTable.appendChild(row);
  }
}

async function loadUsers() {
  try {
    const result = await request("/api/users");
    renderUsers(result.users);
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
  if (!(await window.confirmAction(`Remove ${user.email}? This cannot be undone.`))) {
    return;
  }
  try {
    await request(`/api/users/${user.id}`, {method: "DELETE"});
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User could not be removed.");
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
    showMessage(addMessage, "User added successfully.");
    await loadUsers();
  } catch (error) {
    showMessage(addMessage, error instanceof Error ? error.message : "User could not be added.");
  } finally {
    submitButton.disabled = false;
  }
});

loadUsers();
