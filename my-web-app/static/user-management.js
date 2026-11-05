const addForm = document.querySelector("#add-user-form");
const addMessage = document.querySelector("#add-user-message");
const usersMessage = document.querySelector("#users-message");
const usersTable = document.querySelector("#users-table");

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

function renderUsers(users) {
  usersTable.replaceChildren();
  for (const user of users) {
    const row = document.createElement("tr");
    addCell(row, user.full_name || "—");
    addCell(row, user.email || "—");
    addCell(row, user.status);

    const actions = document.createElement("td");
    const editButton = document.createElement("button");
    editButton.type = "button";
    editButton.textContent = "Edit";
    editButton.addEventListener("click", () => editUser(user));
    actions.appendChild(editButton);

    const statusButton = document.createElement("button");
    statusButton.type = "button";
    statusButton.textContent = user.status === "blocked" ? "Unblock" : "Block";
    statusButton.addEventListener("click", () => updateStatus(user));
    actions.appendChild(statusButton);
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
  const fullName = window.prompt("Full name", user.full_name || "");
  if (fullName === null || fullName.trim() === user.full_name) {
    return;
  }
  try {
    await request(`/api/users/${user.id}`, {
      method: "PATCH",
      body: JSON.stringify({full_name: fullName}),
    });
    await loadUsers();
  } catch (error) {
    showMessage(usersMessage, error instanceof Error ? error.message : "User could not be updated.");
  }
}

async function updateStatus(user) {
  const status = user.status === "blocked" ? "approved" : "blocked";
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
