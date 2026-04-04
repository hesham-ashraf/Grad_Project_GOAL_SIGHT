# GOALSIGHT - Issues and Bugs Identified

**Project:** GOALSIGHT Football Live Score Application  
**Date:** March 7, 2026  
**Phase:** Implementation and Testing  
**Total Issues:** 15

---

## Issues Summary

| Severity | Count | Percentage |
|----------|-------|------------|
| Critical | 2     | 13.3%      |
| High     | 4     | 26.7%      |
| Medium   | 6     | 40.0%      |
| Low      | 3     | 20.0%      |

---

## Detailed Issues Log

### ISSUE-001
**Issue ID:** ISSUE-001  
**Description:** Duplicate Schema Index Warning - Mongoose reports duplicate index on User email field. Index defined both via schema option `{index: true}` and `schema.index()` method  
**Severity:** Medium  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Review User.model.js email field definition
2. Remove one of the duplicate index definitions
3. Keep only `unique: true` attribute or manual `schema.index()` call
4. Test email uniqueness validation after fix
5. Update model tests to verify index behavior

---

### ISSUE-002
**Issue ID:** ISSUE-002  
**Description:** Deprecated MongoDB Connection Options - `useNewUrlParser` and `useUnifiedTopology` options are deprecated in MongoDB Driver v4.0.0+ but still being passed in database connection configuration  
**Severity:** Low  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Open config/database.js
2. Remove `useNewUrlParser: true` from connection options
3. Remove `useUnifiedTopology: true` from connection options
4. Update MongoDB driver to latest stable version if needed
5. Test database connection after changes

---

### ISSUE-003
**Issue ID:** ISSUE-003  
**Description:** Test Database Cleanup Failures - E11000 duplicate key errors occur during test execution because test database (goalsight_test) is not properly cleaned between test suites. Users with email "test@example.com" persist across test runs  
**Severity:** High  
**Status:** Identified - Partial Fix Attempted  
**Fix Plan:**
1. Implement global `beforeEach` hook in Jest setup
2. Add `await User.deleteMany({})` before each test suite
3. Implement proper teardown with `afterAll` hook
4. Use unique email generation (UUID or timestamp) for each test
5. Consider using jest-mongodb for automatic cleanup
6. Add database connection closure in `afterAll` hooks

---

### ISSUE-004
**Issue ID:** ISSUE-004  
**Description:** Test Isolation Failures - Integration tests fail when run together due to shared database state. Tests pass individually but fail in full suite execution (37/42 passing vs 10/10 for JWT alone)  
**Severity:** High  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Implement test database reset between test files
2. Use separate database instances for each test suite
3. Add transaction rollback after each test
4. Implement test data factories with unique identifiers
5. Use `--runInBand` flag to run tests serially instead of parallel
6. Add proper async cleanup with `done()` callbacks

---

### ISSUE-005
**Issue ID:** ISSUE-005  
**Description:** MongoDB Memory Server Installation Failed - npm package `mongodb-memory-server` failed to install due to network/binary download issues. Forced to use local MongoDB instance for testing instead of in-memory database  
**Severity:** Medium  
**Status:** Workaround Implemented  
**Fix Plan:**
1. Configure npm proxy settings if behind corporate firewall
2. Manually download mongodb-memory-server binaries
3. Set `MONGOMS_DOWNLOAD_URL` environment variable
4. Alternative: Use Docker container for test database
5. Document local MongoDB requirement in README
6. Add CI/CD configuration for test database setup

---

### ISSUE-006
**Issue ID:** ISSUE-006  
**Description:** ES Module Configuration Complexity - Project uses ES modules (`"type": "module"`) requiring experimental Node.js flag `--experimental-vm-modules` for Jest testing. Causes warnings and potential instability  
**Severity:** Medium  
**Status:** Workaround Implemented  
**Fix Plan:**
1. Evaluate switching to CommonJS for backend (impact assessment)
2. Update Jest to version with stable ESM support
3. Configure Babel for ESM-to-CommonJS transformation during tests
4. Alternative: Wait for Node.js stable ESM support
5. Add clear documentation for ESM testing setup
6. Suppress experimental warnings in production

---

