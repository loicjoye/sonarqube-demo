FROM node:bookworm AS build

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./

RUN npm run build


FROM node:bookworm AS server

WORKDIR /app

COPY --from=build /app/dist ./dist

COPY ./package*.json ./

RUN npm ci --omit=dev

USER node

CMD ["node", "dist/main.js"]