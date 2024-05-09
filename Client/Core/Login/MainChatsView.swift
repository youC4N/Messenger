//
//  MainChatsView.swift
//  Messenger
//
//  Created by Егор Малыгин on 06.05.2024.
//

import SwiftUI

struct Name: Identifiable {
    var id: String { name }

    let name: String
}

func foo(input: [String]) -> [Name] {
    var res = [Name]()
    for name in input {
        res.append(Name(name: name))
    }
    return res
}
let input = [
    "Aaran", "Aaren", "Aarez", "Aarman", "Aaron", "Aaron-James", "Aarron", "Aaryan", "Aaryn",
    "Aayan", "Aazaan", "Abaan", "Abbas", "Abdallah", "Abdalroof", "Abdihakim", "Abdirahman",
    "Abdisalam", "Abdul", "Abdul-Aziz", "Abdulbasir", "Abdulkadir", "Abdulkarem", "Abdulkhader",
    "Abdullah", "Abdul-Majeed", "Abdulmalik", "Abdul-Rehman", "Abdur", "Abdurraheem",
    "Abdur-Rahman", "Abdur-Rehmaan", "Abel", "Abhinav", "Abhisumant", "Abid", "Abir", "Abraham",
    "Abu", "Abubakar", "Ace", "Adain", "Adam", "Adam-James", "Addison", "Addisson", "Adegbola",
    "Adegbolahan", "Aden", "Adenn", "Adie", "Adil", "Aditya", "Adnan",
]

struct MainChatsView: View {

    var names = foo(input: input)

    var body: some View {
            ScrollView {

                ForEach(names) { name in
                    contactCardView(userName: name.name)
                }

            }
            .padding()
        
        .navigationTitle("Chats")

    }
}

#Preview {
    NavigationStack {
        MainChatsView()
    }
}
