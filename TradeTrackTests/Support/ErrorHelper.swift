@testable import TradeTrack

extension Error {
    var appErrorCode: AppErrorCode? { (self as? AppError)?.code }
}
