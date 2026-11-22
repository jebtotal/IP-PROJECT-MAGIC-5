const config = window.reportConfig;
const filterForm = document.querySelector("#report-filters");
const reportMessage = document.querySelector("#report-message");
const reportHead = document.querySelector("#report-head");
const reportBody = document.querySelector("#report-body");
const runButton = document.querySelector("#report-run");
const printButton = document.querySelector("#report-print");
const pdfButton = document.querySelector("#report-pdf");
let hasResults = false;
const currencyFields = new Set(["totalSales", "currentPrice", "salary", "totalAmount"]);

async function request(url) {
  const response = await fetch(url);
  const result = await response.json();
  if (!response.ok) throw new Error(result.error || "Request could not be completed.");
  return result;
}

function localDate(value) {
  const year = value.getFullYear();
  const month = String(value.getMonth() + 1).padStart(2, "0");
  const day = String(value.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function setupFilters() {
  if (config.filters.includes("dates")) {
    const today = new Date();
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    document.querySelector("#report-from-date").value = localDate(monthStart);
    document.querySelector("#report-to-date").value = localDate(today);
  }
  if (config.filters.includes("employee")) loadEmployees();
}

async function loadEmployees() {
  const select = document.querySelector("#report-employee");
  try {
    const result = await request("/api/reports/employee-job-history/options");
    for (const employee of result.employees) {
      const option = document.createElement("option");
      option.value = employee.empNo;
      option.textContent = `${employee.empNo} — ${employee.name}`;
      select.appendChild(option);
    }
  } catch (error) {
    reportMessage.textContent = error instanceof Error ? error.message : "Employees could not be loaded.";
  }
}

function renderReport(columns, rows) {
  const header = document.createElement("tr");
  for (const column of columns) {
    const heading = document.createElement("th");
    heading.scope = "col";
    heading.textContent = column.label;
    header.appendChild(heading);
  }
  reportHead.replaceChildren(header);
  reportBody.replaceChildren();
  for (const rowData of rows) {
    const row = document.createElement("tr");
    for (const column of columns) {
      const cell = document.createElement("td");
      cell.dataset.label = column.label;
      const value = rowData[column.key];
      if (currencyFields.has(column.key) && value !== null && value !== undefined && value !== "—") {
        const amount = Number(value);
        cell.textContent = Number.isFinite(amount)
          ? `$${amount.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}`
          : value;
      } else {
        cell.textContent = value ?? "—";
      }
      row.appendChild(cell);
    }
    reportBody.appendChild(row);
  }
}

async function runReport(event) {
  if (event) event.preventDefault();
  reportMessage.textContent = "";
  runButton.disabled = true;
  const params = new URLSearchParams(new FormData(filterForm));
  try {
    const result = await request(`/api/reports/${encodeURIComponent(config.slug)}?${params}`);
    renderReport(result.columns, result.rows);
    reportMessage.textContent = result.rows.length
      ? `${result.rows.length} result${result.rows.length === 1 ? "" : "s"}`
      : "No results found for these filters.";
    hasResults = true;
    printButton.disabled = false;
    pdfButton.disabled = false;
  } catch (error) {
    reportMessage.textContent = error instanceof Error ? error.message : "Report could not be generated.";
    reportHead.replaceChildren();
    reportBody.replaceChildren();
    hasResults = false;
    printButton.disabled = true;
    pdfButton.disabled = true;
  } finally {
    runButton.disabled = false;
  }
}

filterForm.addEventListener("submit", runReport);
printButton.addEventListener("click", () => {
  if (hasResults) window.print();
});
pdfButton.addEventListener("click", () => {
  if (hasResults) window.print();
});

setupFilters();
