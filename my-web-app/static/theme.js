(() => {
  const themeKey = "erp-theme";
  const root = document.documentElement;

  document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      const isDark = root.classList.toggle("dark");
      try {
        localStorage.setItem(themeKey, isDark ? "dark" : "light");
      } catch {
        // The current page theme still changes when storage is unavailable.
      }
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

  const sidebarCollapse = document.querySelector("[data-sidebar-collapse]");
  const sidebarResize = document.querySelector("[data-sidebar-resize]");
  if (sidebar && sidebarCollapse && sidebarResize) {
    const sidebarKey = "erp-sidebar";
    const collapsedWidth = 72;
    const defaultWidth = 272;
    const minExpandedWidth = 120;
    const maxWidth = 320;
    let width = defaultWidth;
    let collapsed = root.dataset.sidebarCollapsed === "true";

    try {
      const stored = JSON.parse(localStorage.getItem(sidebarKey) || "{}");
      if (Number.isFinite(stored.width)) {
        width = Math.min(maxWidth, Math.max(collapsedWidth, stored.width));
      }
      collapsed = Boolean(stored.collapsed);
    } catch {
      width = defaultWidth;
      collapsed = false;
    }

    const saveSidebar = () => {
      root.dataset.sidebarCollapsed = String(collapsed);
      root.style.setProperty("--sidebar-width", `${collapsed ? collapsedWidth : width}px`);
      sidebarResize.setAttribute("aria-valuenow", String(collapsed ? collapsedWidth : width));
      sidebarCollapse.setAttribute("aria-expanded", String(!collapsed));
      sidebarCollapse.setAttribute("aria-label", collapsed ? "Expand sidebar" : "Collapse sidebar");
      sidebarCollapse.title = collapsed ? "Expand sidebar" : "Collapse sidebar";
      sidebarCollapse.innerHTML = `<i class="fa-solid fa-angles-${collapsed ? "right" : "left"}" aria-hidden="true"></i>`;
      sidebar.querySelectorAll(".sidebar-link").forEach((link) => {
        link.setAttribute("aria-label", link.querySelector("span")?.textContent.trim() || "");
        link.title = link.querySelector("span")?.textContent.trim() || "";
      });
      try {
        localStorage.setItem(sidebarKey, JSON.stringify({width, collapsed}));
      } catch {
        // Keep the layout usable for this page when storage is unavailable.
      }
    };

    const applyWidth = (nextWidth) => {
      if (nextWidth < minExpandedWidth) {
        width = collapsedWidth;
        collapsed = true;
      } else {
        width = Math.min(maxWidth, Math.max(minExpandedWidth, nextWidth));
        collapsed = false;
      }
      saveSidebar();
    };

    sidebarCollapse.addEventListener("click", () => {
      collapsed = !collapsed;
      if (!collapsed && width < minExpandedWidth) width = defaultWidth;
      saveSidebar();
    });

    sidebarResize.addEventListener("pointerdown", (event) => {
      if (window.matchMedia("(max-width: 767px)").matches) return;
      event.preventDefault();
      sidebarResize.setPointerCapture(event.pointerId);
      const move = (pointerEvent) => applyWidth(pointerEvent.clientX);
      const finish = () => {
        sidebarResize.removeEventListener("pointermove", move);
        sidebarResize.removeEventListener("pointerup", finish);
        sidebarResize.removeEventListener("pointercancel", finish);
      };
      sidebarResize.addEventListener("pointermove", move);
      sidebarResize.addEventListener("pointerup", finish, {once: true});
      sidebarResize.addEventListener("pointercancel", finish, {once: true});
    });

    sidebarResize.addEventListener("dblclick", () => {
      width = defaultWidth;
      collapsed = false;
      saveSidebar();
    });

    sidebarResize.addEventListener("keydown", (event) => {
      if (event.key === "ArrowLeft" || event.key === "ArrowRight") {
        event.preventDefault();
        const direction = event.key === "ArrowRight" ? 1 : -1;
        const currentWidth = collapsed ? minExpandedWidth - 16 : width;
        applyWidth(currentWidth + direction * 16);
      } else if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        collapsed = !collapsed;
        if (!collapsed && width < minExpandedWidth) width = defaultWidth;
        saveSidebar();
      }
    });

    saveSidebar();
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
