//
//  Swime.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 26/05/2021.
//

import Foundation

public struct Swime {
  /// File data
  let data: Data

  ///  A static method to get the `SwimeMimeType` that matches the given file data
  ///
  ///  - returns: Optional<SwimeMimeType>
  static public func mimeType(data: Data) -> SwimeMimeType? {
    return mimeType(swime: Swime(data: data))
  }

  ///  A static method to get the `SwimeMimeType` that matches the given bytes
  ///
  ///  - returns: Optional<SwimeMimeType>
  static public func mimeType(bytes: [UInt8]) -> SwimeMimeType? {
    return mimeType(swime: Swime(bytes: bytes))
  }

  ///  Get the `SwimeMimeType` that matches the given `Swime` instance
  ///
  ///  - returns: Optional<SwimeMimeType>
  static public func mimeType(swime: Swime) -> SwimeMimeType? {
    let bytes = swime.readBytes(count: min(swime.data.count, 262))

    for mime in SwimeMimeType.all {
      if mime.matches(bytes: bytes, swime: swime) {
        return mime
      }
    }

    return nil
  }

  public init(data: Data) {
    self.data = data
  }

  public init(bytes: [UInt8]) {
    self.init(data: Data(bytes))
  }

  ///  Read bytes from file data
  ///
  ///  - parameter count: Number of bytes to be read
  ///
  ///  - returns: Bytes represented with `[UInt8]`
  internal func readBytes(count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)

    data.copyBytes(to: &bytes, count: count)

    return bytes
  }
}
