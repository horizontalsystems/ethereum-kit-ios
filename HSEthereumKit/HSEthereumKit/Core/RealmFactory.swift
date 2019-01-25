import RealmSwift

class RealmFactory {
    private let configuration: Realm.Configuration

    init(realmFileName: String) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        configuration = Realm.Configuration(
                fileURL: documentsUrl?.appendingPathComponent(realmFileName),
                deleteRealmIfMigrationNeeded: true,
                objectTypes: [
                    EthereumTransaction.self,
                    EthereumBalance.self,
                    EthereumGasPrice.self,
                    EthereumBlockHeight.self
                ]
        )
    }

    var realm: Realm {
        return try! Realm(configuration: configuration)
    }

}
