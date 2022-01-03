
import Moya
import Apollo

public class ZLGithubBaseApolloRequest<Operation: Apollo.GraphQLOperation>: ApolloMoyaTargetType{
   
    public var sampleData: Data {
        Data()
    }
    public var task: Task {
        .requestPlain
    }

    public var headers: [String : String]? {
        nil
    }

    public var baseURL: URL {
        URL(string: "https://api.github.com/graphql")!
    }

    public var path: String {
        ""
    }

    public var method: Moya.Method {
        .post
    }

    public var isGraphQLAPI: Bool { true }
    
    public var graphQLOperation: Operation? { nil }
    
    public var interceptorProvider: ((ApolloStore, URLSessionClient) -> InterceptorProvider) {
        return { (store: ApolloStore, client: URLSessionClient) in
            return ZLGithubHttpClient.shared.apolloInterceptorProvider(store:store, client:client)
        }
    }
}



public class ZLGithubBaseAlamofireRequest: ApolloMoyaTargetType{
   
    public typealias GrapqlOperation = ZLBaseGrapQLOperation
    
    public var sampleData: Data {
        Data()
    }
    public var task: Task {
        .requestPlain
    }

    public var headers: [String : String]? {
        ZLGithubHttpClient.shared.alamofireTokenHeader()
    }

    public var baseURL: URL {
        URL(string: "https://api.github.com")!
    }

    public var path: String {
        ""
    }

    public var method: Moya.Method {
        .get
    }
}




public class ZLBaseGrapQLOperation: Apollo.GraphQLOperation {
    
    public typealias Data = ZLBaseGraphQLSelectSet
    
    public var operationType: GraphQLOperationType { .query }

    public var operationDefinition: String { "" }
    public var operationIdentifier: String? { nil }
    public var operationName: String { "ZLBaseGrapQLOperation" }

    public var queryDocument: String { "" }

    public var variables: GraphQLMap? { nil }

    public class ZLBaseGraphQLSelectSet: GraphQLSelectionSet {
        public static var selections: [GraphQLSelection] { [] }

        public var resultMap: ResultMap
        public required init(unsafeResultMap: ResultMap){
            resultMap = unsafeResultMap
        }
    }
}
