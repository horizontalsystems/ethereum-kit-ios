import Foundation
import GRDB

public class GasPrice: Record, Decodable {
    static let defaultGasPrice = GasPrice(
            lowPriority: 1_000_000_000,
            mediumPriority: 3_000_000_000,
            highPriority: 9_000_000_000,
            date: Date(timeIntervalSince1970: 1543211299660)
    )

    private static let primaryKey = "primaryKey"

    private let primaryKey: String = GasPrice.primaryKey

    let lowPriority: Int
    let mediumPriority: Int
    let highPriority: Int
    let date: Date

    init(lowPriority: Int, mediumPriority: Int, highPriority: Int, date: Date) {
        self.lowPriority = lowPriority
        self.mediumPriority = mediumPriority
        self.highPriority = highPriority
        self.date = date

        super.init()
    }

    override open class var databaseTableName: String {
        return "gasPrices"
    }

    enum Columns: String, ColumnExpression {
        case primaryKey
        case lowPriority
        case mediumPriority
        case highPriority
        case date
    }

    required init(row: Row) {
        lowPriority = row[Columns.lowPriority] ?? 0
        mediumPriority = row[Columns.mediumPriority] ?? 0
        highPriority = row[Columns.highPriority] ?? 0
        date = row[Columns.date]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.primaryKey] = primaryKey
        container[Columns.lowPriority] = lowPriority
        container[Columns.mediumPriority] = mediumPriority
        container[Columns.highPriority] = highPriority
        container[Columns.date] = date
    }

    private enum CodingKeys: String, CodingKey {
        case rates
        case date = "time"
    }

    private enum ContainerCodingKeys: String, CodingKey {
        case eth = "ETH"
    }

    private enum GasPriceCodingKeys: String, CodingKey {
        case lowPriority = "low_priority"
        case mediumPriority = "medium_priority"
        case highPriority = "high_priority"
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ethContainer = try container.nestedContainer(keyedBy: ContainerCodingKeys.self, forKey: .rates)
        let ratesContainer = try ethContainer.nestedContainer(keyedBy: GasPriceCodingKeys.self, forKey: .eth)

        lowPriority = try Converter.toWei(GWei: ratesContainer.decode(Int.self, forKey: .lowPriority))
        mediumPriority = try Converter.toWei(GWei: ratesContainer.decode(Int.self, forKey: .mediumPriority))
        highPriority = try Converter.toWei(GWei: ratesContainer.decode(Int.self, forKey: .highPriority))

        date = try Date(timeIntervalSince1970: container.decode(Double.self, forKey: .date) / 1000)

        super.init()
    }

}