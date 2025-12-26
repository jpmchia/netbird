# Plan: Adding LogTo Identity Provider Support

## Overview
This document outlines the plan to add LogTo as a supported identity provider in NetBird, following the same architecture pattern as existing providers (Zitadel, Keycloak, Authentik).

## Architecture Analysis

### Current Pattern
All identity providers follow this structure:
1. **Manager Interface**: All implement `idp.Manager` interface
2. **Configuration**: Provider-specific config structs
3. **Authentication**: OAuth2/OIDC token-based authentication
4. **API Access**: Direct HTTP calls or SDK-based
5. **Factory Pattern**: Centralized manager creation in `idp.NewManager()`

### LogTo Characteristics
- **Protocol**: OIDC/OAuth2 compliant
- **Management API**: REST API for user management
- **Authentication**: Client credentials grant for management API
- **API Endpoints**: Standard OIDC endpoints + management API
- **⚠️ CRITICAL**: Uses Basic Authentication in header (not client_id/client_secret in body)
- **⚠️ CRITICAL**: Requires `resource` parameter in token request

## Implementation Plan

### Phase 1: Core Implementation Files

#### 1.1 Create `logto.go`
**Location**: `/srv/netbird/management/server/idp/logto.go`

**Structure** (following Keycloak/Zitadel pattern):
```go
package idp

// LogtoManager logto manager client instance
type LogtoManager struct {
    managementEndpoint string
    httpClient         ManagerHTTPClient
    credentials        ManagerCredentials
    helper             ManagerHelper
    appMetrics         telemetry.AppMetrics
}

// LogtoClientConfig logto manager client configurations
type LogtoClientConfig struct {
    ClientID           string
    ClientSecret       string
    GrantType          string
    TokenEndpoint      string
    ManagementEndpoint string  // e.g., "https://{tenant-id}.logto.app/api"
    Resource           string  // REQUIRED: "https://{tenant-id}.logto.app/api"
    TenantID           string  // Tenant ID (Cloud) or "default" (OSS)
}

// LogtoCredentials logto authentication information
type LogtoCredentials struct {
    clientConfig LogtoClientConfig
    helper       ManagerHelper
    httpClient   ManagerHTTPClient
    jwtToken     JWTToken
    mux          sync.Mutex
    appMetrics   telemetry.AppMetrics
}

// Logto user profile structures
type logtoProfile struct {
    ID        string `json:"id"`
    Username  string `json:"username"`
    PrimaryEmail string `json:"primaryEmail"`
    Name      string `json:"name"`
    // Add other LogTo-specific fields as needed
}
```

**Required Methods** (implementing `Manager` interface):
- `NewLogtoManager()` - Constructor
- `Authenticate()` - Token management
- `GetUserByEmail()` - Search users by email
- `GetUserDataByID()` - Get user by ID
- `GetAccount()` - Get all users for account
- `GetAllAccounts()` - Get all users indexed by account
- `CreateUser()` - Create new user (if LogTo supports it)
- `InviteUserByID()` - Resend invitation (if LogTo supports it)
- `DeleteUser()` - Delete user
- `UpdateUserAppMetadata()` - Update metadata (may be no-op)

**Helper Methods**:
- `requestJWTToken()` - Request access token
- `parseRequestJWTResponse()` - Parse token response
- `jwtStillValid()` - Check token validity
- `get()` - HTTP GET helper
- `post()` - HTTP POST helper
- `delete()` - HTTP DELETE helper
- `userData()` - Convert LogTo profile to UserData

#### 1.2 Create `logto_test.go`
**Location**: `/srv/netbird/management/server/idp/logto_test.go`

**Test Cases** (following existing test patterns):
- `TestNewLogtoManager()` - Configuration validation
- `TestLogtoRequestJWTToken()` - Token request handling
- `TestLogtoParseRequestJWTResponse()` - Token parsing
- `TestLogtoJwtStillValid()` - Token expiration logic
- `TestLogtoAuthenticate()` - Full authentication flow
- `TestLogtoGetUserByEmail()` - User search
- `TestLogtoGetUserDataByID()` - User retrieval
- `TestLogtoDeleteUser()` - User deletion
- Mock HTTP responses for all test cases

