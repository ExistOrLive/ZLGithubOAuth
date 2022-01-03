
import Moya
import Apollo

public class ZLGithubRepoRequest: ZLGithubBaseApolloRequest<RepoInfoQuery>{
    let login: String
    let name: String
    
    public init(login: String, name: String){
        self.login = login
        self.name = name
        super.init()
    }
        
    public override var graphQLOperation: RepoInfoQuery? { RepoInfoQuery(login: login, name: name) }
    
}
