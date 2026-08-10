import type { NextConfig } from "next";

const isProduction = process.env.NODE_ENV === "production";
const internalHost = process.env.TAURI_DEV_HOST ?? "localhost";

const nextConfig: NextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
  assetPrefix: isProduction ? undefined : `http://${internalHost}:3000`,
{% if cookiecutter.enable_react_compiler %}  reactCompiler: true,
{% endif %}};

export default nextConfig;
