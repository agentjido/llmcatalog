const PageMetadata = {
  mounted() {
    this.sync();
  },

  updated() {
    this.sync();
  },

  sync() {
    const indexingEnabled = this.el.dataset.indexingEnabled === "true";
    const canonicalUrl = indexingEnabled ? this.value("canonicalUrl") : null;
    const robots = indexingEnabled
      ? this.value("robots")
      : "noindex, nofollow";
    const pageTitle = this.value("pageTitle");
    const description = this.value("pageDescription");
    const image = this.value("ogImage");

    this.syncLink('link[rel="canonical"]', { rel: "canonical" }, canonicalUrl);
    this.syncMeta('meta[name="robots"]', { name: "robots" }, robots);
    this.syncMeta(
      'meta[name="description"]',
      { name: "description" },
      description,
    );
    this.syncMeta(
      'meta[property="og:title"]',
      { property: "og:title" },
      pageTitle,
    );
    this.syncMeta(
      'meta[property="og:description"]',
      { property: "og:description" },
      description,
    );
    this.syncMeta(
      'meta[property="og:url"]',
      { property: "og:url" },
      canonicalUrl,
    );
    this.syncMeta(
      'meta[property="og:image"]',
      { property: "og:image" },
      image,
    );
    this.syncMeta(
      'meta[name="twitter:title"]',
      { name: "twitter:title" },
      pageTitle,
    );
    this.syncMeta(
      'meta[name="twitter:description"]',
      { name: "twitter:description" },
      description,
    );
    this.syncMeta(
      'meta[name="twitter:image"]',
      { name: "twitter:image" },
      image,
    );
    this.syncStructuredData();
  },

  value(key) {
    const value = this.el.dataset[key];
    return value && value.trim() !== "" ? value : null;
  },

  syncLink(selector, attributes, href) {
    let element = document.head.querySelector(selector);

    if (!href) {
      element?.remove();
      return;
    }

    if (!element) {
      element = document.createElement("link");
      Object.entries(attributes).forEach(([name, value]) => {
        element.setAttribute(name, value);
      });
      document.head.appendChild(element);
    }

    element.setAttribute("href", href);
  },

  syncMeta(selector, attributes, content) {
    let element = document.head.querySelector(selector);

    if (!content) {
      element?.remove();
      return;
    }

    if (!element) {
      element = document.createElement("meta");
      Object.entries(attributes).forEach(([name, value]) => {
        element.setAttribute(name, value);
      });
      document.head.appendChild(element);
    }

    element.setAttribute("content", content);
  },

  syncStructuredData() {
    let items;

    try {
      items = JSON.parse(this.el.dataset.structuredData || "[]");
    } catch (_error) {
      return;
    }

    document.head
      .querySelectorAll("script[data-seo-structured-data]")
      .forEach((element) => element.remove());

    items.forEach((item) => {
      const element = document.createElement("script");
      element.type = "application/ld+json";
      element.dataset.seoStructuredData = "";
      element.textContent = JSON.stringify(item);
      document.head.appendChild(element);
    });
  },
};

export default PageMetadata;
