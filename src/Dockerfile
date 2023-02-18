FROM ubuntu:18.04

WORKDIR /app
SHELL ["/bin/bash", "-l", "-c"]  # Required to make RVM work
CMD passenger start -p 8080 --static-files-dir ./public

# Install requirements for RVM installation
RUN apt-get update && apt-get install -y curl gpg

# Install RVM
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg --import - && \
    curl -sSL https://get.rvm.io | bash -s stable && \
    echo "source /usr/local/rvm/scripts/rvm" >> ~/.bashrc

# Install Ruby 1.8.7
RUN rvm install 1.8.7 && \
    rvm install rubygems 1.8.2 --force

# Install required gems
RUN gem install rails -v 2.3.8 && \
    gem install sqlite3-ruby -v 1.2.1 && \
    gem install passenger -v 4.0.45 && \
    gem install bundler -v 1.8.7 && \
    gem install rake -v 10.1.1

COPY . /app
