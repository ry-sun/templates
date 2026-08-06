import type { NextConfig } from "next";

{% if cookiecutter.enable_react_compiler or cookiecutter.deployment_target == "static" -%}
const nextConfig: NextConfig = {
{% if cookiecutter.enable_react_compiler %}  reactCompiler: true,
{% endif %}{% if cookiecutter.deployment_target == "static" %}  output: "export",
{% endif %}};
{% else -%}
const nextConfig: NextConfig = {};
{% endif %}
export default nextConfig;
