//
//  ZLGithubScope.swift
//  ZLGithubOAuth
//
//  Created by zhumeng on 01/02/2022.
//  Copyright (c) 2022 zhumeng. All rights reserved.
//

/// ref : https://docs.github.com/en/developers/apps/building-oauth-apps/scopes-for-oauth-apps#available-scopes
public enum ZLGithubScope: String {
    
    /// repo
    case repo                   = "repo"                        // Full control of private repositories
    case repo_status            = "repo:status"                 // Access commit status
    case repo_deployment        = "repo_deployment"             // Access deployment status
    case public_repo            = "public_repo"                 // Access public repositories
    case repo_invite            = "repo:invite"                 // Access repository invitations
    case security_events        = "security_events"             // Read and write security events
    
    /// repo hook
    case admin_repo_hook        = "admin:repo_hook"             // Full control of repository hooks
    case write_repo_hook        = "write:repo_hook"             // Write repository hooks
    case read_repo_hook         = "read:repo_hook"              // Read repository hooks
    
    ///  org
    case admin_org              = "admin:org"                   // Full control of orgs and teams, read and write org projects
    case write_org              = "write:org"                   // Read and write org and team membership, read and write org projects
    case read_org               = "read:org"                    // Read org and team membership, read org projects
    
    /// public_key
    case admin_public_key       = "admin:public_key"            // Full control of user public keys
    case write_public_key       = "write:public_key"            // Write user public keys
    case read_public_key        = "read:public_key"             // Read user public keys
    
    /// org_hook
    case admin_org_hook         = "admin:org_hook"              // Full control of organization hooks
    
    /// gist
    case gist                   = "gist"                        // Create gists
    
    /// notifications
    case notifications          = "notifications"               // Access notifications
    
    /// user
    case user                   = "user"                        // Update ALL user data
    case read_user              = "read:user"                   // Read ALL user profile data
    case user_email             = "user:email"                  // Access user email addresses (read-only)
    case user_follow            = "user:follow"                 // Follow and unfollow users
    
    /// delete_repo
    case delete_repo            = "delete_repo"                 // Delete repositories
    
    /// discussion
    case write_discussion       = "write:discussion"            // Read and write team discussions
    case read_discussion        = "read:discussion"             // Read team discussions
    
    /// packages
    case write_packages         = "write:packages"              // Upload packages to GitHub Package Registry
    case read_packages          = "read:packages"               // Download packages from GitHub Package Registry
    
    /// delete_packages
    case delete_packages        = "delete:packages"             // Delete packages from GitHub Package Registry
    
    /// gpg_key ( Beta )
    case admin_gpg_key          = "admin:gpg_key"               // Full control of public user GPG keys
    case write_gpg_key          = "write:gpg_key"               // Write public user GPG keys
    case read_gpg_key           = "read:gpg_key"                // Read public user GPG keys
    
    /// enterprise  ?
    case admin_enterprise       = "admin:enterprise"            // Full control of enterprises
    case runners_enterprise     = "manage_runners:enterprise"   // Manage enterprise runners and runner-groups
    case billing_enterprise     = "manage_billing:enterprise"   // Read and write enterprise billing data
    case read_enterprise        = "read:enterprise"             // Read enterprise profile data
}

extension ZLGithubScope {
    
    public static func generateGithubScopeStr(scope: [ZLGithubScope]) -> String {
        return scope.reduce("", { result, element in
            if result.isEmpty {
                return result + element.rawValue
            } else {
                return result + "," + element.rawValue
            }
        })
    }
    
    public static func transformGithubScopeFromStr(str: String) -> [ZLGithubScope] {
        let scopeStrArray = str.split(separator: ",")
        return scopeStrArray.compactMap { subString in
            let str = String(subString)
            return ZLGithubScope(rawValue: str)
        }
    }
}


