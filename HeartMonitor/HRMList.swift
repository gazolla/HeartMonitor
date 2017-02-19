//
//  HRMList.swift
//  HeartMonitor
//
//  Created by Gazolla on 11/02/17.
//  Copyright © 2017 Gazolla. All rights reserved.
//

import UIKit
import CoreBluetooth

struct DisplayPeripheral {
    var name:String
    var lastRSSI:NSNumber
    var peripheral:CBPeripheral
}

class HRMList: UIViewController {
    
    var peripherals:[DisplayPeripheral] = []

    var heartMonitor:HeartRateMonitor?{
        didSet{
            heartMonitor?.updateList = { (list:[DisplayPeripheral]) in
                self.peripherals = list
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            heartMonitor?.updateStopScan = {
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    lazy var refreshControl:UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action:  #selector(self.refreshScan(_:)), for: .valueChanged)
        return rc
    }()
    
    func refreshScan(_ refreshControl: UIRefreshControl?){
        self.peripherals = []
        self.tableView.reloadData()
        self.heartMonitor?.startScanning()
    }
    
    lazy var tableView:UITableView = {
        let tv = UITableView(frame: self.view.bounds, style: .grouped)
        tv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tv.delegate = self
        tv.dataSource = self
        tv.register(DeviceCell.self, forCellReuseIdentifier:"cell")
        tv.addSubview(self.refreshControl)
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Lista de Sensores"
        self.view.addSubview(self.tableView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.setContentOffset(CGPoint(x: 0, y: -self.refreshControl.frame.size.height*2), animated: true)
        self.refreshControl.beginRefreshing()
        refreshScan(nil)
    }
}

extension HRMList:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! DeviceCell
        cell.displayPeripheral = self.peripherals[indexPath.item]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let displaySensor = self.peripherals[indexPath.item]
        let sensor = displaySensor.peripheral
        self.heartMonitor?.centralManager.connect(sensor, options: nil)
        _ = self.navigationController?.popViewController(animated: true)
        
    }
}


class DeviceCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required  public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override  open func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var displayPeripheral: DisplayPeripheral? {
        didSet {
            self.textLabel?.text =  "\(displayPeripheral!.name)"
            self.detailTextLabel?.text = "\(displayPeripheral!.lastRSSI)dB - \(displayPeripheral!.peripheral.identifier.uuidString)"
            self.imageView?.image = UIImage(named: "bluetooth")
        }
    }
    
    
}
