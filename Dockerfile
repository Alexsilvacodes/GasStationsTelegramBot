FROM futurejones/swiftlang

RUN apt-get install libssl-dev
RUN mkdir /gas-stations-spain
COPY . /gas-stations-spain
WORKDIR /gas-stations-spain
RUN swift build
CMD [ "./.swift-bin/GasolinerasSwift" ]