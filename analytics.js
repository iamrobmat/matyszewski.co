(() => {
  "use strict";

  const measurementId = window.MATYSZEWSKI_SITE_CONFIG?.googleAnalyticsId;
  if (!/^G-[A-Z0-9]+$/.test(measurementId || "")) {
    return;
  }

  const consentKey = "matyszewski.analytics-consent.v1";
  const consentValues = new Set(["granted", "denied"]);
  let googleTagLoaded = false;
  let consentBanner;
  let settingsButton;

  window.dataLayer = window.dataLayer || [];
  window.gtag =
    window.gtag ||
    function gtag() {
      window.dataLayer.push(arguments);
    };

  window.gtag("consent", "default", {
    ad_storage: "denied",
    ad_user_data: "denied",
    ad_personalization: "denied",
    analytics_storage: "denied",
  });
  window.gtag("set", "ads_data_redaction", true);

  function readConsent() {
    try {
      const consent = window.localStorage.getItem(consentKey);
      return consentValues.has(consent) ? consent : null;
    } catch {
      return null;
    }
  }

  function saveConsent(consent) {
    try {
      window.localStorage.setItem(consentKey, consent);
    } catch {
      // Consent still applies to the current page when storage is unavailable.
    }
  }

  function clearAnalyticsCookies() {
    const hostname = window.location.hostname;
    const domains = new Set([""]);

    if (hostname === "matyszewski.co" || hostname.endsWith(".matyszewski.co")) {
      domains.add(".matyszewski.co");
    } else if (hostname && hostname !== "localhost") {
      domains.add(`.${hostname}`);
    }

    document.cookie.split(";").forEach((cookie) => {
      const name = cookie.split("=")[0].trim();
      if (name === "_ga" || name.startsWith("_ga_")) {
        domains.forEach((domain) => {
          const domainAttribute = domain ? `; Domain=${domain}` : "";
          document.cookie = `${name}=; Max-Age=0; Path=/${domainAttribute}; SameSite=Lax`;
        });
      }
    });
  }

  function loadGoogleTag() {
    if (googleTagLoaded) {
      return;
    }

    googleTagLoaded = true;
    window.gtag("consent", "update", {
      ad_storage: "denied",
      ad_user_data: "denied",
      ad_personalization: "denied",
      analytics_storage: "granted",
    });
    window.gtag("js", new Date());
    window.gtag("config", measurementId, {
      allow_ad_personalization_signals: false,
      allow_google_signals: false,
    });

    const script = document.createElement("script");
    script.async = true;
    script.src = `https://www.googletagmanager.com/gtag/js?id=${encodeURIComponent(measurementId)}`;
    script.dataset.googleAnalytics = "true";
    document.head.append(script);
  }

  function hideBanner() {
    consentBanner?.remove();
    consentBanner = null;
    if (settingsButton) {
      settingsButton.hidden = false;
    }
  }

  function applyConsent(consent) {
    saveConsent(consent);

    if (consent === "granted") {
      loadGoogleTag();
    } else {
      window.gtag("consent", "update", {
        ad_storage: "denied",
        ad_user_data: "denied",
        ad_personalization: "denied",
        analytics_storage: "denied",
      });
      clearAnalyticsCookies();
    }

    hideBanner();
    document.dispatchEvent(
      new CustomEvent("analytics-consent-changed", {
        detail: { consent },
      }),
    );
  }

  function showBanner() {
    if (consentBanner) {
      return;
    }

    consentBanner = document.createElement("section");
    consentBanner.className = "cookie-consent";
    consentBanner.setAttribute("role", "dialog");
    consentBanner.setAttribute("aria-labelledby", "cookie-consent-title");
    consentBanner.innerHTML = `
      <div class="cookie-consent__copy">
        <strong id="cookie-consent-title">Analityka strony</strong>
        <p>
          Za Twoją zgodą użyję Google Analytics, aby sprawdzić, które treści są przydatne.
          Google Analytics uruchomi się dopiero po akceptacji. Reklamy i personalizacja pozostają wyłączone.
        </p>
      </div>
      <div class="cookie-consent__actions">
        <button class="button secondary" type="button" data-consent="denied">Odmów</button>
        <button class="button primary" type="button" data-consent="granted">Akceptuję analitykę</button>
      </div>
    `;

    consentBanner.addEventListener("click", (event) => {
      const button = event.target.closest("[data-consent]");
      if (button) {
        applyConsent(button.dataset.consent);
      }
    });

    document.body.append(consentBanner);
    if (settingsButton) {
      settingsButton.hidden = true;
    }
    consentBanner.querySelector("[data-consent='denied']")?.focus();
  }

  function createSettingsButton() {
    settingsButton = document.createElement("button");
    settingsButton.className = "cookie-settings";
    settingsButton.type = "button";
    settingsButton.textContent = "Ustawienia analityki";
    settingsButton.addEventListener("click", showBanner);
    document.body.append(settingsButton);
  }

  function initialize() {
    createSettingsButton();
    const consent = readConsent();

    if (consent === "granted") {
      loadGoogleTag();
    } else if (consent === "denied") {
      clearAnalyticsCookies();
    } else {
      showBanner();
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initialize, { once: true });
  } else {
    initialize();
  }
})();
