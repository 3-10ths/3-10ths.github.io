FROM node:18-alpine AS base
WORKDIR /usr/src/next/
ENV CI=true
RUN yarn global add pnpm
ARG PORT=3000
ENV PORT=${PORT}
EXPOSE ${PORT}

# Next.js collects completely anonymous telemetry data about general usage.
# Learn more here: https://nextjs.org/telemetry
# Uncomment the following line in case you want to disable telemetry during the build.
ENV NEXT_TELEMETRY_DISABLED=1

# Install dependencies only when needed
FROM base AS deps
# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk add --no-cache libc6-compat

# Install dependencies based on the preferred package manager
COPY package.json pnpm-lock.yaml ./
RUN --mount=type=cache,id=pnpm-store,target=/root/.pnpm-store \
    pnpm i --frozen-lockfile --unsafe-perm \
        | grep -v "cross-device link not permitted\|Falling back to copying packages from store"

# Rebuild only when needed
FROM base AS builder
COPY --from=deps /usr/src/next/node_modules ./node_modules
COPY --from=deps /usr/src/next/package.json /usr/src/next/pnpm-lock.yaml ./
# COPY . .
COPY app ./app
COPY public ./public
COPY tsconfig.json .eslintrc.json next-env.* *.config.js ./

RUN pnpm build
CMD ["pnpm", "dev"]

# Clean up node modules
FROM builder AS assets
RUN rm -rf node_modules && pnpm recursive exec -- rm -rf ./app ./node_modules

# Common layer for runtimes
FROM base as source

COPY entrypoint.sh .
CMD exec ./entrypoint.sh
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs \
    && chown nextjs:nodejs entrypoint.sh
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Docker compose production image, copy all the files
FROM source AS standalone

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=assets --chown=nextjs:nodejs /usr/src/next/.next/standalone ./
COPY --from=assets --chown=nextjs:nodejs /usr/src/next/.next/static ./.next/static
COPY --from=assets --chown=nextjs:nodejs /usr/src/next/public ./public
USER nextjs

FROM source AS export
COPY --from=assets --chown=nextjs:nodejs /usr/src/next/out ./
CMD [ "pnpm", "dlx", "http-server" ]

# Lambda production image
FROM public.ecr.aws/lambda/nodejs:18-arm64 as lambda
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.7.0 /lambda-adapter /opt/extensions/lambda-adapter

ARG AWS_LWA_ENABLE_COMPRESSION=false
ENV AWS_LWA_ENABLE_COMPRESSION=${AWS_LWA_ENABLE_COMPRESSION}
ARG AWS_LWA_INVOKE_MODE=response_stream
ENV AWS_LWA_INVOKE_MODE=${AWS_LWA_INVOKE_MODE}
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR ${LAMBDA_TASK_ROOT}
COPY --from=assets /usr/src/next/.next/standalone ./
COPY --from=assets /usr/src/next/.next/static ./.next/static
COPY --from=assets /usr/src/next/public ./public
# COPY --from=builder /usr/src/next/ ./
COPY --from=source /usr/src/next/entrypoint.sh ./
RUN ln -s /tmp/cache ./.next/cache
CMD exec ./entrypoint.sh
# ENTRYPOINT ["npm", "run", "start", "--loglevel=verbose", "--cache=/tmp/npm"]
