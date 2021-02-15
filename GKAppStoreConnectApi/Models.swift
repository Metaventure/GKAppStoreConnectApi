//
//  Models.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew Liakh on 28.01.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation

public struct ASCApp {
    public var id: String
    public var sku: String
    public var platform: String
    public var iconUrl: String
    public var name: String
    
    public init(id: String, sku: String, platform: String, iconUrl: String, name: String) {
        self.id = id
        self.sku = sku
        self.platform = platform
        self.iconUrl = iconUrl
        self.name = name
    }
}

public struct ASCUser {
    public var email: String
    public var personId: String
    public var currentTeamId: String
    public var teams: [ASCTeam]
    
    public init(email: String, personId: String, currentTeamId: String, teams: [ASCTeam]) {
        self.email = email
        self.personId = personId
        self.currentTeamId = currentTeamId
        self.teams = teams
    }
}

public struct ASCTeam {
    public var name: String
    public var providerId: Int
    public var apps: [ASCApp]
    
    public init(name: String, providerId: Int, apps: [ASCApp]) {
        self.name = name
        self.providerId = providerId
        self.apps = apps
    }
}

public struct ASCAppPromoCodesInfo {
    public var version: String
    public var versionId: Int
    public var contractFilename: String
    public var codesLeft: Int
    
    public init(version: String, versionId: Int, contractFilename: String, codesLeft: Int) {
        self.version = version
        self.versionId = versionId
        self.contractFilename = contractFilename
        self.codesLeft = codesLeft
    }
}

public struct ASCAppInternalPurchase {
    public var id: String
    public var name: String
    public var codesLeft: Int
    public var isSubscription: Bool
    public var durationDays: Int?
    
    public init(id: String, name: String, codesLeft: Int, isSubscription: Bool, durationDays: Int?) {
        self.id = id
        self.name = name
        self.codesLeft = codesLeft
        self.isSubscription = isSubscription
        self.durationDays = durationDays
    }
}

public struct ASCPromoCode {
    public var code: String
    public var creationDate: Date?
    public var expirationDate: Date?
    public var requestId: String
    public var platform: String? = nil
    public var version: String? = nil
    public var type: CodeType = .classic
    
    public init(code: String, creationDate: Date?, expirationDate: Date?, requestId: String, platform: String? = nil, version: String? = nil, type: CodeType = .classic) {
        self.code = code
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.requestId = requestId
        self.platform = platform
        self.version = version
        self.type = type
    }
    
    public enum CodeType {
        case classic
        case offer
    }
}

public struct ASCInAppPurchasePromoCode {
    public var code: String
    public var creationDate: Int
    public var expirationDate: Int
    public var requestId: String
    
    public init(code: String, creationDate: Int, expirationDate: Int, requestId: String) {
        self.code = code
        self.creationDate = creationDate
        self.expirationDate = expirationDate
        self.requestId = requestId
    }
}

public struct ASCPriceTiers {
    public static var tiers: [(Int, String)] {
        var tiersDict = [(Int, String)]()
        var i = 1
        for price in prices.components(separatedBy: ",") {
            tiersDict.append((i, price))
            i += 1
        }
        
        return tiersDict
    }
    
    private static var prices = "$0.49,$0.99,$1.49,$1.99,$2.49,$2.99,$3.49,$3.99,$4.49,$4.99,$5.49,$5.99,$6.49,$6.99,$7.49,$7.99,$8.49,$8.99,$9.49,$9.99,$10.49,$10.99,$11.49,$11.99,$12.49,$12.99,$13.49,$13.99,$14.49,$14.99,$15.49,$15.99,$16.49,$16.99,$17.49,$17.99,$18.49,$18.99,$19.49,$19.99,$20.49,$20.99,$21.49,$21.99,$22.49,$22.99,$23.49,$23.99,$24.49,$24.99,$25.49,$25.99,$26.49,$26.99,$27.49,$27.99,$28.49,$28.99,$29.49,$29.99,$30.99,$31.99,$32.99,$33.99,$34.99,$35.99,$36.99,$37.99,$38.99,$39.99,$40.99,$41.99,$42.99,$43.99,$44.99,$45.99,$46.99,$47.99,$48.99,$49.99,$50.99,$51.99,$52.99,$53.99,$54.99,$55.99,$56.99,$57.99,$58.99,$59.99,$60.99,$61.99,$62.99,$63.99,$64.99,$65.99,$66.99,$67.99,$68.99,$69.99,$70.99,$71.99,$72.99,$73.99,$74.99,$75.99,$76.99,$77.99,$78.99,$79.99,$80.99,$81.99,$82.99,$83.99,$84.99,$85.99,$86.99,$87.99,$88.99,$89.99,$90.99,$91.99,$92.99,$93.99,$94.99,$95.99,$96.99,$97.99,$98.99,$99.99,$100.99,$101.99,$102.99,$103.99,$104.99,$105.99,$106.99,$107.99,$108.99,$109.99,$110.99,$111.99,$112.99,$113.99,$114.99,$115.99,$116.99,$117.99,$118.99,$119.99,$120.99,$121.99,$122.99,$123.99,$124.99,$129.99,$134.99,$139.99,$144.99,$149.99,$154.99,$159.99,$164.99,$169.99,$174.99,$179.99,$184.99,$189.99,$194.99,$199.99,$204.99,$209.99,$214.99,$219.99,$224.99,$229.99,$234.99,$239.99,$244.99,$249.99,$254.99,$259.99,$264.99,$269.99,$274.99,$279.99,$284.99,$289.99,$294.99,$299.99,$329.99,$349.99,$399.99,$449.99,$499.99,$599.99,$699.99,$799.99,$899.99,$999.99"
}

