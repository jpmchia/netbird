# LogTo Research Findings

## Research Date
December 26, 2024

## Overview
This document compiles research findings about LogTo's Management API, authentication mechanisms, and integration requirements for NetBird.

## 1. LogTo Architecture

### Core Service
- **Type**: Monolithic service
- **OIDC Provider**: Mounted at `/oidc` endpoint
- **Standards**: OAuth 2.0 and OpenID Connect (OIDC) compliant
- **Implementation**: Uses certified OpenID Connect implementation (`node-oidc-provider`)

### Key Components
- **Core Service**: Handles OIDC Provider and various APIs
- **Management API**: Programmatic control over LogTo functionalities
- **Account API**: For building custom account centers

## 2. Authentication Methods

### 2.1 User Authentication Flow
- **Protocol**: OAuth 2.0 / OIDC
- **Flow Type**: Authorization Code Flow
- **Use Case**: User-facing applications
- **Process**: 
  1. User redirected to LogTo for authentication
  2. User authenticates
  3. Redirect back to application with authorization code
  4. Exchange code for tokens

### 2.2 Machine-to-Machine (M2M) Authentication
- **Protocol**: OAuth 2.0 Client Credentials Flow
- **Use Case**: Service-to-service communication, Management API access
- **Flow**: 
  1. Application authenticates with client credentials
  2. Receives access token
  3. Uses token for API requests
- **No User Interaction**: Required for backend integrations

### 2.3 SAML Authentication
- **Support**: LogTo can act as SAML Identity Provider
- **Flow**: SP-initiated SSO
- **Use Case**: Enterprise SSO scenarios

## 3. Management API

### 3.1 Overview
- **Purpose**: Programmatic control and automation
- **Capabilities**: 
  - User management
  - Application configuration
  - Audit logs access
  - Organization management
- **Authentication**: Uses M2M (Machine-to-Machine) authentication

### 3.2 API Documentation
- **OpenAPI Spec**: Available at `https://openapi.logto.io/`
- **Base URL**: Typically `https://{logto-instance}/api` (VERIFY)
- **Authentication**: Bearer token (from client credentials flow)

### 3.3 Assumed Endpoints (NEEDS VERIFICATION)

Based on standard REST API patterns and similar IdPs:

#### User Management Endpoints:
```
GET    /api/users              - List all users (with pagination)
GET    /api/users/{id}          - Get user by ID
GET    /api/users?email={email} - Search users by email
POST   /api/users               - Create new user (if supported)
DELETE /api/users/{id}          - Delete user
PATCH  /api/users/{id}          - Update user (if needed)
```

#### Authentication Endpoints:
```
POST   /oidc/token              - OAuth2 token endpoint
GET    /oidc/.well-known/openid-configuration - OIDC discovery
```

**⚠️ CRITICAL**: These endpoints need to be verified against actual LogTo documentation or API.

## 4. Authentication Details

### 4.1 Client Credentials Flow (for Management API)

**Token Request**:
```
POST {TokenEndpoint}
Content-Type: application/x-www-form-urlencoded

client_id={ClientID}
&client_secret={ClientSecret}
&grant_type=client_credentials
&scope={scopes}  # Verify required scopes
```

**Token Endpoint**: Typically `https://{logto-instance}/oidc/token`

**Expected Response**:
```json
{
  "access_token": "...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "..."
}
```

### 4.2 Required Scopes (NEEDS VERIFICATION)
- Management API access likely requires specific scopes
- Common patterns: `all`, `read:users`, `write:users`, `delete:users`
- **Action Required**: Verify exact scope requirements

### 4.3 Token Usage
- **Header**: `Authorization: Bearer {access_token}`
- **Expiration**: Typically 3600 seconds (1 hour)
- **Refresh**: Request new token when expired

## 5. User Profile Structure

### 5.1 Assumed User Object (NEEDS VERIFICATION)

Based on OIDC standard and similar IdPs:

