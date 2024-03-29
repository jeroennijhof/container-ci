FROM ruby:3.0.4 AS stable
WORKDIR /app
COPY . ./
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker/compose-bin /docker-compose /root/.docker/cli-plugins/docker-compose

RUN rm -f Gemfile.lock
RUN bundle install

EXPOSE 9292
HEALTHCHECK CMD wget -Y off -q --spider http://localhost:9292/ || exit 1
CMD bundle exec rackup -o0.0.0.0 -p9292


FROM stable AS test
CMD bundle exec rspec


FROM stable AS security-checks
CMD bundle exec env
