FROM node:11.3.0

WORKDIR /usr/src/app

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

CMD yarn start