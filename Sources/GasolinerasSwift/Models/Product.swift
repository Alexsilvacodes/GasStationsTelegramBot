//
// GasolinerasBot
//
// Alexsays - 2019
//

import Foundation

struct Product: Decodable {
    var productID: String
    var name: String
    var shortname: String

    private enum CodingKeys: String, CodingKey {
        case productID = "IDProducto"
        case name = "NombreProducto"
        case shortname = "NombreProductoAbreviatura"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productID = try container.decode(String.self, forKey: .productID)
        name = try container.decode(String.self, forKey: .name)
        shortname = try container.decode(String.self, forKey: .shortname)
    }
}
