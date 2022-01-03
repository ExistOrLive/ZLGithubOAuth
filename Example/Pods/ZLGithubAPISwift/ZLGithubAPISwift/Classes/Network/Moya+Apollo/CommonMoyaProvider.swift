
import Moya
import Apollo
import Alamofire
import Foundation

public class CommonMoyaProvider {
    
    // 回调queue
    private var defaultCallBackQueue: DispatchQueue = .main
    
    // Alamofire Session
    private var alamofireSession: Alamofire.Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        return Session(configuration: configuration, startRequestsImmediately: false)}()
    
    // Apollo Cache  默认为内存缓存 
    private var apolloStore: Apollo.ApolloStore = Apollo.ApolloStore(cache: InMemoryNormalizedCache())
    
    // Apolloc
    private var apolloSession: Apollo.URLSessionClient = {
        
        let queue = DispatchQueue(label: "org.apollo.session.rootqueue")
        let delegateQueue = OperationQueue()
        delegateQueue.underlyingQueue = queue
        delegateQueue.name = "org.apollo.session.sessionDelegateQueue"
        delegateQueue.maxConcurrentOperationCount = 1
        return Apollo.URLSessionClient(sessionConfiguration: .default, callbackQueue: delegateQueue)
    }()
    
}


extension CommonMoyaProvider  {
    

    // MARK: ApolloMoyaProviderType
    public func request<Target: ApolloMoyaTargetType>(_ target: Target,
                                                      callbackQueue: DispatchQueue?,
                                                      completion: @escaping Completion) -> Moya.Cancellable {
        
        if target.isGraphQLAPI {
            
            let apolloMoyaProvider = ApolloMoyaProvider<Target>(apolloStore: apolloStore,
                                                                apolloURLSessionClient: apolloSession,
                                                                callBackQueue: defaultCallBackQueue)
            
            return apolloMoyaProvider.request(target,
                                              callbackQueue: callbackQueue,
                                              progress: nil,
                                              apolloMoyaCompletion: completion)
        } else {
            
            let alamofireMoyaProvider = MoyaProvider<Target>(endpointClosure: MoyaProvider.defaultEndpointMapping,
                                                             requestClosure: MoyaProvider<Target>.defaultRequestMapping,
                                                             stubClosure: MoyaProvider.neverStub,
                                                             callbackQueue: defaultCallBackQueue,
                                                             session: alamofireSession,
                                                             plugins: [],
                                                             trackInflights: false)
            
            return alamofireMoyaProvider.request(target,
                                                 callbackQueue: callbackQueue,
                                                 progress: nil,
                                                 apolloMoyaCompletion: completion)
        }
    }
}
