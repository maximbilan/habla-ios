import SwiftUI

struct CallerIdSettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingVerification = false

    private var state: AppState { store.state }
    private var selectedCountry: PhoneCountry {
        PhoneCountryCatalog.country(isoCode: state.callerId.selectedCountryCode) ?? PhoneCountryCatalog.defaultCountry
    }

    private var isVerifyDisabled: Bool {
        state.callerId.phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || state.callerId.isLoading
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("📞 Your Phone Number")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appTextPrimary)

                Text("Enter the phone number you want recipients to see when you call them.")
                    .font(.system(size: 15))
                    .foregroundColor(.appTextSecondary)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Phone number")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)

                    Menu {
                        ForEach(PhoneCountryCatalog.countries) { country in
                            Button(country.label) {
                                store.dispatch(.callerIdCountryChanged(country.isoCode))
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(selectedCountry.name)
                                .font(.system(size: 14, weight: .medium))
                            Text(selectedCountry.dialCode)
                                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                    }

                    TextField(selectedCountry.dialCode, text: phoneNumberBinding)
                        .keyboardType(.phonePad)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 16))
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Label (optional)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appTextSecondary)

                    TextField("My mobile", text: friendlyNameBinding)
                        .font(.system(size: 16))
                        .foregroundColor(.appTextPrimary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.appSurface))
                }

                Button {
                    store.dispatch(.startCallerIdVerification)
                    isShowingVerification = true
                } label: {
                    HStack {
                        Spacer()
                        if state.callerId.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Verify Number")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.appAccent)
                    )
                }
                .disabled(isVerifyDisabled)
                .opacity(isVerifyDisabled ? 0.55 : 1.0)

                Text("Twilio will call this number. Answer the call and enter the code on your phone's keypad.")
                    .font(.system(size: 14))
                    .foregroundColor(.appTextSecondary)

                if let error = state.callerId.error {
                    Text(error.localizedDescription)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding(20)
            .background(Color.appBackground)
            .navigationTitle("Add Caller ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if state.callerId.phoneNumber.isEmpty {
                store.dispatch(.callerIdPhoneNumberChanged(selectedCountry.dialCode))
            }
        }
        .onChange(of: state.callerId.validationCode) { _, newValue in
            if newValue != nil {
                isShowingVerification = true
            }
        }
        .onChange(of: state.callerId.verificationStatus) { _, newValue in
            if case .verified = newValue {
                dismiss()
            }
        }
        .sheet(isPresented: $isShowingVerification) {
            CallerIdVerificationView(isPresented: $isShowingVerification)
                .environmentObject(store)
        }
    }

    private var phoneNumberBinding: Binding<String> {
        Binding(
            get: { state.callerId.phoneNumber },
            set: { store.dispatch(.callerIdPhoneNumberChanged($0)) }
        )
    }

    private var friendlyNameBinding: Binding<String> {
        Binding(
            get: { state.callerId.friendlyName },
            set: { store.dispatch(.callerIdFriendlyNameChanged($0)) }
        )
    }
}
