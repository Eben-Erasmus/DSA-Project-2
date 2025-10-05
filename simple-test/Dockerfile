FROM ballerina/ballerina:2201.8.0

WORKDIR /app

COPY . /app/

RUN rm -rf target && bal build

EXPOSE 8090

CMD ["bal", "run", "target/bin/simple_service.jar"]
