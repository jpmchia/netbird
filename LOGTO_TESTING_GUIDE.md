# LogTo Integration Testing Guide

## Prerequisites

### 1. LogTo Instance Setup

You need either:
- **LogTo Cloud**: Sign up at https://cloud.logto.io/
- **LogTo OSS**: Self-hosted instance (see https://docs.logto.io/self-hosted/get-started)

### 2. Required Information

From your LogTo instance, you'll need:
- **Tenant ID** (for Cloud) or use `"default"` (for OSS)
- **LogTo Endpoint URL**: 
  - Cloud: `https://{tenant-id}.logto.app`
  - OSS: Your self-hosted URL (e.g., `https://logto.example.com`)

### 3. Create Machine-to-Machine (M2M) Application

1. Log into LogTo Console
2. Navigate to **Applications** → **Create Application**
3. Select **Machine-to-Machine** application type
4. Complete the creation process
5. **Assign M2M Roles**:
   - Go to the M2M app details page
   - Assign roles that include LogTo Management API permissions
   - Look for roles with the LogTo icon (these include Management API permissions)
   - Or use the pre-configured "Logto Management API access" role

6. **Get Credentials**:
   - **App ID** (Client ID)
   - **App Secret** (Client Secret)
   - Save these securely

### 4. Verify Management API Resource

1. Navigate to **API Resources** → **Logto Management API**
2. Verify the resource identifier:
   - Cloud: `https://{tenant-id}.logto.app/api`
   - OSS: `https://default.logto.app/api` (or your custom endpoint)

## NetBird Configuration

### Environment Variables

Create or update your `setup.env` file:

```bash
# Identity Provider Type
NETBIRD_MGMT_IDP="logto"

# LogTo Management API Credentials
NETBIRD_IDP_MGMT_CLIENT_ID="your-m2m-app-id"
NETBIRD_IDP_MGMT_CLIENT_SECRET="your-m2m-app-secret"

# LogTo-Specific Configuration
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://{tenant-id}.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_RESOURCE="https://{tenant-id}.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_TENANT_ID="your-tenant-id"  # or "default" for OSS

# OIDC Configuration (for user authentication)
NETBIRD_AUTH_AUTHORITY="https://{tenant-id}.logto.app"
NETBIRD_AUTH_TOKEN_ENDPOINT="https://{tenant-id}.logto.app/oidc/token"
NETBIRD_AUTH_AUDIENCE="your-audience"
NETBIRD_AUTH_CLIENT_ID="your-user-app-client-id"
NETBIRD_AUTH_CLIENT_SECRET="your-user-app-client-secret"
```

### Example Configuration (Cloud)

```bash
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="abc123xyz"
NETBIRD_IDP_MGMT_CLIENT_SECRET="secret-key-here"
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://mytenant.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_RESOURCE="https://mytenant.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_TENANT_ID="mytenant"
```

### Example Configuration (OSS)

```bash
NETBIRD_MGMT_IDP="logto"
NETBIRD_IDP_MGMT_CLIENT_ID="abc123xyz"
NETBIRD_IDP_MGMT_CLIENT_SECRET="secret-key-here"
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT="https://logto.example.com/api"
NETBIRD_IDP_MGMT_EXTRA_RESOURCE="https://default.logto.app/api"
NETBIRD_IDP_MGMT_EXTRA_TENANT_ID="default"
```

## Testing Checklist

### 1. Authentication Test

**Goal**: Verify token acquisition works

**Steps**:
1. Start NetBird management server with LogTo configuration
2. Check logs for authentication success
3. Verify no errors related to token acquisition

**Expected Result**:
- No authentication errors in logs
- Token successfully obtained
- Token cached and reused

**What to Check**:
```bash
# Check management server logs
docker-compose logs management | grep -i logto
# Should see: "requesting new jwt token for logto idp manager"
# Should NOT see: "unable to get logto token"
```

### 2. GetUserByEmail Test

**Goal**: Verify user search by email works

**Steps**:
1. Create a test user in LogTo Console (or use existing user)
2. Use NetBird API or admin UI to search for user by email
3. Verify user is found

**Expected Result**:
- User found successfully
- User data matches LogTo user

**Test Command** (if using NetBird API):
```bash
# This would be through NetBird's user management API
# Check that user lookup works
```

### 3. GetUserDataByID Test

**Goal**: Verify user retrieval by ID works

**Steps**:
1. Get a user ID from LogTo Console
2. Use NetBird to retrieve user by ID
3. Verify user data is correct

**Expected Result**:
- User retrieved successfully
- All user fields populated correctly

### 4. CreateUser Test

**Goal**: Verify user creation works

**Steps**:
1. Use NetBird to create a new user
2. Check LogTo Console to verify user was created
3. Verify user data matches

**Expected Result**:
- User created successfully
- User appears in LogTo Console
- User has correct email, name, and profile fields

**What to Verify**:
- User ID is returned
- User appears in LogTo Console
- Profile structure is correct (givenName, familyName)
- Email is set correctly

### 5. DeleteUser Test

**Goal**: Verify user deletion works

**Steps**:
1. Create a test user (or use existing)
2. Delete user via NetBird
3. Verify user is deleted in LogTo Console

**Expected Result**:
- User deleted successfully
- User no longer appears in LogTo Console

**⚠️ Warning**: This is destructive - use a test user!

### 6. GetAccount / GetAllAccounts Test

**Goal**: Verify account/user listing works

**Steps**:
1. Have multiple users in LogTo
2. Use NetBird to get all accounts/users
3. Verify all users are returned

**Expected Result**:
- All users retrieved
- Pagination works correctly (if many users)
- User data is correct

### 7. Pagination Test

**Goal**: Verify pagination works for large user sets

**Steps**:
1. Create or ensure you have >20 users in LogTo
2. Use NetBird to get all accounts
3. Verify all users are retrieved across pages

**Expected Result**:
- All users retrieved regardless of count
- No missing users
- Pagination parameters work correctly

## Manual API Testing (Optional)

You can also test the LogTo API directly using curl:

### 1. Get Access Token

```bash
# For LogTo Cloud
curl -X POST "https://{tenant-id}.logto.app/oidc/token" \
  -H "Authorization: Basic $(echo -n 'app-id:app-secret' | base64)" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "resource=https://{tenant-id}.logto.app/api" \
  -d "scope=all"
```

**Expected Response**:
```json
{
  "access_token": "eyJhbG...",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "all"
}
```

### 2. List Users

```bash
curl -X GET "https://{tenant-id}.logto.app/api/users" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json"
```

### 3. Create User

```bash
curl -X POST "https://{tenant-id}.logto.app/api/users" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "primaryEmail": "test@example.com",
    "name": "Test User",
    "username": "test@example.com",
    "profile": {
      "givenName": "Test",
      "familyName": "User"
    }
  }'
```

### 4. Get User by ID

```bash
curl -X GET "https://{tenant-id}.logto.app/api/users/{user-id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json"
```

### 5. Delete User

```bash
curl -X DELETE "https://{tenant-id}.logto.app/api/users/{user-id}" \
  -H "Authorization: Bearer {access_token}" \
  -H "Content-Type: application/json"
```

## Common Issues and Troubleshooting

### Issue: "unable to get logto token, statusCode 401"

**Possible Causes**:
- Incorrect App ID or App Secret
- Basic auth encoding issue
- M2M app not assigned proper roles

**Solutions**:
- Verify credentials in LogTo Console
- Check that M2M app has "Logto Management API access" role
- Verify Basic auth header format: `Basic base64(appId:appSecret)`

### Issue: "unable to get logto token, statusCode 400"

**Possible Causes**:
- Missing or incorrect `resource` parameter
- Incorrect `scope` parameter

**Solutions**:
- Verify `resource` matches: `https://{tenant-id}.logto.app/api`
- Ensure `scope` is set to `"all"`

### Issue: "unable to get {endpoint}, statusCode 403"

**Possible Causes**:
- M2M app doesn't have required permissions
- Token expired

**Solutions**:
- Verify M2M app has Management API permissions
- Check token expiration (should auto-refresh)

### Issue: User creation fails

**Possible Causes**:
- Invalid payload structure
- Missing required fields
- Email already exists

**Solutions**:
- Verify payload structure matches LogTo API
- Check that `primaryEmail` and `name` are provided
- Ensure email is unique

### Issue: User profile fields are empty

**Possible Causes**:
- Profile structure not parsed correctly
- Name extraction logic issue

**Solutions**:
- Verify `userData()` method handles all cases
- Check that profile.givenName/familyName are set
- Verify fallback to top-level `name` field works

## Verification Checklist

After testing, verify:

- [ ] Authentication works (token acquisition)
- [ ] Token caching and refresh works
- [ ] GetUserByEmail finds users correctly
- [ ] GetUserDataByID retrieves user correctly
- [ ] CreateUser creates users with correct structure
- [ ] DeleteUser removes users successfully
- [ ] GetAccount returns users for account
- [ ] GetAllAccounts returns all users
- [ ] Pagination works for large user sets
- [ ] Error handling works correctly
- [ ] User profile structure matches LogTo API
- [ ] Name extraction handles all cases (name field, profile fields, username fallback)

## Test Data

### Sample Test Users

Create these in LogTo for testing:

1. **User with full profile**:
   - Email: `fullprofile@test.com`
   - Name: `John Doe`
   - Profile: givenName="John", familyName="Doe"

2. **User with name only**:
   - Email: `nameonly@test.com`
   - Name: `Jane Smith`
   - No profile fields

3. **User with profile only**:
   - Email: `profileonly@test.com`
   - No top-level name
   - Profile: givenName="Bob", familyName="Johnson"

4. **User with username only**:
   - Email: `usernameonly@test.com`
   - Username: `testuser`
   - No name or profile

## Next Steps After Testing

1. **Document any issues found**
2. **Update implementation** if API structure differs
3. **Add integration tests** based on findings
4. **Update documentation** with verified configuration examples
5. **Create user guide** for LogTo setup

## Resources

- LogTo Management API Docs: https://docs.logto.io/integrate-logto/interact-with-management-api
- LogTo OpenAPI Spec: https://openapi.logto.io/
- LogTo Console: https://cloud.logto.io/ (Cloud) or your OSS instance
- NetBird Documentation: https://docs.netbird.io/

---

**Note**: Always test with a non-production LogTo instance first!

