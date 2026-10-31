const form = document.querySelector("#login-form");
const message = document.querySelector("#form-message");
const submitButton = form.querySelector('button[type="submit"]');

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  message.textContent = "";
  submitButton.disabled = true;

  try {
    const response = await fetch("/api/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(Object.fromEntries(new FormData(form).entries())),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error || "Login failed.");
    window.location.assign(result.redirect);
  } catch (error) {
    message.textContent = error instanceof Error ? error.message : "Login failed.";
    submitButton.disabled = false;
  }
});
