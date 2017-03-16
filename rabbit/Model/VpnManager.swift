//
//  VpnManager.swift
//  rabbit
//
//  Created by CYC on 2016/11/19.
//  Copyright © 2016年 yicheng. All rights reserved.
//

import Foundation
import NetworkExtension


enum VPNStatus {
    case off
    case connecting
    case on
    case disconnecting
}


class VpnManager{
    static let shared = VpnManager()
    var observerAdded: Bool = false
    var vpnManager: NETunnelProviderManager = NETunnelProviderManager()
    let tunnelBundleId = "com.ISEC.JiGuangVPN.tunnel"
    let serverAddress = "192.168.123.62"//"<server-ip>"
    let serverPort = "8389"//"54345"
    let mtu = "1400"
    let ip = "a.ssx.host"
    let subnet = "255.255.255.0"
    let password = "asdf"
    let method = "aes-128-cfb"

    
    fileprivate(set) var vpnStatus = VPNStatus.off {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
        }
    }
    
    init() {
        loadProviderManager{
            guard let manager = $0 else{return}
            self.updateVPNStatus(manager)
        }
        addVPNStatusObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func addVPNStatusObserver() {
        guard !observerAdded else{
            return
        }
        loadProviderManager { [unowned self] (manager) -> Void in
            if let manager = manager {
                self.observerAdded = true
                NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object: manager.connection, queue: OperationQueue.main, using: { [unowned self] (notification) -> Void in
                    self.updateVPNStatus(manager)
                    })
            }
        }
    }
    
    
    func updateVPNStatus(_ manager: NEVPNManager) {
        switch manager.connection.status {
        case .connected:
            self.vpnStatus = .on
        case .connecting, .reasserting:
            self.vpnStatus = .connecting
        case .disconnecting:
            self.vpnStatus = .disconnecting
        case .disconnected, .invalid:
            self.vpnStatus = .off
        }
        print(self.vpnStatus)
    }
}

