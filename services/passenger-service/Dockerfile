FROM ballerina/ballerina:2201.8.0

WORKDIR /app
COPY . /app/
RUN rm -rf target && bal build
EXPOSE 8091
CMD ["bal", "run", "target/bin/passenger_service.jar"]
