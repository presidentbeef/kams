#FROM ruby:2.5
FROM ruby:2.3

#RUN apk add \
#  ruby-full \
#  ruby-dev

RUN gem install bundler -v 1.17.3

COPY app /app/


WORKDIR /app

RUN mkdir /storage && \
  mkdir /conf && \
  mv storage/* /storage && \
  mv conf/* /conf && \
  rm -r storage/ && \
  rm -r conf && \
  ln -s /storage storage && \
  ln -s /conf conf

WORKDIR /app

#COPY ../kams-storage /storage

# Swap the base storage for the real storage
#RUN if [ -d /storage ] \
#  then \
#    rm /app/storage && \
#    cp -r /storage/ /app/storage
#  fi
# This now happens at runtime, not build-time!

RUN bundle install

COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh


# Redirect the log to STDOUT
#RUN ln -sf /dev/stdout /app/logs/system.log     
#  && ln -sf /dev/stderr /app/log/error.log
# I think error.log doesn't exist

ENTRYPOINT ["/usr/bin/entrypoint.sh"]
#ENTRYPOINT ["ruby", "/app/main.rb"]
#CMD ["/bin/bash"]
#CMD ["ruby", "./server.rb"]
#CMD ["/usr/bin/entrypoint.sh"]
