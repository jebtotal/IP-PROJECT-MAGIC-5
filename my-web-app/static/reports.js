const config = window.reportsConfig;
const reportPicker = document.querySelector("#report-picker");
const reportsMessage = document.querySelector("#reports-message");
const reportOutput = document.querySelector("#report-output");
const reportTitle = document.querySelector("#report-title");
const reportSubtitle = document.querySelector("#report-subtitle");
const reportFilters = document.querySelector("#report-filters");
const reportMessage = document.querySelector("#report-message");
const reportTableHead = document.querySelector("#report-table-head");
const reportTableBody = document.querySelector("#report-table-body");
let selectedReport = null;
let requestSequence = 0;

const reportDefinitions = {
  products_master: {
    name: "Product Master List",
    columns: [
      ["productCode", "Product Code"],
      ["description", "Description"],
      ["unit", "Unit"],
      ["unitPrice", "Current Unit Price"],
    ],
  },
  active_employees: {
    name: "Active Employees",
    columns: [
      ["employeeNo", "Employee No"],
      ["fullName", "Employee"],
      ["gender", "Gender"],
      ["hireDate", "Hire Date"],
      ["job", "Job"],
      ["department", "Department"],
    ],
  },
  all_employees: {
    name: "All Employees",
    columns: [
      ["employeeNo", "Employee No"],
      ["fullName", "Employee"],
      ["gender", "Gender"],
      ["hireDate", "Hire Date"],
      ["separationDate", "Separation Date"],
      ["status", "Status"],
      ["job", "Job"],
      ["department", "Department"],
    ],
  },
  employee_job_history: {
    name: "Employee Job History",
    columns: [
      ["effectiveDate", "Effective Date"],
      ["jobCode", "Job Code"],
      ["job", "Job"],
      ["departmentCode", "Department Code"],
      ["department", "Department"],
      ["salary", "Salary"],
    ],
  },
  top_customers: {
    name: "Top Customers",
    columns: [
      ["customer_no", "Customer No"],
      ["customer_name", "Customer"],
      ["transaction_count", "Transactions"],
      ["total_amount", "Sales Total"],
    ],
  },
  top_products: {
    name: "Top Products",
    columns: [
      ["product_code", "Product Code"],
      ["description", "Product"],
      ["unit", "Unit"],
      ["quantity_sold", "Quantity Sold"],
      ["revenue", "Sales Total"],
    ],
  },
  top_sales: {
    name: "Top Sales",
    columns: [
      ["transaction_no", "Transaction No"],
      ["sale_date", "Sale Date"],
      ["customer_name", "Customer"],
      ["salesperson", "Salesperson"],
      ["total_amount", "Sales Total"],
    ],
  },
};

async function request(url) {
  const response = await fetch(url, {headers: {"Accept": "application/json"}});
  let result;
  try {
    result = await response.json();
  } catch {
    throw new Error("The server returned an invalid response.");
  }
  if (!response.ok) throw new Error(result.error || "Report could not be loaded.");
  return result;
}

function appendReportCell(row, value, heading) {
  const cell = document.createElement(heading ? "th" : "td");
  if (heading) cell.scope = "col";
  cell.textContent = value === null || value === undefined || value === ""
    ? "—"
    : String(value);
  row.appendChild(cell);
}

function formatCurrency(value) {
  if (value === null || value === undefined || value === "") return "—";
  const amount = Number(value);
  return Number.isFinite(amount)
    ? new Intl.NumberFormat("en-PH", {style: "currency", currency: "PHP"}).format(amount)
    : String(value);
}

function renderRows(rows) {
  const definition = reportDefinitions[selectedReport];
  reportTableHead.replaceChildren();
  reportTableBody.replaceChildren();
  const headingRow = document.createElement("tr");
  for (const [, label] of definition.columns) appendReportCell(headingRow, label, true);
  reportTableHead.appendChild(headingRow);

  for (const rowData of rows) {
    const row = document.createElement("tr");
    for (const [key] of definition.columns) {
      const value = ["unitPrice", "salary", "total_amount", "revenue"].includes(key)
        ? formatCurrency(rowData[key])
        : rowData[key];
      appendReportCell(row, value, false);
    }
    reportTableBody.appendChild(row);
  }
  reportMessage.textContent = rows.length ? `${rows.length} row(s).` : "No records found.";
}

