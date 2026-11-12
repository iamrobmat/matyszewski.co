(() => {
  "use strict";

  const passwordKey = "matyszewski.course-password.v1";
  const toolKey = "matyszewski.course-tool.v1";
  const progressKeyPrefix = "matyszewski.course-progress.v1:";
  const tools = new Set(["both", "claude", "codex"]);

  const gate = document.getElementById("course-gate");
  const form = document.getElementById("gate-form");
  const input = document.getElementById("gate-password");
  const message = document.getElementById("gate-message");
  const unavailable = document.getElementById("gate-unavailable");
  const content = document.getElementById("course-content");
  const payload = readPayload();

  function readPayload() {
    const element = document.getElementById("course-payload");
    if (!element) {
      return null;
    }

    try {
      return JSON.parse(element.textContent);
    } catch {
      return null;
    }
  }

  function storageGet(key) {
    try {
      return window.localStorage.getItem(key);
    } catch {
      return null;
    }
  }

  function storageSet(key, value) {
    try {
      window.localStorage.setItem(key, value);
    } catch {
      // Ćwiczenia działają też bez zapisu w przeglądarce.
    }
  }

  function storageRemove(key) {
    try {
      window.localStorage.removeItem(key);
    } catch {
      // Brak dostępu do localStorage nie blokuje strony.
    }
  }

  // Ta sama normalizacja co w scripts/encrypt-course-page.mjs.
  function normalizePassword(password) {
    return password.normalize("NFC").trim().toLowerCase();
  }

  function base64ToBytes(value) {
    return Uint8Array.from(window.atob(value), (character) => character.charCodeAt(0));
  }

  async function decrypt(password) {
    const encoder = new TextEncoder();
    const baseKey = await crypto.subtle.importKey(
      "raw",
      encoder.encode(normalizePassword(password)),
      "PBKDF2",
      false,
      ["deriveKey"],
    );
    const key = await crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt: base64ToBytes(payload.salt),
        iterations: payload.iterations,
        hash: "SHA-256",
      },
      baseKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["decrypt"],
    );
    const plaintext = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: base64ToBytes(payload.iv) },
      key,
      base64ToBytes(payload.ciphertext),
    );
    return new TextDecoder().decode(plaintext);
  }

  // Postęp jest przypisany do hasła, więc nowe szkolenie zaczyna się od zera.
  async function progressKey(password) {
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(`course:${normalizePassword(password)}`),
    );
    const hex = Array.from(new Uint8Array(digest).slice(0, 8), (byte) =>
      byte.toString(16).padStart(2, "0"),
    ).join("");
    return `${progressKeyPrefix}${hex}`;
  }

  function readProgress(key) {
    try {
      const value = JSON.parse(storageGet(key) || "[]");
      return new Set(Array.isArray(value) ? value : []);
    } catch {
      return new Set();
    }
  }

  function setupProgress(key) {
    const checkboxes = Array.from(content.querySelectorAll("input[data-step]"));
    const done = readProgress(key);
    const doneCount = content.querySelector("[data-progress-done]");
    const totalCount = content.querySelector("[data-progress-total]");
    const bar = content.querySelector("[data-progress-bar]");

    function render() {
      const completed = checkboxes.filter((checkbox) => checkbox.checked).length;
      doneCount.textContent = String(completed);
      totalCount.textContent = String(checkboxes.length);
      bar.max = checkboxes.length;
      bar.value = completed;
      for (const checkbox of checkboxes) {
        checkbox.closest(".step")?.classList.toggle("is-done", checkbox.checked);
      }
    }

    for (const checkbox of checkboxes) {
      checkbox.checked = done.has(checkbox.dataset.step);
      checkbox.addEventListener("change", () => {
        const completed = checkboxes
          .filter((item) => item.checked)
          .map((item) => item.dataset.step);
        storageSet(key, JSON.stringify(completed));
        render();
      });
    }

    render();
  }

  function setupToolSwitch() {
    const radios = Array.from(content.querySelectorAll('input[name="course-tool"]'));
    const saved = storageGet(toolKey);
    const initial = tools.has(saved) ? saved : "both";

    function apply(tool) {
      document.documentElement.dataset.courseTool = tool;
    }

    for (const radio of radios) {
      radio.checked = radio.value === initial;
      radio.addEventListener("change", () => {
        if (radio.checked) {
          apply(radio.value);
          storageSet(toolKey, radio.value);
        }
      });
    }

    apply(initial);
  }

  async function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      await navigator.clipboard.writeText(text);
      return;
    }

    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.append(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    textarea.remove();
    if (!copied) {
      throw new Error("Copy failed");
    }
  }

  function setupCopyButtons() {
    for (const button of content.querySelectorAll(".copy-button")) {
      const label = button.textContent;
      let resetTimer;

      button.addEventListener("click", async () => {
        const text = button.closest(".prompt")?.querySelector(".prompt-text")?.textContent.trim();
        if (!text) {
          return;
        }

        try {
          await copyText(text);
          button.textContent = "Skopiowano";
        } catch {
          button.textContent = "Zaznacz i skopiuj ręcznie";
        }

        window.clearTimeout(resetTimer);
        resetTimer = window.setTimeout(() => {
          button.textContent = label;
        }, 2000);
      });
    }
  }

  async function unlock(password, { moveFocus }) {
    const html = await decrypt(password);
    content.innerHTML = html;
    gate.hidden = true;
    storageSet(passwordKey, password);
    setupToolSwitch();
    setupCopyButtons();
    setupProgress(await progressKey(password));

    if (moveFocus) {
      content.querySelector("#course-title")?.focus();
    }
  }

  function showForm() {
    form.hidden = false;
    input.focus();
  }

  async function start() {
    if (!payload || !window.crypto?.subtle) {
      unavailable.hidden = false;
      return;
    }

    const savedPassword = storageGet(passwordKey);
    if (savedPassword) {
      try {
        await unlock(savedPassword, { moveFocus: false });
        return;
      } catch {
        storageRemove(passwordKey);
      }
    }

    showForm();
  }

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const button = form.querySelector("button");
    button.disabled = true;
    message.textContent = "Sprawdzam hasło…";

    try {
      await unlock(input.value, { moveFocus: true });
      message.textContent = "";
    } catch {
      message.textContent = "To hasło nie pasuje. Sprawdź slajd albo zapytaj prowadzącego.";
      input.select();
    } finally {
      button.disabled = false;
    }
  });

  start();
})();
