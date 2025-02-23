//
//  Group.swift
//  
//
//  Created by Yurii Zadoianchuk on 07/09/2022.
//

import Foundation

extension ByteInfo {
    
    /// Represents rules for decoding one group within a ``ByteInfo``
    public struct Group: Decodable {
        
        /// Encoding rule
        public enum MappingType: Decodable {
            
            /// Group is mapped across multiple bits
            /// Actual mapping is described within ``ByteInfo/Group/Mapping`` struct
            case bitmap([Mapping])
            
            /// Group represens a hex value
            case hex
            
            /// Group represents a boolean value
            case bool
            
            /// Group is RFU
            case RFU
        }
            
        /// Describes mapping of an individual meaning within a group
        public struct Mapping: Decodable {
            
            /// Lowest bits represent the actual value
            /// The number of lowest bits is ``ByteInfo/Group/pattern`` set bits
            public let pattern: UInt8
            
            /// Meaning of this specific mapping variant
            public let meaning: String
            
            private enum CodingKeys: String, CodingKey {
                case pattern
                case meaning
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                self.pattern = try container.decodeIntegerFromString(radix: 2, forKey: .pattern)
                self.meaning = try container.decode(String.self, forKey: .meaning)
            }
            
        }
        
        /// Name of the group
        public let name: String
        
        /// Type of mapping used to encode group meaning
        public let type: MappingType
        
        /// Describes which bits from the byte represent the group
        /// i.e. 00001100 means b4 and b3 represent this group
        public let pattern: UInt8
        
        private enum CodingKeys: String, CodingKey {
            case name
            case type
            case pattern
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.type = try decoder.singleValueContainer().decode(MappingType.self)
            switch type {
            case .RFU:
                self.name = MappingType.RawType.RFU.rawValue
            case .bool, .hex, .bitmap:
                self.name = try container.decode(String.self, forKey: .name)
            }
            
            self.pattern = try container.decodeIntegerFromString(radix: 2, forKey: .pattern)
        }
        
    }
    
}

extension ByteInfo.Group.MappingType {
    
    private enum CodingKeys: String, CodingKey {
        case type
        case mappings
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        switch try container.decode(RawType.self, forKey: .type) {
        case .bitmap:
            self = .bitmap(try container.decode([ByteInfo.Group.Mapping].self, forKey: .mappings))
        case .hex:
            self = .hex
        case .bool:
            self = .bool
        case .RFU:
            self = .RFU
        }
    }
    
    internal var stringValue: String {
        switch self {
        case .bool: return RawType.bool.rawValue
        case .hex: return RawType.hex.rawValue
        case .bitmap: return RawType.bitmap.rawValue
        case .RFU: return RawType.RFU.rawValue
        }
    }
    
    internal enum RawType: String, Decodable {
        case bitmap
        case hex
        case bool
        case RFU
    }
    
}
