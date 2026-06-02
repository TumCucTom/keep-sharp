import SwiftUI

struct NavigationBar: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var query: String = ""

    var body: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.openHome()
            } label: {
                Image(systemName: "house")
            }
            .help("LeetCode home")

            Button {
                viewModel.openProblemSet()
            } label: {
                Text("All Problems")
            }

            Divider().frame(height: 16)

            TextField("Problem # or slug (e.g. 1 or two-sum)", text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submit() }

            Button("Go") { submit() }
                .keyboardShortcut(.defaultAction)
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()

            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func submit() {
        let value = query
        query = ""
        viewModel.navigate(input: value)
    }
}
