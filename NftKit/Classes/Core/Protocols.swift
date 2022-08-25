protocol ITransactionSyncerDelegate: AnyObject {
    func didSync(nfts: [Nft], type: NftType)
}

protocol IBalanceSyncManagerDelegate: AnyObject {
    func didFinishSyncBalances()
}
