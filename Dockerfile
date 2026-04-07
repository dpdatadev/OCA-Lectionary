# Use the official Ruby image as the base image
FROM ruby:3.3-slim

# Set the working directory inside the container
WORKDIR /app

# Install system dependencies required for native gem compilation
RUN apt-get update && apt-get install -y \
  build-essential \
  ruby-dev \
  && rm -rf /var/lib/apt/lists/*

# Copy the Gemfile and Gemfile.lock to install dependencies
COPY Gemfile Gemfile.lock ./

# Install the Ruby dependencies
RUN bundle install

# Copy the rest of the application code
COPY . .

# Set the entry point to run app.rb
CMD ["ruby", "app.rb"]