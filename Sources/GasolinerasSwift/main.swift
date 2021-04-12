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

guard let token = Enviroment.get("GASOLINERAS_TOKEN"), Enviroment.get("MAPBOX_TOKEN") != nil else {
    print("Token not available")
    exit(1)
}

class GasStationController {
    let bot: Bot
    var productID: String

    init(bot: Bot) {
        self.bot = bot
        self.productID = ""
    }

    func gasinfoHandler(_ update: Update, _ context: BotContext?) throws {
        guard let message = update.message else { return }

        GasStationAPI.shared.requestListProducts() { result in
            let deleteParams = Bot.DeleteMessageParams(chatId: .chat(message.chat.id),
                                                       messageId: message.messageId)
            do { try self.bot.deleteMessage(params: deleteParams) } catch { print(error.localizedDescription) }

            switch result {
            case .success(let response):
                let desiredProducts = ["G98E5", "G98E10", "GOA", "NGO", "G95E5", "G95E10", "GLP", "GNC", "GNL"]
                let products = response.filter { desiredProducts.contains($0.shortname) }
                var buttons: [InlineKeyboardButton] = []
                products.forEach { product in
                    let button = InlineKeyboardButton(text: product.name, callbackData: "prod/\(product.productID)")
                    buttons.append(button)
                }
                var matrix: [[InlineKeyboardButton]] = [[]]
                while buttons.count > 1 {
                    matrix.append([buttons.removeFirst(), buttons.removeFirst()])
                }
                if buttons.count > 0 {
                    matrix.append([buttons.removeFirst()])
                }
                let keyboard = InlineKeyboardMarkup(inlineKeyboard: matrix)
                let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                   text: "Seleccione un producto",
                                                   replyMarkup: ReplyMarkup.inlineKeyboardMarkup(keyboard))
                do { try self.bot.sendMessage(params: params) } catch { print(error.localizedDescription) }
            case .failure(let error):
                let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                   text: error.localizedDescription)
                do { try self.bot.sendMessage(params: params) } catch { print(error.localizedDescription) }
            }
        }
    }

    func productHandler(_ update: Update, _ context: BotContext?) throws {
        guard let query = update.callbackQuery, let message = query.message, let data = query.data else { return }

        let deleteParams = Bot.DeleteMessageParams(chatId: .chat(message.chat.id),
                                                   messageId: message.messageId)
        do { try self.bot.deleteMessage(params: deleteParams) } catch { print(error.localizedDescription) }

        productID = String(data.split(separator: "/")[1])

        if let updateMsg = update.message, let location = updateMsg.location {
            resolveGasStations(update,
                               latitude: Double(location.latitude),
                               longitude: Double(location.longitude))
        } else {
            let button = [[KeyboardButton(text: "Enviar localización actual", requestLocation: true)]]
            let markup = ReplyKeyboardMarkup(keyboard: button, oneTimeKeyboard: true)
            let locationParams = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                       text: "Gasolineras cercanas",
                                                       replyMarkup: ReplyMarkup.replyKeyboardMarkup(markup))

            do { try self.bot.sendMessage(params: locationParams) } catch { print(error.localizedDescription) }
        }
    }

    func locationHandler(_ update: Update, _ context: BotContext?) throws {
        guard let message = update.message, let location = message.location else { return }

        let deleteParams = Bot.DeleteMessageParams(chatId: .chat(message.chat.id),
                                                   messageId: message.messageId)
        do { try self.bot.deleteMessage(params: deleteParams) } catch { print(error.localizedDescription) }
        let markup = ReplyMarkup.replyKeyboardRemove(ReplyKeyboardRemove(removeKeyboard: true))
        let removeParams = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                 text: "...",
                                                 replyMarkup: markup)
        do {
            try self.bot.sendMessage(params: removeParams).whenSuccess { message in
                let deleteParams = Bot.DeleteMessageParams(chatId: .chat(message.chat.id),
                                                           messageId: message.messageId)
                do { try self.bot.deleteMessage(params: deleteParams) } catch { print(error.localizedDescription) }
            }
        } catch { print(error.localizedDescription) }


        resolveGasStations(update,
                           latitude: Double(location.latitude),
                           longitude: Double(location.longitude))
    }

    private func resolveGasStations(_ update: Update, latitude: Double, longitude: Double) {
        guard let message = update.message else { return }

        GasStationAPI.shared.requestGasStations(productID: productID) { result in
            switch result {
            case .success(let response):
                let currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                var gasStations = response.gasStations.sorted(by: { Double($1.price!)! > Double($0.price!)! })
                    .filter {
                        let gsLocation = CLLocationCoordinate2D(latitude: Double($0.latitude)!, longitude: Double($0.longitude)!)
                        return currentLocation.distance(to: gsLocation) / 1000 <= 10
                }
                gasStations = Array(gasStations.prefix(6))
                var resultText = "_Actualizado - \(response.date) Hora Peninsular_\n\n"
                var num = 1
                gasStations.forEach { gasStation in
                    resultText += "⛽️ *Gasolinera \(num)*\n"
                    resultText += "_Nombre:_ *\(gasStation.name)* / _Localidad:_ *\(gasStation.city)*\n"
                    resultText += "🕐 *\(gasStation.schedule)*\n"
                    resultText += "💰 _Precio:_ *\(gasStation.price!) €*\n"
                    resultText += "🌍 [Ver en mapa](https://www.google.com/maps/place/\(gasStation.latitude)+\(gasStation.longitude)/@\(gasStation.latitude),\(gasStation.longitude),15z)\n\n"
                    num += 1
                }
                if gasStations.isEmpty {
                    resultText += "No hay datos para su consulta"
                    let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                       text: resultText,
                                                       parseMode: .markdown)
                    do { try self.bot.sendMessage(params: params) } catch { print(error.localizedDescription) }
                } else {
                    let imageURL = GasStationAPI.Helper.generateImageURL(gasStations, location: currentLocation)
                    let params = Bot.SendPhotoParams(chatId: .chat(message.chat.id),
                                                     photo: .url(imageURL),
                                                     caption: resultText,
                                                     parseMode: .markdown)
                    do { try self.bot.sendPhoto(params: params) } catch { print(error.localizedDescription) }
                }
            case .failure(let error):
                let params = Bot.SendMessageParams(chatId: .chat(message.chat.id),
                                                   text: error.localizedDescription)
                do { try self.bot.sendMessage(params: params) } catch { print(error.localizedDescription) }
            }
        }
    }
}

do {
    let bot = try Bot(token: token)

    let dispatcher = Dispatcher(bot: bot)
    let controller = GasStationController(bot: bot)

    let gasinfoHandler = CommandHandler(commands: ["/gasinfo"], callback: controller.gasinfoHandler)
    dispatcher.add(handler: gasinfoHandler)

    let productHandler = CallbackQueryHandler(pattern: "prod/*", callback: controller.productHandler)
    dispatcher.add(handler: productHandler)

    let locationHandler = MessageHandler(filters: .location, callback: controller.locationHandler)
    dispatcher.add(handler: locationHandler)

    _ = try Updater(bot: bot, dispatcher: dispatcher).startLongpolling().wait()
} catch {
    print(error.localizedDescription)
}
