// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "guidemeserver",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
            .package(url: "https://github.com/IBM-Swift/Kitura.git", from: "2.5.0"),
            .package(url: "https://github.com/IBM-Swift/Swift-Kuery-ORM.git", from: "0.3.1"),
            .package(url: "https://github.com/IBM-Swift/SwiftKueryMySQL.git", from: "1.2.0"),
            .package(url: "https://github.com/IBM-Swift/Swift-JWT.git", from: "2.0.0"),
            .package(url: "https://github.com/IBM-Swift/Kitura-WebSocket.git", from: "2.1.1"),
            .package(url: "https://github.com/IBM-Swift/Kitura-Session.git", from: "3.2.0"),
            .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsGoogle.git", from: "2.2.0"),
            .package(url: "https://github.com/IBM-Swift/Kitura-CredentialsFacebook.git", from: "2.2.0"),
            .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.12.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "GuideME-Server",
            dependencies: [ .target(name: "Application"), "Kitura"],
            path: "./Sources/GuideMEServer/GuideMEServer"),
        .target(
            name: "Application",
            dependencies: ["Kitura", "SwiftKueryORM", "SwiftKueryMySQL", "SwiftJWT", "CryptoSwift", "Kitura-WebSocket", "KituraSession", "CredentialsGoogle", "CredentialsFacebook"],
            path: "./Sources/GuideMEServer/Application"),
    ]
)
