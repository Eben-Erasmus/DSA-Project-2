FROM ballerina/ballerina:2201.8.0

WORKDIR /app

# Copy source files
COPY . /app/

# Remove any existing target directory and build
RUN rm -rf target && bal build

EXPOSE 8086

CMD ["bal", "run", "target/bin/admin_service.jar"]
