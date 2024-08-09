//
//  RecipeInstructionsSheet.swift
//  Persephone
//
//  Created by Zach Wassynger on 8/9/24.
//

import SwiftUI

struct RecipeInstructionsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    enum Mode {
        case Add(instructions: Binding<[RecipeSection]>)
        case Edit(section: RecipeSection)
        
        func computeTitle() -> String {
            switch self {
            case .Add(_):
                return "Add Section"
            case .Edit(_):
                return "Edit Section"
            }
        }
    }
    
    let mode: Mode
    
    @State private var header: String = ""
    @State private var details: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Header") {
                    TextField("required", text: $header)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                }
                Section("Details") {
                    TextField("required", text: $details, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .lineLimit(5...12)
                }
            }.navigationTitle(mode.computeTitle())
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .onAppear {
                    switch mode {
                    case .Edit(let section):
                        header = section.header
                        details = section.details
                    default:
                        break
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        switch mode {
                        case .Add(let instructions):
                            Button("Add") {
                                instructions.wrappedValue.append(RecipeSection(header: header, details: details))
                                dismiss()
                            }.disabled(header.isEmpty || details.isEmpty)
                        case .Edit(var section):
                            Button("Save") {
                                section.header = header
                                section.details = details
                                dismiss()
                            }.disabled(header.isEmpty || details.isEmpty)
                        }
                    }
                }
        }.presentationDetents([.medium])
    }
}

#Preview {
    RecipeInstructionsSheet(mode: .Add(instructions: .constant([])))
}
