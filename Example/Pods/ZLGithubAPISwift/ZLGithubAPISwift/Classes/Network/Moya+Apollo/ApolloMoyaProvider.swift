
import Moya
import Apollo

public class ApolloMoyaProvider<Target: ApolloMoyaTargetType>: ApolloMoyaProviderType{
        
    // Apollo 缓存
    private var apolloStore: Apollo.ApolloStore
    
    // Apollo 网络核心 封装了 URLSession
    private var apolloURLSessionClient: Apollo.URLSessionClient
    
    // 回调queue
    private var defaultCallBackQueue: DispatchQueue
    
    init(apolloStore: Apollo.ApolloStore = Apollo.ApolloStore(),
         apolloURLSessionClient: Apollo.URLSessionClient = Apollo.URLSessionClient(),
         callBackQueue: DispatchQueue = DispatchQueue.main){
        self.apolloStore = apolloStore
        self.apolloURLSessionClient = apolloURLSessionClient
        self.defaultCallBackQueue = callBackQueue
    }
    
    convenience init(cache: NormalizedCache = InMemoryNormalizedCache(),
                     sessionConfiguration: URLSessionConfiguration = .default,
                     callbackQueue: DispatchQueue = .main){
        let apolloStore = ApolloStore(cache: cache)
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = callbackQueue
        let apolloURLSessionClient = URLSessionClient(sessionConfiguration: sessionConfiguration, callbackQueue: operationQueue)
        
        self.init(apolloStore: apolloStore, apolloURLSessionClient: apolloURLSessionClient, callBackQueue: callbackQueue)
    }
    

    // MARK: ApolloMoyaProviderType
    public func request(_ target: Target,
                        callbackQueue: DispatchQueue?,
                        progress: ProgressBlock?,
                        apolloMoyaCompletion: @escaping Completion) -> Moya.Cancellable {
        
        guard target.isGraphQLAPI == true else {
            
            let result = Result<Any, ApolloMoyaError>.failure(ApolloMoyaError.graphQLError(GraphQLError(["message":"this is not a graphql request"])))
            if let queue = callbackQueue {
                queue.async { apolloMoyaCompletion(result) }
            } else {
                self.defaultCallBackQueue.async { apolloMoyaCompletion(result) }
            }
            return CancellableWrapper()
        }
        
        guard let operation = target.graphQLOperation else {
            
            let result = Result<Any, ApolloMoyaError>.failure(ApolloMoyaError.graphQLError(GraphQLError(["message":"GraphQLOperation is ni"])))
            if let queue = callbackQueue {
                queue.async { apolloMoyaCompletion(result) }
            } else {
                self.defaultCallBackQueue.async { apolloMoyaCompletion(result) }
            }
            return CancellableWrapper()
        }
        
        
        let interceptorProvider = target.interceptorProvider(apolloStore,apolloURLSessionClient)
        let networkTransport = RequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: target.baseURL)
        
        var cachePolicy: Apollo.CachePolicy = .default
        if target.graphQLOperationType == .query {
            cachePolicy = .returnCacheDataAndFetch
        }
        
        
        let apolloCancellable: Apollo.Cancellable =  networkTransport.send(operation: operation,
                                                                           cachePolicy: cachePolicy,
                                                                           contextIdentifier: nil,
                                                                           callbackQueue: callbackQueue ?? self.defaultCallBackQueue) {  result in
            
            switch result{
            case .success(let graphQLData):
                apolloMoyaCompletion(Result.success(graphQLData))
            case .failure(let error):
                if let graphError = error as? GraphQLError {
                    apolloMoyaCompletion(Result.failure(ApolloMoyaError.graphQLError(graphError)))
                } else {
                    apolloMoyaCompletion(Result.failure(ApolloMoyaError.otherError(error)))
                }
            }
        }
        return ApolloCancellableWrapper(apolloCancellable: apolloCancellable)
        
    }
    
    
    // MARK: MoyaProviderType
    public func request(_ target: Target,
                        callbackQueue: DispatchQueue?,
                        progress: ProgressBlock?,
                        completion: @escaping Moya.Completion) -> Moya.Cancellable {
        
        let result = Result<Moya.Response, MoyaError>.failure(MoyaError.requestMapping("GraphQL APIs do not support MoyaProviderType Request Method"))
        if let queue = callbackQueue {
            queue.async { completion(result) }
        } else {
            self.defaultCallBackQueue.async { completion(result) }
        }
        return CancellableWrapper()
        
    }
    
}
