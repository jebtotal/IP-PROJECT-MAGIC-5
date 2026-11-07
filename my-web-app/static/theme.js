(() => {
  const themeKey = "erp-theme";
  const root = document.documentElement;

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const isDark = root.classList.toggle("dark");
      localStorage.setItem(themeKey, isDark ? "dark" : "light");
    });
  });

  document.querySelectorAll("[data-password-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const input = document.getElementById(button.dataset.passwordToggle);
      if (!input) return;
      const showPassword = input.type === "password";
      input.type = showPassword ? "text" : "password";
      button.setAttribute("aria-label", showPassword ? "Hide password" : "Show password");
      const icon = button.querySelector("i");
      if (icon) {
        icon.classList.toggle("fa-eye", !showPassword);
        icon.classList.toggle("fa-eye-slash", showPassword);
      }
    });
  });

  document.querySelectorAll("[data-dialog-close]").forEach((button) => {
    button.addEventListener("click", () => {
      document.getElementById(button.dataset.dialogClose)?.close();
    });
  });

  const sidebar = document.getElementById("app-sidebar");
  const sidebarToggle = document.querySelector("[data-sidebar-toggle]");
  if (sidebar && sidebarToggle) {
    sidebarToggle.addEventListener("click", () => {
      const isOpen = sidebar.classList.toggle("is-open");
      sidebarToggle.setAttribute("aria-expanded", String(isOpen));
    });
    document.addEventListener("click", (event) => {
      if (
        sidebar.classList.contains("is-open") &&
        !sidebar.contains(event.target) &&
        !sidebarToggle.contains(event.target)
      ) {
        sidebar.classList.remove("is-open");
        sidebarToggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  const confirmDialog = document.getElementById("confirm-dialog");
  const confirmMessage = document.getElementById("confirm-message");
  if (confirmDialog && confirmMessage) {
    let resolveConfirmation;
    const finishConfirmation = (confirmed) => {
      if (!resolveConfirmation) return;
      const resolve = resolveConfirmation;
      resolveConfirmation = null;
      confirmDialog.close();
      resolve(confirmed);
    };
    confirmDialog.querySelector("[data-confirm-cancel]").addEventListener("click", () => {
      finishConfirmation(false);
    });
    confirmDialog.querySelector("[data-confirm-accept]").addEventListener("click", () => {
      finishConfirmation(true);
    });
    confirmDialog.addEventListener("close", () => finishConfirmation(false));
    window.confirmAction = (message) => {
      confirmMessage.textContent = message;
      confirmDialog.showModal();
      return new Promise((resolve) => {
        resolveConfirmation = resolve;
      });
    };
  }
})();
