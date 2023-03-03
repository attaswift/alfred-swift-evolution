#!/usr/bin/swift
//
// se-lookup.swift
//
// A script filter for looking up swift-evolution proposals in Alfred.

import Foundation

/// Data transfer object definition for a Swift Evolution proposal in the
/// JSON format used by swift.org.
struct ProposalDTO: Decodable {
    static let dataURL = URL(string: "https://download.swift.org/swift-evolution/proposals.json")!

    var id: String
    var title: String
    var link: String
    var status: Status

    struct Status: Decodable {
        var state: String
    }
}

struct Proposal {
    let baseURL = URL(string: "https://github.com/apple/swift-evolution/blob/main/proposals")!

    var id: String
    var title: String
    var url: URL
    var status: Status

    var number: Int? {
        guard let digits = id.split(separator: "-").last else { return nil }
        return Int(digits)
    }

    var searchText: String {
        "\(id) \(number.map(String.init(describing:)) ?? "") \(title) \(status.description) \(status.description)"
            .lowercased()
    }

    func matches(_ query: String) -> Bool {
        let words = query
            .split { $0.isWhitespace || $0.isNewline }
            .map { $0.lowercased() }
        if words.count == 0 { return true }
        if words.count == 1, let number = Int(words[0]) {
            return self.number == number
        }
        return words.contains { searchText.contains($0) }
    }
}

extension Proposal {
    init(dto: ProposalDTO) {
        self.id = dto.id
        self.title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.url = baseURL.appendingPathComponent(dto.link)
        self.status = Status(dto: dto.status)
    }
}

extension Proposal {
    enum Status: CustomStringConvertible {
        case awaitingReview
        case scheduledForReview
        case activeReview
        case returnedForRevision
        case withdrawn
        case deferred // status is no longer in use
        case accepted
        case acceptedWithRevisions
        case rejected
        case implemented
        case previewing
        case error
        case unknown(status: String)

        init(dto: ProposalDTO.Status) {
            switch dto.state {
            case ".awaitingReview": self = .awaitingReview
            case ".scheduledForReview": self = .scheduledForReview
            case ".activeReview": self = .activeReview
            case ".returnedForRevision": self = .returnedForRevision
            case ".withdrawn": self = .withdrawn
            case ".deferred": self = .deferred
            case ".accepted": self = .accepted
            case ".acceptedWithRevisions": self = .acceptedWithRevisions
            case ".rejected": self = .rejected
            case ".implemented": self = .implemented
            case ".previewing": self = .previewing
            case ".error": self = .error
            default: self = .unknown(status: dto.state)
            }
        }

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
            case .previewing: return "Previewing"
            case .error: return "Error"
            case .unknown(let underlying): return "Unknown status: \(underlying)"
            }
        }
    }
}

/// An item a Script Filter workflow returns to Alfred for display.
/// Represents one row in an Alfred result set.
///
/// Documentation: <https://www.alfredapp.com/help/workflows/inputs/script-filter/json/>
struct AlfredItem: Encodable {
    enum `Type`: String, Encodable {
        /// An item that is not a file.
        case `default`
        /// "type": "file" makes Alfred treat your result as a file on your system. This allows the
        /// user to perform actions on the file like they can with Alfred's standard file filters.
        case file
        /// When returning files, Alfred will check if the file exists before presenting that result
        /// to the user. This has a very small performance implication but makes the results as
        /// predictable as possible. If you would like Alfred to skip this check as you are certain
        /// that the files you are returning exist, you can use "type": "file:skipcheck".
        case fileSkipCheck = "file:skipcheck"
    }

    /// A unique identifier for the item which allows Alfred to learn about this item for subsequent
    /// sorting and ordering of the user's actioned results.
    ///
    /// If you would like Alfred to always show the results in the order you return them from your
    /// script, exclude the UID field.
    var uid: String?
    /// The title displayed in the result row.
    var title: String
    /// The subtitle displayed in the result row.
    var subtitle: String?
    /// The argument which is passed through the workflow to the connected output action.
    /// Optional, but strongly recommended.
    var arg: String?
    /// Whether this item is valid or not. If an item is valid then Alfred will action this item
    /// when the user presses return. If the item is not valid, Alfred will do nothing.
    var valid: Bool = true
    /// An optional but recommended string you can provide which is populated into Alfred's search
    /// field if the user auto-completes (Tab key by default) the selected result.
    var autocomplete: String?
    /// The item type.
    var type: `Type` = .default
    /// A Quick Look URL which will be visible if the user uses the Quick Look feature within Alfred
    /// (tapping Shift, or Cmd+Y). Note that quicklookurl will also accept a file path, both
    /// absolute and relative to home using ~/.
    var quicklookurl: String?
}

extension AlfredItem {
    init(proposal: Proposal) {
        self.uid = proposal.url.absoluteString
        self.title = proposal.id
        self.subtitle = "\(proposal.title) (\(proposal.status.description))"
        self.arg = proposal.url.absoluteString
        self.autocomplete = proposal.id
        self.quicklookurl = proposal.url.absoluteString
    }

    init(error: Error) {
        // Dumping an `Error`’s contents seems to be the best way to extract all the
        // salient error information into a semi-readable string. This obviously isn’t
        // ideal for user-facing error messages, but I think it’s acceptable for a
        // developer tool such as this.
        // Unfortunately, `error.localizedDescription` or the various `LocalizedError` 
        // properties carry little to no actionable information about the failure reason
        // for typical library errors such as Foundation.CocoaError or Swift.DecodingError.
        let title = "Error: \(error.localizedDescription)"
        var errorInfo = ""
        dump(error, to: &errorInfo)
        self.init(
            uid: "status", // Identifier for status messages
            title: title,
            subtitle: errorInfo,
            arg: "\(title)\n\(errorInfo)",
            valid: false
        )
    }
}

// MARK: - Main program

let query = CommandLine.arguments.dropFirst().joined(separator: " ")
let result: [AlfredItem]
do {
    let data = try Data(contentsOf: ProposalDTO.dataURL)
    let decoder = JSONDecoder()
    let allProposals = try decoder.decode([ProposalDTO].self, from: data)
    result = allProposals
        .map(Proposal.init(dto:))
        .filter { $0.matches(query) }
        .sorted { ($0.number ?? 0) > ($1.number ?? 0) }
        .map(AlfredItem.init(proposal:))
} catch {
    result = [AlfredItem(error: error)]
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let resultData = try encoder.encode(["items": result])
print(String(decoding: resultData, as: UTF8.self))
