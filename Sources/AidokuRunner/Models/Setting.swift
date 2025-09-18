//
//  Setting.swift
//  AidokuRunner
//
//  Created by Skitty on 2/14/24.
//

import Foundation

enum SettingType: String, Codable {
    case group
    case select
    case multiselect = "multi-select"
    case toggle = "switch"
    case stepper
    case segment
    case text
    case button
    case link
    case login
    case page
    case editableList = "editable-list"
    case custom

    init?(_ byteValue: UInt8) {
        switch byteValue {
            case 0: self = .group
            case 1: self = .select
            case 2: self = .multiselect
            case 3: self = .toggle
            case 4: self = .stepper
            case 5: self = .segment
            case 6: self = .text
            case 7: self = .button
            case 8: self = .link
            case 9: self = .login
            case 10: self = .page
            case 11: self = .editableList
            case 12: self = .custom
            default: return nil
        }
    }

    var byteValue: UInt8 {
        switch self {
            case .group: 0
            case .select: 1
            case .multiselect: 2
            case .toggle: 3
            case .stepper: 4
            case .segment: 5
            case .text: 6
            case .button: 7
            case .link: 8
            case .login: 9
            case .page: 10
            case .editableList: 11
            case .custom: 12
        }
    }
}

public struct Setting: Sendable, Hashable {
    public let key: String
    public var title: String
    public var notification: String?
    public var requires: String?
    public var requiresFalse: String?
    public var refreshes: [String]

    public let value: Value

    public enum Value: Sendable, Hashable {
        case group(GroupSetting)
        case select(SelectSetting)
        case multiselect(MultiSelectSetting)
        case toggle(ToggleSetting)
        case stepper(StepperSetting)
        case segment(SegmentSetting)
        case text(TextSetting)
        case button(ButtonSetting)
        case link(LinkSetting)
        case login(LoginSetting)
        case page(PageSetting)
        case editableList(EditableListSetting)
        case custom
    }

    public init(
        key: String = "",
        title: String = "",
        notification: String? = nil,
        requires: String? = nil,
        requiresFalse: String? = nil,
        refreshes: [String] = [],
        value: Value
    ) {
        self.key = key
        self.title = title
        self.notification = notification
        self.requires = requires
        self.requiresFalse = requiresFalse
        self.value = value
        self.refreshes = refreshes
    }
}

extension Setting {
    var type: SettingType {
        switch value {
            case .group: .group
            case .select: .select
            case .multiselect: .multiselect
            case .toggle: .toggle
            case .stepper: .stepper
            case .segment: .segment
            case .text: .text
            case .button: .button
            case .link: .link
            case .login: .login
            case .page: .page
            case .editableList: .editableList
            case .custom: .custom
        }
    }
}

// MARK: Group
public struct GroupSetting: Sendable, Codable, Hashable {
    public let footer: String?
    public let items: [Setting]

    public init(footer: String? = nil, items: [Setting]) {
        self.footer = footer
        self.items = items
    }
}

// MARK: Select
public struct SelectSetting: Sendable, Codable, Hashable {
    public let values: [String]
    public let titles: [String]?
    public let defaultValue: String?

    public init(
        values: [String],
        titles: [String]? = nil,
        defaultValue: String? = nil
    ) {
        self.values = values
        self.titles = titles
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case values
        case titles
        case defaultValue = "default"
    }
}

public struct MultiSelectSetting: Sendable, Codable, Hashable {
    public let values: [String]
    public let titles: [String]?
    public let defaultValue: [String]?

    public init(
        values: [String],
        titles: [String]? = nil,
        defaultValue: [String]? = nil
    ) {
        self.values = values
        self.titles = titles
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case values
        case titles
        case defaultValue = "default"
    }
}

// MARK: Toggle
public struct ToggleSetting: Sendable, Codable, Hashable {
    public let subtitle: String?
    public var authToDisable: Bool?
    public var defaultValue: Bool?

