//
//  Parser.swift
//  Demangler
//
//  Created by tarunon on 2018/12/16.
//  Copyright © 2018年 tarunon. All rights reserved.
//

import Foundation

public struct Module: Equatable {
    public var text: String
}

public struct Identifier: Equatable {
    public var text: String
}

public struct Function: Equatable {
    public var module: Module
    public var identifier: Identifier
    public var labelList: [Label]
    public var type: Type
}

public struct Label: Equatable {
    public var identifier: Identifier
}

public indirect enum Type: Equatable {
    case structure(Structure)
    case tuple(Tuple)
    case function(FunctionType)
}

public struct Structure: Equatable {
    public var module: Module
    public var identifier: Identifier
}

public struct Tuple: Equatable {
    public var tupleElements: [Type]
}

public struct ArgumentTuple: Equatable {
    public var index: Int
    public var type: Type
}

public struct ReturnType: Equatable {
    public var type: Type
}

public struct FunctionType: Equatable {
    public var argumentTuples: [ArgumentTuple]
    public var returnType: ReturnType
}

public enum Global: Equatable {
    case function(Function)
}

public enum ParseError: Error {
    case fail
    case unsupportedType(String)
    case notKnownTypeKind
}

public struct ParseResult<T> {
    public var value: T
    public var index: String.Index
    
    func map<U>(_ f: (T) throws -> U) rethrows -> ParseResult<U> {
        return try ParseResult<U>(value: f(value), index: index)
    }
}

public protocol Parser {
    associatedtype Result
    func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Result>
}

extension Parser {
    public func parse(text: String) throws -> ParseResult<Result> {
        return try parse(text: text, start: text.startIndex, end: text.endIndex)
    }
}

public class IntParser: Parser {
    public typealias Result = Int
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Int> {
        let beginIndex = start
        var endIndex = text.index(after: beginIndex)
        var tmp: Int?
        while let test = Int(text[beginIndex..<endIndex]), endIndex < end {
            tmp = test
            endIndex = text.index(after: endIndex)
        }
        endIndex = text.index(before: endIndex)
        guard let result = tmp else {
            throw ParseError.fail
        }
        return .init(value: result, index: endIndex)
    }
}

public class ModuleParser: Parser {
    public typealias Result = Module
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Module> {
        let intResult = try IntParser().parse(text: text, start: start, end: end)
        let startIndex = intResult.index
        let endIndex = text.index(startIndex, offsetBy: intResult.value)
        guard endIndex < end else { throw ParseError.fail }
        return .init(value: .init(text: String(text[startIndex..<endIndex])), index: endIndex)
    }
}

public class IdentifierParser: Parser {
    public typealias Result = Identifier
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Identifier> {
        let intResult = try IntParser().parse(text: text, start: start, end: end)
        let startIndex = intResult.index
        let endIndex = text.index(startIndex, offsetBy: intResult.value)
        guard endIndex < end else { throw ParseError.fail }
        return .init(value: .init(text: String(text[startIndex..<endIndex])), index: endIndex)
    }
}

public class LabelParser: Parser {
    public typealias Result = Label
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Label> {
        return try IdentifierParser().parse(text: text, start: start, end: end).map(Label.init)
    }
}

public class LabelsParser: Parser {
    public typealias Result = [Label]
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<[Label]> {
        var index = start
        var result = [Label]()
        LOOP: while true {
            do {
                let labelResult = try LabelParser().parse(text: text, start: index, end: end)
                result.append(labelResult.value)
                index = labelResult.index
            } catch {
                break LOOP
            }
        }
        return .init(value: result, index: index)
    }
}

public class KnownTypeKindParser: Parser {
    public typealias Result = Void
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Void> {
        if text[start] == "S", text.index(after: start) < end {
            return .init(value: (), index: text.index(after: start))
        } else {
            throw ParseError.notKnownTypeKind
        }
    }
}

