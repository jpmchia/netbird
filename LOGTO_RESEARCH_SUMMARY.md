# LogTo Integration Research Summary

## Executive Summary

This document summarizes research findings for integrating LogTo as an identity provider in NetBird. LogTo follows standard OAuth2/OIDC patterns, making it similar to existing providers like Keycloak. However, specific API endpoint details require verification during implementation.

## Key Findings

### ✅ Confirmed Information

1. **Authentication Protocol**
   - OAuth 2.0 / OpenID Connect (OIDC) compliant
   - Supports Machine-to-Machine (M2M) authentication via Client Credentials grant
   - Token endpoint: `/oidc/token` (standard OIDC pattern)

2. **Architecture**
   - Monolithic Core Service
   - OIDC Provider mounted at `/oidc`
   - Management API available for programmatic control
   - Uses certified OpenID Connect implementation

3. **Management API**
   - Available for user management and configuration
   - Requires M2M application setup
   - Uses Bearer token authentication
   - OpenAPI documentation available at `https://openapi.logto.io/`

4. **SDKs Available**
   - TypeScript/JavaScript SDK
   - Go SDK (check GitHub)
   - Python SDK
   - Other language SDKs available

### ⚠️ Information Requiring Verification

1. **API Endpoints** (CRITICAL)
   - Management API base path (likely `/api`)
   - User endpoints (likely `/api/users`, `/api/users/{id}`)
   - Exact endpoint paths need verification

2. **User Profile Structure** (CRITICAL)
   - Field names (email, name, id, etc.)
   - Response format
   - Custom fields support

3. **Scopes** (IMPORTANT)
   - Required scopes for Management API access
   - Scope format and naming

4. **Features** (IMPORTANT)
   - User creation support
   - User invitation support
   - Custom metadata/app metadata support
   - Pagination implementation

5. **Error Handling** (IMPORTANT)
   - Error response format
   - HTTP status codes
   - Error message structure

## Implementation Strategy

### Phase 1: Verification (Before Implementation)

1. **Access OpenAPI Documentation**
   - Navigate to `https://openapi.logto.io/`
   - Locate Management API section
   - Document exact endpoints:
     - `GET /api/users` - List users
     - `GET /api/users/{id}` - Get user by ID
     - `GET /api/users?email={email}` - Search by email
     - `POST /api/users` - Create user (if supported)
     - `DELETE /api/users/{id}` - Delete user

2. **Verify Authentication**
   - Confirm token endpoint: `/oidc/token`
   - Verify required scopes
   - Test client credentials flow

3. **Verify User Profile**
   - Get sample user object from API
   - Document field names and structure
   - Verify email, name, ID fields

4. **Test Operations** (if test instance available)
   - Test user retrieval
   - Test user search
   - Test user deletion
   - Test user creation (if supported)

### Phase 2: Implementation Approach

Based on research, LogTo integration should follow the **Keycloak pattern**:

1. **Similarities to Keycloak**:
   - Client credentials grant for Management API
   - REST API for user management
   - Requires management endpoint configuration
   - Direct HTTP calls (no SDK needed)

2. **Implementation Pattern**:
   ```
   LogtoManager (similar to KeycloakManager)
   ├── LogtoClientConfig (similar to KeycloakClientConfig)
   ├── LogtoCredentials (similar to KeycloakCredentials)
   └── Methods:
       ├── Authenticate() - Token management
       ├── GetUserByEmail() - Search users
       ├── GetUserDataByID() - Get user by ID
       ├── GetAccount() - Get users for account
       ├── GetAllAccounts() - Get all users
       ├── DeleteUser() - Delete user
       ├── CreateUser() - Create user (if supported)
       └── InviteUserByID() - Resend invite (if supported)
   ```

## Configuration Requirements

### Required Configuration Fields

```go
type LogtoClientConfig struct {
    ClientID           string  // M2M application client ID
    ClientSecret       string  // M2M application client secret
    GrantType          string  // "client_credentials"
    TokenEndpoint      string  // "https://logto.example.com/oidc/token"
    ManagementEndpoint string  // "https://logto.example.com/api"
}
```

### Environment Variables

```bash
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="your-m2m-client-id"
NETBIRD_IDP_MGMT_CLIENT_SECRET="your-m2m-client-secret"
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://logto.example.com/api"
```

