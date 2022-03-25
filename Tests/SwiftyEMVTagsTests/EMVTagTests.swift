import XCTest
@testable import SwiftyEMVTags
import SwiftyBERTLV

final class EMVTagTests: XCTestCase {
    
    func testInitPrimitiveTLVAllSchemes() throws {
        
        let tlv = try XCTUnwrap(BERTLV.parse(bytes: [0x5A, 0x01, 0xBB]).first)
        
        let sut = EMVTag(tlv: tlv)
        
        XCTAssertEqual(sut.tag, tlv.tag)
        XCTAssertEqual(sut.isConstructed, tlv.isConstructed)
        XCTAssertEqual(sut.value, tlv.value)
        XCTAssertEqual(sut.subtags.count, tlv.subTags.count)
        XCTAssertEqual(sut.kernel, .all)
        
    }
    
    func testInitConstructedTLVAllSchemes() throws {
        
        let subTlv = try XCTUnwrap(BERTLV.parse(bytes: [0x5A, 0x01, 0xFF]).first)
        let tlv = try XCTUnwrap(BERTLV.parse(bytes: [0xE1, 0x03, 0x5A, 0x01, 0xFF]).first)
        
        let sut = EMVTag(tlv: tlv)
        
        XCTAssertEqual(sut.tag, tlv.tag)
        XCTAssertEqual(sut.isConstructed, tlv.isConstructed)
        XCTAssertEqual(sut.value, tlv.value)
        XCTAssertEqual(sut.subtags.count, tlv.subTags.count)
        
        let sutSubTag = try XCTUnwrap(sut.subtags.first)
        XCTAssertEqual(sutSubTag.tag, subTlv.tag)
        XCTAssertEqual(sutSubTag.isConstructed, subTlv.isConstructed)
        XCTAssertEqual(sutSubTag.value, subTlv.value)
        XCTAssertEqual(sutSubTag.subtags.count, subTlv.subTags.count)
        XCTAssertEqual(sutSubTag.kernel, .all)
        
    }
    
    func testInitPrimitiveTLVSpecificScheme() throws {
        
        let tlv = try XCTUnwrap(BERTLV.parse(bytes: [0x5A, 0x01, 0xBB]).first)
        
        var mockSource = infoSourceMock
        mockSource.onInfo = { (_, kernel) in
            EMVTag.Info.mockInfo(with: kernel)
        }
        
        let sut = EMVTag(tlv: tlv, kernel: .kernel2, infoSource: mockSource)
        
        XCTAssertEqual(sut.isConstructed, tlv.isConstructed)
        XCTAssertEqual(sut.value, tlv.value)
        XCTAssertEqual(sut.subtags.count, tlv.subTags.count)
        XCTAssertEqual(sut.kernel, .kernel2)
        
    }
    
    func testInitConstructedTLVSpecificScheme() throws {
        
        var mockSource = infoSourceMock
        mockSource.onInfo = { (_, kernel) in
            EMVTag.Info.mockInfo(with: kernel)
        }
        
        let subTlv = try XCTUnwrap(BERTLV.parse(bytes: [0x5A, 0x01, 0xFF]).first)
        let tlv = try XCTUnwrap(BERTLV.parse(bytes: [0xE1, 0x03, 0x5A, 0x01, 0xFF]).first)
        
        let sut = EMVTag(tlv: tlv, kernel: .kernel3, infoSource: mockSource)
        
        XCTAssertEqual(sut.tag, tlv.tag)
        XCTAssertEqual(sut.isConstructed, tlv.isConstructed)
        XCTAssertEqual(sut.value, tlv.value)
        XCTAssertEqual(sut.subtags.count, tlv.subTags.count)
        
        let sutSubTag = try XCTUnwrap(sut.subtags.first)
        XCTAssertEqual(sutSubTag.tag, subTlv.tag)
        XCTAssertEqual(sutSubTag.isConstructed, subTlv.isConstructed)
        XCTAssertEqual(sutSubTag.value, subTlv.value)
        XCTAssertEqual(sutSubTag.subtags.count, subTlv.subTags.count)
        XCTAssertEqual(sutSubTag.kernel, .kernel3)
        
    }
    
    func testByteDecoding() {
        let byte: UInt8 = 0xFF
        
        let sut = (0..<byte.bitWidth).map {
            EMVTag.BitMeaning(meaning: "", byte: byte, bitIdx: $0)
        }
        
        XCTAssertFalse(sut.map(\.isSet).contains(false))
    }
    
    func testByteDecoding2() {
        let byte: UInt8 = 0x00
        
        let sut = (0..<byte.bitWidth).map {
            EMVTag.BitMeaning(meaning: "", byte: byte, bitIdx: $0)
        }
        
        XCTAssertFalse(sut.map(\.isSet).contains(true))
    }
    
    func testBytesDecoding() throws {
        
        let value: [UInt8] = [0xFF, 0xAA, 0xBB]
        let tag = try BERTLV.parse(bytes: [0x5A, 0x03] + value).first!
        
        var mockSource = infoSourceMock
        mockSource.onInfo = { (tag, kernel) in
            EMVTag.Info(
                tag: tag,
                name: "",
                description: "",
                source: .kernel,
                format: .unknown,
                kernel: .all,
                minLength: "",
                maxLength: "", byteMeaningList: [
                    (0..<UInt8.bitWidth).map(\.description),
                    (0..<UInt8.bitWidth).map(\.description),
                    (0..<UInt8.bitWidth).map(\.description)
                ]
            )
        }
        
        let sut = EMVTag(tlv: tag, kernel: .kernel4, infoSource: mockSource)
        
        _ = sut.decodedMeaningList.enumerated().map { (byteIdx, byte) in
            byte.bitList.enumerated().map { (bitIdx, bit) in
                (0..<UInt8.bitWidth).map { i in
                    XCTAssertEqual((value[byteIdx] >> bitIdx & 0x01 == 0x01), bit.isSet)
                    XCTAssertEqual(bitIdx.description, bit.meaning)
                }
            }
        }
        
    }
    
}
