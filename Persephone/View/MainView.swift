//
//  MainView.swift
//  Persephone
//
//  Created by Zach Wassynger on 7/10/24.
//

import SwiftData
import SwiftUI

struct MainView: View {
    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .accent
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView {
            FoodDatabaseView()
                .tabItem {
                    Label("Database", systemImage: "tablecells")
                }
            CookbookView()
                .tabItem {
                    Label("Cookbook", systemImage: "book")
                }
            Text("Inventory")
                .tabItem {
                    Label("Inventory", systemImage: "list.clipboard")
                }
            LogWeekView()
                .tabItem {
                    Label("Logbook", systemImage: "calendar")
                }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    MainView()
}
