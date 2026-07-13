//
//  InputStreamReader.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//

import Foundation


class InputStreamReader {
    let stream: InputStream

    init(stream: InputStream) {
        self.stream = stream
    }

    func readAll() throws -> Data {
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data = Data()

        stream.open()
        defer { stream.close() }

        while stream.hasBytesAvailable {
            let readBytes = stream.read(&buffer, maxLength: buffer.count)
            if readBytes < 0, let error = stream.streamError {
                throw error
            }
            data.append(buffer, count: readBytes)
        }

        return data
    }
}
