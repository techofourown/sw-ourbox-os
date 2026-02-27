(() => {
  const listEl = document.getElementById("task-list");
  const inputEl = document.getElementById("task-input");
  const addBtn = document.getElementById("add-btn");
  const STORAGE_KEY = "todo-bloom-tasks";

  const load = () => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
    } catch (e) {
      console.warn("Failed to parse tasks", e);
      return [];
    }
  };

  const save = (tasks) => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
  };

  const render = (tasks) => {
    listEl.innerHTML = "";
    if (!tasks.length) {
      const empty = document.createElement("li");
      empty.className = "empty";
      empty.textContent = "No tasks yet";
      listEl.appendChild(empty);
      return;
    }
    tasks.forEach((task, idx) => {
      const li = document.createElement("li");
      const label = document.createElement("span");
      label.textContent = task;
      const del = document.createElement("button");
      del.type = "button";
      del.className = "ghost";
      del.textContent = "Remove";
      del.addEventListener("click", () => {
        const next = [...tasks.slice(0, idx), ...tasks.slice(idx + 1)];
        save(next);
        render(next);
      });
      li.append(label, del);
      listEl.appendChild(li);
    });
  };

  const add = () => {
    const value = (inputEl.value || "").trim();
    if (!value) return;
    const tasks = load();
    const next = [...tasks, value];
    save(next);
    render(next);
    inputEl.value = "";
    inputEl.focus();
  };

  addBtn.addEventListener("click", add);
  inputEl.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      e.preventDefault();
      add();
    }
  });

  render(load());
})();