    public init(subtitle: String? = nil, authToDisable: Bool? = nil, defaultValue: Bool = false) {
        self.subtitle = subtitle
        self.authToDisable = authToDisable
        self.defaultValue = defaultValue
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.authToDisable = try container.decodeIfPresent(Bool.self, forKey: .authToDisable)
        self.defaultValue = (try? container.decode(Bool.self, forKey: .defaultValue)) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(authToDisable, forKey: .authToDisable)
        try container.encode(defaultValue ?? false, forKey: .defaultValue)
    }

    enum CodingKeys: String, CodingKey {
        case subtitle
        case authToDisable
        case defaultValue = "default"
    }
}

// MARK: Stepper
public struct StepperSetting: Sendable, Codable, Hashable {
    public let minimumValue: Double
    public let maximumValue: Double
    public let stepValue: Double?
    public var defaultValue: Double?

    public init(minimumValue: Double, maximumValue: Double, stepValue: Double? = nil, defaultValue: Double? = nil) {
        self.minimumValue = minimumValue
        self.maximumValue = maximumValue
        self.stepValue = stepValue
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case minimumValue
        case maximumValue
        case stepValue
        case defaultValue = "default"
    }
}

// MARK: Segment
public struct SegmentSetting: Sendable, Codable, Hashable {
    public let options: [String]
    public var defaultValue: Int?

    public init(options: [String], defaultValue: Int? = nil) {
        self.options = options
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case options
        case defaultValue = "default"
    }
}

// MARK: Text
public struct TextSetting: Sendable, Codable, Hashable {
    public let placeholder: String?
    public let autocapitalizationType: Int?
    public let keyboardType: Int?
    public let returnKeyType: Int?
    public let autocorrectionDisabled: Bool?
    public let secure: Bool?
    public var defaultValue: String?

    public init(
        placeholder: String? = nil,
        autocapitalizationType: Int? = nil,
        keyboardType: Int? = nil,
        returnKeyType: Int? = nil,
        autocorrectionDisabled: Bool = false,
        secure: Bool = false,
        defaultValue: String? = nil
    ) {
        self.placeholder = placeholder
        self.autocapitalizationType = autocapitalizationType
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.autocorrectionDisabled = autocorrectionDisabled
        self.secure = secure
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case placeholder
        case autocapitalizationType
        case keyboardType
        case returnKeyType
        case autocorrectionDisabled
        case secure
        case defaultValue = "default"
    }
}

// MARK: Button
public struct ButtonSetting: Sendable, Codable, Hashable {
    public let destructive: Bool?
    public let confirmTitle: String?
    public let confirmText: String?

    public init(destructive: Bool, confirmTitle: String?, confirmText: String?) {
        self.destructive = destructive
        self.confirmTitle = confirmTitle
        self.confirmText = confirmText
    }
}

// MARK: Link
public struct LinkSetting: Sendable, Codable, Hashable {
    public let url: String
    public let external: Bool?

    public init(url: String, external: Bool?) {
        self.url = url
        self.external = external
    }
}

// MARK: Login
public struct LoginSetting: Sendable, Codable, Hashable {
    public let method: Method
    public let url: String?
    public let urlKey: String?
    public let logoutTitle: String?
    public let pkce: Bool?
    public let tokenUrl: String?
    public let callbackScheme: String?
    public let useEmail: Bool?

    public enum Method: String, Sendable, Codable {
        case basic
        case oauth
        case web
    }

    public init(
        method: Method,
        url: String? = nil,
        urlKey: String? = nil,
        logoutTitle: String? = nil,
        pkce: Bool = false,
        tokenUrl: String? = nil,
        callbackScheme: String? = nil,
        useEmail: Bool? = nil
    ) {
        self.method = method
        self.url = url
        self.urlKey = urlKey
        self.logoutTitle = logoutTitle
        self.pkce = pkce
        self.tokenUrl = tokenUrl
        self.callbackScheme = callbackScheme
        self.useEmail = useEmail
    }
}

// MARK: Page
public struct PageSetting: Sendable, Codable, Hashable {
    public let items: [Setting]
    public let inlineTitle: Bool?
    public let authToOpen: Bool?

