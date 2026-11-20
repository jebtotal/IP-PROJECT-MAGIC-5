(() => {
  const overlay = document.querySelector("#auth-modal-overlay");
  if (!overlay) return;

  const panels = [...overlay.querySelectorAll("[data-modal-panel]")];
  const routeByModal = {
    login: "/login",
    register: "/register",
    forgot: "/forgot-password",
    reset: "/reset-password",
    set_password: "/set-password",
  };
  const modalByPath = Object.fromEntries(
    Object.entries(routeByModal).map(([modal, path]) => [path, modal])
  );
  let lastTrigger = null;

  const showModal = (name, updateHistory = true) => {
    const panel = panels.find((item) => item.dataset.modalPanel === name);
    if (!panel) return;

    panels.forEach((item) => {
      item.hidden = item !== panel;
    });
    overlay.classList.add("active");
    overlay.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-open");

    const path = routeByModal[name];
    if (updateHistory && path && window.location.pathname !== path) {
      window.history.pushState({ authModal: name }, "", path);
    }

    panel.querySelector("input:not([type='hidden'])")?.focus({ preventScroll: true });
  };

  const closeModal = (updateHistory = true) => {
    const wasOpen = overlay.classList.contains("active");
    overlay.classList.remove("active");
    overlay.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-open");
    panels.forEach((panel) => {
      panel.hidden = true;
    });

    if (updateHistory && wasOpen && window.location.pathname !== "/") {
      window.history.replaceState({}, "", "/");
    }
    lastTrigger?.focus({ preventScroll: true });
  };

  document.addEventListener("click", (event) => {
    const trigger = event.target.closest("[data-auth-modal]");
    if (trigger) {
      event.preventDefault();
      lastTrigger = trigger;
      showModal(trigger.dataset.authModal);
      return;
    }

    if (event.target.closest("[data-auth-close]")) {
      closeModal();
    }
  });

  overlay.addEventListener("click", (event) => {
    if (event.target === overlay) closeModal();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && overlay.classList.contains("active")) {
      event.preventDefault();
      closeModal();
    }
  });

  window.addEventListener("popstate", () => {
    const name = modalByPath[window.location.pathname];
    if (name) {
      showModal(name, false);
    } else {
      closeModal(false);
    }
  });

  const query = new URLSearchParams(window.location.search);
  const queryModal = query.get("authModal");
  const initialModal =
    overlay.dataset.openModal || queryModal || modalByPath[window.location.pathname];
  if (initialModal) {
    if (initialModal === "reset") {
      const tokenInput = overlay.querySelector('#reset-password-form [name="token"]');
      if (tokenInput) tokenInput.value = query.get("token") || tokenInput.value;
    }
    showModal(initialModal, false);
    if (queryModal && routeByModal[queryModal]) {
      const token = queryModal === "reset" ? query.get("token") : null;
      const suffix = token ? `?token=${encodeURIComponent(token)}` : "";
      window.history.replaceState({}, "", `${routeByModal[queryModal]}${suffix}`);
    }
  }

  document.querySelectorAll(".auth-modal form").forEach((form) => {
    const message = form.querySelector("[data-form-message]");
    const submitButton = form.querySelector('button[type="submit"]');
    if (!message || !submitButton) return;

    form.addEventListener("submit", async (event) => {
      event.preventDefault();
      message.textContent = "";
      message.classList.remove("success");
      submitButton.disabled = true;

      try {
        const formData = new FormData(form);
        if (form.id === "register-form") {
          formData.set(
            "full_name",
            `${formData.get("first_name").trim()} ${formData.get("last_name").trim()}`.trim()
          );
        }

        const response = await fetch(form.action, {
          method: form.method.toUpperCase(),
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(Object.fromEntries(formData.entries())),
        });
        const result = await response.json();

        if (!response.ok) {
          throw new Error(result.error || "The request could not be completed.");
        }

        if (form.id === "login-form" || form.id === "reset-password-form" || form.id === "set-password-form") {
          window.location.assign(result.redirect);
          return;
        }

        message.classList.add("success");
        message.textContent = result.message;
        if (form.id === "register-form") form.reset();
      } catch (error) {
        message.textContent =
          error instanceof Error ? error.message : "The request could not be completed.";
      } finally {
        submitButton.disabled = false;
      }
    });
  });
})();
