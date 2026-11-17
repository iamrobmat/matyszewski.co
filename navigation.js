(() => {
  const finePointer = window.matchMedia("(hover: hover) and (pointer: fine)");

  document.querySelectorAll(".nav-dropdown").forEach((dropdown) => {
    const summary = dropdown.querySelector("summary");
    const menu = dropdown.querySelector(".nav-dropdown-menu");
    let closeTimer;

    if (!summary || !menu) {
      return;
    }

    const openOnHover = () => {
      if (!finePointer.matches) {
        return;
      }

      window.clearTimeout(closeTimer);
      dropdown.open = true;
    };

    const closeAfterHover = () => {
      if (!finePointer.matches) {
        return;
      }

      window.clearTimeout(closeTimer);
      closeTimer = window.setTimeout(() => {
        if (!menu.contains(document.activeElement)) {
          dropdown.open = false;
        }
      }, 180);
    };

    dropdown.addEventListener("mouseenter", openOnHover);
    dropdown.addEventListener("mouseleave", closeAfterHover);

    summary.addEventListener("click", (event) => {
      if (finePointer.matches && event.detail > 0 && dropdown.open) {
        event.preventDefault();
      }
    });

    dropdown.addEventListener("focusout", (event) => {
      if (!dropdown.contains(event.relatedTarget)) {
        dropdown.open = false;
      }
    });
  });
})();
