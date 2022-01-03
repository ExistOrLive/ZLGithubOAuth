
import Moya
import Apollo

public class ZLGithubLanguageListRequest: ZLGithubBaseAlamofireRequest{
        
    public override init(){
        super.init()
    }
    
    public override var path: String {
        return "languages"
    }
    
}
