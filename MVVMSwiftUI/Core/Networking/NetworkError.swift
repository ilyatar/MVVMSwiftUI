//
//  NetworkError.swift
//  MVVMSwiftUI
//
//  Created by Ilya Tarasov on 16.11.2026.
//

import Foundation

enum NetworkError: Error, Equatable {
    case invalidResponse
    case unacceptableStatusCode(Int)
    case decodingFailed(String)
    case transport(String)
}

enum UserFacingErrorMapper {
    static func message(for error: Error) -> String {
        switch error {
        case NetworkError.unacceptableStatusCode(let code):
            return "Сервер вернул ошибку (код \(code))."
        case NetworkError.invalidResponse:
            return "Получен некорректный ответ сервера."
        case NetworkError.decodingFailed:
            return "Не удалось обработать данные сервера."
        case NetworkError.transport:
            return "Проверьте подключение к интернету и попробуйте снова."
        default:
            return "Не удалось загрузить данные."
        }
    }
}
