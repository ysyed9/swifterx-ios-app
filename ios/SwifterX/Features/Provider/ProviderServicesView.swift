import SwiftUI
import FirebaseFirestore

/// Provider edits the services customers see on their public profile (`providers/{uid}/services`).
struct ProviderServicesView: View {
    @EnvironmentObject private var dataService: DataService
    @EnvironmentObject private var authManager: AuthManager

    @State private var services: [ServiceItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showEditor = false
    @State private var editingItem: ServiceItem?
    @State private var draftName = ""
    @State private var draftPrice = ""
    @State private var servicesListener: ListenerRegistration?

    private var providerUID: String? { authManager.userUID }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Your services")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Text("These appear on your profile so customers can add them to the cart.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(sxHex: "#828282"))
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                if providerUID == nil {
                    Text("Sign in as a provider to manage services.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(sxHex: "#cc3333"))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                } else if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if services.isEmpty {
                    Text("No services yet. Tap Add service.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(sxHex: "#828282"))
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                } else {
                    ForEach(services) { item in
                        VStack(spacing: 0) {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)
                                    Text("$\(String(format: "%.2f", item.price))")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color(sxHex: "#828282"))
                                }
                                Spacer()
                                Button("Edit") { openEditor(item) }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.black)
                                Button("Delete", role: .destructive) {
                                    Task { await deleteService(item) }
                                }
                                .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            Divider().padding(.leading, 20)
                        }
                    }
                    .padding(.top, 16)
                }

                Button {
                    openEditor(nil)
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add service")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(providerUID == nil ? Color.gray : Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                }
                .disabled(providerUID == nil)
                .buttonStyle(.plain)

                Spacer().frame(height: 32)
            }
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                Form {
                    Section("Service") {
                        TextField("Name", text: $draftName)
                            .textInputAutocapitalization(.words)
                        TextField("Price (USD)", text: $draftPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle(editingItem == nil ? "New service" : "Edit service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { Task { await saveDraft() } }
                            .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .onAppear { attachServicesListener() }
        .onChange(of: authManager.userUID) { _, _ in attachServicesListener() }
        .onDisappear {
            servicesListener?.remove()
            servicesListener = nil
        }
    }

    private func attachServicesListener() {
        servicesListener?.remove()
        servicesListener = nil
        guard let uid = providerUID, !uid.isEmpty else {
            services = []
            isLoading = false
            return
        }
        isLoading = true
        errorMessage = nil
        let ref = Firestore.firestore()
            .collection("providers").document(uid).collection("services")
        servicesListener = ref.addSnapshotListener { snapshot, error in
            Task { @MainActor in
                if let error {
                    isLoading = false
                    if services.isEmpty { services = [] }
                    errorMessage = UserFacingError.message(from: error)
                    return
                }
                let docs = snapshot?.documents ?? []
                services = ServiceItemFirestore.sortedItems(from: docs)
                isLoading = false
                // Do not clear errorMessage here — a failed save would be wiped on the next snapshot.
            }
        }
    }

    private func openEditor(_ item: ServiceItem?) {
        editingItem = item
        draftName = item?.name ?? ""
        draftPrice = item.map { String(format: "%.2f", $0.price) } ?? ""
        showEditor = true
    }

    private func saveDraft() async {
        guard let uid = providerUID else { return }
        errorMessage = nil
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= 120 else {
            errorMessage = "Enter a service name (up to 120 characters)."
            return
        }
        guard let price = Double(draftPrice.replacingOccurrences(of: ",", with: ".")),
              price > 0, price < 100_000 else {
            errorMessage = "Enter a valid price greater than zero."
            return
        }
        let id = editingItem?.id ?? UUID().uuidString
        let item = ServiceItem(id: id, name: name, price: price)
        do {
            try await dataService.saveProviderService(providerID: uid, item: item)
            errorMessage = nil
            showEditor = false
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }

    private func deleteService(_ item: ServiceItem) async {
        guard let uid = providerUID else { return }
        do {
            try await dataService.deleteProviderService(providerID: uid, serviceId: item.id)
        } catch {
            errorMessage = UserFacingError.message(from: error)
        }
    }
}

#Preview {
    NavigationStack {
        ProviderServicesView()
    }
    .environmentObject(DataService(client: PreviewAPIClient.shared))
    .environmentObject(AuthManager())
}
