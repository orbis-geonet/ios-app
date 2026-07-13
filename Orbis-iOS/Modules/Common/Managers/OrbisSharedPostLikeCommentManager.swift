//
//  OrbisSharedPostLikeCommentManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 12/08/2021.
//

import Foundation
import FirebaseDynamicLinks

class OrbisSharedPostLikeCommentManager {
    static let shared = OrbisSharedPostLikeCommentManager()
    
    var pendingComments = PostComments()
    let commentPostManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    let likePostManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func postComment(toPost post: OrbisFeedPost, text: String) -> PostComment {
        let comment = PostComment(key: UUID().uuidString, text: text, post: post)
        pendingComments.append(comment)
        let url = GetApiAddress.post(.comments, [post.postKey!]).url
        let param = comment.toCommentRequestObject.toParameter
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        commentPostManager.processApiRequest(urlLink: url, parameters: param, method: .post, headers: header, parameterDestination: .methodDependent, isContentJSON: true) { [weak self] data, err in
            if let error = err {
                self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (error, comment))
            }
            else {
                guard let respData = data as? Data else {
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (CommonError.invalidDataFormat, comment))
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let serverComment = try decoder.decode(PostComment.self, from: respData)
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    let tuple = (serverComment, comment)
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostSuccess), object: tuple)
                    
                    return
                } catch {
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (error, comment))
                    return
                }
                
            }
        }
        return comment
    }
    
    func postCommentReply(toComment commentKey: String, post: OrbisFeedPost, text: String) -> PostComment {
        let comment = PostComment(key: UUID().uuidString, text: text, post: post, commentKey: commentKey)
        pendingComments.append(comment)
        let url = GetApiAddress.post(.comments, [post.postKey!]).url
        let param = comment.toCommentRequestObject.toParameter
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        commentPostManager.processApiRequest(urlLink: url, parameters: param, method: .post, headers: header, parameterDestination: .methodDependent, isContentJSON: true) { [weak self] data, err in
            if let error = err {
                self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (error, comment))
            }
            else {
                guard let respData = data as? Data else {
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (CommonError.invalidDataFormat, comment))
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let serverComment = try decoder.decode(PostComment.self, from: respData)
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    let tuple = (comment, serverComment)
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostSuccess), object: tuple)
                    
                    return
                } catch {
                    self?.pendingComments.removeAll(where: {$0.commentKey == comment.commentKey})
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Comment.pendingCommentPostFailure), object: (error, comment))
                    return
                }
                
            }
        }
        return comment
    }
    
    func deleteComment(fromPost postKey: String, key: String) {
        let url = GetApiAddress.post(.commentDetail, [postKey, key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        commentPostManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { data, err in
            if let error = err {
                debugPrint("Error deleting comment \(error.localizedDescription)")
            }
            else {
                debugPrint("Comment successfully deleted")
            }
        }
    }
    
    // MARK:- Likes
    
    func likePost(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.likePost, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { data, err in
            if let error = err {
                debugPrint("Error liking post \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let post = try decoder.decode(OrbisFeedPost.self, from: respData)
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Post.postUpdated), object: post)
                    completion(post, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func unlikePost(key: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.likePost, [key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { data, err in
            if let error = err {
                debugPrint("Error unliking post \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let post = try decoder.decode(OrbisFeedPost.self, from: respData)
                    NotificationCenter.default.post(name: NSNotification.Name(AppNotificationKeys.Post.postUpdated), object: post)
                    completion(post, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func likeComment(key: String, postKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.likeComment, [postKey, key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: header) { data, err in
            if let error = err {
                debugPrint("Error liking comment \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let comment = try decoder.decode(PostComment.self, from: respData)
                    completion(comment, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    func unlikeComment(key: String, postKey: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.likeComment, [postKey, key]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { data, err in
            if let error = err {
                debugPrint("Error unliking comment \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let comment = try decoder.decode(PostComment.self, from: respData)
                    completion(comment, nil)
                    return
                } catch {
                    completion(nil, error)
                    return
                }
            }
        }
    }
    
    // MARK:- Delete post
    
    func deletePost(post: OrbisFeedPost, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.details, [post.postKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: [:], method: .delete, headers: header) { data, err in
            if let error = err {
                debugPrint("Error deleting post \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(post.postKey!, nil)
            }
        }
    }
    
    func reportPost(post: OrbisFeedPost, text: String, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.report, [post.postKey!]).url
        let header = NetworkRequestManager.shared.getHeader(authorized: true, contentType: .json, accept: .none)
        likePostManager.processApiRequest(urlLink: url, parameters: ["reportText": text], method: .post, headers: header, isContentJSONString: true) { data, err in
            if let error = err {
                debugPrint("Error reporting post \(error.localizedDescription)")
                completion(nil, error)
            }
            else {
                completion(true, nil)
            }
        }
    }
    
    // MARK:- Share post
    
    func getPostShareLink(forPost post: OrbisFeedPost, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.sharePost, [post.postKey!]).url
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        NetworkRequestManager.shared.processApiRequest(urlLink: url, parameters: [:], method: .put, headers: headers, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                guard let string = String(data: respData, encoding: .utf8) else {
                    completion(nil, CommonError.invalidDataFormat)
                    return
                }
                completion(string, nil)
            }
        })
    }
}
