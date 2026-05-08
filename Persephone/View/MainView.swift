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
            LogWeekView()
                .tabItem {
                    Label("Logbook", systemImage: "calendar")
                }
            CookbookView()
                .tabItem {
                    Label("Cookbook", systemImage: "book")
                }
            Text("Inventory")
                .tabItem {
                    Label("Inventory", systemImage: "list.clipboard")
                }
            FoodDatabaseView()
                .tabItem {
                    Label("Database", systemImage: "tablecells")
                }
        }
    }
}

#Preview(traits: .modifier(MockDataPreviewModifier())) {
    MainView()
}
