//#import "In3Private.h"
//#import <incubed/eth_api.h> // functions for direct api-access
//#import <incubed/in3_init.h> // if included the verifier will automaticly be initialized.
//
//@implementation In3Private
//in3_t *client;
//
//NSString *const GET_BLOCK_BY_NUMBER                         = @"eth_getBlockByNumber";
//NSString *const BLOCK_BY_HASH                               = @"eth_getBlockByHash";
//NSString *const BLOCK_NUMBER                                = @"eth_blockNumber";
//NSString *const GAS_PRICE                                   = @"eth_gasPrice";
//NSString *const CHAIN_ID                                    = @"eth_chainId";
//NSString *const CALL                                        = @"eth_call";
//NSString *const ESTIMATE_GAS                                = @"eth_estimateGas";
//NSString *const GET_BALANCE                                 = @"eth_getBalance";
//NSString *const GET_CODE                                    = @"eth_getCode";
//NSString *const GET_STORAGE_AT                              = @"eth_getStorageAt";
//NSString *const GET_BLOCK_TRANSACTION_COUNT_BY_HASH         = @"eth_getBlockTransactionCountByHash";
//NSString *const GET_BLOCK_TRANSACTION_COUNT_BY_NUMBER       = @"eth_getBlockTransactionCountByNumber";
//NSString *const GET_FILTER_CHANGES                          = @"eth_getFilterChanges";
//NSString *const GET_FILTER_LOGS                             = @"eth_getFilterLogs";
//NSString *const GET_LOGS                                    = @"eth_getLogs";
//NSString *const GET_TRANSACTION_BY_BLOCK_HASH_AND_INDEX     = @"eth_getTransactionByBlockHashAndIndex";
//NSString *const GET_TRANSACTION_BY_BLOCK_NUMBER_AND_INDEX   = @"eth_getTransactionByBlockNumberAndIndex";
//NSString *const GET_TRANSACTION_BY_HASH                     = @"eth_getTransactionByHash";
//NSString *const GET_TRANSACTION_COUNT                       = @"eth_getTransactionCount";
//NSString *const GET_TRANSACTION_RECEIPT                     = @"eth_getTransactionReceipt";
//NSString *const GET_UNCLE_BY_BLOCK_NUMBER_AND_INDEX         = @"eth_getUncleByBlockNumberAndIndex";
//NSString *const GET_UNCLE_COUNT_BY_BLOCK_HASH               = @"eth_getUncleCountByBlockHash";
//NSString *const GET_UNCLE_COUNT_BY_BLOCK_NUMBER             = @"eth_getUncleCountByBlockNumber";
//NSString *const NEW_BLOCK_FILTER                            = @"eth_newBlockFilter";
//NSString *const NEW_FILTER                                  = @"eth_newFilter";
//NSString *const UNINSTALL_FILTER                            = @"eth_uninstallFilter";
//NSString *const SEND_RAW_TRANSACTION                        = @"eth_sendRawTransaction";
//NSString *const SEND_TRANSACTION                            = @"eth_sendTransaction";
//NSString *const ABI_ENCODE                                  = @"in3_abiEncode";
//NSString *const ABI_DECODE                                  = @"in3_abiDecode";
//NSString *const CHECKSUM_ADDRESS                            = @"in3_checksumAddress";
//NSString *const ENS                                         = @"in3_ens";
//
//- (instancetype)initWithChainId:(UInt32)chainId {
//    client = in3_for_chain(chainId);
//    client->proof = PROOF_NONE;
//
//    return self;
//}
//
//- (UInt64)blockNumber {
//    return eth_blockNumber(client);
//}
//
//- (UInt64)transactionCount:(NSData *)address {
//    return eth_getTransactionCount(client, (uint8_t *)address.bytes, BLKNUM_LATEST());
//}
//
//- (NSNumber *)transactionReceipt:(NSData *)transactionHash {
//    eth_tx_receipt_t *receipt = eth_getTransactionReceipt(client, (uint8_t *)transactionHash.bytes);
//    if (receipt != nil) {
//        return receipt->status ? @1 : @0;
//    }
//    return @-1;
//}
//
//- (bool)transactionExist:(NSData *)transactionHash {
//    eth_tx_receipt_t *receipt = eth_getTransactionReceipt(client, (uint8_t *)transactionHash.bytes);
//    return receipt != nil;
//}
//
//- (NSString *)rpcCall:(NSString *)method params:(NSString *)parameters didFailWithError:(NSError **)error {
//    char *call_method = (char *) [method UTF8String];
//    char *call_params = (char *) [parameters UTF8String];
//
//    // prepare 2 pointers for the result.
//    char *cResult, *cError;
//    in3_ret_t res = in3_client_rpc(
//            client,                                                         //  the configured client
//            call_method,                                                    // the rpc-method you want to call.
//            call_params,                                                    // the arguments as json-string
//            &cResult,                                                       // the reference to a pointer will hold the result
//            &cError);                                                       // the pointer which may hold a error message
//
//    if (res == IN3_OK) {
//        NSString *result = [NSString stringWithUTF8String: cResult];
//
//        free(cResult);
//        return result;
//    } else {
//        *error = [self error: [NSString stringWithUTF8String: cError]];
//        free(cError);
//        return NULL;
//    }
//
//}
//
//// ###################
//
//- (NSError *)error:(NSString *)text {
//    return [[NSError alloc] initWithDomain: @"incubed.wrapper" code: 101 userInfo: @{NSLocalizedDescriptionKey: text}];
//}
//
//@end