### ISSUE-007
**Issue ID:** ISSUE-007  
**Description:** npm CLI Coverage Flag Not Recognized - Running `npm test -- --coverage` produces warning "Unknown cli config '--coverage'". Coverage must be run via direct Jest command `npx jest --coverage`  
**Severity:** Low  
**Status:** Workaround Documented  
**Fix Plan:**
1. Update package.json test scripts
2. Add separate script: `"test:coverage": "jest --coverage"`
3. Add script: `"test:html": "jest --coverage --coverageReporters=html"`
4. Update documentation with correct test commands
5. Consider using jest.config.js to enable coverage by default

---

### ISSUE-008
**Issue ID:** ISSUE-008  
**Description:** User Model Duplicate Email Test Failure - Test "should fail with duplicate email" expects promise rejection but receives resolved promise. User.create() succeeds instead of throwing error for duplicate email  
**Severity:** High  
**Status:** Test Failing  
**Fix Plan:**
1. Verify MongoDB unique index is properly created on email field
2. Add manual uniqueness check in User model pre-save hook
3. Update test to properly clear database before duplicate test
4. Add explicit error handling for E11000 duplicate key errors
5. Mock User.create() to return rejected promise in test
6. Verify schema validation is active

---

### ISSUE-009
**Issue ID:** ISSUE-009  
**Description:** Auth Controller Error Code Inconsistency - Registration endpoint returns `500 Internal Server Error` for duplicate email instead of `400 Bad Request`. Failing to properly catch and handle E11000 MongoDB duplicate key error  
**Severity:** High  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Open src/controllers/auth.controller.js
2. Add specific error handling for error.code === 11000
3. Return 400 status with message "Email already registered"
4. Update error response format to match API standards
5. Add similar handling for duplicate username if applicable
6. Update integration tests to expect 400 instead of 500

---

### ISSUE-010
**Issue ID:** ISSUE-010  
**Description:** Jest Force Exit Warning - After test completion, Jest displays "Force exiting Jest: Have you considered using `--detectOpenHandles`" indicating open async handles (likely database connections not closed)  
**Severity:** Medium  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Add `afterAll` hook in each test file to close mongoose connection
2. Implement: `await mongoose.connection.close()`
3. Add global teardown file in Jest configuration
4. Use `--detectOpenHandles` flag to identify specific handles
5. Ensure Socket.IO connections are properly closed in tests
6. Add timeout for connection closure attempts

---

### ISSUE-011
**Issue ID:** ISSUE-011  
**Description:** Login Test Document Not Found Error - Test "should login with valid credentials" fails with "No document found for query" error. User created in registration test is deleted before login test due to cleanup issues  
**Severity:** Medium  
**Status:** Test Failing  
**Fix Plan:**
1. Redesign test data lifecycle management
2. Create fresh user in login test beforeEach hook
3. Store user credentials in test suite scope variables
4. Implement test transaction rollback instead of deletion
5. Use fixtures or factories for consistent test data
6. Separate registration and login into independent test files

---

### ISSUE-012
**Issue ID:** ISSUE-012  
**Description:** Low Overall Code Coverage - Overall test coverage is 12.53% (37 of 42 tests passing). Critical modules like Match.controller.js (0%), LiveController.js (0%), Socket handlers (0%), and SportmonksService.js (0%) have no test coverage  
**Severity:** Critical  
**Status:** Identified - Needs Implementation  
**Fix Plan:**
1. Prioritize testing for Match.controller.js (639 lines)
2. Create integration tests for LiveController endpoints
3. Implement Socket.IO event handler tests using socket.io-client
4. Mock SportmonksService API calls with jest.mock()
5. Target minimum 60% code coverage across all modules
6. Add coverage threshold in jest.config.js to prevent regression

---

### ISSUE-013
**Issue ID:** ISSUE-013  
**Description:** Authentication Middleware Low Coverage - auth.middleware.js only has 45.45% coverage with critical authorization logic untested (lines 68-90, 99-114). Role-based access control and token refresh logic not validated  
**Severity:** Critical  
**Status:** Identified - Needs Implementation  
**Fix Plan:**
1. Create tests/unit/auth.middleware.test.js
2. Test requireAuth with missing/invalid/expired tokens
3. Test authorizeRoles for all role combinations (fan, manager, admin)
4. Test refreshToken endpoint functionality
5. Mock JWT verification failures
6. Test edge cases (malformed headers, missing Bearer prefix)
7. Target 90%+ coverage for security-critical middleware

---

