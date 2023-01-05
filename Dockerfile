FROM swift:5.7.2

RUN apt update && apt install libssl-dev -y
RUN mkdir /gas-stations-spain
COPY . /gas-stations-spain
WORKDIR /gas-stations-spain
RUN swift build
CMD [ "./.swift-bin/GasolinerasSwift" ]