### Phase 2: Integration Points

#### 2.1 Update `idp.go`
**File**: `/srv/netbird/management/server/idp/idp.go`

**Changes**:
1. Add `LogtoClientCredentials` field to `Config` struct:
```go
type Config struct {
    // ... existing fields ...
    LogtoClientCredentials *LogtoClientConfig
}
```

2. Add case in `NewManager()` switch statement:
```go
case "logto":
    logtoClientConfig := config.LogtoClientCredentials
    if config.ClientConfig != nil {
        logtoClientConfig = &LogtoClientConfig{
            ClientID:           config.ClientConfig.ClientID,
            ClientSecret:       config.ClientConfig.ClientSecret,
            GrantType:          config.ClientConfig.GrantType,
            TokenEndpoint:      config.ClientConfig.TokenEndpoint,
            ManagementEndpoint: config.ExtraConfig["ManagementEndpoint"],
        }
    }
    
    if logtoClientConfig == nil {
        return nil, fmt.Errorf("logto IdP configuration is missing")
    }
    
    return NewLogtoManager(*logtoClientConfig, appMetrics)
```

#### 2.2 Update Configuration Templates

**File**: `/srv/netbird/infrastructure_files/management.json.tmpl`
- Add `"LogtoClientCredentials": null` to `IdpManagerConfig` section

**File**: `/srv/netbird/infrastructure_files/setup.env.example`
- Add LogTo configuration examples:
```bash
# LogTo Management API endpoint
# NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://logto.example.com/api"
```

### Phase 3: Configuration Details

#### 3.1 Required Configuration Fields

**Common Fields** (from `ClientConfig`):
- `Issuer`: LogTo instance issuer URL
- `TokenEndpoint`: OAuth2 token endpoint (e.g., `https://logto.example.com/oidc/token`)
- `ClientID`: Management API client ID
- `ClientSecret`: Management API client secret
- `GrantType`: `"client_credentials"` (for management API)

**LogTo-Specific Fields** (in `ExtraConfig`):
- `ManagementEndpoint`: LogTo Management API base URL (e.g., `https://logto.example.com/api`)

#### 3.2 Environment Variables

**Standard Variables**:
- `NETBIRD_MGMT_IDP="logto"`
- `NETBIRD_IDP_MGMT_CLIENT_ID`: LogTo management client ID
- `NETBIRD_IDP_MGMT_CLIENT_SECRET`: LogTo management client secret

**Extra Config Variables**:
- `NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT`: Management API endpoint

### Phase 4: API Integration Details

#### 4.1 Authentication Flow

**Token Request** (⚠️ DIFFERENT from Keycloak - uses Basic auth in header):
```
POST {TokenEndpoint}
Authorization: Basic {base64(appId:appSecret)}
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
resource=https://{tenant-id}.logto.app/api  # REQUIRED parameter
scope=all
```

**⚠️ CRITICAL DIFFERENCES**:
- Uses Basic Authentication in header (NOT client_id/client_secret in body)
- Requires `resource` parameter (not optional)
- Resource format: `https://{tenant-id}.logto.app/api` (Cloud) or `https://default.logto.app/api` (OSS)

