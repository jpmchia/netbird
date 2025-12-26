# LogTo OIDC Flows Configuration Guide

## Overview

The **OIDC Device Authorization Flow** and **PKCE Authorization Flow** are **generic OAuth2/OIDC flows** that work with any OIDC-compliant provider, including LogTo. These flows do NOT require provider-specific implementation - they use standard OIDC endpoints.

NetBird automatically discovers OIDC endpoints from the `.well-known/openid-configuration` endpoint, so configuration is straightforward.

## LogTo OIDC Configuration Endpoint

LogTo provides a standard OIDC configuration endpoint:

- **Cloud**: `https://{tenant-id}.logto.app/.well-known/openid-configuration`
- **OSS**: `https://{your-logto-instance}/.well-known/openid-configuration`

### What NetBird Auto-Discovers

When you configure `NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT`, NetBird automatically fetches and configures:

- ✅ `issuer` → `AuthIssuer`
- ✅ `token_endpoint` → `TokenEndpoint` (for both Device and PKCE flows)
- ✅ `authorization_endpoint` → `AuthorizationEndpoint` (for PKCE flow)
- ✅ `device_authorization_endpoint` → `DeviceAuthEndpoint` (for Device flow, if supported)
- ✅ `jwks_uri` → `AuthKeysLocation` (JWT certificate location)

## Configuration

### Required Configuration

#### 1. OIDC Configuration Endpoint

```bash
# LogTo Cloud
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT="https://{tenant-id}.logto.app/.well-known/openid-configuration"

# LogTo OSS
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT="https://{your-logto-instance}/.well-known/openid-configuration"
```

#### 2. Create User-Facing Application in LogTo

**Important**: The OIDC flows use a **different application** than the Management API M2M app:

1. Go to **Applications** → **Create Application**
2. Select **Traditional Web Application** (for PKCE) or **Native Application** (for Device Flow)
3. Configure:
   - **Redirect URIs**: `http://localhost:53000` (or your configured PKCE ports)
   - **Post Sign-out Redirect URIs**: (optional)
   - **CORS Allowed Origins**: (if needed)
4. Get **App ID** and **App Secret**

#### 3. Configure OIDC Flows

```bash
# OIDC Basic Configuration
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT="https://{tenant-id}.logto.app/.well-known/openid-configuration"
NETBIRD_AUTH_AUDIENCE="your-audience"  # API Resource identifier
NETBIRD_AUTH_CLIENT_ID="your-user-app-client-id"  # User-facing app, NOT M2M app
NETBIRD_AUTH_CLIENT_SECRET="your-user-app-client-secret"
NETBIRD_AUTH_SUPPORTED_SCOPES="openid profile email"

# Device Authorization Flow (Optional)
NETBIRD_AUTH_DEVICE_AUTH_PROVIDER="hosted"  # Use "hosted" for LogTo
NETBIRD_AUTH_DEVICE_AUTH_CLIENT_ID=$NETBIRD_AUTH_CLIENT_ID
NETBIRD_AUTH_DEVICE_AUTH_AUDIENCE=$NETBIRD_AUTH_AUDIENCE
NETBIRD_AUTH_DEVICE_AUTH_SCOPE="openid"
NETBIRD_AUTH_DEVICE_AUTH_USE_ID_TOKEN=false

# PKCE Authorization Flow (Optional)
NETBIRD_AUTH_PKCE_REDIRECT_URL_PORTS="53000"
NETBIRD_AUTH_PKCE_AUDIENCE=$NETBIRD_AUTH_AUDIENCE
NETBIRD_AUTH_PKCE_USE_ID_TOKEN=false
NETBIRD_AUTH_PKCE_DISABLE_PROMPT_LOGIN=false
```

### Complete Example Configuration

```bash
# ============================================
# LogTo OIDC Configuration
# ============================================
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT="https://mytenant.logto.app/.well-known/openid-configuration"
NETBIRD_AUTH_AUDIENCE="https://mytenant.logto.app/api"  # Your API Resource identifier
NETBIRD_AUTH_CLIENT_ID="user-app-client-id"  # User-facing application
NETBIRD_AUTH_CLIENT_SECRET="user-app-secret"
NETBIRD_AUTH_SUPPORTED_SCOPES="openid profile email"

# Device Authorization Flow
NETBIRD_AUTH_DEVICE_AUTH_PROVIDER="hosted"
NETBIRD_AUTH_DEVICE_AUTH_CLIENT_ID=$NETBIRD_AUTH_CLIENT_ID
NETBIRD_AUTH_DEVICE_AUTH_AUDIENCE=$NETBIRD_AUTH_AUDIENCE
NETBIRD_AUTH_DEVICE_AUTH_SCOPE="openid"
NETBIRD_AUTH_DEVICE_AUTH_USE_ID_TOKEN=false

# PKCE Authorization Flow
NETBIRD_AUTH_PKCE_REDIRECT_URL_PORTS="53000"
NETBIRD_AUTH_PKCE_AUDIENCE=$NETBIRD_AUTH_AUDIENCE
NETBIRD_AUTH_PKCE_USE_ID_TOKEN=false

# ============================================
# LogTo Management API (Separate Configuration)
# ============================================
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="m2m-app-client-id"  # M2M application
NETBIRD_IDP_MGMT_CLIENT_SECRET="m2m-app-secret"
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://mytenant.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_RESOURCE="https://mytenant.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_TENANT_ID="mytenant"
```

