//
//  S3+Put.swift
//  S3
//
//  Created by Ondrej Rafaj on 01/12/2016.
//  Copyright © 2016 manGoweb UK Ltd. All rights reserved.
//

import Foundation
import Vapor


// Helper S3 extension for uploading files by their URL/path
extension S3 {
    
    // MARK: Upload
    
    /// Upload file to S3
    public func put(file: File.Upload, headers strHeaders: [String: String], on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        let headers: HTTPHeaders
        let url: URL

        do {
            url = try makeURLBuilder().url(file: file)

            var awsHeaders: [String: String] = strHeaders
            awsHeaders["content-type"] = file.mime.description
            awsHeaders["x-amz-acl"] = file.access.rawValue
            headers = try signer.headers(for: .PUT, urlString: url.absoluteString, headers: awsHeaders, payload: .bytes(file.data))
        } catch let error {
            return eventLoop.future(error: error)
        }

        var buffer = ByteBufferAllocator().buffer(capacity: file.data.count)
        buffer.writeBytes(file.data)

        var request = ClientRequest()
        request.method = .PUT
        request.headers = headers
        request.body = buffer
        request.url = URI(string: url.description)

        return self.execute(request, on: eventLoop).flatMapThrowing { response in
            try self.check(response)
            let res = File.Response(data: file.data, bucket: file.bucket ?? self.defaultBucket, path: file.path, access: file.access, mime: file.mime)
            return res
        }
    }
    
    /// Upload file to S3
    public func put(file: File.Upload, on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        return put(file: file, headers: [:], on: eventLoop)
    }
    
    /// Upload file by it's URL to S3
    public func put(file url: URL, destination: String, access: AccessControlList = .privateAccess, on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error {
            return eventLoop.future(error: error)
        }

        let file = File.Upload(data: data, bucket: nil, destination: destination, access: access, mime: mimeType(forFileAtUrl: url))
        return put(file: file, on: eventLoop)
    }
    
    /// Upload file by it's path to S3
    public func put(file path: String, destination: String, access: AccessControlList = .privateAccess, on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        let url: URL = URL(fileURLWithPath: path)
        return put(file: url, destination: destination, bucket: nil, access: access, on: eventLoop)
    }
    
    /// Upload file by it's URL to S3, full set
    public func put(file url: URL, destination: String, bucket: String?, access: AccessControlList = .privateAccess, on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error {
            return eventLoop.future(error: error)
        }
        
        let file = File.Upload(data: data, bucket: bucket, destination: destination, access: access, mime: mimeType(forFileAtUrl: url))
        return put(file: file, on: eventLoop)
    }
    
    /// Upload file by it's path to S3, full set
    public func put(file path: String, destination: String, bucket: String?, access: AccessControlList = .privateAccess, on eventLoop: EventLoop) -> EventLoopFuture<File.Response> {
        let url: URL = URL(fileURLWithPath: path)
        return put(file: url, destination: destination, bucket: bucket, access: access, on: eventLoop)
    }
    
}