**Token Response**:
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "..."
}
```

#### 4.2 Management API Endpoints

**Assumed LogTo API Structure** (needs verification):
- `GET /api/users` - List users
- `GET /api/users/{id}` - Get user by ID
- `GET /api/users?email={email}` - Search by email
- `POST /api/users` - Create user (if supported)
- `DELETE /api/users/{id}` - Delete user
- `POST /api/users/{id}/invite` - Resend invitation (if supported)

**Note**: Actual endpoints need to be verified against LogTo documentation.

#### 4.3 Error Handling

**Pattern** (following Zitadel approach):
- Parse error responses from LogTo API
- Return descriptive error messages
- Handle HTTP status codes appropriately
- Log errors with context

### Phase 5: Implementation Details

#### 5.1 Token Management

**Caching Strategy**:
- Cache JWT tokens with expiration tracking
- Check token validity before each request (`jwtStillValid()`)
- Refresh tokens automatically when expired
- Use mutex for thread-safe token access

**Implementation** (similar to KeycloakCredentials):
```go
func (lc *LogtoCredentials) Authenticate(ctx context.Context) (JWTToken, error) {
    lc.mux.Lock()
    defer lc.mux.Unlock()
    
    if lc.jwtStillValid() {
        return lc.jwtToken, nil
    }
    
    resp, err := lc.requestJWTToken(ctx)
    // ... parse and cache token
}
```

#### 5.2 User Data Mapping

**LogTo Profile → UserData**:
```go
func (lp logtoProfile) userData() *UserData {
    return &UserData{
        Email: lp.PrimaryEmail,
        Name:  lp.Name,
        ID:    lp.ID,
    }
}
```

#### 5.3 Feature Implementation Status

**Must Implement**:
- ✅ `GetUserByEmail()` - Required for user lookup
- ✅ `GetUserDataByID()` - Required for user retrieval
- ✅ `GetAccount()` / `GetAllAccounts()` - Required for account management
- ✅ `DeleteUser()` - Required for user deletion

**Optional** (based on LogTo API capabilities):
- ⚠️ `CreateUser()` - If LogTo supports programmatic user creation
- ⚠️ `InviteUserByID()` - If LogTo supports invitation resend
- ⚠️ `UpdateUserAppMetadata()` - May be no-op if LogTo doesn't support custom metadata

### Phase 6: Testing Strategy

#### 6.1 Unit Tests

**Test File**: `logto_test.go`

**Test Coverage**:
1. **Configuration Validation**:
   - Valid configuration
   - Missing ClientID
   - Missing ClientSecret
   - Missing TokenEndpoint
   - Missing ManagementEndpoint
   - Missing GrantType

2. **Authentication**:
   - Successful token request
   - Failed token request (400, 401, 500)
   - Token parsing
   - Token expiration checking
   - Token refresh logic

3. **User Operations**:
   - GetUserByEmail (success, not found, error)
   - GetUserDataByID (success, not found, error)
   - GetAccount (success, empty, error)
   - GetAllAccounts (success, error)
   - DeleteUser (success, not found, error)

4. **Error Handling**:
   - HTTP errors
   - Invalid JSON responses
   - Network errors
   - Timeout handling

#### 6.2 Integration Tests

**Considerations**:
- Test against real LogTo instance (if available)
- Test token refresh scenarios
- Test concurrent requests
- Test error recovery

#### 6.3 Mock Implementation

**Use existing patterns**:
- Mock HTTP client responses
- Use `telemetry.MockAppMetrics`
- Test helper functions for JWT token generation

### Phase 7: Documentation Updates

#### 7.1 Code Documentation

**Add GoDoc comments**:
- Package-level documentation
- Function documentation
- Type documentation
- Example usage

#### 7.2 Configuration Documentation

**Update**:
- `setup.env.example` - Add LogTo configuration examples
- `README.md` - Add LogTo to supported providers list
- Configuration guide - Add LogTo setup instructions

#### 7.3 User Documentation

**Create/Update**:
- LogTo integration guide
- Configuration examples
- Troubleshooting guide
- API endpoint documentation

### Phase 8: Verification Checklist

#### 8.1 Code Quality
- [ ] Follows existing code style
- [ ] Implements all required interface methods
- [ ] Proper error handling
- [ ] Comprehensive test coverage
- [ ] No linter errors

#### 8.2 Integration
- [ ] Manager factory integration
- [ ] Configuration template updates
- [ ] Environment variable support
- [ ] Telemetry/metrics integration

#### 8.3 Functionality
- [ ] Authentication works
- [ ] User search works
- [ ] User retrieval works
- [ ] User deletion works
- [ ] Account management works
- [ ] Error handling works

#### 8.4 Documentation
- [ ] Code comments added
- [ ] Configuration examples provided
- [ ] Integration guide created
- [ ] README updated

## Implementation Order

1. **Research Phase**:
   - Verify LogTo API endpoints
   - Understand LogTo authentication flow
   - Identify required scopes/permissions

2. **Core Implementation**:
   - Create `logto.go` with basic structure
   - Implement authentication
   - Implement user retrieval methods

3. **Testing**:
   - Write unit tests
   - Test against mock responses
   - Verify error handling

4. **Integration**:
   - Update `idp.go` factory
   - Update configuration templates
   - Test end-to-end integration

5. **Documentation**:
   - Add code documentation
   - Update configuration examples
   - Create user guide

6. **Verification**:
   - Run all tests
   - Verify against real LogTo instance (if available)
   - Code review

## Notes and Considerations

### LogTo API Research Status

**Research Completed**: See `LOGTO_RESEARCH_SUMMARY.md` and `LOGTO_RESEARCH_FINDINGS.md` for detailed findings.

**Key Findings**:
- ✅ LogTo uses standard OAuth2/OIDC patterns
- ✅ Supports Machine-to-Machine (M2M) authentication via Client Credentials grant
- ✅ Management API available for programmatic control
- ✅ Token endpoint: `/oidc/token` (standard OIDC pattern)
- ⚠️ Exact API endpoints need verification from OpenAPI documentation
- ⚠️ User profile structure needs verification
- ❓ User creation/invitation support needs verification

**Before Implementation, Verify**:
1. **Management API Endpoints**:
   - Exact endpoint paths (likely `/api/users`, `/api/users/{id}`)
   - Request/response formats
   - Required scopes/permissions

2. **Authentication**:
   - ✅ Client credentials grant supported
   - ⚠️ Required scopes for management API (verify exact names)
   - ✅ Token expiration (typically 3600 seconds)

3. **User Management**:
   - ❓ User creation API (verify if supported)
   - ❓ Invitation API (verify if supported)
   - ❓ Metadata/custom fields support

4. **Error Responses**:
   - ⚠️ Error response format (likely standard OAuth2 format)
   - ✅ HTTP status codes (standard: 200, 201, 400, 401, 404, 500)
   - ❓ Rate limiting behavior

### Similarity to Existing Providers

**Most Similar**: Keycloak
- Both use client credentials grant
- Both use REST API for management
- Both require admin endpoint configuration

**Key Differences** (to verify):
- API endpoint structure
- User profile format
- Error response format
- Supported operations

### Potential Challenges

1. **API Documentation**: May need to reverse-engineer or contact LogTo team
2. **User Creation**: May not be supported programmatically
3. **Invitations**: May require different approach
4. **Metadata**: May not support custom app metadata

## Success Criteria

1. ✅ LogTo can be configured as identity provider
2. ✅ User lookup by email works
3. ✅ User retrieval by ID works
4. ✅ User deletion works
5. ✅ Account management works
6. ✅ All tests pass
7. ✅ Documentation is complete
8. ✅ Code follows existing patterns

## Estimated Effort

- **Research**: 2-4 hours
- **Core Implementation**: 8-12 hours
- **Testing**: 4-6 hours
- **Integration**: 2-3 hours
- **Documentation**: 2-3 hours
- **Total**: 18-28 hours

## Next Steps

1. **Research LogTo API**:
   - Review LogTo documentation
   - Test API endpoints manually
   - Understand authentication flow

2. **Create Implementation Branch**:
   - Create feature branch: `feature/logto-idp-support`
   - Set up development environment

3. **Start Implementation**:
   - Begin with authentication implementation
   - Follow existing patterns closely
   - Write tests alongside implementation

4. **Iterate**:
   - Test frequently
   - Get feedback early
   - Adjust based on findings