## Assumptions (To Verify)

### Safe Assumptions (Standard OAuth2/OIDC)

1. ✅ Token endpoint: `/oidc/token`
2. ✅ Client credentials grant supported
3. ✅ Bearer token authentication
4. ✅ Standard HTTP status codes (200, 201, 400, 401, 404, 500)

### Moderate Assumptions (Common Patterns)

1. ⚠️ Management API base: `/api`
2. ⚠️ User endpoints: `/api/users`, `/api/users/{id}`
3. ⚠️ User profile fields: `id`, `email`, `name`
4. ⚠️ Pagination: Query parameters (`page`, `pageSize`, or `limit`, `offset`)

### Risky Assumptions (Need Verification)

1. ❓ User creation: May not be supported programmatically
2. ❓ User invitations: May require different approach
3. ❓ Custom metadata: May not support app metadata
4. ❓ Exact scope names: Need to verify

## Research Gaps and Next Steps

### Critical Gaps

1. **Exact API Endpoints**
   - Action: Access OpenAPI documentation
   - Verify: Endpoint paths, request/response formats

2. **User Profile Structure**
   - Action: Get sample API response
   - Verify: Field names, data types, structure

3. **Feature Support**
   - Action: Review API documentation
   - Verify: Create, invite, metadata support

### Recommended Actions

1. **Before Implementation**:
   - [ ] Access `https://openapi.logto.io/` and document Management API endpoints
   - [ ] Set up test LogTo instance (if possible)
   - [ ] Create M2M application and test authentication
   - [ ] Test user management endpoints
   - [ ] Document actual API behavior

2. **During Implementation**:
   - Start with authentication (lowest risk)
   - Implement read operations (GetUserByEmail, GetUserDataByID)
   - Implement write operations (DeleteUser, CreateUser if supported)
   - Handle errors appropriately
   - Add comprehensive tests

3. **After Implementation**:
   - Test against real LogTo instance
   - Verify all operations work correctly
   - Document any deviations from assumptions
   - Update research findings

## Risk Assessment

### Low Risk ✅
- Authentication flow (standard OAuth2/OIDC)
- Token management (standard patterns)
- Basic HTTP operations

### Medium Risk ⚠️
- Exact endpoint paths (likely standard REST)
- User profile structure (likely standard OIDC claims)
- Error handling (likely standard OAuth2 errors)

### High Risk ❓
- User creation support (may not be available)
- User invitation support (may require different approach)
- Custom metadata support (may not be available)

## Comparison with Existing Providers

| Aspect | Keycloak | Zitadel | Authentik | LogTo (Research) |
|--------|----------|---------|-----------|------------------|
| **Auth Method** | Client Credentials | Client Credentials / PAT | Password Grant | Client Credentials ✅ |
| **API Access** | Direct HTTP | Direct HTTP | Go SDK | Direct HTTP ✅ |
| **Management Endpoint** | AdminEndpoint | ManagementEndpoint | N/A (SDK) | ManagementEndpoint ⚠️ |
| **User Creation** | ❌ | ✅ | ❌ | ❓ |
| **User Invite** | ❌ | ✅ | ❌ | ❓ |
| **Most Similar** | - | - | - | **Keycloak** |

## Conclusion

LogTo appears to be a good fit for NetBird integration, following standard OAuth2/OIDC patterns similar to Keycloak. The implementation should be straightforward once API endpoint details are verified.

**Recommended Approach**:
1. Verify API endpoints from OpenAPI documentation
2. Follow Keycloak implementation pattern
3. Implement authentication first
4. Implement user operations incrementally
5. Test thoroughly with real LogTo instance

**Estimated Effort**:
- Research/Verification: 2-4 hours
- Implementation: 8-12 hours (after verification)
- Testing: 4-6 hours
- **Total**: 14-22 hours

## Resources

- **Documentation**: https://docs.logto.io/
- **OpenAPI Spec**: https://openapi.logto.io/
- **GitHub**: https://github.com/logto-io/logto
- **Management API**: https://logto.io/products/management-api

---

**Status**: Research Complete - Ready for API Verification and Implementation

**Next Action**: Access OpenAPI documentation to verify exact endpoints before implementation

