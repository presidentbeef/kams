FROM ruby:2.5

#RUN apk add \
#  ruby-full \
#  ruby-dev

RUN gem install bundler

COPY . /app/
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh
WORKDIR /app

#COPY ../kams-storage /storage

# Swap the base storage for the real storage
#RUN if [ -d /storage ] \
#  then \
#    rm /app/storage && \
#    cp -r /storage/ /app/storage
#  fi

RUN bundle install

#ENTRYPOINT ["/usr/bin/entrypoint.sh"]
#ENTRYPOINT ["ruby", "/app/main.rb"]
#CMD ["/bin/bash"]
#CMD ["ruby", "./server.rb"]
CMD ["/usr/bin/entrypoint.sh"]
