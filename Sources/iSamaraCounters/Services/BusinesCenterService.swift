//
//  BusinesCenterService.swift
//  Izumrud
//
//  Created by Sergey Balalaev on 18.05.2022.
//  Copyright © 2022 Byterix. All rights reserved.
//

import Foundation
import PromiseKit
import MessageUI

public class BusinesCenterService : NSObject, SendDataService, MFMailComposeViewControllerDelegate {

    public override init() {
        super.init()
    }
    
    var result: Promise<Data>?
    
    public func map(_ input: SendDataServiceInput) -> Promise<Data> {
        
        result = nil
        
        if MFMailComposeViewController.canSendMail() {
            
            var waterBody = ""
            for waterCounter in input.waterCounters {
                if waterCounter.isValid { #warning("Has problem with checking realy params. Order can be invalided.")
                    waterBody +=
                        """
                        Стояки № \(waterCounter.order)
                        Номер счетчика горячей воды: \(waterCounter.hotSerialNumberRow.value ?? "")
                        Значение счетчика горячей воды: \(waterCounter.hotCountRow.value ?? "")
                        Номер счетчика холодной воды: \(waterCounter.coldSerialNumberRow.value ?? "")
                        Значение счетчика холодной воды: \(waterCounter.coldCountRow.value ?? "")
                        
                        """
                    #warning("3th counter should all empty values, or 2th for realy one. Please will add it if need. Without dobavit_schyotchik_hvs_(3/2) each other")
                }
            }
            
            let body =
                """
                Добрый день.
                Меня зовут \(input.surnameRow.value ?? "") \(input.nameRow.value ?? "") \(input.patronymicRow.value ?? "")
                Проживаю по адресу: Самара, Пятая+просека, дом \(input.homeNumberRow.value ?? ""), квартира+\(input.flatNumberRow.value ?? "")
                
                Передаю показания счетчиков электроэнергии:
                день: \(input.dayElectricCountRow.value ?? "")
                ночь: \(input.nightElectricCountRow.value ?? "")
                
                Информация по счётчикам воды:
                \(waterBody)
                """

             let mailComposeViewController = MFMailComposeViewController()
             mailComposeViewController.mailComposeDelegate = self
             mailComposeViewController.setToRecipients(["data_5proseka@mail.ru"])
             mailComposeViewController.setSubject("Показания сч-ов для УК БЦ")
             mailComposeViewController.setMessageBody(body, isHTML: false)

            NavigationUtils.navigationController?.present(mailComposeViewController, animated: true, completion: nil)

        } else {
            error("Почта не настроена для отправки показаний")
        }
        
        return Promise<Data>{[weak self] resolver in
            DispatchQueue.global(qos: .utility).async {[weak self] in
                while(self != nil && self?.result == nil){
                    sleep(1)
                }
                self?.result?.done { data in
                    resolver.fulfill(data)
                }.catch{ error in
                    resolver.reject(error)
                }
            }
        }
    }
    
    func error(_ message: String){
        let error = NSError(domain: self.title, code: 412, userInfo: [NSLocalizedDescriptionKey: message])
        result = .init(error: error)
    }
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        controller.dismiss(animated: true) {[weak self] in
            if let error = error {
                self?.result = Promise<Data>(error: error)
            } else {
                if result == .sent {
                    self?.result = .value(Data())
                } else {
                    self?.error("Показания не были отправлены почтой")
                }
            }
        }

    }
    
    public let title: String = "Бизнес-центер"
    public let name: String = "BusinesCenter"
    public let days = Range<Int>(uncheckedBounds: (lower: 15, upper: 22))
    
    var url: String = ""
    
}
