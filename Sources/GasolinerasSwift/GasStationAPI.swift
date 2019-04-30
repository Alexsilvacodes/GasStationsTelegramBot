//
// GasolinerasBot
//
// Alexsays - 2019
//

import Foundation
#if !os(Linux)
import CoreLocation
#endif

enum NetworkError: Error {
    case wrongURL
    case wrongJSON
    case serverError
}

class GasStationAPI {

    enum Constants: String {
        case serverURL = "https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes"
        case listProductsPath = "/Listados/ProductosPetroliferos"
        case productFilterPath = "/EstacionesTerrestres/FiltroProducto/"
    }

    class Helper {

        static func generateImageURL(_ gasStations: [GasStation], location: CLLocationCoordinate2D) -> String {
            guard let googleAPI = Enviroment.get("GOOGLE_API") else {
                return ""
            }

            var imageURL = """
            https://maps.googleapis.com/maps/api/staticmap?center=\(location.latitude),\
            \(location.longitude)&zoom=13&size=1024x1024&maptype=hybrid
            """
            var num = 1

            gasStations.forEach { gasStation in
                imageURL += "&markers=color:red%7Clabel:\(num)%7C\(gasStation.latitude),\(gasStation.longitude)"
                num += 1
            }

            imageURL += "&markers=color:blue%7C\(location.latitude),\(location.longitude)"
            imageURL += "&key=\(googleAPI)"
            return imageURL
        }
        
    }

    static let shared = GasStationAPI()

    func requestGasStations(productID: String,
                            completion: @escaping (Result<GasStationResponse, NetworkError>) -> Void) {
        guard let url = URL(string: Constants.serverURL.rawValue +
            Constants.productFilterPath.rawValue + productID) else {
            completion(.failure(.wrongURL))
            return
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder.init()

                    let response = try decoder.decode(GasStationResponse.self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.wrongJSON))
                }
            } else {
                completion(.failure(.serverError))
            }
        }
        task.resume()
    }

    func requestListProducts(completion: @escaping (Result<[Product], NetworkError>) -> Void) {
        guard let url = URL(string: Constants.serverURL.rawValue + Constants.listProductsPath.rawValue) else {
                completion(.failure(.wrongURL))
                return
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder.init()

                    let response = try decoder.decode([Product].self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(.wrongJSON))
                }
            } else {
                completion(.failure(.serverError))
            }
        }
        task.resume()
    }

}