public struct ASCOfferCodeAmount {
    public static let amounts = [500, 1000, 1500, 2000, 2500, 5000, 7500, 10000, 15000, 20000, 25000]
}

struct ASCCountry {
    var code: String
    var countryName: String
    var fRetailPrice: String
    var fWholesalePrice: String
    var fWholesalePrice2: String
    var tierStem: String
    
    static var allCountries = "AF,AL,DZ,AO,AI,AG,AR,AM,AU,AT,AZ,BS,BH,BB,BY,BE,BZ,BJ,BM,BT,BO,BA,BW,BR,VG,BN,BG,BF,KH,CM,CA,CV,KY,TD,CL,CN,CO,CD,CG,CR,CI,HR,CY,CZ,DK,DM,DO,EC,EG,SV,EE,SZ,FJ,FI,FR,GA,GM,GE,DE,GH,GR,GD,GT,GW,GY,HN,HK,HU,IS,IN,ID,IQ,IE,IL,IT,JM,JP,JO,KZ,KE,KR,XK,KW,KG,LA,LV,LB,LR,LY,LT,LU,MO,MG,MW,MY,MV,ML,MT,MR,MU,MX,FM,MD,MN,ME,MS,MA,MZ,MM,NA,NR,NP,NL,NZ,NI,NE,NG,MK,NO,OM,PK,PW,PA,PG,PY,PE,PH,PL,PT,QA,RO,RU,RW,ST,SA,SN,RS,SC,SL,SG,SK,SI,SB,ZA,ES,LK,KN,LC,VC,SR,SE,CH,TW,TJ,TZ,TH,TO,TT,TN,TR,TM,TC,UG,UA,AE,GB,US,UY,UZ,VU,VE,VN,YE,ZM,ZW".components(separatedBy: ",")
}

public struct ASCOfferCampaign {
    public var id: String
    public var duration: Duration
    public var newSubscribersEligibility: Bool
    public var existingSubscribersEligibility: Bool
    public var expiredSubscribersEligibility: Bool
    public var typeOfOffer: OfferType
    public var priceTier: Int
    
    public init(id: String, duration: Duration, newSubscribersEligibility: Bool, existingSubscribersEligibility: Bool, expiredSubscribersEligibility: Bool, typeOfOffer: OfferType, priceTier: Int) {
        self.id = id
        self.duration = duration
        self.newSubscribersEligibility = newSubscribersEligibility
        self.existingSubscribersEligibility = existingSubscribersEligibility
        self.expiredSubscribersEligibility = expiredSubscribersEligibility
        self.typeOfOffer = typeOfOffer
        self.priceTier = priceTier
    }
    
    public init(jsonString: String) {
        let json = JSON(parseJSON: jsonString)
        self.id = json["id"].stringValue
        self.duration = Duration(rawValue: json["duration"].stringValue)!
        self.newSubscribersEligibility = json["newSubscribersEligibility"].boolValue
        self.existingSubscribersEligibility = json["existingSubscribersEligibility"].boolValue
        self.expiredSubscribersEligibility = json["expiredSubscribersEligibility"].boolValue
        self.typeOfOffer = OfferType(rawValue: json["typeOfOffer"].stringValue)!
        self.priceTier = json["priceTier"].intValue
    }
    
    public enum Duration: String {
        case threeDays = "3d"
        case week = "1w"
        case twoWeeks = "2w"
        case month = "1m"
        case twoMonths = "2m"
        case threeMonths = "3m"
        case fourMonths = "4m"
        case fiveMonths = "5m"
        case sixMonths = "6m"
        case sevenMonths = "7m"
        case eightMonths = "8m"
        case nineMonths = "9m"
        case tenMonths = "10m"
        case elevenMonths = "11m"
        case twelveMonths = "12m"
        case year = "1y"
        
