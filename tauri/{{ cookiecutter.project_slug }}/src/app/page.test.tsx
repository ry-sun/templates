import { cleanup, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import Home from "./page";

const { invoke } = vi.hoisted(() => ({
  invoke: vi.fn(),
}));

vi.mock("@tauri-apps/api/core", () => ({ invoke }));

const projectName = {{ cookiecutter.project_name | tojson }};

afterEach(cleanup);

describe("Home", () => {
  beforeEach(() => {
    invoke.mockReset();
  });

  it("renders the generated project name", () => {
    render(<Home />);
    expect(screen.getByRole("heading", { level: 1, name: projectName })).toBeInTheDocument();
  });

  it("invokes the Rust greeting command", async () => {
    invoke.mockResolvedValue("Hello, Codex! You've been greeted from Rust!");
    render(<Home />);

    fireEvent.change(screen.getByLabelText("Name"), { target: { value: "Codex" } });
    fireEvent.click(screen.getByRole("button", { name: "Greet from Rust" }));

    expect(invoke).toHaveBeenCalledWith("greet", { name: "Codex" });
    expect(
      await screen.findByText("Hello, Codex! You've been greeted from Rust!"),
    ).toBeInTheDocument();
  });
});
