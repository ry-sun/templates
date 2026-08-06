import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Home from "./page";

const projectName = {{ cookiecutter.project_name | tojson }};

describe("Home", () => {
  it("renders the generated project name", () => {
    render(<Home />);
    expect(
      screen.getByRole("heading", { level: 1, name: projectName }),
    ).toBeInTheDocument();
  });
});
