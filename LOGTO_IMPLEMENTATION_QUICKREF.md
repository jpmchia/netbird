# LogTo Integration - Quick Reference Guide

## File Structure

```
management/server/idp/
├── logto.go          # Main implementation (NEW)
├── logto_test.go     # Unit tests (NEW)
└── idp.go            # Update: Add LogTo case (MODIFY)
```

## Configuration Structure

### LogtoClientConfig
```go
type LogtoClientConfig struct {
    ClientID           string  // Required
    ClientSecret       string  // Required
    GrantType          string  // Required: "client_credentials"
    TokenEndpoint      string  // Required: OAuth2 token endpoint
    ManagementEndpoint string  // Required: LogTo Management API base URL
}
```

### Environment Variables
```bash
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="your-client-id"
NETBIRD_IDP_MGMT_CLIENT_SECRET="your-client-secret"
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://logto.example.com/api"
```

### JSON Configuration
```json
{
  "IdpManagerConfig": {
    "ManagerType": "logto",
    "ClientConfig": {
      "Issuer": "https://logto.example.com",
      "TokenEndpoint": "https://logto.example.com/oidc/token",
      "ClientID": "...",
      "ClientSecret": "...",
      "GrantType": "client_credentials"
    },
    "ExtraConfig": {
      "ManagementEndpoint": "https://logto.example.com/api"
    },
    "LogtoClientCredentials": null
  }
}
```

## Implementation Checklist

### Core Implementation (`logto.go`)
- [ ] Define `LogtoManager` struct
- [ ] Define `LogtoClientConfig` struct
- [ ] Define `LogtoCredentials` struct
- [ ] Define `logtoProfile` struct
- [ ] Implement `NewLogtoManager()`
- [ ] Implement `Authenticate()` method
- [ ] Implement `requestJWTToken()` helper
- [ ] Implement `parseRequestJWTResponse()` helper
- [ ] Implement `jwtStillValid()` helper
- [ ] Implement `GetUserByEmail()`
- [ ] Implement `GetUserDataByID()`
- [ ] Implement `GetAccount()`
- [ ] Implement `GetAllAccounts()`
- [ ] Implement `DeleteUser()`
- [ ] Implement `CreateUser()` (if supported)
- [ ] Implement `InviteUserByID()` (if supported)
- [ ] Implement `UpdateUserAppMetadata()` (may be no-op)
- [ ] Implement `get()` HTTP helper
- [ ] Implement `post()` HTTP helper
- [ ] Implement `delete()` HTTP helper
- [ ] Implement `userData()` conversion helper

### Integration (`idp.go`)
- [ ] Add `LogtoClientCredentials *LogtoClientConfig` to `Config` struct
- [ ] Add `case "logto":` in `NewManager()` switch
- [ ] Handle configuration mapping from `ClientConfig` and `ExtraConfig`

### Configuration Templates
- [ ] Update `management.json.tmpl`: Add `"LogtoClientCredentials": null`
- [ ] Update `setup.env.example`: Add LogTo configuration examples

### Testing (`logto_test.go`)
- [ ] `TestNewLogtoManager()` - Configuration validation
- [ ] `TestLogtoRequestJWTToken()` - Token request
- [ ] `TestLogtoParseRequestJWTResponse()` - Token parsing
- [ ] `TestLogtoJwtStillValid()` - Token expiration
- [ ] `TestLogtoAuthenticate()` - Full auth flow
- [ ] `TestLogtoGetUserByEmail()` - User search
- [ ] `TestLogtoGetUserDataByID()` - User retrieval
- [ ] `TestLogtoDeleteUser()` - User deletion
- [ ] Mock HTTP client setup
- [ ] Error handling tests

## Code Pattern Reference

