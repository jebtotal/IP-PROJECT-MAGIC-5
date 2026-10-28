const form = document.querySelector("#register-form");
const message = document.querySelector("#form-message");
const submitButton = form.querySelector('button[type="submit"]');

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  message.textContent = "";
  submitButton.disabled = true;

  const formData = new FormData(form);
  const payload = Object.fromEntries(formData.entries());

  try {
    const response = await fetch("/api/register", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const result = await response.json();

    if (!response.ok) {
      throw new Error(result.error || "Registration could not be completed.");
    }

    message.textContent = result.message;
    form.reset();
  } catch (error) {
    message.textContent =
      error instanceof Error ? error.message : "Registration could not be completed.";
  } finally {
    submitButton.disabled = false;
  }
});
