//
//  Prospect.swift
//  HotProspects
//
//  Created by Jacob LeCoq on 3/3/21.
//

import SwiftUI

class Prospect: Identifiable, Codable {
    private(set) var id = UUID()
    var name = "Anonymous"
    var emailAddress = ""
    var date = Date()
    fileprivate(set) var isContacted = false
}

class Prospects: ObservableObject {
    static let saveKey = "SavedData"
    
    @Published private(set) var people: [Prospect]

    init() {
        self.people = []
        
        // User defaults
        //if let data = UserDefaults.standard.data(forKey: Self.saveKey) {
        
        if let data = loadData() {
            if let decoded = try? JSONDecoder().decode([Prospect].self, from: data) {
                self.people = decoded
                return
            }
        }
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(people) {
            // Challenge 2
            // User defaults
            
            //UserDefaults.standard.set(encoded, forKey: Self.saveKey)
            
            // File
            saveFile(data: encoded)
        }
    }
    
    private func saveFile(data: Data){
        let url = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        
        do {
            try data.write(to: url, options: [.atomicWrite, .completeFileProtection])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func loadData() -> Data? {
        let url = getDocumentsDirectory().appendingPathComponent(Self.saveKey)
        
        if let data = try? Data(contentsOf: url) {
            return data
        }

        return nil
    }
    
    // Challenge 2
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