```json
{
  "id": "user-id",
  "username": "username",
  "primaryEmail": "user@example.com",
  "name": "Display Name",
  "avatar": "https://...",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

**⚠️ CRITICAL**: Actual structure needs verification from LogTo API documentation.

### 5.2 User Creation (if supported)

**Assumed Request**:
```json
{
  "username": "username",
  "primaryEmail": "user@example.com",
  "name": "Display Name",
  "password": "..." // if password-based
}
```

**⚠️ CRITICAL**: Verify if LogTo supports programmatic user creation.

## 6. Error Handling

### 6.1 Assumed Error Format (NEEDS VERIFICATION)

Standard OAuth2/OIDC error format:
```json
{
  "error": "error_code",
  "error_description": "Human-readable error description"
}
```

HTTP Status Codes:
- `200 OK` - Success
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Invalid or expired token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

**⚠️ CRITICAL**: Verify LogTo's actual error response format.

## 7. SDKs and Libraries

### 7.1 Available SDKs
- **TypeScript/JavaScript**: Available
- **Go**: Available (check GitHub)
- **Python**: Available
- **Other languages**: Check GitHub repository

### 7.2 Management API SDK
- LogTo provides TypeScript SDK for Management API
- **Decision**: Use direct HTTP calls (like Keycloak) or SDK?
- **Recommendation**: Start with direct HTTP calls for consistency with existing providers

## 8. Configuration Requirements

### 8.1 Required Configuration

**Common Fields**:
- `Issuer`: LogTo instance issuer URL (e.g., `https://logto.example.com`)
- `TokenEndpoint`: OAuth2 token endpoint (e.g., `https://logto.example.com/oidc/token`)
- `ClientID`: Management API application client ID
- `ClientSecret`: Management API application client secret
- `GrantType`: `"client_credentials"`

**LogTo-Specific Fields**:
- `ManagementEndpoint`: Management API base URL (e.g., `https://logto.example.com/api`)

### 8.2 Setup Steps (VERIFY)

1. Create Machine-to-Machine application in LogTo Console
2. Configure appropriate scopes/permissions
3. Obtain Client ID and Client Secret
4. Configure Management API endpoint
5. Test authentication flow

## 9. Verification Checklist

### 9.1 API Endpoints (CRITICAL - NEEDS VERIFICATION)
- [ ] Verify Management API base path (likely `/api`)
- [ ] Verify user list endpoint (`GET /api/users`)
- [ ] Verify user by ID endpoint (`GET /api/users/{id}`)
- [ ] Verify user search by email endpoint
- [ ] Verify user creation endpoint (if supported)
- [ ] Verify user deletion endpoint (`DELETE /api/users/{id}`)
- [ ] Verify user update endpoint (if needed)

### 9.2 Authentication (CRITICAL - NEEDS VERIFICATION)
- [ ] Verify token endpoint path (`/oidc/token`)
- [ ] Verify required scopes for Management API
- [ ] Verify token expiration time
- [ ] Verify token refresh mechanism

### 9.3 User Profile (CRITICAL - NEEDS VERIFICATION)
- [ ] Verify user object structure
- [ ] Verify field names (email, name, id, etc.)
- [ ] Verify user creation payload format
- [ ] Verify user update payload format

### 9.4 Error Handling (NEEDS VERIFICATION)
- [ ] Verify error response format
- [ ] Verify HTTP status codes
- [ ] Verify error message structure

### 9.5 Features (NEEDS VERIFICATION)
- [ ] Verify if user creation is supported
- [ ] Verify if user invitations are supported
- [ ] Verify if custom metadata/app metadata is supported
- [ ] Verify pagination support for user listing
- [ ] Verify rate limiting behavior

## 10. Research Gaps

### 10.1 Critical Gaps
1. **Exact API Endpoints**: Need to verify actual endpoint paths
2. **User Profile Structure**: Need actual API response examples
3. **Scopes**: Need to identify required scopes for Management API
4. **User Creation**: Need to verify if programmatic creation is supported
5. **Error Format**: Need actual error response examples

