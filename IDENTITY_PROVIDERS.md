
## Identity Provider Integration Overview

All three IdPs implement the same `Manager` interface, enabling a unified approach with provider-specific implementations.

### 1. **Common Architecture**

All IdPs follow the same pattern:
- Implement the `Manager` interface (`idp.go`)
- Use OAuth2/OIDC for authentication
- Support token caching and refresh
- Integrate via the `IdpManagerConfig` in the management server configuration

### 2. **Zitadel Integration**

**Location**: `/srv/netbird/management/server/idp/zitadel.go`

**Authentication**:
- Client credentials grant (OAuth2)
- Optional PAT (Personal Access Token) support
- Scope: `"openid urn:zitadel:iam:org:project:id:zitadel:aud"`

**Configuration** (`ZitadelClientConfig`):
```go
- ClientID
- ClientSecret  
- GrantType (typically "client_credentials")
- TokenEndpoint
- ManagementEndpoint (required)
- PAT (optional - Personal Access Token)
```

**API Access**: Direct HTTP calls to Zitadel Management API

**Features**:
- ✅ CreateUser (with automatic invite)
- ✅ GetUserByEmail
- ✅ GetUserDataByID
- ✅ GetAccount/GetAllAccounts
- ✅ InviteUserByID (resend invitations)
- ✅ DeleteUser
- ⚠️ UpdateUserAppMetadata (no-op)

**Special Features**:
- Supports both JWT tokens and PAT
- Automatic user invitation on creation
- Handles human and machine accounts

### 3. **Keycloak Integration**

**Location**: `/srv/netbird/management/server/idp/keycloak.go`

**Authentication**:
- Client credentials grant (OAuth2)
- Uses Keycloak Admin API

**Configuration** (`KeycloakClientConfig`):
```go
- ClientID
- ClientSecret
- GrantType (typically "client_credentials")
- TokenEndpoint
- AdminEndpoint (required - e.g., "https://keycloak.example.com/admin/realms/netbird")
```

**API Access**: Direct HTTP calls to Keycloak Admin REST API

**Features**:
- ❌ CreateUser (not implemented)
- ✅ GetUserByEmail
- ✅ GetUserDataByID
- ✅ GetAccount/GetAllAccounts
- ❌ InviteUserByID (not implemented)
- ✅ DeleteUser
- ⚠️ UpdateUserAppMetadata (no-op)

**Special Features**:
- Pagination support for fetching all users
- Uses user count API for efficient pagination

### 4. **Authentik Integration**

**Location**: `/srv/netbird/management/server/idp/authentik.go`

**Authentication**:
- Password grant (username/password)
- Uses official Authentik Go SDK (`goauthentik.io/api/v3`)
- Scope: `"goauthentik.io/api"`

**Configuration** (`AuthentikClientConfig`):
```go
- Issuer (required)
- ClientID
- Username (required)
- Password (required)
- TokenEndpoint
- GrantType (typically "password" or "authorization_code")
```

**API Access**: Uses Authentik's official Go SDK

**Features**:
- ❌ CreateUser (not implemented)
- ✅ GetUserByEmail
- ✅ GetUserDataByID
- ✅ GetAccount/GetAllAccounts
- ❌ InviteUserByID (not implemented)
- ✅ DeleteUser
- ⚠️ UpdateUserAppMetadata (no-op)

**Special Features**:
- Uses official SDK instead of direct HTTP calls
- Built-in pagination support
- Context-based authentication

### 5. **Configuration Example**

From `management.json.tmpl`:
```json
"IdpManagerConfig": {
    "ManagerType": "$NETBIRD_MGMT_IDP",  // "zitadel", "keycloak", or "authentik"
    "ClientConfig": {
        "Issuer": "$NETBIRD_AUTH_AUTHORITY",
        "TokenEndpoint": "$NETBIRD_AUTH_TOKEN_ENDPOINT",
        "ClientID": "$NETBIRD_IDP_MGMT_CLIENT_ID",
        "ClientSecret": "$NETBIRD_IDP_MGMT_CLIENT_SECRET",
        "GrantType": "client_credentials"
    },
    "ExtraConfig": $NETBIRD_IDP_MGMT_EXTRA_CONFIG  // Provider-specific config
}
```

**Provider-Specific ExtraConfig**:
- **Zitadel**: `{"ManagementEndpoint": "...", "PAT": "..."}`
- **Keycloak**: `{"AdminEndpoint": "https://keycloak.example.com/admin/realms/netbird"}`
- **Authentik**: `{"Username": "...", "Password": "..."}`

### 6. **Key Differences Summary**

| Feature | Zitadel | Keycloak | Authentik |
|---------|---------|----------|-----------|
| **Auth Method** | Client Credentials / PAT | Client Credentials | Password Grant |
| **API Access** | Direct HTTP | Direct HTTP | Go SDK |
| **CreateUser** | ✅ Full support | ❌ Not implemented | ❌ Not implemented |
| **InviteUser** | ✅ Supported | ❌ Not implemented | ❌ Not implemented |
| **User Search** | ✅ Email search | ✅ Email search | ✅ Email search |
| **Delete User** | ✅ Supported | ✅ Supported | ✅ Supported |
| **Pagination** | ✅ Supported | ✅ Supported | ✅ SDK handles |

### 7. **Integration Points**

1. Manager Factory (`idp.go:NewManager`): Creates the appropriate manager based on `ManagerType`
2. Token Management: All use JWT tokens with caching and automatic refresh
3. Error Handling: Provider-specific error parsing
4. Metrics: All integrate with telemetry for monitoring API calls

The design allows switching IdPs by changing the `ManagerType` in the configuration, with each provider implementing the same interface.