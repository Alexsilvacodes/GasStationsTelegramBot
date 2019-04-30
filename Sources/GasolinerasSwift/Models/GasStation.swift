//
// GasolinerasBot
//
// Alexsays - 2019
//

struct GasStationResponse: Decodable {

    var date: String
    var gasStations: [GasStation]
    var message: String
    var result: String

    private enum CodingKeys: String, CodingKey {
        case date = "Fecha"
        case gasStations = "ListaEESSPrecio"
        case message = "Nota"
        case result = "ResultadoConsulta"
    }

}

struct GasStation: Decodable {

    var zipcode: String
    var address: String
    var schedule: String
    var latitude: String
    var longitude: String
    var city: String
    var municipality: String
    var province: String
    var name: String
    var gasStationID: String
    var municipalityID: String
    var provinceID: String
    var acID: String
    var price: String?

    private enum CodingKeys: String, CodingKey {
        case zipcode = "C.P."
        case address = "Dirección"
        case schedule = "Horario"
        case latitude = "Latitud"
        case longitude = "Longitud (WGS84)"
        case city = "Localidad"
        case municipality = "Municipio"
        case province = "Provincia"
        case name = "Rótulo"
        case gasStationID = "IDEESS"
        case municipalityID = "IDMunicipio"
        case provinceID = "IDProvincia"
        case acID = "IDCCAA"
        case price = "PrecioProducto"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        zipcode = try container.decode(String.self, forKey: .zipcode)
        address = try container.decode(String.self, forKey: .address)
        schedule = try container.decode(String.self, forKey: .schedule)
        latitude = try container.decode(String.self, forKey: .latitude)
        latitude = latitude.replacingOccurrences(of: ",", with: ".")
        longitude = try container.decode(String.self, forKey: .longitude)
        longitude = longitude.replacingOccurrences(of: ",", with: ".")
        city = try container.decode(String.self, forKey: .city)
        municipality = try container.decode(String.self, forKey: .municipality)
        province = try container.decode(String.self, forKey: .province)
        name = try container.decode(String.self, forKey: .name)
        gasStationID = try container.decode(String.self, forKey: .gasStationID)
        municipalityID = try container.decode(String.self, forKey: .municipalityID)
        provinceID = try container.decode(String.self, forKey: .provinceID)
        acID = try container.decode(String.self, forKey: .acID)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        if let priceAux = price {
            price = priceAux.replacingOccurrences(of: ",", with: ".")
        }
    }

}
