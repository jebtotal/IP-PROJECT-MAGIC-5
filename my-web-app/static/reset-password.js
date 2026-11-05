const form = document.querySelector("#reset-password-form");
const message = document.querySelector("#form-message");
const submitButton = form.querySelector('button[type="submit"]');

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  message.textContent = "";
  submitButton.disabled = true;

  try {
    const response = await fetch("/api/reset-password", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(Object.fromEntries(new FormData(form).entries())),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || "Password reset failed.");
    window.location.assign(result.redirect);
  } catch (error) {
    message.textContent = error instanceof Error ? error.message : "Password reset failed.";
    submitButton.disabled = false;
  }
});