public class StructureParser: Parser {
    public typealias Result = Structure
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Structure> {
        let tmp = try KnownTypeKindParser().parse(text: text, start: start, end: end)
        let swiftModule = Module(text: "Swift")
        switch text[tmp.index] {
        case "b":
            return .init(value: .init(module: swiftModule, identifier: .init(text: "Bool")), index: text.index(after: tmp.index))
        case "i":
            return .init(value: .init(module: swiftModule, identifier: .init(text: "Int")), index: text.index(after: tmp.index))
        case "S":
            return .init(value: .init(module: swiftModule, identifier: .init(text: "String")), index: text.index(after: tmp.index))
        case "f":
            return .init(value: .init(module: swiftModule, identifier: .init(text: "Float")), index: text.index(after: tmp.index))
        default:
            throw ParseError.unsupportedType(String(text[tmp.index]))
        }
    }
}

public class TupleParser: Parser {
    public typealias Result = Tuple
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Tuple> {
        if text[start] == "y" { return .init(value: Tuple(tupleElements: []), index: text.index(after: start)) }
        guard let hIndex = text[start..<end].lastIndex(of: "_") else { throw ParseError.fail }
        guard let tIndex = text[hIndex..<end].lastIndex(of: "t") else { throw ParseError.fail }
        let head = try TypeParser().parse(text: text, start: start, end: tIndex)
        var index = head.index
        guard text[index] == "_" else { throw ParseError.fail }
        index = text.index(after: index)
        var result = [head.value]
        while text[index] != "t" {
            let tail = try TypeParser().parse(text: text, start: index, end: tIndex)
            index = tail.index
            result.append(tail.value)
        }
        index = text.index(after: index)
        return .init(value: .init(tupleElements: result), index: index)
    }
}

public class TypeParser: Parser {
    public typealias Result = Type
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Type> {
        do {
            return try FunctionTypeParser().parse(text: text, start: start, end: end).map(Type.function)
        } catch {
            do {
                return try TupleParser().parse(text: text, start: start, end: end).map(Type.tuple)
            } catch {
                return try StructureParser().parse(text: text, start: start, end: end).map(Type.structure)
            }
        }
    }
}

public class ReturnTypeParser: Parser {
    public typealias Result = ReturnType
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<ReturnType> {
        return try TypeParser().parse(text: text, start: start, end: end).map(ReturnType.init)
    }
}

public class ArgumentTuplesParser: Parser {
    public typealias Result = [ArgumentTuple]
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<[ArgumentTuple]> {
        return try TupleParser().parse(text: text, start: start, end: end).map { $0.tupleElements.enumerated().map { ArgumentTuple(index: $0.offset + 1, type: $0.element) } }
    }
}

public class FunctionTypeParser: Parser {
    public typealias Result = FunctionType
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<FunctionType> {
        guard let fIndex = text[start..<end].lastIndex(of: "F") else { throw ParseError.fail }
        let returnResult = try ReturnTypeParser().parse(text: text, start: start, end: fIndex)
        let argumentTuplesResult = try ArgumentTuplesParser().parse(text: text, start: returnResult.index, end: fIndex)
        guard text[argumentTuplesResult.index] == "F" else { throw ParseError.fail }
        let index = text.index(after: argumentTuplesResult.index)
        return .init(value: FunctionType(argumentTuples: argumentTuplesResult.value, returnType: returnResult.value), index: index)
    }
}

public class FunctionParser: Parser {
    public typealias Result = Function
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Function> {
        let moduleResult = try ModuleParser().parse(text: text, start: start, end: end)
        let identifierResult = try IdentifierParser().parse(text: text, start: moduleResult.index, end: end)
        let labelListResult = try LabelsParser().parse(text: text, start: identifierResult.index, end: end)
        let typeResult = try TypeParser().parse(text: text, start: labelListResult.index, end: end)
        
        return .init(
            value: Function(
                module: moduleResult.value,
                identifier: identifierResult.value,
                labelList: labelListResult.value,
                type: typeResult.value
            ),
            index: typeResult.index
        )
    }
}

public class GlobalParser: Parser {
    public typealias Result = Global
    public func parse(text: String, start: String.Index, end: String.Index) throws -> ParseResult<Global> {
        let startIndex = text.index(start, offsetBy: 2)
        guard text[start..<startIndex] == "$S" else { throw ParseError.fail }
        return try FunctionParser().parse(text: text, start: startIndex, end: end).map(Global.function)
    }
}
