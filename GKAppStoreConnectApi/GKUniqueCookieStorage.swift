//
//  GKCookieStorage.swift
//  GKAppStoreConnectApi
//
//  Created by Andrew on 08.04.20.
//  Copyright © 2020 Gikken. All rights reserved.
//

import Foundation
import CommonCrypto

class GKUniqueCookieStorage: HTTPCookieStorage {
    
    init(identifier: String) {
        super.init()
        loadStorage(forIdentifier: identifier)
    }
    
    override func setCookie(_ cookie: HTTPCookie) {
        store(cookie: cookie)
    }
    
    override func storeCookies(_ cookies: [HTTPCookie], for task: URLSessionTask) {
        for cookie in cookies {
            store(cookie: cookie)
        }
    }
    
    override func setCookies(_ cookies: [HTTPCookie], for URL: URL?, mainDocumentURL: URL?) {
        for cookie in cookies {
            store(cookie: cookie, forUrl: URL)
        }
    }
    
    override func cookies(for URL: URL) -> [HTTPCookie]? {
        return loadCookies(forUrl: URL)
    }
    
    override var cookies: [HTTPCookie]? {
        return loadCookies()
    }
    
    override func getCookiesFor(_ task: URLSessionTask, completionHandler: @escaping ([HTTPCookie]?) -> Void) {
        completionHandler(loadCookies())
    }
    
    override func sortedCookies(using sortOrder: [NSSortDescriptor]) -> [HTTPCookie] {
        let cookies = loadCookies() as NSArray
        return cookies.sortedArray(using: sortOrder) as! [HTTPCookie]
    }
    
    override func removeCookies(since date: Date) {
        let cookieUrls = loadCookieUrls()
        
        for url in cookieUrls {
            let fileTimestamp = Int(url.lastPathComponent.components(separatedBy: "_")[1])!
            if fileTimestamp > Int(date.timeIntervalSince1970 * 1000) {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let error {
                    NSLog("Failed to remove a cookie at \(url.path). Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    override func deleteCookie(_ cookie: HTTPCookie) {
        let cookieUrl = fileUrlFor(cookie: cookie)
        do {
            try FileManager.default.removeItem(at: cookieUrl)
        } catch let error {
            NSLog("Failed to remove a cookie at \(cookieUrl.path). Error: \(error.localizedDescription)")
        }
    }
    
    private var storageUrl: URL!
    
    private func loadStorage(forIdentifier id: String) {
        let fm = FileManager()
        guard var baseUrl = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Can't create cookie storage")
        }
        
        baseUrl.appendPathComponent("GKUniqueCookieStorage")
        baseUrl.appendPathComponent(hmac(string: id, key: "/B?E(H+MbQeThVmYq3t6w9z$C&F)J@Nc"))
        
        storageUrl = baseUrl
    }
    
    private func loadCookies(forUrl url: URL? = nil) -> [HTTPCookie] {
        let files = loadCookieUrls(forUrl: url)
        return loadCookiesAt(fileUrls: files)
    }
    
    private func loadCookiesAt(fileUrls files: [URL]) -> [HTTPCookie] {
        var cookies = [HTTPCookie]()
        for file in files {
            do {
                let data = try Data(contentsOf: file)
                if let cookieProperties = NSKeyedUnarchiver.unarchiveObject(with: data) as? [HTTPCookiePropertyKey : Any],
                    let cookie = HTTPCookie(properties: cookieProperties) {
                    cookies.append(cookie)
                }
            } catch let error {
                NSLog("Can't read cookie data at \(file.path). Error: \(error.localizedDescription)")
            }
        }
        return cookies
    }
    
    private func loadCookieUrls(forUrl url: URL? = nil) -> [URL] {
        let fm = FileManager()
        let domain = url?.host ?? "default"
        let cookiesDir: URL = url == nil ? storageUrl : storage(forDomain: domain)
        
        var files = [URL]()
        if let enumerator = fm.enumerator(at: cookiesDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! && fileURL.pathExtension == cookieFileExtension {
                        files.append(fileURL)
                    }
                } catch { print(error, fileURL) }
            }
        }
        
        return files
    }
    
    private func storage(forUrl url: URL) -> URL {
        return storage(forDomain: url.host ?? "default")
    }
    
    private func storage(forDomain domain: String) -> URL {
        let urlStorageUrl = storageUrl.appendingPathComponent("storage_\(domain)")
        
        return urlStorageUrl
    }
    
    private func store(cookie: HTTPCookie, forUrl url: URL? = nil) {
        let fm = FileManager()
        
        let cookieUrl = fileUrlFor(cookie: cookie)
        
        do {
            let cookieData = try NSKeyedArchiver.archivedData(withRootObject: cookie.properties ?? [:], requiringSecureCoding: true)
            
            let cookiesDir = cookieUrl.deletingLastPathComponent()
            if !fm.fileExists(atPath: cookiesDir.path) {
                try fm.createDirectory(at: cookiesDir, withIntermediateDirectories: true, attributes: nil)
            }
            
            try cookieData.write(to: cookieUrl, options: .atomic)
        } catch let error {
            NSLog("Failed to store cookies at \(cookieUrl.path). Error: \(error.localizedDescription)")
        }
    }
    
    private func fileUrlFor(cookie: HTTPCookie, forUrl url: URL? = nil) -> URL {
        let domain = url?.host ?? cookie.domain
        let cookiesDir = storage(forDomain: domain)
        let cookieFileName = fileNameFor(cookie: cookie)
        return cookiesDir.appendingPathComponent(cookieFileName)
    }
    
    private func fileNameFor(cookie: HTTPCookie) -> String {
        return "\(cookie.name)_\(Int(Date().timeIntervalSince1970 * 1000))_\(Int.random(in: 1000...9999)).\(cookieFileExtension)"
    }
    
    private func hmac(string: String, key: String) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), key, key.count, string, string.count, &digest)
        let data = Data(digest)
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    private let cookieFileExtension = "cookiedata"
    
}
