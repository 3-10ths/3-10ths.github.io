# ThreeTenths

[![Deploy GitHub Pages](https://github.com/3-10ths/3-10ths.github.io/actions/workflows/nextjs.yml/badge.svg)](https://github.com/3-10ths/3-10ths.github.io/actions/workflows/nextjs.yml)

Statically generated landing page. Hosted on [GitHub Pages](https://3-10ths.github.io/) using [GitHub Actions](https://github.com/3-10ths/3-10ths.github.io/actions/workflows/nextjs.yml).

## Contributing

This is a [Next.js](https://nextjs.org/) project bootstrapped with [`create-next-app`](https://github.com/vercel/next.js/tree/canary/packages/create-next-app).

## Install

```bash
pnpm install
echo "NEXT_PUBLIC_URI=http://localhost:3000/" >> .env.local
```

## Develop

Run the development server:

```bash
pnpm dev
```

OR develop using Docker:

```bash
docker compose up -d --build
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result. The page auto-updates as you edit files.

## Cleanup

```bash
docker compose down --rmi all -v --remove-orphans
```
