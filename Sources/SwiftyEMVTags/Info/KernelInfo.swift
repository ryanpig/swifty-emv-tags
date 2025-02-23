//
//  KernelInfo.swift
//  
//
//  Created by Yurii Zadoianchuk on 10/09/2022.
//

import Foundation
import SwiftyBERTLV

/// Represents information about kernel and associated tags
public struct KernelInfo: Decodable, Identifiable {
    
    /// Category of the kernel
    public enum Category: String, Decodable {
        /// Kernel describing scheme-specific tags
        case scheme
        
        /// Kernel describing vendor-specifig tags
        case vendor
    }
    
    /// The identifier of the kernel
    public let id: String
    
    /// Name of the kernel
    public let name: String
    
    /// Category of the kernel
    public let category: Category
    
    /// Description of the kernel
    public let description: String
    
    /// Tag decoding information
    public let tags: [TagDecodingInfo]
    
    public init(
        id: String,
        name: String,
        category: Category,
        description: String,
        tags: [TagDecodingInfo]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
        self.tags = tags
    }
    
    internal func decodeTag(
        _ bertlv: BERTLV,
        
        tagMapper: AnyTagMapper,
        context: UInt64? = nil
    ) -> EMVTag.DecodedTag? {
        matchingTag(for: bertlv.tag, context: context)
            .map { tagInfo in
                .init(
                    kernel: id,
                    tagInfo: tagInfo.info,
                    result: .init(
                        catching: { try decodeBytes(bertlv.value, bytesInfo: tagInfo.bytes) }
                    ),
                    extendedDescription: tagMapper.extentedDescription(
                        for: tagInfo.info,
                        value: bertlv.value
                    )
                )
            }
    }
    
    private func matchingTag(
        for tag: UInt64,
        context: UInt64?
    ) -> TagDecodingInfo? {
        // Try with context first if present.
        // If no tags found - try without context.
        context.flatMap { ctx in
            tags.first(where: { $0.isMatching(tag: tag, context: ctx) })
        } ?? tags.first(where: { $0.isMatching(tag: tag, context: nil) })
    }
    
    private func decodeBytes(_ bytes: [UInt8], bytesInfo: [ByteInfo]) throws -> [EMVTag.DecodedByte] {
        guard bytesInfo.isEmpty == false else {
            return []
        }
        
        guard bytes.count == bytesInfo.count else {
            throw EMVTagError.byteCountNotEqual
        }
        
        return try zip(bytes, bytesInfo)
            .map(EMVTag.DecodedByte.init)
    }
    
}

/// Represents decoding information about a specific tag
public struct TagDecodingInfo: Decodable {
    
    /// General tag information
    public let info: TagInfo
    
    /// Rules for decoding tag value bytes
    public let bytes: [ByteInfo]
    
    public enum CodingKeys: CodingKey {
        case info
        case bytes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.info = try container.decode(TagInfo.self, forKey: .info)
        self.bytes = try container.decodeIfPresent([ByteInfo].self, forKey: .bytes) ?? []
    }
    
    func isMatching(tag: UInt64, context: UInt64?) -> Bool {
        self.info.tag == tag && self.info.context == context
    }
    
}
