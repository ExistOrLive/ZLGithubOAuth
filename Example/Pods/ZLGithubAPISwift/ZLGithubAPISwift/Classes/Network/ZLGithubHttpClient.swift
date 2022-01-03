
import Moya
import Apollo

public class ZLGithubHttpClient : NSObject {
    
    // 网络组件
    public let provider: CommonMoyaProvider = CommonMoyaProvider()
    
    // 信号量 同步锁
    private let sem = DispatchSemaphore(value: 1)
    
    // model
    private var token: String?
    
    public func setToken(token: String) {
        sem.wait()
        self.token = token
        sem.signal()
    }
}

extension ZLGithubHttpClient{
    public static let shared : ZLGithubHttpClient = ZLGithubHttpClient()
    
    func alamofireTokenHeader() -> [String : String] {
        ["Authorization":"token \(token ?? "")"]
    }
    
    func apolloTokenInterceptor() -> Apollo.ApolloInterceptor {
        ZLTokenIntercetor(token: token ?? "")
    }
    
    func apolloInterceptorProvider(store: ApolloStore, client: URLSessionClient) -> Apollo.InterceptorProvider {
        ZLNetworkInterceptorProvider(store: store, client: client)
    }
}


private class ZLTokenIntercetor : Apollo.ApolloInterceptor {
    
    let token: String
    
    init(token: String){
        self.token = token
    }
    
    func interceptAsync<Operation: GraphQLOperation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void){
        request.addHeader(name:"Authorization", value: "token \(token)")
        chain.proceedAsync(request: request, response: response, completion: completion)
    }
}


private struct ZLNetworkInterceptorProvider: InterceptorProvider {
    
    // These properties will remain the same throughout the life of the `InterceptorProvider`, even though they
    // will be handed to different interceptors.
    private let store: ApolloStore
    private let client: URLSessionClient
    
    init(store: ApolloStore,
         client: URLSessionClient) {
        self.store = store
        self.client = client
    }
    
    func interceptors<Operation: GraphQLOperation>(for operation: Operation) -> [ApolloInterceptor] {
        return [
            ZLGithubHttpClient.shared.apolloTokenInterceptor(),
            MaxRetryInterceptor(),
            LegacyCacheReadInterceptor(store: self.store),
            NetworkFetchInterceptor(client: self.client),
            // ZLTokenInvalidDealIntercetor(),
            ResponseCodeInterceptor(),
            LegacyParsingInterceptor(cacheKeyForObject: self.store.cacheKeyForObject),
            AutomaticPersistedQueryInterceptor(),
            LegacyCacheWriteInterceptor(store: self.store)
        ]
    }
}
