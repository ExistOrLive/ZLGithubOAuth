
import Moya
import Apollo

public class ZLGithubUserRequest: ZLGithubBaseApolloRequest<UserInfoQuery>{
    let login: String
    
    public init(login: String){
        self.login = login
        super.init()
    }
        
    public override var graphQLOperation: UserInfoQuery? { UserInfoQuery(login: login) }
    
}
