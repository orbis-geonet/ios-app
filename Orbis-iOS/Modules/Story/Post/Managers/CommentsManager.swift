//
//  CommentsManager.swift
//  Orbis-iOS
//
//  Created by Nikesh Shakya on 18/04/2021.
//

import Foundation

class CommentsManager {
//    let comments = [
//        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy",
//        "sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna",
//        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut",
//        "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore. :smiley: :smiley:"
//    ]
//    let dates = ["1h", "2h", "4h", "8h"]
//
//    func getRandomComments() -> PostComments {
//        var comments = PostComments()
//        for _ in 3...10 {
//            comments.append(getRandomComment())
//        }
//        return comments
//    }
//
//    func getRandomComment() -> PostComment {
//        let commentId = UUID().uuidString
//        let comment = PostComment(id: commentId, postId: UUID().uuidString, user: FeedManager().getRandomUser(), comment: comments.randomElement()!, datePosted: dates.randomElement()!, likesCount: Int.random(in: 100...300), replies: getRandomCommentReplies(forId: commentId))
//        return comment
//    }
//
//    func getRandomCommentReplies(forId id: String) -> PostCommentReplies?{
//        let hasReplies = [true, false, false, false, true, false, false].randomElement()!
//        if hasReplies {
//            var replies = PostCommentReplies()
//            for _ in 1...3 {
//                replies.append(getRandomCommentReply(forComment: id))
//            }
//            return replies
//        }
//        return nil
//    }
//
//    func getRandomCommentReply(forComment id: String) -> PostCommentReply {
//        let reply = PostCommentReply(id: UUID().uuidString, commentId: id, user: FeedManager().getRandomUser(), comment: comments.randomElement()!, datePosted: dates.randomElement()!, likesCount: Int.random(in: 100...300))
//        return reply
//    }
    
    let orbisPostCommentsManager = NetworkRequestManager(session: NetworkRequestManager.getNewSession())
    
    func fetchPostComments(postKey: String, page: Int, limit: Int, completion: @escaping responseBlock) {
        let url = GetApiAddress.post(.comments, [postKey]).url
        let parameters: [String: Any] = [
            PlaceNetworkParameterKeys.Fetch.page: page,
            PlaceNetworkParameterKeys.Fetch.limit: limit
        ]
        let isAuthenticated = UserSessionManager.shared.currentUser != nil
        let headers = NetworkRequestManager.shared.getHeader(authorized: isAuthenticated, contentType: .json, accept: .none)
        orbisPostCommentsManager.processApiRequest(urlLink: url, parameters: parameters, method: .get, headers: headers, parameterDestination: .queryString, completion: { (data, err) in
            if let error = err {
                completion(nil,error)
                return
            }
            else {
                guard let respData = data as? Data else {
                    completion(nil, nil)
                    return
                }
                let decoder = JSONDecoder()
                do {
                    let comments = try decoder.decode(PostComments.self, from: respData)
                    completion(comments, nil)
                    return
                } catch (let decodeError) {
                    debugPrint("error in decoding comment: \(decodeError.localizedDescription)")
                    completion(nil, decodeError)
                    return
                }
            }
        })
    }
}
