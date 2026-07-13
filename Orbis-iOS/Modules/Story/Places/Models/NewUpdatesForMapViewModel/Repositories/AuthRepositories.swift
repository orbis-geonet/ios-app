//
//  AuthRepositories.swift
//  Orbis-iOS
//
//  Created by Kamran on 02/11/2024.
//


import Foundation
import Combine

class AuthRepositories {
    private let apiInterface = ApiServiceImplementation()
    private let prefManager = PrefManager()


    func login(loginBody: LoginBody) -> AnyPublisher<UserProfile, Error> {
        return apiInterface.login(loginBody: loginBody)
            .eraseToAnyPublisher()
    }

    func signup(signUpBody: SignUpBody) -> AnyPublisher<UserProfile, Error> {
        return apiInterface.signup(signUpBody: signUpBody)
            .eraseToAnyPublisher()
    }

    func updateSocialProfile(token: String, profileUpdateBody: ProfileUpdateBody) -> AnyPublisher<UserProfile, Error> {
        return apiInterface.updateProfile(token: token, profileUpdateBody: profileUpdateBody)
            .eraseToAnyPublisher()
    }

    func refreshToken() -> AnyPublisher<Data, Error> {
        guard let refreshToken = getRefreshToken()?.data(using: .utf8) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return apiInterface.refreshToken(requestBody: refreshToken)
            .eraseToAnyPublisher()
    }

    func saveIdToken(token: String) {
        prefManager.saveIdToken(token)
    }

    func getIdToken() -> String? {
        return prefManager.getIdToken()
    }

    func saveUserKey(key: String) {
        prefManager.saveUserKey(key)
    }

    func getUserKey() -> String? {
        return prefManager.getUserKey()
    }

    func saveRefreshToken(token: String) {
        prefManager.saveRefreshToken(token)
    }

    func saveEmail(email: String) {
        prefManager.saveEmail(email)
    }

    func getRefreshToken() -> String? {
        return prefManager.getRefreshToken()
    }

    func getRefreshEmail() -> String? {
        return prefManager.getRefreshEmail()
    }

    func saveSocialLogin() {
        prefManager.saveSocialLogin()
    }

    func deleteSocialLogin() {
        prefManager.deleteSocialLogin()
    }

    func isSocialLogin() -> Bool {
        return prefManager.isSocialLogin()
    }

    func saveFcmToken(token: String) {
        prefManager.saveFcm(token)
    }

    func getFcmToken() -> String? {
        return prefManager.getFcm()
    }

    func saveUserName(name: String) {
        prefManager.saveUserName(name)
    }

    func getUserName() -> String? {
        return prefManager.getUserName()
    }

    func savePartnerKey(key: String?) {
        prefManager.savePartnerKey(key)
    }
}