### 10.2 Recommended Next Steps
1. **Access OpenAPI Documentation**: 
   - Navigate to `https://openapi.logto.io/`
   - Find Management API section
   - Document exact endpoints and request/response formats

2. **Test with LogTo Instance**:
   - Set up test LogTo instance (if possible)
   - Create M2M application
   - Test authentication flow
   - Test user management endpoints
   - Document actual API behavior

3. **Review LogTo GitHub Repository**:
   - Check for API examples
   - Review Management API implementation
   - Check for Go SDK or examples

4. **Contact LogTo Support** (if needed):
   - Request Management API documentation
   - Clarify endpoint paths
   - Verify feature support

## 11. Similarities to Existing Providers

### 11.1 Most Similar: Keycloak
- Both use client credentials grant
- Both use REST API for management
- Both require admin/management endpoint configuration
- Both support user CRUD operations

### 11.2 Key Differences (to verify)
- API endpoint structure
- User profile format
- Error response format
- Feature support (create, invite, etc.)

## 12. Implementation Assumptions

Based on research, we can proceed with these assumptions (to be verified):

1. **Authentication**: Client credentials grant with Bearer token
2. **API Base Path**: `/api` (standard REST API pattern)
3. **User Endpoints**: Standard REST patterns (`/api/users`, `/api/users/{id}`)
4. **Token Endpoint**: `/oidc/token` (standard OIDC pattern)
5. **User Profile**: Standard OIDC user claims (email, name, id)

## 13. Risk Assessment

### 13.1 Low Risk (Standard OAuth2/OIDC)
- Authentication flow (client credentials)
- Token management
- Basic HTTP request patterns

### 13.2 Medium Risk (Needs Verification)
- Exact endpoint paths
- User profile structure
- Error handling format

### 13.3 High Risk (Critical to Verify)
- User creation support
- User invitation support
- Custom metadata support
- Pagination implementation

## 14. Recommendations

### 14.1 Before Implementation
1. **Verify API Endpoints**: Access OpenAPI documentation or test instance
2. **Test Authentication**: Verify client credentials flow works
3. **Test User Operations**: Verify user CRUD operations
4. **Document Findings**: Update this document with verified information

### 14.2 Implementation Approach
1. **Start with Authentication**: Implement token management first
2. **Implement Read Operations**: Get user by ID, search by email
3. **Implement Write Operations**: Create, update, delete (if supported)
4. **Handle Edge Cases**: Error handling, pagination, rate limiting

### 14.3 Testing Strategy
1. **Unit Tests**: Mock HTTP responses based on verified API format
2. **Integration Tests**: Test against real LogTo instance (if available)
3. **Error Scenarios**: Test error handling with various error responses

## 15. Resources

### 15.1 Documentation
- LogTo Docs: https://docs.logto.io/
- OpenAPI Spec: https://openapi.logto.io/
- GitHub: https://github.com/logto-io/logto

### 15.2 Key Documentation Pages
- Core Service: https://docs.logto.io/concepts/core-service
- Authentication Flow: https://docs.logto.io/integrate-logto/integrate-logto-into-your-application/understand-authentication-flow
- Management API: https://logto.io/products/management-api
- M2M Authentication: (search in docs)

## 16. Next Actions

### Immediate Actions
1. ✅ Research LogTo architecture and authentication
2. ⏳ Access OpenAPI documentation for exact endpoints
3. ⏳ Verify user profile structure
4. ⏳ Verify Management API endpoints
5. ⏳ Test authentication flow (if test instance available)

### Before Implementation
1. Complete API endpoint verification
2. Document actual user profile structure
3. Verify feature support (create, invite, metadata)
4. Update implementation plan with verified details

---

## Notes

- This research is based on publicly available information and standard OAuth2/OIDC patterns
- Actual API behavior may differ - verification is critical before implementation
- LogTo appears to follow standard OAuth2/OIDC patterns, making integration straightforward
- Management API access requires M2M application setup in LogTo Console