### ISSUE-014
**Issue ID:** ISSUE-014  
**Description:** Missing Environment Configuration Validation - No validation exists for required environment variables (JWT_SECRET, MONGODB_URI, etc.). Application may crash at runtime if .env file is incomplete or malformed  
**Severity:** Medium  
**Status:** Identified - Not Fixed  
**Fix Plan:**
1. Create src/config/validateEnv.js
2. Use joi or Yup for schema validation
3. Define required variables: JWT_SECRET, MONGODB_URI, PORT, NODE_ENV
4. Validate on application startup in server.js
5. Throw descriptive error with missing variable names
6. Add unit tests for environment validation logic
7. Document all required environment variables in README

---

### ISSUE-015
**Issue ID:** ISSUE-015  
**Description:** No API Documentation - Backend REST API endpoints lack documentation. No Swagger/OpenAPI specification exists making it difficult for frontend developers to integrate and for future maintenance  
**Severity:** Medium  
**Status:** Identified - Not Implemented  
**Fix Plan:**
1. Install swagger-jsdoc and swagger-ui-express packages
2. Add JSDoc comments to all route handlers
3. Define OpenAPI 3.0 specification in swagger.config.js
4. Document request/response schemas for all endpoints
5. Add authentication requirements to protected routes
6. Mount Swagger UI at /api/v1/docs endpoint
7. Generate Postman collection from OpenAPI spec

---

## Priority Fixes Roadmap

### Phase 1: Critical Fixes (Week 1)
1. **ISSUE-013** - Complete auth middleware test coverage
2. **ISSUE-012** - Expand test coverage to 60%+ minimum
3. **ISSUE-009** - Fix auth controller error handling

### Phase 2: High Priority (Week 2)
4. **ISSUE-003** - Implement proper test database cleanup
5. **ISSUE-004** - Resolve test isolation failures
6. **ISSUE-008** - Fix duplicate email validation

### Phase 3: Medium Priority (Week 3)
7. **ISSUE-010** - Close database connections properly
8. **ISSUE-011** - Fix login test document errors
9. **ISSUE-014** - Add environment validation
10. **ISSUE-015** - Create API documentation

### Phase 4: Low Priority (Week 4)
11. **ISSUE-001** - Remove duplicate indexes
12. **ISSUE-002** - Remove deprecated MongoDB options
13. **ISSUE-007** - Update npm scripts
14. **ISSUE-005** - Setup mongodb-memory-server
15. **ISSUE-006** - Evaluate ESM configuration

---

## Testing Gaps Analysis

| Module | Current Coverage | Target Coverage | Gap |
|--------|------------------|-----------------|-----|
| jwt.js | 100% | 100% | ✅ Met |
| User.model.js | 93.3% | 95% | -1.7% |
| auth.controller.js | 48.6% | 80% | -31.4% |
| auth.middleware.js | 45.5% | 90% | -44.5% |
| match.controller.js | 0% | 70% | -70% |
| liveController.js | 0% | 70% | -70% |
| sockets/index.js | 0% | 60% | -60% |
| sportmonksService.js | 0% | 50% | -50% |

**Overall Gap:** From 12.53% to target 70% = **57.47% coverage gap**

---

## Technical Debt Summary

### Accumulated Debt:
1. **Test Infrastructure:** ~8 hours to implement proper cleanup and isolation
2. **Missing Tests:** ~40 hours to reach 70% coverage across all modules
3. **Error Handling:** ~4 hours to standardize error responses
4. **Documentation:** ~6 hours for complete API documentation
5. **Configuration:** ~2 hours for environment validation

**Total Estimated Effort:** ~60 hours

---

## Lessons Learned

1. **Test Database Management:** Always implement proper cleanup hooks from the start
2. **ESM Complexity:** Consider CommonJS for backend until ESM support is stable
3. **Coverage Goals:** Define coverage thresholds before implementation begins
4. **Error Handling:** Standardize error responses across all controllers
5. **Documentation:** Write API docs concurrently with implementation
6. **Environment Setup:** Validate configuration on startup to catch issues early

---

## Recommendations for Future Development

1. ✅ Implement CI/CD pipeline with automated testing
2. ✅ Add pre-commit hooks with ESLint and Prettier
3. ✅ Setup Husky to prevent commits with failing tests
4. ✅ Use Docker Compose for consistent test environments
5. ✅ Implement request validation middleware (express-validator)
6. ✅ Add rate limiting for API endpoints (express-rate-limit)
7. ✅ Setup error tracking (Sentry or similar)
8. ✅ Implement structured logging (Winston or Pino)

---

**Report Generated:** March 7, 2026  
**Reviewed By:** Development Team  
**Next Review:** After Phase 1 completion
