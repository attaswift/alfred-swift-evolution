#!/usr/bin/swift
//
// se-lookup.swift
//
// A script filter for looking up swift-evolution proposals in Alfred.

import Foundation

let baseURL = URL(string: "https://github.com/apple/swift-evolution/blob/master/proposals")!
let dataURL = URL(string: "https://data.swift.org/swift-evolution/proposals")!

struct LookupError: LocalizedError {
    let errorDescription: String?

    init(_ message: String) {
        self.errorDescription = message
    }
}

struct Proposal {
    enum Status: String, CustomStringConvertible {
        case awaitingReview = ".awaitingReview"
        case scheduledForReview = ".scheduledForReview"
        case activeReview = ".activeReview"
        case returnedForRevision = ".returnedForRevision"
        case withdrawn = ".withdrawn"
        case deferred = ".deferred"
        case accepted = ".accepted"
        case acceptedWithRevisions = ".acceptedWithRevisions"
        case rejected = ".rejected"
        case implemented = ".implemented"
        case error = ".error"
        case unknown = ""

        var description: String {
            switch self {
            case .awaitingReview: return "Awaiting Review"
            case .scheduledForReview: return "Scheduled for Review"
            case .activeReview: return "Active Review"
            case .returnedForRevision: return "Returned for Revision"
            case .withdrawn: return "Withdrawn"
            case .deferred: return "Deferred"
            case .accepted: return "Accepted"
            case .acceptedWithRevisions: return "Accepted with Revisions"
            case .rejected: return "Rejected"
            case .implemented: return "Implemented"
            case .error: return "Error"
            case .unknown: return "Unknown Status"
            }
        }
    }

    let number: Int
    let id: String
    let title: String
    let url: URL
    let status: Status
    let searchText: String

    init?(from json: Any) {
        guard let json = json as? [String: Any] else { return nil }
        guard json["errors"] == nil else { return nil }
        guard let id = json["id"] as? String else { return nil }
        guard id.hasPrefix("SE-") else { return nil }
        guard let number = Int(id.components(separatedBy: "-").last!) else { return nil }
        guard let title = json["title"] as? String else { return nil }
        guard let link = json["link"] as? String else { return nil }
        self.number = number
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.status = Status(rawValue: (json["status"] as? [String: Any])?["state"] as? String ?? "") ?? .unknown
        self.url = baseURL.appendingPathComponent(link)

        self.searchText = "\(id.lowercased()) \(number) \(title.lowercased()) \(status.rawValue) \(status.description.lowercased())"
    }

    var alfredItem: [String: String] {
        return [
            "uid": url.absoluteString,
            "type": "default",
            "title": "\(id)",
            "subtitle": "\(title) (\(status.description))",
            "autocomplete": id,
            "quicklookurl": url.absoluteString,
            "arg": url.absoluteString,
        ]
    }

    func matches(_ query: String) -> Bool {
        let words = query
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        if words.count == 0 { return true }
        if words.count == 1, let number = Int(words[0]) {
            return self.number == number
        }
        return words.index { !searchText.contains($0) } == nil
    }
}

let query = CommandLine.arguments.dropFirst().joined(separator: " ")

do {
    guard let data = try? Data(contentsOf: dataURL) else {
        throw LookupError("Can't download proposals data")
    }
    guard let json = try JSONSerialization.jsonObject(with: data) as? [Any] else {
        throw LookupError("Proposal data has unknown structure")
    }
    let items = json
        .flatMap { Proposal(from: $0) }
        .filter { $0.matches(query) }
        .sorted { $0.number > $1.number }
        .map { $0.alfredItem }

    let resultData = try JSONSerialization.data(withJSONObject: ["items": items], options: .prettyPrinted)
    print(String(data: resultData, encoding: .utf8)!)
}
catch {
    let report: [String: Any] = [
        "valid": false,
        "type": "default",
        "title": "Swift proposals are unavailable",
        "subtitle": "\(error.localizedDescription)",
    ]
    let resultData = try JSONSerialization.data(withJSONObject: ["items": [report]], options: .prettyPrinted)
    print(String(data: resultData, encoding: .utf8)!)
}
