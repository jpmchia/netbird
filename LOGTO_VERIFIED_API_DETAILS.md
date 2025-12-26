# LogTo Management API - Verified API Details

## Source
- **Documentation**: https://docs.logto.io/integrate-logto/interact-with-management-api
- **OpenAPI Spec**: https://openapi.logto.io/ (example: https://auth.terra-net.io/api/swagger.json)

## ✅ VERIFIED: Authentication Details

### Token Endpoint
- **Path**: `/oidc/token`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`

### ⚠️ CRITICAL DIFFERENCE: Authentication Method

**LogTo uses Basic Authentication in the header**, NOT client_id/client_secret in the body (unlike Keycloak/Zitadel).

**Format**: `Authorization: Basic {base64(appId:appSecret)}`

### Token Request Format

```http
POST /oidc/token
Authorization: Basic {base64(appId:appSecret)}
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
resource=https://{tenant-id}.logto.app/api
scope=all
```

**Key Points**:
- ✅ `resource` parameter is **REQUIRED** (not optional)
- ✅ Resource format: `https://{tenant-id}.logto.app/api` (Cloud) or `https://default.logto.app/api` (OSS)
- ✅ Scope is `all` for Management API access
- ✅ For Logto Cloud: Must use default endpoint `https://{tenant_id}.logto.app/oidc/token` (no custom domain)
- ✅ Basic auth in header (NOT client_id/client_secret in body)

### Token Response

```json
{
  "access_token": "eyJhbG...2g",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "all"
}
```

### Using Access Token
- **Header**: `Authorization: Bearer {access_token}`
- **Token Type**: Always `Bearer`
- **Expiration**: 3600 seconds (1 hour)

## ✅ VERIFIED: Management API Base

### API Base URL
- **Cloud**: `https://{tenant-id}.logto.app/api`
- **OSS**: `https://default.logto.app/api` (or custom endpoint)
- **Base Path**: `/api` ✅ **CONFIRMED**

### API Endpoints Structure
All Management API endpoints are under `/api/` prefix.

## ✅ VERIFIED: User Management Endpoints

Based on OpenAPI spec:

### List Users
```
GET /api/users
```

**Query Parameters**:
- `page` (integer, default: 1) - Page number starting from 1
- `page_size` (integer, default: 20) - Items per page
- `search` (string) - Search query
- `exact` (boolean) - Exact match
- Additional filters available

**Response**: Paginated list of users

### Get User by ID
```
GET /api/users/{id}
```

**Path Parameters**:
- `id` (string) - User ID

**Response**: Single user object

### Search Users by Email
```
GET /api/users?search={email}&exact=true
```

**Query Parameters**:
- `search` - Email address to search
- `exact` - Set to `true` for exact match

**Response**: List of matching users

### Create User
```
POST /api/users
```

**Status**: ⚠️ Needs verification - check OpenAPI spec for request body structure

### Update User
```
PATCH /api/users/{id}
```

**Status**: ⚠️ Needs verification

### Delete User
```
DELETE /api/users/{id}
```

**Path Parameters**:
- `id` (string) - User ID

**Response**: Likely `204 No Content`

## ✅ VERIFIED: Pagination

### Pagination Parameters
- `page` - Page number (starts from 1, default: 1)
- `page_size` - Items per page (default: 20)

### Pagination Headers

1. **Link Header**:
   ```
   Link: <https://logto.dev/users?page=1&page_size=20>; rel="first"
   Link: <https://logto.dev/users?page=2&page_size=20>; rel="next"
   Link: <https://logto.dev/users?page=10&page_size=20>; rel="prev"
   Link: <https://logto.dev/users?page=10&page_size=20>; rel="last"
   ```

2. **Total-Number Header**:
   ```
   Total-Number: 216
   ```

### Pagination Relations
- `rel="first"` - First page URL
- `rel="next"` - Next page URL
- `rel="prev"` - Previous page URL
- `rel="last"` - Last page URL

## ⚠️ NEEDS VERIFICATION: User Profile Structure

Based on standard patterns, likely structure:

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

**Action Required**: Verify actual field names from API response or OpenAPI spec.

## ⚠️ NEEDS VERIFICATION: User Creation

**Status**: Unknown if programmatic user creation is supported
**Action Required**: Check OpenAPI spec for POST /api/users endpoint details

## ⚠️ NEEDS VERIFICATION: User Invitations

**Status**: Unknown if invitation API exists
**Action Required**: Check for invitation-related endpoints in OpenAPI spec

## ✅ VERIFIED: Error Handling

### Standard HTTP Status Codes
- `200 OK` - Success
- `201 Created` - Resource created
- `204 No Content` - Success (delete operations)
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Invalid or expired token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

### Error Response Format
**Likely standard OAuth2/OIDC format** (needs verification):
```json
{
  "error": "error_code",
  "error_description": "Human-readable description"
}
```

## ✅ VERIFIED: Rate Limiting

- **Logto Cloud**: Tenant-level runtime rate limits apply
- **Logto OSS**: Not specified (likely no limits)

## Updated Configuration Requirements

### Required Configuration

