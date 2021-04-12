//
// GasolinerasBot
//
// Alexsays - 2019
//

import Foundation
#if !os(Linux)
import CoreLocation
#endif
import Telegrammer

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
            guard let mapboxToken = Enviroment.get("MAPBOX_TOKEN") else {
                return ""
            }

            var imageURL = "https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/"

            var markers: [String] = []
            gasStations.forEach { gasStation in
                markers.append("pin-s-\(markers.count + 1)+ff0004(\(gasStation.longitude),\(gasStation.latitude))")
            }

            imageURL += markers.joined(separator: ",")

            imageURL += "/\(location.longitude),\(location.latitude),12/1024x1024?access_token=\(mapboxToken)"
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