        public func durationType(subDurationDays days: Int) -> String {
            switch days {
            case 7:
                return "1w"
            case 30:
                return "1m"
            case 90:
                return "3m"
            case 180:
                return "6m"
            case 365:
                return "1y"
            default:
                return "1\(rawValue.last!)"
            }
        }
        
        public func numberOfPeriods(subDurationDays days: Int) -> Int {
            var value = rawValue
            value.removeLast()
            let intValue = Int(value)!
            
            switch days {
            case 7:
                return intValue
            case 30:
                return intValue
            case 90:
                return intValue / 3
            case 180:
                return intValue / 6
            case 365:
                return intValue
            default:
                return 1
            }
        }
        
        public var name: String {
            switch self {
            case .threeDays:
                return "3 Days"
            case .week:
                return "1 Week"
            case .twoWeeks:
                return "2 Weeks"
            case .month:
                return "1 Month"
            case .twoMonths:
                return "2 Months"
            case .threeMonths:
                return "3 Months"
            case .fourMonths:
                return "4 Months"
            case .fiveMonths:
                return "5 Months"
            case .sixMonths:
                return "6 Months"
            case .sevenMonths:
                return "7 Months"
            case .eightMonths:
                return "8 Months"
            case .nineMonths:
                return "9 Months"
            case .tenMonths:
                return "10 Months"
            case .elevenMonths:
                return "11 Months"
            case .twelveMonths:
                return "12 Months"
            case .year:
                return "1 Year"
            }
        }
    }
    
    public enum OfferType: String {
        case payAsYouGo = "PayAsYouGo"
        case payUpFront = "PayUpFront"
        case free = "FreeTrial"
        
        public func getDurations(subDurationDays duration: Int) -> [Duration] {
            switch self {
            case .payAsYouGo:
                switch duration {
                case 7:
                    return [.week, .twoWeeks, .month, .twoMonths, .threeMonths, .fourMonths, .fiveMonths, .sixMonths, .sevenMonths, .eightMonths, .nineMonths, .tenMonths, .elevenMonths, .twelveMonths]
                case 30:
                    return [.month, .twoMonths, .threeMonths, .fourMonths, .fiveMonths, .sixMonths, .sevenMonths, .eightMonths, .nineMonths, .tenMonths, .elevenMonths, .twelveMonths]
                case 90:
                    return [.threeMonths, .sixMonths, .nineMonths, .twelveMonths]
                case 180:
                    return [.sixMonths, .twelveMonths]
                case 365:
                    return [.year]
                default:
                    return [.threeDays, .week, .twoWeeks, .month, .twoMonths, .threeMonths, .fourMonths, .fiveMonths, .sixMonths, .sevenMonths, .eightMonths, .nineMonths, .tenMonths, .elevenMonths, .twelveMonths]
                }
            case .payUpFront:
                switch duration {
                case 7:
                    return [.week, .twoWeeks, .month, .twoMonths, .threeMonths, .sixMonths, .year]
                case 30:
                    return [.month, .twoMonths, .threeMonths, .sixMonths, .year]
                case 90:
                    return [.threeMonths, .sixMonths, .nineMonths, .year]
                case 180:
                    return [.sixMonths, .twelveMonths]
                case 365:
                    return [.year]
                default:
                    return [.threeDays, .week, .twoWeeks, .month, .twoMonths, .threeMonths, .fourMonths, .fiveMonths, .sixMonths, .sevenMonths, .eightMonths, .nineMonths, .tenMonths, .elevenMonths, .twelveMonths]
                }
                
            case .free:
                return [.threeDays, .week, .twoWeeks, .month, .twoMonths, .threeMonths, .sixMonths, .year]
            }
        }
    }
    
    public var jsonString: String {
        let jsonObject: [String: Any] = [
            "id": id,
            "duration": duration.rawValue,
            "newSubscribersEligibility": newSubscribersEligibility,
            "existingSubscribersEligibility": existingSubscribersEligibility,
            "expiredSubscribersEligibility": expiredSubscribersEligibility,
            "typeOfOffer": typeOfOffer.rawValue,
            "priceTier": priceTier
        ]
        return String(data: try! JSONSerialization.data(withJSONObject: jsonObject, options: []), encoding: .utf8)!
    }
}

// 180 days
let kASCOfferCodeDuration: TimeInterval = 60*60*24*180

let GK_ERRORDOMAIN_APPSTORECONNECTAPI_LOGIN = "co.gikken.PromoCodes.AppStoreConnectLogin"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_APPS = "co.gikken.PromoCodes.AppStoreConnectApps"
let GK_ERRORDOMAIN_APPSTORECONNECTAPI_PROMOCODES = "co.gikken.PromoCodes.AppStoreConnectPromoCodes"