    public init(items: [Setting], inlineTitle: Bool = false, authToOpen: Bool = false) {
        self.items = items
        self.inlineTitle = inlineTitle
        self.authToOpen = authToOpen
    }
}

// MARK: Editable List
public struct EditableListSetting: Sendable, Codable, Hashable {
    public let lineLimit: Int?
    public let inline: Bool?
    public let placeholder: String?
    public let defaultValue: [String]?

    public init(
        lineLimit: Int? = nil,
        inline: Bool = false,
        placeholder: String? = nil,
        defaultValue: [String]? = nil
    ) {
        self.lineLimit = lineLimit
        self.inline = inline
        self.placeholder = placeholder
        self.defaultValue = defaultValue
    }

    enum CodingKeys: String, CodingKey {
        case lineLimit
        case inline
        case placeholder
        case defaultValue = "default"
    }
}

// MARK: Codable
extension Setting: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try? container.decode(SettingType.self, forKey: .type)
        guard let type else { throw DecodingError.invalidType }
        key = (try? container.decode(String.self, forKey: .key)) ?? ""
        if type != .group && key.isEmpty {
            throw DecodingError.missingKey
        }
        title = (try? container.decode(String.self, forKey: .title)) ?? ""
        notification = try container.decodeIfPresent(String.self, forKey: .notification)
        requires = try container.decodeIfPresent(String.self, forKey: .requires)
        requiresFalse = try container.decodeIfPresent(String.self, forKey: .requiresFalse)
        refreshes = try container.decodeIfPresent([String].self, forKey: .refreshes) ?? []

        _ = try? container.decode(UInt8.self, forKey: .enumValue)

        switch type {
            case .group: value = .group(try GroupSetting(from: decoder))
            case .select: value = .select(try SelectSetting(from: decoder))
            case .multiselect: value = .multiselect(try MultiSelectSetting(from: decoder))
            case .toggle: value = .toggle(try ToggleSetting(from: decoder))
            case .stepper: value = .stepper(try StepperSetting(from: decoder))
            case .segment: value = .segment(try SegmentSetting(from: decoder))
            case .text: value = .text(try TextSetting(from: decoder))
            case .button: value = .button(try ButtonSetting(from: decoder))
            case .link: value = .link(try LinkSetting(from: decoder))
            case .login: value = .login(try LoginSetting(from: decoder))
            case .page: value = .page(try PageSetting(from: decoder))
            case .editableList: value = .editableList(try EditableListSetting(from: decoder))
            case .custom: value = .custom
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.rawValue, forKey: .type)
        let key: String? = if key.isEmpty { nil } else { key }
        try container.encode(key, forKey: .key)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(notification, forKey: .notification)
        try container.encodeIfPresent(requires, forKey: .requires)
        try container.encodeIfPresent(requiresFalse, forKey: .requiresFalse)
        try container.encodeIfPresent(refreshes, forKey: .refreshes)

        try container.encode(type.byteValue, forKey: .enumValue)

        switch value {
            case let .group(value): try value.encode(to: encoder)
            case let .select(value): try value.encode(to: encoder)
            case let .multiselect(value): try value.encode(to: encoder)
            case let .toggle(value): try value.encode(to: encoder)
            case let .stepper(value): try value.encode(to: encoder)
            case let .segment(value): try value.encode(to: encoder)
            case let .text(value): try value.encode(to: encoder)
            case let .button(value): try value.encode(to: encoder)
            case let .link(value): try value.encode(to: encoder)
            case let .login(value): try value.encode(to: encoder)
            case let .page(value): try value.encode(to: encoder)
            case let .editableList(value): try value.encode(to: encoder)
            case .custom: break
        }
    }

    enum DecodingError: Error {
        case invalidType
        case missingKey
    }

    enum CodingKeys: String, CodingKey {
        case type
        case key
        case title
        case notification
        case requires
        case requiresFalse
        case refreshes
        case enumValue
    }
}