### Authentication Pattern (from Keycloak)
```go
func (lc *LogtoCredentials) Authenticate(ctx context.Context) (JWTToken, error) {
    lc.mux.Lock()
    defer lc.mux.Unlock()
    
    if lc.appMetrics != nil {
        lc.appMetrics.IDPMetrics().CountAuthenticate()
    }
    
    if lc.jwtStillValid() {
        return lc.jwtToken, nil
    }
    
    resp, err := lc.requestJWTToken(ctx)
    if err != nil {
        return lc.jwtToken, err
    }
    defer resp.Body.Close()
    
    jwtToken, err := lc.parseRequestJWTResponse(resp.Body)
    if err != nil {
        return lc.jwtToken, err
    }
    
    lc.jwtToken = jwtToken
    return lc.jwtToken, nil
}
```

### HTTP Request Pattern
```go
func (lm *LogtoManager) get(ctx context.Context, resource string, q url.Values) ([]byte, error) {
    jwtToken, err := lm.credentials.Authenticate(ctx)
    if err != nil {
        return nil, err
    }
    
    reqURL := fmt.Sprintf("%s/%s?%s", lm.managementEndpoint, resource, q.Encode())
    req, err := http.NewRequest(http.MethodGet, reqURL, nil)
    if err != nil {
        return nil, err
    }
    req.Header.Add("authorization", "Bearer "+jwtToken.AccessToken)
    req.Header.Add("content-type", "application/json")
    
    resp, err := lm.httpClient.Do(req)
    // ... handle response
}
```

## Comparison with Existing Providers

| Aspect | Keycloak | Zitadel | Authentik | LogTo (planned) |
|--------|----------|---------|-----------|-----------------|
| **Auth Method** | Client Credentials | Client Credentials / PAT | Password Grant | Client Credentials |
| **API Access** | Direct HTTP | Direct HTTP | Go SDK | Direct HTTP |
| **Config Field** | AdminEndpoint | ManagementEndpoint | Username/Password | ManagementEndpoint |
| **Token Scope** | (default) | `urn:zitadel:iam:org:project:id:zitadel:aud` | `goauthentik.io/api` | (to verify) |
| **CreateUser** | ❌ | ✅ | ❌ | ⚠️ (verify) |
| **InviteUser** | ❌ | ✅ | ❌ | ⚠️ (verify) |

## API Endpoints (To Verify)

**Assumed LogTo Management API**:
- `GET /api/users` - List users
- `GET /api/users/{id}` - Get user by ID  
- `GET /api/users?email={email}` - Search by email
- `POST /api/users` - Create user
- `DELETE /api/users/{id}` - Delete user

**Note**: Actual endpoints need verification against LogTo documentation.

## Research Tasks

Before starting implementation:

1. **API Documentation**:
   - [ ] Find LogTo Management API documentation
   - [ ] Verify endpoint paths
   - [ ] Understand request/response formats

2. **Authentication**:
   - [ ] Verify client credentials grant support
   - [ ] Identify required scopes
   - [ ] Understand token expiration

3. **User Management**:
   - [ ] Check if user creation is supported
   - [ ] Check if invitations are supported
   - [ ] Understand user profile structure

4. **Error Handling**:
   - [ ] Understand error response format
   - [ ] Identify HTTP status codes
   - [ ] Check rate limiting behavior

## Testing Strategy

### Unit Tests
- Mock HTTP responses
- Test all error scenarios
- Verify token caching
- Test concurrent access

### Integration Tests
- Test against real LogTo instance (if available)
- Verify end-to-end flows
- Test error recovery

## Common Pitfalls to Avoid

1. **Token Management**: Ensure thread-safe token access with mutex
2. **Error Parsing**: Follow LogTo's error response format
3. **Configuration**: Validate all required fields
4. **HTTP Client**: Reuse HTTP client, don't create new ones
5. **Metrics**: Integrate with telemetry system
6. **Context**: Pass context through all operations

## Quick Start

1. Research LogTo API endpoints and authentication
2. Create `logto.go` following Keycloak pattern
3. Implement authentication first
4. Implement user retrieval methods
5. Write tests alongside implementation
6. Integrate into factory pattern
7. Update configuration templates
8. Test end-to-end
9. Document and review

