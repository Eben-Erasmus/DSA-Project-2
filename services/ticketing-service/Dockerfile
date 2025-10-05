FROM ballerina/ballerina:2201.8.0

WORKDIR /app

COPY . .

RUN bal build

EXPOSE 8083

CMD ["bal", "run", "target/bin/ticketing_service.jar"]
