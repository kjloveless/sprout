const islands = new Map([
  ["counter", () => import("/assets/counter.js")]
]);

for (const root of document.querySelectorAll("[data-island]")) {
  const load = islands.get(root.dataset.island);
  if (!load) {
    console.error("unknown island:", root.dataset.island);
    continue;
  }

  try {
    const props = JSON.parse(root.dataset.props ?? "{}");
    const { mount } = await load();
    mount(root, props);
  } catch (error) {
    console.error("could not start island:", error);
  }
}
