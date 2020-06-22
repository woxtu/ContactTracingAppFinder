//
//  ViewController.swift
//  ContactTracingAppFinder
//
//  Created by woxtu on 2020/06/22.
//  Copyright © 2020 woxtu. All rights reserved.
//

import AudioToolbox
import CoreBluetooth
import UIKit

extension CBUUID {
    // Contact Tracing Bluetooth Specification (Apple/Google)
    // https://blog.google/documents/58/Contact_Tracing_-_Bluetooth_Specification_v1.1_RYGZbKW.pdf
    static let contactDetectionService: CBUUID = .init(string: "0000FD6F-0000-1000-8000-00805F9B34FB")
}

extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .resetting: return "Resetting"
        case .unsupported: return "Unsupported"
        case .unauthorized: return "Unauthorized"
        case .poweredOff: return "Powered Off"
        case .poweredOn: return "Powered On"
        @unknown default: return "Unknown"
        }
    }
}

struct Contact {
    let date: Date
    let peripheral: CBPeripheral
}

class ViewController: UIViewController {
    @IBOutlet var tableView: UITableView!

    private var centralManager: CBCentralManager!
    private var contacts: [Contact] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contacts[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = contact.peripheral.identifier.uuidString
        cell.detailTextLabel?.text = ISO8601DateFormatter.string(from: contact.date,
                                                                 timeZone: .current,
                                                                 formatOptions: [.withInternetDateTime])
        return cell
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        title = "State: \(central.state)"

        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [.contactDetectionService])
        } else {
            centralManager.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if RSSI.intValue > -70, RSSI.intValue < -55 {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            contacts.append(Contact(date: Date(), peripheral: peripheral))
            tableView.reloadData()
        }
    }
}
