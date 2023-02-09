import SwiftUI
#if os(watchOS)
import WatchKit
#endif

public struct AsyncButton<Label: View>: View {
    private let role: ButtonRole?
    private let options: AsyncButtonOptions
    private let transaction: Transaction
    private let action: () async throws -> Void
    private let label: (Bool) -> Label

    @State private var operations = [AnyHashable: AsyncButtonOperation]()
    @State private var showingErrorAlert = false
    @State private var localizedError: AnyLocalizedError?

#if os(iOS)
    private let generator = UINotificationFeedbackGenerator()
#elseif os(watchOS)
    private let watchDevice = WKInterfaceDevice.current()
#endif

    @State private var tint: Color?

    var operationIsLoading: Bool {
        operations.values.contains { operation in
            if case .loading = operation {
                return true
            } else {
                return false
            }
        }
    }

    var showProgressView: Bool {
#if os(watchOS)
        false
#else
        options.contains(.showProgressViewOnLoading) && operationIsLoading
#endif
    }

    var buttonDisabled: Bool {
        options.contains(.disableButtonOnLoading) && operationIsLoading
    }

    public var body: some View {
        Button(
            role: role,
            action: {
                if options.contains(.disallowParallelOperations) {
                    guard !operationIsLoading else { return }
                }
                let actionTask = Task {
                    try await action()
                }
                operations[actionTask] = .loading(actionTask)
                Task {
                    if options.contains(.enableHapticFeedback) {
#if os(iOS)
                        generator.prepare()
#endif
                    }
                    let result = await actionTask.result
                    operations[actionTask] = .completed(actionTask, result)
                    if options.contains(.enableHapticFeedback) {
#if os(iOS)
                        switch result {
                        case .success:
                            generator.notificationOccurred(.success)
                        case .failure:
                            generator.notificationOccurred(.error)
                        }
#elseif os(watchOS)
                        switch result {
                        case .success:
                            watchDevice.play(options.contains(.enableSuccessHapticFeedback) ? .success : .click)
                        case .failure:
                            watchDevice.play(.failure)
                        }
#endif
                    }
                    if options.contains(.enableTintFeedback) {
                        withAnimation(.linear(duration: 0.1)) {
                            switch result {
                            case .success:
                                tint = .green
                            case .failure:
                                tint = .red
                            }
                        }
                        withAnimation(.linear(duration: 0.2).delay(1.5)) {
                            tint = nil
                        }
                    }
                    if options.contains(.showAlertOnError) {
                        if case .failure(let error) = result {
                            let localizedError = error as? LocalizedError ?? UnlocalizedError(error: error)
                            self.localizedError = AnyLocalizedError(erasing: localizedError)
                            showingErrorAlert = true
                        }
                    }
                }
            },
            label: {
                label(operationIsLoading)
                    .opacity(showProgressView ? 0 : 1)

                if showProgressView {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        )
        .disabled(buttonDisabled)
        .animation(transaction.animation, value: operations)
        .tint(tint)
        .alert(isPresented: $showingErrorAlert, error: localizedError) { error in
            Button("OK") {
                showingErrorAlert = false
            }
        } message: { error in
            if let message = error.failureReason ?? error.recoverySuggestion ?? error.helpAnchor {
                Text(message)
            }
        }

    }

    public init(
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = [],
        transaction: Transaction = Transaction(),
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping (Bool) -> Label
    ) {
        self.role = role
        self.options = options
        self.transaction = transaction
        self.action = action
        self.label = label
    }
}

public extension AsyncButton {

    init(
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            label()
        }
    }
}

public extension AsyncButton where Label == Text {

    init(
        _ titleKey: LocalizedStringKey,
        role: ButtonRole? = nil,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void
    ) {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            Text(titleKey)
        }
    }
}

public extension AsyncButton where Label == Text {

    init<S>(
        _ title: S,
        role: ButtonRole?,
        options: AsyncButtonOptions = .automatic,
        transaction: Transaction = Transaction(animation: .default),
        action: @escaping () async throws -> Void
    ) where S : StringProtocol
    {
        self.init(role: role, options: options, transaction: transaction, action: action) { _ in
            Text(title)
        }
    }
}
