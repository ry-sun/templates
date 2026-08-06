const projectName = {{ cookiecutter.project_name | tojson }};
const description = {{ cookiecutter.description | tojson }};

export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col justify-center gap-4 px-6">
      <p className="text-sm text-muted-foreground">Next.js frontend starter</p>
      <h1 className="text-4xl font-semibold tracking-tight">{projectName}</h1>
      <p className="max-w-xl text-muted-foreground">{description}</p>
    </main>
  );
}
