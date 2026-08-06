"use client";

import { invoke } from "@tauri-apps/api/core";
import { type FormEvent, useState } from "react";

const projectName = {{ cookiecutter.project_name | tojson }};
const description = {{ cookiecutter.description | tojson }};

export default function Home() {
  const [name, setName] = useState("");
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);

    try {
      setMessage(await invoke<string>("greet", { name }));
    } catch (caughtError) {
      setMessage(null);
      setError(caughtError instanceof Error ? caughtError.message : "Unable to invoke Tauri.");
    }
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-6 px-6">
      <div className="space-y-3">
        <p className="text-sm text-muted-foreground">Tauri + Next.js starter</p>
        <h1 className="text-4xl font-semibold tracking-tight">{projectName}</h1>
        <p className="max-w-xl text-muted-foreground">{description}</p>
      </div>

      <form className="flex max-w-md flex-col gap-3" onSubmit={handleSubmit}>
        <label className="text-sm font-medium" htmlFor="name">
          Name
        </label>
        <input
          className="rounded-md border bg-background px-3 py-2"
          id="name"
          onChange={(event) => setName(event.target.value)}
          placeholder="Codex"
          value={name}
        />
        <button className="rounded-md bg-primary px-4 py-2 text-primary-foreground" type="submit">
          Greet from Rust
        </button>
      </form>

      {message ? <p role="status">{message}</p> : null}
      {error ? <p role="alert">{error}</p> : null}
    </main>
  );
}
