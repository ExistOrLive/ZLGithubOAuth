import Moya
import Apollo

// MARK: Moya.Cancellable
class CancellableWrapper: Moya.Cancellable {
    internal var innerCancellable: Moya.Cancellable = SimpleCancellable()

    var isCancelled: Bool { return innerCancellable.isCancelled }

    internal func cancel() {
        innerCancellable.cancel()
    }
}

class SimpleCancellable: Moya.Cancellable {
    var isCancelled = false
    func cancel() {
        isCancelled = true
    }
}

class ApolloCancellableWrapper: Moya.Cancellable {
    
    let apolloCancellable: Apollo.Cancellable
    var isCancelled: Bool = false
    
    init(apolloCancellable: Apollo.Cancellable){
        self.apolloCancellable = apolloCancellable
    }
    
    func cancel(){
        self.isCancelled = true
        self.apolloCancellable.cancel()
    }
}



// 扩展 Moya.TargetType 支持 Apollo
public protocol ApolloMoyaTargetType: Moya.TargetType {
    associatedtype GrapqlOperation: Apollo.GraphQLOperation
    var isGraphQLAPI: Bool { get }
    var graphQLOperation: GrapqlOperation? { get }   // graphQLQuery Apollo.GraphQLOperation
    var interceptorProvider: ((Apollo.ApolloStore,Apollo.URLSessionClient) -> Apollo.InterceptorProvider) { get }
    var graphQLOperationType: Apollo.GraphQLOperationType {get}
}

// 默认ApolloMoyaTargetType 实现
public extension ApolloMoyaTargetType {
    
    var isGraphQLAPI: Bool {
        false
    }
    
    var graphQLOperation: GrapqlOperation? {
        nil
    }
    
    var interceptorProvider: ((Apollo.ApolloStore,Apollo.URLSessionClient) -> Apollo.InterceptorProvider){
        func getLegacyInterceptorProvider(store: Apollo.ApolloStore, client: Apollo.URLSessionClient) -> Apollo.InterceptorProvider{
            return Apollo.LegacyInterceptorProvider(client: client, shouldInvalidateClientOnDeinit: false, store: store)
        }
        return getLegacyInterceptorProvider
    }
    
    var graphQLOperationType: Apollo.GraphQLOperationType {
        graphQLOperation?.operationType ?? .query
    }
}


public typealias Completion = (_ result: Result<Any, ApolloMoyaError>) -> Void

// 扩展 MoyaProviderType 支持 Apollo
public protocol ApolloMoyaProviderType: MoyaProviderType where Target: ApolloMoyaTargetType{
    func request(_ target: Target, callbackQueue: DispatchQueue?, progress: Moya.ProgressBlock?, apolloMoyaCompletion: @escaping Completion) -> Moya.Cancellable
}


//
extension Moya.MoyaProvider: ApolloMoyaProviderType where Target: ApolloMoyaTargetType{
    
    public func request(_ target: Target, callbackQueue: DispatchQueue?, progress: Moya.ProgressBlock?, apolloMoyaCompletion: @escaping Completion) -> Moya.Cancellable{
        return request(target, callbackQueue: callbackQueue, progress: progress, completion: { result in
            switch result{
            case .success(let response):
                apolloMoyaCompletion(Result.success(response))
            case .failure(let error):
                apolloMoyaCompletion(Result.failure(ApolloMoyaError.moyaError(error)))
            }
        })
    }
}


// MARK: ApolloMoyaError
public enum ApolloMoyaError: LocalizedError {
    case moyaError(MoyaError)
    case graphQLError(GraphQLError)
    case otherError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .moyaError(let error):
            return error.errorDescription
        case .graphQLError(let error):
            return error.errorDescription
        case .otherError(let error):
            return error.localizedDescription
        }
    }
    
    
}

