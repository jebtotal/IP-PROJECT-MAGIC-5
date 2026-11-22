const searchInput = document.querySelector("#audit-search");
const auditBody = document.querySelector("#audit-body");
const auditMessage = document.querySelector("#audit-message");
const previousButton = document.querySelector("#audit-previous");
const nextButton = document.querySelector("#audit-next");
const pageLabel = document.querySelector("#audit-page-label");
const pageSize = 50;
let currentPage = 1;
let searchTimer;

async function loadAuditLog() {
  auditMessage.textContent = "";
  const params = new URLSearchParams({
    search: searchInput.value.trim(),
    page: String(currentPage),
  });
  try {
    const response = await fetch(`/api/audit-log?${params}`);
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || "Audit log could not be loaded.");
    if (!Array.isArray(result.rows) || !Number.isInteger(result.total)) {
      throw new Error("The server returned an invalid audit log.");
    }
    renderAuditRows(result.rows);
    const pageCount = Math.max(1, Math.ceil(result.total / pageSize));
    if (currentPage > pageCount) {
      currentPage = pageCount;
      await loadAuditLog();
      return;
    }
    pageLabel.textContent = `Page ${currentPage} of ${pageCount} · ${result.total} entries`;
    previousButton.disabled = currentPage <= 1;
    nextButton.disabled = currentPage >= pageCount;
    if (!result.rows.length) {
      auditMessage.textContent = searchInput.value.trim()
        ? "No audit entries match this search."
        : "No audit entries were found.";
    }
  } catch (error) {
    auditBody.replaceChildren();
    pageLabel.textContent = "";
    auditMessage.textContent = error instanceof Error
      ? error.message
      : "Audit log could not be loaded.";
  }
}

function firstValue(entry, keys) {
  for (const key of keys) {
    const value = entry[key];
    if (value !== null && value !== undefined && value !== "") return value;
  }
  return "—";
}

function formatTimestamp(value) {
  if (!value || value === "—") return "—";
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? String(value) : parsed.toLocaleString();
}

function addCell(row, value, label) {
  const cell = document.createElement("td");
  cell.dataset.label = label;
  cell.textContent = value === null || value === undefined || value === ""
    ? "—"
    : String(value);
  row.appendChild(cell);
  return cell;
}

function renderAuditRows(entries) {
  auditBody.replaceChildren();
  for (const entry of entries) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
    const row = document.createElement("tr");
    const timestamp = firstValue(entry, [
      "created_at", "action_at", "timestamp", "occurred_at",
    ]);
    addCell(row, formatTimestamp(timestamp), "Date / Time");
    addCell(row, firstValue(entry, ["actor_email", "action_by", "actor_id"]), "Actor");
    addCell(row, firstValue(entry, ["event_type", "action"]), "Event");
    const record = [
      entry.table_name || entry.resource || "",
      entry.record_key || entry.target_id || entry.audit_id || entry.id || "",
    ].filter(Boolean).join(" · ");
    addCell(row, record || "—", "Record");

    const changesCell = document.createElement("td");
    changesCell.dataset.label = "Changes";
    const details = document.createElement("details");
    const summary = document.createElement("summary");
    summary.textContent = "View changes";
    const changes = document.createElement("pre");
    changes.className = "audit-change-values";
    changes.textContent = JSON.stringify({
      old: entry.old_values ?? null,
      new: entry.new_values ?? null,
    }, null, 2);
    details.append(summary, changes);
    changesCell.appendChild(details);
    row.appendChild(changesCell);
    auditBody.appendChild(row);
  }
}

searchInput.addEventListener("input", () => {
  window.clearTimeout(searchTimer);
  searchTimer = window.setTimeout(() => {
    currentPage = 1;
    loadAuditLog();
  }, 200);
});

previousButton.addEventListener("click", () => {
  if (currentPage <= 1) return;
  currentPage -= 1;
  loadAuditLog();
});

nextButton.addEventListener("click", () => {
  if (nextButton.disabled) return;
  currentPage += 1;
  loadAuditLog();
});

loadAuditLog();
