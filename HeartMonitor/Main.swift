//
//  Main.swift
//  HeartMonitor
//
//  Created by Gazolla on 04/02/17.
//  Copyright © 2017 Gazolla. All rights reserved.
//

import UIKit

class Main: UIViewController {
    
    var heartMonitor:HeartRateMonitor? {
        didSet{
            heartMonitor?.update = { (hr:HeartRate) in
                DispatchQueue.main.sync {
                    self.heartRateLabel.text = "\(hr.BPM)"
                }
            }
            heartMonitor?.updateMessage = { (msg:String) in
                DispatchQueue.main.sync {
                    self.heartMsgLabel.text = "\(msg)"
                    self.refreshButtons()
                }
            }
        }
    }

    lazy var topSpace:UIView = {
        let s = UIView()
        s.backgroundColor = UIColor.clear
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.heightAnchor.constraint(equalToConstant: self.view.bounds.height*0.35).isActive = true
        s.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        return s
    }()
    
    lazy var bottomSpace:UIView = {
        let s = UIView()
        s.backgroundColor = UIColor.clear
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.heightAnchor.constraint(equalToConstant: self.view.bounds.height*0.2).isActive = true
        s.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        return s
    }()
    
    lazy var hrmList:HRMList = {
        return HRMList()
    }()

    lazy var btnConnect:UIButton = {
        let b = UIButton()
        b.backgroundColor = UIColor(red: 30/255.0, green: 144/255.0, blue: 255/255.0, alpha: 1.0)
        b.layer.cornerRadius = 5
        b.setTitle("connect sensor", for: UIControlState())
        b.titleLabel!.font =  UIFont(name: "HelveticaNeue-CondensedBlack" , size: 20)
        b.addTarget(target, action: #selector(self.btnConnectTapped(_:)), for: UIControlEvents.touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 65).isActive = true
        b.widthAnchor.constraint(equalToConstant: 145).isActive = true
        return b
    }()
    
    lazy var btnRemove:UIButton = {
        let b = UIButton()
        b.backgroundColor = UIColor(red: 30/255.0, green: 144/255.0, blue: 255/255.0, alpha: 1.0)
        b.layer.cornerRadius = 5
        b.setTitle("remove sensor", for: UIControlState())
        b.titleLabel!.font =  UIFont(name: "HelveticaNeue-CondensedBlack" , size: 20)
        b.addTarget(target, action: #selector(self.btnRemoveTapped(_:)), for: UIControlEvents.touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 65).isActive = true
        b.widthAnchor.constraint(equalToConstant: 145).isActive = true
        return b
    }()
    
    func btnConnectTapped(_ sender:UIButton){
        self.hrmList.heartMonitor = self.heartMonitor
        self.navigationController?.pushViewController(self.hrmList, animated: true)
    }
    
    func btnRemoveTapped(_ sender:UIButton){
        if (heartMonitor?.isPeripheralRegistered())! {
            heartMonitor?.removePeripheral()
            refreshButtons()
        }
    }
    
    lazy var heartMsgLabel:UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        l.textColor = UIColor.black
        l.backgroundColor = UIColor.clear
        l.text = "........................."
        return l
    }()
    
    lazy var heartRateLabel:UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lbl.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 100)
        lbl.textColor = UIColor.black
        lbl.backgroundColor = UIColor.clear
        lbl.text = "00"
        return lbl
    }()

    lazy var mainStack:UIStackView = {
        let s = UIStackView(frame: self.view.bounds)
        s.axis = .vertical
        s.alignment = .center
        s.distribution = .equalCentering
        s.spacing = 0
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.addArrangedSubview(self.topSpace)
        s.addArrangedSubview(self.heartRateStack)
        s.addArrangedSubview(self.btnStack)
        s.addArrangedSubview(self.bottomSpace)
        return s
    }()
    
    lazy var btnStack:UIStackView = {
        let s = UIStackView(frame: self.view.bounds)
        s.axis = .horizontal
        s.distribution = .equalCentering
        s.alignment = .center
        s.spacing = 0
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        s.addArrangedSubview(UIView())
        s.addArrangedSubview(self.btnConnect)
        s.addArrangedSubview(UIView())
        s.addArrangedSubview(self.btnRemove)
        s.addArrangedSubview(UIView())
        return s
    }()
    
    lazy var heartRateStack:UIStackView = {
        let s = UIStackView(frame: self.view.bounds)
        s.axis = .vertical
        s.distribution = .equalCentering
        s.alignment = .center
        s.spacing = 0
        s.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        s.widthAnchor.constraint(equalToConstant: self.view.bounds.width).isActive = true
        s.addArrangedSubview(self.heartMsgLabel)
        s.addArrangedSubview(self.heartRateLabel)
        return s
    }()
    
    func refreshButtons(){
        self.btnConnect.isEnabled = !(self.heartMonitor?.isPeripheralRegistered())!
        let alphaConnect:CGFloat = (self.btnConnect.isEnabled) ? 1.0 : 0.5
        self.btnConnect.backgroundColor = UIColor(red: 30/255.0, green: 144/255.0, blue: 255/255.0, alpha: alphaConnect)

        self.btnRemove.isEnabled = (self.heartMonitor?.isPeripheralRegistered())!
        let alphaRemove:CGFloat = (self.btnRemove.isEnabled) ? 1.0 : 0.5
        self.btnRemove.backgroundColor = UIColor(red: 30/255.0, green: 144/255.0, blue: 255/255.0, alpha: alphaRemove)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshButtons()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.mainStack)
    }


}
