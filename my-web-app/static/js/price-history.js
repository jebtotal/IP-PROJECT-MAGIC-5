function renderPrices(records) {
  pricesBody.replaceChildren();
  const today = new Date().toISOString().split("T")[0];
  for (const record of records) {
    const row = document.createElement("tr");
    if (record.isDeleted) row.classList.add("record-deleted");
    addCell(row, record.effDate, "Effective Date");
    addCell(row, record.unitPrice, "Unit Price");
    // Mark the row that is in force today with "Current" badge
    const isCurrent = !record.isDeleted && record.effDate <= today;
    if (config.isAdmin) {
      const status = addCell(row, record.isDeleted ? "Inactive" : "Active", "Status");
      status.classList.add("record-status");
      const stampCell = addCell(row, record.stamp, "Stamp");
      if (isCurrent) {
        stampCell.classList.add("status-approved");
        stampCell.title = "Current price row";
      }
    }
    // Add "Current" indicator cell for all viewers when row is in force
    if (isCurrent && !config.isAdmin) {
      const currentCell = document.createElement("td");
      currentCell.dataset.label = "Current";
      currentCell.className = "status-approved font-bold";
      currentCell.textContent = "Current";
      row.appendChild(currentCell);
    }

    const actionsCell = document.createElement("td");