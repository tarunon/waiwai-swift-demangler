//
//  ParserTests.swift
//  ParserTests
//
//  Created by tarunon on 2018/12/16.
//  Copyright © 2018年 tarunon. All rights reserved.
//

import XCTest
@testable import Parser

class ParserTests: XCTestCase {
    func testIntParse() {
        let text = "123aaa"
        let result = try! IntParser().parse(text: text)
        XCTAssertEqual(result.value, 123)
        XCTAssertEqual(result.index, text.index(text.startIndex, offsetBy: 3))
        
        do {
            let text = "a"
            _ = try IntParser().parse(text: text)
            XCTFail()
        } catch {
            // nop
        }
    }
    
    func testModuleParse() {
        let text1 = "3abc4"
        let result1 = try! ModuleParser().parse(text: text1)
        XCTAssertEqual(result1.value.text, "abc")
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 4))
        
        let text2 = "12swiftswiftswift"
        let result2 = try! ModuleParser().parse(text: text2)
        XCTAssertEqual(result2.value.text, "swiftswiftsw")
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 14))
    }
    
    func testIdentifierParse() {
        let text1 = "3abc4"
        let result1 = try! IdentifierParser().parse(text: text1)
        XCTAssertEqual(result1.value.text, "abc")
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 4))
        
        let text2 = "12swiftswiftswift"
        let result2 = try! IdentifierParser().parse(text: text2)
        XCTAssertEqual(result2.value.text, "swiftswiftsw")
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 14))
    }
    
    func testLabelParse() {
        let text1 = "3abc4"
        let result1 = try! LabelParser().parse(text: text1)
        XCTAssertEqual(result1.value.identifier.text, "abc")
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 4))
        
        let text2 = "12swiftswiftswift"
        let result2 = try! LabelParser().parse(text: text2)
        XCTAssertEqual(result2.value.identifier.text, "swiftswiftsw")
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 14))
    }
    
    func testLabelsParse() {
        let text1 = "3abcd"
        let result1 = try! LabelsParser().parse(text: text1)
        XCTAssertEqual(result1.value[0].identifier.text, "abc")
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 4))
        
        let text2 = "12swiftswiftswift"
        let result2 = try! LabelsParser().parse(text: text2)
        XCTAssertEqual(result2.value[0].identifier.text, "swiftswiftsw")
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 14))
        
        let text3 = "3abc4abcde"
        let result3 = try! LabelsParser().parse(text: text3)
        XCTAssertEqual(result3.value[0].identifier.text, "abc")
        XCTAssertEqual(result3.value[1].identifier.text, "abcd")
        XCTAssertEqual(result3.index, text3.index(text3.startIndex, offsetBy: 9))
    }
    
    func testStructureParse() {
        let text1 = "Sb"
        let result1 = try! StructureParser().parse(text: text1)
        XCTAssertEqual(result1.value.identifier.text, "Bool")
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 2))
    }
    
    func testArgumentTuplesParse() {
        let text1 = "Sb_t"
        let result1 = try! ArgumentTuplesParser().parse(text: text1)
        XCTAssertEqual(result1.value, [ArgumentTuple(index: 1, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool"))))])
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 4))
        
        let text2 = "Sb_SfSft"
        let result2 = try! ArgumentTuplesParser().parse(text: text2)
        XCTAssertEqual(result2.value, [
            ArgumentTuple(index: 1, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool")))),
            ArgumentTuple(index: 2, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Float")))),
            ArgumentTuple(index: 3, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Float"))))
            ])
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 8))
    }
    
    func testFunctionTypeParse() {
        let text1 = "SbSb_tF"
        let result1 = try! FunctionTypeParser().parse(text: text1)
        XCTAssertEqual(result1.value, FunctionType(
            argumentTuples: [
                ArgumentTuple(index: 1, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool"))))
            ],
            returnType: ReturnType(type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool"))))
        ))
        XCTAssertEqual(result1.index, text1.index(text1.startIndex, offsetBy: 7))
        
        let text2 = "SbSb_SiSitF"
        let result2 = try! FunctionTypeParser().parse(text: text2)
        XCTAssertEqual(result2.value, FunctionType(
            argumentTuples: [
                ArgumentTuple(index: 1, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool")))),
                ArgumentTuple(index: 2, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Int")))),
                ArgumentTuple(index: 3, type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Int"))))
            ],
            returnType: ReturnType(type: Type.structure(Structure(module: Module(text: "Swift"), identifier: Identifier(text: "Bool"))))
        ))
        XCTAssertEqual(result2.index, text2.index(text2.startIndex, offsetBy: 11))
    }
    
    func testFunctionParse() {
        let text = "13ExampleNumber6isEven6numberSbSi_tF"
        let result = try! FunctionParser().parse(text: text)
        XCTAssertEqual(result.value, Function(
            module: Module(text: "ExampleNumber"),
            identifier: Identifier(text: "isEven"),
            labelList: [
                Label(identifier: Identifier(text: "number"))
            ],
            type: Type.function(FunctionType(
                argumentTuples: [
                    ArgumentTuple(
                        index: 1,
                        type: Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "Int")
                        ))
                    )
                ],
                returnType: ReturnType(
                    type: Type.structure(Structure(
                        module: Module(text: "Swift"),
                        identifier: Identifier(text: "Bool")
                    ))
                )
            ))
        ))
        XCTAssertEqual(result.index, text.index(text.startIndex, offsetBy: 36))
    }
    
    func testFunctionParseArgument3() {
        let text = "13ExampleNumber6isEven6number4hoge4fugaSbSi_SSSftF"
        let result = try! FunctionParser().parse(text: text)
        XCTAssertEqual(result.value, Function(
            module: Module(text: "ExampleNumber"),
            identifier: Identifier(text: "isEven"),
            labelList: [
                Label(identifier: Identifier(text: "number")),
                Label(identifier: Identifier(text: "hoge")),
                Label(identifier: Identifier(text: "fuga"))
            ],
            type: Type.function(FunctionType(
                argumentTuples: [
                    ArgumentTuple(
                        index: 1,
                        type: Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "Int")
                        ))
                    ),
                    ArgumentTuple(
                        index: 2,
                        type: Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "String")
                        ))
                    ),
                    ArgumentTuple(
                        index: 3,
                        type: Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "Float")
                        ))
                    )
                ],
                returnType: ReturnType(
                    type: Type.structure(Structure(
                        module: Module(text: "Swift"),
                        identifier: Identifier(text: "Bool")
                    ))
                )
            ))
        ))
        XCTAssertEqual(result.index, text.index(text.startIndex, offsetBy: 50))
    }
    
    func testFunctionParseReturn2() {
        let text = "7Example3fooSS_SityF"
        let result = try! FunctionParser().parse(text: text)
        XCTAssertEqual(result.value, Function(
            module: Module(text: "Example"),
            identifier: Identifier(text: "foo"),
            labelList: [
            ],
            type: Type.function(FunctionType(
                argumentTuples: [
                ],
                returnType: ReturnType(
                    type: Type.tuple(Tuple(tupleElements: [
                        Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "String")
                        )),
                        Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "Int")
                        ))
                        ]))
                )
            ))
        ))
//        XCTAssertEqual(result.index, text.index(text.startIndex, offsetBy: 36))
    }
    
    func testGlobalParse() {
        let text = "$S13ExampleNumber6isEven6numberSbSi_tF"
        let result = try! GlobalParser().parse(text: text)
        XCTAssertEqual(result.value, Global.function(
            Function(
                module: Module(text: "ExampleNumber"),
                identifier: Identifier(text: "isEven"),
                labelList: [
                    Label(identifier: Identifier(text: "number"))
                ],
                type: Type.function(FunctionType(
                    argumentTuples: [
                        ArgumentTuple(
                            index: 1,
                            type: Type.structure(Structure(
                                module: Module(text: "Swift"),
                                identifier: Identifier(text: "Int")
                            ))
                        )
                    ],
                    returnType: ReturnType(
                        type: Type.structure(Structure(
                            module: Module(text: "Swift"),
                            identifier: Identifier(text: "Bool")
                        ))
                    )
                ))
        )))
        XCTAssertEqual(result.index, text.index(text.startIndex, offsetBy: 38))
    }
}
