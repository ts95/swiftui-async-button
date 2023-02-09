import Foundation

public struct AsyncButtonOptions: OptionSet {
    public let rawValue: Int

    public static let disableButtonOnLoading       = AsyncButtonOptions(rawValue: 1 << 0)
    public static let showProgressViewOnLoading    = AsyncButtonOptions(rawValue: 1 << 1)
    public static let showAlertOnError             = AsyncButtonOptions(rawValue: 1 << 2)
    public static let disallowParallelOperations   = AsyncButtonOptions(rawValue: 1 << 3)
    public static let enableHapticFeedback         = AsyncButtonOptions(rawValue: 1 << 4)
    public static let enableTintFeedback           = AsyncButtonOptions(rawValue: 1 << 5)

#if os(watchOS)
    public static let enableSuccessHapticFeedback = AsyncButtonOptions(rawValue: 1 << 6)
#endif

    public static let all: AsyncButtonOptions = [
        .disableButtonOnLoading,
        .showProgressViewOnLoading,
        .showAlertOnError,
        .disallowParallelOperations,
        .enableHapticFeedback,
        .enableTintFeedback
    ]

    public static let automatic: AsyncButtonOptions = [
        .disableButtonOnLoading,
        .showProgressViewOnLoading,
        .showAlertOnError,
        .disallowParallelOperations,
        .enableHapticFeedback
    ]

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