// load VPN Profiles
extension VpnManager{

    
    fileprivate func createProviderManager() -> NETunnelProviderManager {
        let manager = NETunnelProviderManager()
        let conf = NETunnelProviderProtocol()
        conf.serverAddress = "Rabbit"
        manager.protocolConfiguration = conf
        manager.localizedDescription = "com.windvalley.rabbit.PacketTunnel"
        return manager
    }
    func initVPNTunnelProviderManager() {
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            if let savedManagers = savedManagers {
                if savedManagers.count > 0 {
                    self.vpnManager = savedManagers[0]
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error:Error?) in
                if let error = error {
                    print(error)
                }
                
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.providerBundleIdentifier = self.tunnelBundleId
                
                providerProtocol.providerConfiguration = ["port": self.serverPort,
                                                          "server": self.serverAddress,
//                                                          "ip": self.ip,
//                                                          "subnet": self.subnet,
//                                                          "mtu": self.mtu,
                                                          "password":self.password,
                                                          "method":self.method,
                                                          "ymal_conf":self.getRuleConf()
                ]//["port":1024,"method":"aes-256-cfb","password":"31415857","server": self.serverAddress]
                
                providerProtocol.serverAddress = self.serverAddress
                self.vpnManager.protocolConfiguration = providerProtocol
                self.vpnManager.localizedDescription = "NEPacketTunnelVPNDemoConfig"
                self.vpnManager.isEnabled = true
                
                self.vpnManager.saveToPreferences(completionHandler: { (error:Error?) in
                    if let error = error {
                        print(error)
                    } else {
                        print("Save successfully")
                        do {
                            try self.vpnManager.connection.startVPNTunnel(options: [:])
                        } catch {
                            print("startVPNTunnel \(error)")
                        }
                    }
                })
                
                
            })
        }
    }

    
    
    func loadAndCreatePrividerManager(_ complete: @escaping (NETunnelProviderManager?) -> Void ){
        NETunnelProviderManager.loadAllFromPreferences { (savedManagers: [NETunnelProviderManager]?, error: Error?) in
            if let error = error {
                print(error)
            }
            if let savedManagers = savedManagers {
                if savedManagers.count > 0 {
                    self.vpnManager = savedManagers[0]
                }
            }
            
            self.vpnManager.loadFromPreferences(completionHandler: { (error:Error?) in
                if let error = error {
                    print(error)
                }
                
                let providerProtocol = NETunnelProviderProtocol()
                providerProtocol.providerBundleIdentifier = self.tunnelBundleId
                
                providerProtocol.providerConfiguration = ["port": self.serverPort,
                                                          "server": self.serverAddress,
                                                          "ip": self.ip,
                                                          "subnet": self.subnet,
                                                          "mtu": self.mtu,
                                                          "password":self.password,
                                                          "method":self.method
                ]//["port":1024,"method":"aes-256-cfb","password":"31415857","server": self.serverAddress]
                
                providerProtocol.serverAddress = self.serverAddress
                self.vpnManager.protocolConfiguration = providerProtocol
                self.vpnManager.localizedDescription = "com.windvalley.rabbit.PacketTunnel"
                self.vpnManager.isEnabled = true
                
                self.vpnManager.saveToPreferences(completionHandler: { (error:Error?) in
                    if let error = error {
                        print(error)
                    } else {
                        print("Save successfully")
                    }
                })
                self.addVPNStatusObserver()
                
            })
        }
}
    
    func newSearchDictionary(identifier: String){
//        var searchDictionary = <#value#>
        
    }
    
    func createKeychainValue(password: String, identifier: String){
        
    }
    
    func loadProviderManager(_ complete: @escaping (NETunnelProviderManager?) -> Void){
        NETunnelProviderManager.loadAllFromPreferences { (managers, error) in
            if let managers = managers {
                if managers.count > 0 {
                    let manager = managers[0]
                    complete(manager)
                    return
                }
            }
            complete(nil)
        }
    }
    
    
    func delDupConfig(_ arrays:[NETunnelProviderManager]){
        if (arrays.count)>1{
            for i in 0 ..< arrays.count{
                print("Del DUP Profiles")
                arrays[i].removeFromPreferences(completionHandler: { (error) in
                    if(error != nil){print(error.debugDescription)}
                })
            }
        }
    }
    //存储vpn的配置信息
    
    
    
}

// Actions
extension VpnManager{
    func connect(){
        self.initVPNTunnelProviderManager()
//        self.loadAndCreatePrividerManager { (manager) in
//            guard let manager = manager else{return}
//            do{
//                try manager.connection.startVPNTunnel(options: [:])
//            }catch let err{
//                print(err)
//            }
//        }
    }
    
    func disconnect(){
        loadProviderManager{$0?.connection.stopVPNTunnel()}
    }
}

// Generate and Load ConfigFile
extension VpnManager{
    fileprivate func getRuleConf() -> String{
        let Path = Bundle.main.path(forResource: "NEKitRule", ofType: "conf")
        let Data = try? Foundation.Data(contentsOf: URL(fileURLWithPath: Path!))
        let str = String(data: Data!, encoding: String.Encoding.utf8)!
        return str
    }
    
    fileprivate func setRulerConfig(_ manager:NETunnelProviderManager){
        var conf = [String:AnyObject]()
        conf["ss_address"] = "192.168.123.62" as AnyObject?
        conf["ss_port"] = 8389 as AnyObject?
        conf["ss_method"] = "aes-128-cfb" as AnyObject?
        conf["ss_password"] = "asdf" as AnyObject?
        conf["ymal_conf"] = getRuleConf() as AnyObject?
        let orignConf = manager.protocolConfiguration as! NETunnelProviderProtocol
        orignConf.providerConfiguration = conf
        manager.protocolConfiguration = orignConf
    }
}
