//
// Example code for article
// Codable Conformance for Swift Enums with Associated Values
// https://nilcoalescing.com/blog/CodableConformanceForSwiftEnumsWithMultipleAssociatedValuesOfDifferentTypes/
//
// This example code was written for Swift 5
// and shows how we can add Codable conformance
// for Swift enums with associated values.
//
// Swift 5.5 has added automatic Codable conformance
// for enums with associated values. See the proposal for details:
// https://github.com/apple/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md
//

import Foundation

// Sample Data

struct Connection: Codable {
    let url: URL
    let messages: [String]
}

enum EditSubview: String, Codable {
    case headers
    case query
    case body
}

struct Item: Codable {
    let name: String
}

enum ViewState {
    case empty
    case editing(subview: EditSubview)
    case exchangeHistory(connection: Connection?)
    case list(selectedId: UUID, expandedItems: [Item])
}


// Coding Keys

extension ViewState {
    enum CodingKeys: String, CodingKey {
        case empty, editing, exchangeHistory, list
    }
}


// Encoding

extension ViewState: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .empty:
            try container.encode(true, forKey: .empty)
        case .editing(let subview):
            try container.encode(subview, forKey: .editing)
        case .exchangeHistory(let connection):
            try container.encode(connection, forKey: .exchangeHistory)
        case .list(let selectedID, let expandedItems):
            
            // encoding multiple values using the extension to KeyedEncodingContainer
            try container.encodeValues(selectedID, expandedItems, for: .list)
            
//            // encoding multiple values without using the extension to KeyedEncodingContainer
//            var nestedContainer = container.nestedUnkeyedContainer(forKey: .list)
//            try nestedContainer.encode(selectedID)
//            try nestedContainer.encode(expandedItems)
        }
    }
}

// Decoding

extension ViewState: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first
        
        switch key {
        case .empty:
            self = .empty
        case .editing:
            let subview = try container.decode(EditSubview.self, forKey: .editing)
            self = .editing(subview: subview)
        case .exchangeHistory:
            let connection = try container.decode(
                Connection?.self, forKey: .exchangeHistory
            )
            self = .exchangeHistory(connection: connection)
        case .list:
            
            // decoding multiple values using the extension to KeyedDecodingContainer
            let (selectedId, expandedItems): (UUID, [Item]) = try container
                .decodeValues(for: .list)
            self = .list(selectedId: selectedId, expandedItems: expandedItems)
            
            
//            // decoding multiple values without using the extension to KeyedDecodingContainer
//            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .list)
//            let selectedId = try nestedContainer.decode(UUID.self)
//            let expandedItems = try nestedContainer.decode([Item].self)
//            self = .list(selectedId: selectedId, expandedItems: expandedItems)

        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Unabled to decode enum."
                )
            )
        }
    }
}

extension KeyedEncodingContainer {
    mutating func encodeValues<V1: Encodable, V2: Encodable>(
        _ v1: V1, _ v2: V2, for key: Key
    ) throws {
        var container = self.nestedUnkeyedContainer(forKey: key)
        try container.encode(v1)
        try container.encode(v2)
    }
}

extension KeyedDecodingContainer {
    func decodeValues<V1: Decodable, V2: Decodable>(
        for key: Key
    ) throws -> (V1, V2) {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return (
            try container.decode(V1.self),
            try container.decode(V2.self)
        )
    }
}


// Example Usage

let encoder = JSONEncoder()
let decoder = JSONDecoder()

let viewStateEmpty = ViewState.empty
let viewStateEditing = ViewState.editing(subview: EditSubview.headers)
let viewStateExchangeHistory = ViewState.exchangeHistory(
    connection: Connection(
        url: URL(string: "wss://stocks.websocket.demo.cleora.app")!,
        messages: ["connected", "disconnected"]
    )
)
let viewStateList = ViewState.list(
    selectedId: UUID(),
    expandedItems: [Item(name: "Request 1"), Item(name: "Request 2")]
)

do {
    let encodedViewStateEmpty = try encoder.encode(viewStateEmpty)
    let encodedViewStateEmotyString = String(
        data: encodedViewStateEmpty,
        encoding: .utf8
    )
    print(encodedViewStateEmotyString ?? "Wrong Data")
    
    let decodedViewStateEmpty = try decoder.decode(
        ViewState.self, from: encodedViewStateEmpty
    )
    print(decodedViewStateEmpty)
} catch {
    print(error.localizedDescription)
}