function buildFilters(reportId, employeeOptions = []) {
  reportFilters.replaceChildren();
  if (["top_customers", "top_products", "top_sales"].includes(reportId)) {
    const startLabel = document.createElement("label");
    startLabel.className = "record-field";
    startLabel.textContent = "Start Date";
    const start = document.createElement("input");
    start.type = "date";
    start.name = "startDate";
    start.required = true;
    start.value = config.today.slice(0, 7) + "-01";
    startLabel.appendChild(start);
    reportFilters.appendChild(startLabel);

    const endLabel = document.createElement("label");
    endLabel.className = "record-field";
    endLabel.textContent = "End Date";
    const end = document.createElement("input");
    end.type = "date";
    end.name = "endDate";
    end.required = true;
    end.value = config.today;
    endLabel.appendChild(end);
    reportFilters.appendChild(endLabel);

    const topLabel = document.createElement("label");
    topLabel.className = "record-field";
    topLabel.textContent = "Top N";
    const top = document.createElement("input");
    top.type = "number";
    top.name = "topN";
    top.min = "1";
    top.max = "100";
    top.step = "1";
    top.required = true;
    top.value = "10";
    topLabel.appendChild(top);
    reportFilters.appendChild(topLabel);
  } else if (reportId === "employee_job_history") {
    const employeeLabel = document.createElement("label");
    employeeLabel.className = "record-field";
    employeeLabel.textContent = "Employee";
    const employee = document.createElement("select");
    employee.name = "employeeNo";
    employee.required = true;
    employee.add(new Option("Choose employee...", ""));
    for (const option of employeeOptions) {
      employee.add(new Option(`${option.fullName} (${option.employeeNo})`, option.employeeNo));
    }
    employeeLabel.appendChild(employee);
    reportFilters.appendChild(employeeLabel);
  }

  if (reportFilters.children.length) {
    const run = document.createElement("button");
    run.type = "submit";
    run.className = "btn btn-primary";
    run.textContent = "Run Report";
    reportFilters.appendChild(run);
  }
}

async function runReport(event) {
  if (event) event.preventDefault();
  if (!selectedReport) return;
  const sequence = ++requestSequence;
  const query = new URLSearchParams(new FormData(reportFilters));
  reportMessage.textContent = "Loading report...";
  reportTableHead.replaceChildren();
  reportTableBody.replaceChildren();
  try {
    const result = await request(
      `/api/reports/${encodeURIComponent(selectedReport)}?${query}`,
    );
    if (sequence !== requestSequence) return;
    if (selectedReport === "employee_job_history") {
      const previousEmployee = query.get("employeeNo");
      buildFilters(selectedReport, result.employeeOptions);
      const employeeSelect = reportFilters.querySelector('[name="employeeNo"]');
      if (previousEmployee) employeeSelect.value = previousEmployee;
      if (!previousEmployee) {
        reportMessage.textContent = "Choose an employee, then run the report.";
        return;
      }
    }
    reportSubtitle.textContent = ["top_customers", "top_products", "top_sales"].includes(selectedReport)
      ? `${query.get("startDate")} through ${query.get("endDate")} · Top ${query.get("topN")}`
      : selectedReport === "employee_job_history"
        ? `Employee ${query.get("employeeNo")}`
        : "";
    renderRows(result.rows);
  } catch (error) {
    if (sequence !== requestSequence) return;
    reportMessage.textContent = error instanceof Error ? error.message : "Report could not be loaded.";
  }
}

function selectReport(reportId) {
  requestSequence += 1;
  selectedReport = reportId;
  const definition = reportDefinitions[reportId];
  reportOutput.hidden = false;
  reportTitle.textContent = definition.name;
  reportSubtitle.textContent = "";
  reportMessage.textContent = "";
  reportTableHead.replaceChildren();
  reportTableBody.replaceChildren();
  buildFilters(reportId);
  reportPicker.querySelectorAll("[data-report]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.report === reportId);
    button.setAttribute("aria-pressed", String(button.dataset.report === reportId));
  });
  if (reportFilters.children.length) {
    if (reportId === "employee_job_history") runReport();
    else reportMessage.textContent = "Set the report filters and run the report.";
  } else {
    runReport();
  }
}

for (const reportId of config.reports) {
  const definition = reportDefinitions[reportId];
  if (!definition) continue;
  const button = document.createElement("button");
  button.type = "button";
  button.className = "report-picker-button";
  button.dataset.report = reportId;
  button.setAttribute("aria-pressed", "false");
  button.textContent = definition.name;
  button.addEventListener("click", () => selectReport(reportId));
  reportPicker.appendChild(button);
}

reportFilters.addEventListener("submit", runReport);
document.querySelector("#report-print").addEventListener("click", () => window.print());
