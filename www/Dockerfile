# Builder, tester and runtime container for local development
# NOTE: Use the same cypress version both in Dockerfile and package.json to
#       avoid unnecessary cypress download
FROM taitounited/cypress:3.6.0
ARG SERVICE_DIR=.
RUN apt-get -y update && apt-get -y install rsync # rsync for windows devs
ENV NODE_ENV development

RUN mkdir /service && chown node:node /service

WORKDIR /service
COPY ${SERVICE_DIR}/install.sh \
     ${SERVICE_DIR}/package* \
     /service/
RUN . ./install.sh
RUN npm install --loglevel warn

# Install site npm libraries on container to speed up builds
COPY ${SERVICE_DIR}/hooks.json \
     ${SERVICE_DIR}/site/package* \
     /service/site/
RUN rm -f /service/site/hooks.json
RUN mkdir -p /build && \
    npm run install-site

# Start development
EXPOSE 8080
CMD eval $DC_COMMAND; . ~/.bashrc && ./develop.sh
