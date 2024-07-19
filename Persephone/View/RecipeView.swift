//
//  RecipeView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/17/24.
//

import SwiftData
import SwiftUI

struct RecipeView: View {
    var recipe: Recipe
    
    let servingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
    
    let timeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        createStackedText(upper: "\(servingFormatter.string(for: recipe.sizeInfo.numServings)!) servings", lower: recipe.sizeInfo.servingSize.uppercased())
                    }
                    if (!recipe.metaData.tags.isEmpty) {
                        Divider()
                        Label(recipe.metaData.tags.joined(separator: ", "), systemImage: "tag.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .labelStyle(CenterLabelStyle())
                    }
                }
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                        createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.totalTime)!) min", lower: "TOTAL")
                    }
                    Divider()
                    createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.prepTime)!) min", lower: "PREP")
                    if (recipe.metaData.cookTime != nil) {
                        Divider()
                        createStackedText(upper: "\(timeFormatter.string(for: recipe.metaData.cookTime!)!) min", lower: "COOK")
                    }
                    Spacer()
                }
                Text(recipe.metaData.details)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .italic()
                    .fontWeight(.light)
                    .font(.subheadline)
                Divider()
                if (!recipe.foodEntries.isEmpty) {
                    ForEach(recipe.foodEntries.sorted(by: { x, y in
                        x.name.caseInsensitiveCompare(y.name).rawValue < 0
                    }), id: \.name) { entry in
                        HStack(spacing: 8) {
                            Text("\(servingFormatter.string(for: entry.amount)!) \(entry.unit.getAbbreviation())").bold()
                            Text("·")
                            Text(entry.name).fontWeight(.light)
                        }
                    }
                    Divider()
                }
                createInstructionsView(createInstructions(recipe.metaData.instructions))
                Spacer()
            }.padding(24)
        }.navigationTitle(recipe.name)
            .fontDesign(.serif)
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    NavigationLink {
                        RecipeEditor(recipe: recipe)
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
    }
    
    private func createInstructions(_ raw: String) -> Instructions {
        let lines = raw.split(separator: "\n")
        var sections: [Section] = []
        var section: Section? = nil
        lines.forEach { line in
            if line.starts(with: try! Regex("\\d\\.")) {
                if section == nil {
                    section = Section()
                    sections.append(section!)
                }
                section!.steps.append(line.string)
            } else {
                section = Section(heading: line.string)
                sections.append(section!)
            }
        }
        return Instructions(sections: sections)
    }
    
    private func createInstructionsView(_ instructions: Instructions) -> some View {
        VStack(alignment: .leading) {
            ForEach(instructions.sections, id: \.self.heading) { section in
                VStack {
                    Text(section.heading ?? "Heading").bold()
                    ForEach(section.steps, id: \.self) { step in
                        Text(step)
                    }
                }
                Spacer()
            }
        }
    }
    
    private func createStackedText(upper: String, lower: String) -> some View {
        VStack(alignment: .leading) {
            Text(upper).font(.subheadline).bold()
            Text(lower).font(.caption2).fontWeight(.light).italic()
        }
    }
}

private struct Instructions {
    var sections: [Section]
    
    init(sections: [Section] = []) {
        self.sections = sections
    }
}

private struct Section {
    var heading: String?
    var steps: [String]
    
    init(heading: String? = nil, steps: [String] = []) {
        self.heading = heading
        self.steps = steps
    }
}

private struct CenterLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Recipe.self, configurations: config)
    let recipe = Recipe(name: "Buttermilk Waffles",
                        sizeInfo: RecipeSizeInfo(
                            servingSize: "1 waffle",
                            numServings: 6,
                            cookedWeight: 255),
                        metaData: RecipeMetaData(
                            details: "My fav waffles, some more text here just put them on the iron for a few minutes and eat",
                            instructions: "Prep\n1. Put in the water and the mix, mix together until barely mixed.\n2. Put mix in the waffle iron.\n3. Wait until its done.",
                            totalTime: 25,
                            prepTime: 8,
                            cookTime: 17,
                            tags: ["Breakfast", "Bread"]))
    container.mainContext.insert(recipe)
    container.mainContext.insert(RecipeFoodEntry(name: "Water", recipe: recipe, amount: 1.0, unit: .Liter))
    container.mainContext.insert(RecipeFoodEntry(name: "Salt", recipe: recipe, amount: 600, unit: .Milligram))
    return NavigationStack {
        RecipeView(recipe: recipe)
    }
}
