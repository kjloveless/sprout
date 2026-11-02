export function mount(root, props) {
  const output = root.querySelector("[data-count]");
  const button = root.querySelector("[data-add]");

  if (!output || !button || !Number.isSafeInteger(props.initial)) {
    throw new Error("invalid counter markup or intitial value");
  }

  let count = props.initial;
  button.addEventListener("click", () => {
    if (count === Number.MAX_SAFE_INTEGER) return;
    count += 1;
    output.textContent = String(count);
  });
}