## Important Notes

### Two Different Applications

1. **User-Facing Application** (for OIDC flows):
   - Used by Device Authorization Flow and PKCE Flow
   - Type: Traditional Web Application or Native Application
   - Used for end-user authentication

2. **M2M Application** (for Management API):
   - Used by Management API integration
   - Type: Machine-to-Machine
   - Used for backend user management operations

### Device Authorization Flow Support

⚠️ **Status**: LogTo's support for Device Authorization Flow needs verification:
- Some sources indicate LogTo may not support Device Authorization Flow
- If not supported, only PKCE Flow will work
- Check LogTo's OIDC configuration endpoint response for `device_authorization_endpoint`

### Verifying OIDC Configuration

You can verify LogTo's OIDC configuration:

```bash
curl https://{tenant-id}.logto.app/.well-known/openid-configuration
```

**Expected Response**:
```json
{
  "issuer": "https://{tenant-id}.logto.app",
  "authorization_endpoint": "https://{tenant-id}.logto.app/oidc/auth",
  "token_endpoint": "https://{tenant-id}.logto.app/oidc/token",
  "userinfo_endpoint": "https://{tenant-id}.logto.app/oidc/me",
  "jwks_uri": "https://{tenant-id}.logto.app/oidc/jwks",
  "device_authorization_endpoint": "https://{tenant-id}.logto.app/oidc/device",  // May not exist
  ...
}
```

## Implementation Status

### ✅ Already Implemented (Generic OIDC)

- **PKCE Authorization Flow**: ✅ Works automatically with LogTo
- **Device Authorization Flow**: ✅ Works automatically if LogTo supports it
- **OIDC Endpoint Discovery**: ✅ Auto-configured from `.well-known/openid-configuration`

### ✅ Management API (Provider-Specific)

- **User Management**: ✅ Implemented (CreateUser, GetUserByEmail, DeleteUser, etc.)
- **Authentication**: ✅ Implemented (Basic auth + resource parameter)

## Testing OIDC Flows

### 1. Verify OIDC Configuration Discovery

Check management server logs for:
```
loading OIDC configuration from the provided IDP configuration endpoint
loaded OIDC configuration from the provided IDP configuration endpoint
overriding DeviceAuthorizationFlow.TokenEndpoint with a new value
overriding PKCEAuthorizationFlow.AuthorizationEndpoint with a new value
```

### 2. Test PKCE Flow

1. Start NetBird client
2. Attempt to login
3. Should redirect to LogTo login page
4. After authentication, should redirect back to NetBird

### 3. Test Device Flow

1. Start NetBird client on device without browser
2. Should display device code and URL
3. Visit URL on another device
4. Enter device code
5. Complete authentication

## Troubleshooting

### Issue: OIDC endpoints not auto-discovered

**Solution**: Verify `NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT` is correctly set and accessible

### Issue: Device Authorization Flow not working

**Possible Causes**:
- LogTo may not support Device Authorization Flow
- Check OIDC config for `device_authorization_endpoint` field

**Solution**: Use PKCE Flow instead (works on all platforms with browser)

### Issue: PKCE Flow redirect fails

**Possible Causes**:
- Redirect URI not configured in LogTo application
- Port already in use

**Solution**: 
- Add `http://localhost:53000` to LogTo app redirect URIs
- Check port availability

## Summary

**What I've Implemented**:
- ✅ Management API integration (provider-specific)
- ✅ User management operations

**What Works Automatically** (No Implementation Needed):
- ✅ PKCE Authorization Flow (generic OIDC)
- ✅ Device Authorization Flow (generic OIDC, if LogTo supports it)
- ✅ OIDC endpoint discovery

**What You Need to Configure**:
1. Set `NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT` to LogTo's OIDC config endpoint
2. Create user-facing application in LogTo
3. Configure redirect URIs
4. Set client ID and secret for user authentication

The OIDC flows are **already functional** - they just need proper configuration!

