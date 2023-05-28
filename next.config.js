/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  output: 'export', // standalone vs export, ensure to update .env IMAGE_TARGET
  compress: false,
}

module.exports = nextConfig