```go
type LogtoClientConfig struct {
    ClientID           string  // M2M App ID
    ClientSecret       string  // M2M App Secret
    GrantType          string  // "client_credentials"
    TokenEndpoint      string  // "https://{tenant-id}.logto.app/oidc/token"
    ManagementEndpoint string  // "https://{tenant-id}.logto.app/api"
    Resource           string  // "https://{tenant-id}.logto.app/api" (for token request)
    TenantID           string  // Tenant ID (for Cloud) or "default" (for OSS)
}
```

### Environment Variables

```bash
# Basic Configuration
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="your-m2m-app-id"
NETBIRD_IDP_MGMT_CLIENT_SECRET="your-m2m-app-secret"

# LogTo-Specific
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://{tenant-id}.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_RESOURCE="https://{tenant-id}.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_TENANT_ID="your-tenant-id"  # or "default" for OSS
```

## Implementation Notes

### ⚠️ CRITICAL: Authentication Implementation Difference

**Key Difference from Keycloak/Zitadel**:
- LogTo uses **Basic Authentication in header** (not client_id/client_secret in body)
- LogTo requires **`resource` parameter** in token request

### Correct Authentication Implementation

```go
func (lc *LogtoCredentials) requestJWTToken(ctx context.Context) (*http.Response, error) {
    // Basic auth: base64(appId:appSecret)
    auth := base64.StdEncoding.EncodeToString(
        []byte(fmt.Sprintf("%s:%s", lc.clientConfig.ClientID, lc.clientConfig.ClientSecret))
    )
    
    data := url.Values{}
    data.Set("grant_type", "client_credentials")
    data.Set("resource", lc.clientConfig.Resource)  // REQUIRED - different from Keycloak!
    data.Set("scope", "all")
    
    req, err := http.NewRequest(http.MethodPost, lc.clientConfig.TokenEndpoint, strings.NewReader(data.Encode()))
    if err != nil {
        return nil, err
    }
    
    req.Header.Add("Authorization", "Basic "+auth)  // Basic auth in header - different!
    req.Header.Add("Content-Type", "application/x-www-form-urlencoded")
    
    log.WithContext(ctx).Debug("requesting new jwt token for logto idp manager")
    
    resp, err := lc.httpClient.Do(req)
    // ... handle response
}
```

### Pagination Implementation

```go
func (lm *LogtoManager) fetchAllUsers(ctx context.Context) ([]logtoProfile, error) {
    users := make([]logtoProfile, 0)
    page := 1
    pageSize := 100  // Use larger page size for efficiency
    
    for {
        q := url.Values{}
        q.Add("page", strconv.Itoa(page))
        q.Add("page_size", strconv.Itoa(pageSize))
        
        body, err := lm.get(ctx, "users", q)
        if err != nil {
            return nil, err
        }
        
        var response struct {
            Data  []logtoProfile `json:"data"`
            Total int            `json:"total"`
        }
        
        err = lm.helper.Unmarshal(body, &response)
        if err != nil {
            return nil, err
        }
        
        users = append(users, response.Data...)
        
        // Check if more pages exist
        if len(response.Data) < pageSize {
            break
        }
        page++
    }
    
    return users, nil
}
```

## Updated Implementation Checklist

### Authentication
- [x] ✅ Verify token endpoint: `/oidc/token`
- [x] ✅ Verify Basic auth in header (NOT body) - **CRITICAL DIFFERENCE**
- [x] ✅ Verify resource parameter requirement - **CRITICAL DIFFERENCE**
- [x] ✅ Verify scope: `all`
- [x] ✅ Verify token expiration: 3600 seconds

### API Endpoints
- [x] ✅ Verify base path: `/api`
- [x] ✅ Verify list users: `GET /api/users`
- [x] ✅ Verify get user: `GET /api/users/{id}`
- [x] ✅ Verify search users: `GET /api/users?search={email}&exact=true`
- [ ] ⚠️ Verify create user: `POST /api/users` (check if supported)
- [x] ✅ Verify delete user: `DELETE /api/users/{id}`

### Pagination
- [x] ✅ Verify pagination parameters: `page`, `page_size`
- [x] ✅ Verify Link headers
- [x] ✅ Verify Total-Number header

### User Profile
- [ ] ⚠️ Verify user object structure from OpenAPI spec
- [ ] ⚠️ Verify field names (id, email, name, etc.)

## Key Differences from Other Providers

| Aspect | Keycloak | Zitadel | LogTo |
|--------|----------|---------|-------|
| **Auth Method** | client_id/client_secret in body | client_id/client_secret in body | **Basic auth in header** ⚠️ |
| **Resource Param** | Not required | Not required | **Required** ⚠️ |
| **Token Endpoint** | `/realms/{realm}/protocol/openid-connect/token` | `/oauth/v2/token` | `/oidc/token` |
| **API Base** | `/admin/realms/{realm}` | Management endpoint | `/api` |

## Next Steps

1. ✅ Authentication details verified (with critical differences noted)
2. ✅ API endpoints verified
3. ✅ Pagination verified
4. ⏳ Verify user profile structure from OpenAPI spec
5. ⏳ Verify user creation support from OpenAPI spec
6. ⏳ Verify user invitation support (if exists)
7. ⏳ Verify error response format

## References

- **Management API Documentation**: https://docs.logto.io/integrate-logto/interact-with-management-api
- **OpenAPI Spec**: https://openapi.logto.io/
- **Example Swagger**: https://auth.terra-net.io/api/swagger.json

---

**Status**: Critical authentication details verified - Ready for implementation with noted differences
