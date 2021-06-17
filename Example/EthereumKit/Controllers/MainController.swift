import UIKit
import EthereumKit

class MainController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let balanceNavigation = UINavigationController(rootViewController: BalanceController())
        balanceNavigation.tabBarItem.title = "Balance"
        balanceNavigation.tabBarItem.image = UIImage(named: "Balance Tab Bar Icon")

        let transactionsNavigation = UINavigationController(rootViewController: TransactionsController())
        transactionsNavigation.tabBarItem.title = "Transactions"
        transactionsNavigation.tabBarItem.image = UIImage(named: "Transactions Tab Bar Icon")

        let sendNavigation = UINavigationController(rootViewController: SendController())
        sendNavigation.tabBarItem.title = "Send"
        sendNavigation.tabBarItem.image = UIImage(named: "Send Tab Bar Icon")

        let receiveNavigation = UINavigationController(rootViewController: ReceiveController())
        receiveNavigation.tabBarItem.title = "Receive"
        receiveNavigation.tabBarItem.image = UIImage(named: "Receive Tab Bar Icon")

        var controllers = [balanceNavigation, transactionsNavigation, sendNavigation, receiveNavigation]

//        if let _ = Manager.shared.uniswapKit {
//            let swapNavigation = UINavigationController(rootViewController: UniswapController())
//            swapNavigation.tabBarItem.title = "Swap"
//            swapNavigation.tabBarItem.image = UIImage(named: "Transactions Tab Bar Icon")
//            controllers.append(swapNavigation)
//        }
        if let oneInchKit = Manager.shared.oneInchKit {
            let swapTokenFactory = SwapTokenFactory()
            let swapTradeDataFactory = SwapTradeDataFactory(swapTokenFactory: swapTokenFactory)
//            let swapService = UniswapService(uniswapKit: swapKit, swapTokenFactory: swapTokenFactory, swapTradeDataFactory: swapTradeDataFactory)
            let oneInchService = OneInchService(oneInchKit: oneInchKit, swapTokenFactory: swapTokenFactory, swapTradeDataFactory: swapTradeDataFactory)
            let swapController = OneInchController(swapAdapter: oneInchService, inputFieldSwapAdapter: nil)

            let swapNavigation = UINavigationController(rootViewController: swapController)
            swapNavigation.tabBarItem.title = "Swap"
            swapNavigation.tabBarItem.image = UIImage(named: "Transactions Tab Bar Icon")
            controllers.append(swapNavigation)
        }

        viewControllers = controllers
    }

}
