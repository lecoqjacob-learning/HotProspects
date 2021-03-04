//
//  ProspectsView.swift
//  HotProspects
//
//  Created by Jacob LeCoq on 3/3/21.
//

import CodeScanner
import SwiftUI
import UserNotifications

struct ProspectsView: View {
    enum FilterType {
        case none, contacted, uncontacted
    }

    // Challenge 3
    enum SortType {
        case name, recent
    }

    @EnvironmentObject var prospects: Prospects
    @State private var isShowingScanner = false

    // Challenge 3
    @State private var isShowingPopover = false
    @State private var isShowingSortOptions = false
    @State private var sortBy: SortType = .name
    
    var simulateDataArr: [String] = ["Paul Hudson\npaul@hackingwithswift.com", "Jacob LeCoq\nlecoqjacob@gmail.com", "Sarah Parker\nsarahp@gmail.com"]

    let filter: FilterType

    var title: String {
        switch filter {
        case .none:
            return "Everyone"
        case .contacted:
            return "Contacted people"
        case .uncontacted:
            return "Uncontacted people"
        }
    }

    var filteredProspects: [Prospect] {
        switch filter {
        case .none:
            return prospects.people
        case .contacted:
            return prospects.people.filter { $0.isContacted }
        case .uncontacted:
            return prospects.people.filter { !$0.isContacted }
        }
    }

    var filteredSortedProspects: [Prospect] {
        switch sortBy {
        case .name:
            return filteredProspects.sorted { $0.name < $1.name }
        case .recent:
            return filteredProspects.sorted { $0.date < $1.date }
        }
    }
    
    static let taskDateFormat: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter
        }()

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSortedProspects) { prospect in
                    HStack {
                        // Challenge 1
                        if self.filter == .none {
                            Image(systemName: prospect.isContacted ? "envelope" : "envelope.badge")
                        }

                        VStack(alignment: .leading) {
                            Text(prospect.name)
                                .font(.headline)
                            Text(prospect.emailAddress)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(prospect.date, formatter: Self.taskDateFormat)
                        
                    }
                    .contextMenu {
                        Button(prospect.isContacted ? "Mark Uncontacted" : "Mark Contacted") {
                            self.prospects.toggle(prospect)
                        }

                        if !prospect.isContacted {
                            Button("Remind Me") {
                                self.addNotification(for: prospect)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr], simulatedData: simulateDataArr.randomElement()!, completion: self.handleScan)
            }
            .actionSheet(isPresented: $isShowingSortOptions) {
                ActionSheet(title: Text("Sort by"), buttons: [
                    .default(Text((self.sortBy == .name ? "✓ " : "") + "Name"), action: { self.sortBy = .name }),
                    .default(Text((self.sortBy == .recent ? "✓ " : "") + "Most recent"), action: { self.sortBy = .recent }),
                    .cancel()
                ])
            }
            .navigationBarTitle(title)
            // Challenge 3
            .navigationBarItems(leading: Button("Sort") {
                self.isShowingSortOptions = true
            }, trailing: Button(action: {
                self.isShowingScanner = true
            }) {
                Image(systemName: "qrcode.viewfinder")
                Text("Scan")
            })
        }
    }

    private func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        isShowingScanner = false

        switch result {
        case .success(let code):
            let details = code.components(separatedBy: "\n")
            guard details.count == 2 else { return }

            let person = Prospect()
            person.name = details[0]
            person.emailAddress = details[1]

            prospects.add(person)
        case .failure:
            print("Scanning failed")
        }
    }

    private func addNotification(for prospect: Prospect) {
        let center = UNUserNotificationCenter.current()

        let addRequest = {
            let content = UNMutableNotificationContent()
            content.title = "Contact \(prospect.name)"
            content.subtitle = prospect.emailAddress
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = 9
//            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                addRequest()
            } else {
                center.requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
                    if success {
                        addRequest()
                    } else {
                        print("D'oh")
                    }
                }
            }
        }
    }
}

struct ProspectsView_Previews: PreviewProvider {
    static var previews: some View {
        ProspectsView(filter: .none)
    }
}
