# LogTo Audience Configuration Guide

## What is NETBIRD_AUTH_AUDIENCE?

The `NETBIRD_AUTH_AUDIENCE` is the **API Resource identifier** in LogTo. It identifies which API Resource the access token is intended for and validates that tokens are issued for the correct resource.

## How to Find/Set the Audience for LogTo

### Option 1: Use LogTo Management API Resource (Recommended)

LogTo provides a built-in **"Logto Management API"** resource:

- **Cloud**: `https://{tenant-id}.logto.app/api`
- **OSS**: `https://default.logto.app/api` (or your custom endpoint)

**Configuration**:
```bash
NETBIRD_AUTH_AUDIENCE="https://{tenant-id}.logto.app/api"
```

**Where to find it**:
1. Log into LogTo Console
2. Go to **API Resources** → **Logto Management API**
3. The identifier is shown at the top (format: `https://{tenant-id}.logto.app/api`)

### Option 2: Create a Custom API Resource

If you want to use a separate API Resource for NetBird:

1. **Create API Resource**:
   - Go to **API Resources** → **Create API Resource**
   - Set **Name**: "NetBird API" (or your preferred name)
   - Set **Identifier**: `https://netbird.{your-domain}/api` (or any unique identifier)
   - Save the resource

2. **Assign to Your User Application**:
   - Go to your user-facing application (used for PKCE/Device flows)
   - Go to **API Resource Roles** tab
   - Assign roles/permissions from your NetBird API Resource

3. **Use the Identifier**:
   ```bash
   NETBIRD_AUTH_AUDIENCE="https://netbird.{your-domain}/api"
   ```

## Complete Configuration Example

### Using Management API Resource (Simplest)

```bash
# LogTo Cloud
NETBIRD_AUTH_AUDIENCE="https://mytenant.logto.app/api"

# LogTo OSS
NETBIRD_AUTH_AUDIENCE="https://default.logto.app/api"
```

### Using Custom API Resource

```bash
NETBIRD_AUDIENCE="https://netbird.example.com/api"
```

## Important Notes

### 1. Different from Management API Configuration

**Management API** (for user management operations):
- Uses M2M application
- Uses `resource` parameter in token request
- Configured via `NETBIRD_IDP_MGMT_EXTRA_RESOURCE`

**OIDC Flows** (for user authentication):
- Uses user-facing application
- Uses `audience` parameter in token request
- Configured via `NETBIRD_AUTH_AUDIENCE`

### 2. Application Must Have Access

Your **user-facing application** (used for PKCE/Device flows) must have:
- Access to the API Resource specified in `NETBIRD_AUTH_AUDIENCE`
- Appropriate roles/permissions assigned

### 3. Verify in LogTo Console

1. Go to your user-facing application
2. Check **API Resource Roles** tab
3. Ensure the API Resource (matching your audience) is listed
4. Ensure appropriate roles are assigned

## Troubleshooting

### Issue: "Invalid audience" error

**Possible Causes**:
- Audience doesn't match any API Resource identifier
- Application doesn't have access to the API Resource
- Wrong tenant ID in the identifier

**Solutions**:
- Verify the API Resource identifier in LogTo Console
- Ensure your user-facing application has access to the API Resource
- Check tenant ID matches your LogTo instance

### Issue: Token validation fails

**Possible Causes**:
- Audience mismatch between token and expected audience
- API Resource not properly configured

**Solutions**:
- Verify `NETBIRD_AUTH_AUDIENCE` matches the API Resource identifier exactly
- Check that the API Resource exists and is accessible

## Quick Reference

| Configuration | Value | Example |
|--------------|-------|---------|
| **LogTo Cloud** | `https://{tenant-id}.logto.app/api` | `https://mytenant.logto.app/api` |
| **LogTo OSS** | `https://default.logto.app/api` | `https://default.logto.app/api` |
| **Custom Resource** | Your API Resource identifier | `https://netbird.example.com/api` |

## Summary

**For LogTo Cloud**:
```bash
NETBIRD_AUTH_AUDIENCE="https://{your-tenant-id}.logto.app/api"
```

**For LogTo OSS**:
```bash
NETBIRD_AUTH_AUDIENCE="https://default.logto.app/api"
```

Replace `{your-tenant-id}` with your actual LogTo tenant ID (found in your LogTo Console URL or settings).

