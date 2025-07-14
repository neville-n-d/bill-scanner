# Backend Implementation Guide

## Overview

This guide covers the implementation of the Electricity Bill Analyzer backend, which supports both regular users and Terahive ESS users with a simplified registration process.

## Key Changes from Previous Version

### Simplified User Registration
- **Before**: Users had to specify `userType` during registration
- **After**: Users simply indicate `hasTerahiveEss` (boolean) during registration
- The system automatically determines `userType` based on this flag
- No database lookup required during registration

### User Types
1. **Regular Users** (`userType: 'regular'`)
   - Basic bill analysis and analytics
   - No Terahive ESS integration

2. **Terahive ESS Users** (`userType: 'terahive_ess'`)
   - All regular user features
   - Real-time system monitoring
   - Advanced analytics with ESS data

## Registration Flow

### 1. User Registration
```javascript
// POST /api/auth/register
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "firstName": "John",
  "lastName": "Doe",
  "hasTerahiveEss": false,  // Simple boolean flag
  "phone": "+1234567890"
}
```

### 2. System Response
```javascript
{
  "success": true,
  "data": {
    "user": {
      "userType": "regular",  // Automatically determined
      "hasTerahiveEss": false,
      // ... other user data
    }
  }
}
```

### 3. Optional ESS Setup (for Terahive users)
Users with Terahive ESS can optionally set up their system details later:
```javascript
// POST /api/users/terahive-setup
{
  "systemId": "TH-ESS-001",
  "systemName": "Home Energy Storage",
  "capacity": 13.5,
  "batteryType": "lithium-ion",
  "inverterPower": 5.0,
  "installationDate": "2024-01-01"
}
```

## Database Schema

### User Model
```javascript
{
  email: String,
  password: String,
  firstName: String,
  lastName: String,
  userType: {
    type: String,
    enum: ['regular', 'terahive_ess'],
    default: 'regular'
  },
  terahiveEss: {
    isInstalled: {
      type: Boolean,
      default: false
    },
    systemId: String,
    systemName: String,
    capacity: Number,
    batteryType: String,
    inverterPower: Number,
    installationDate: Date,
    location: Object,
    apiCredentials: Object,
    lastSync: Date,
    syncStatus: String
  },
  // ... other fields
}
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register with `hasTerahiveEss` flag
- `POST /api/auth/login` - Standard login
- `GET /api/auth/me` - Get user profile

### User Management
- `PUT /api/users/terahive-status` - Update Terahive ESS status
- `POST /api/users/terahive-setup` - Setup ESS system details

### Bill Management
- `POST /api/bills/upload` - Upload and process bills
- `GET /api/bills` - Get user's bills
- `PUT /api/bills/:id` - Update bill
- `DELETE /api/bills/:id` - Delete bill

### Analytics
- `GET /api/analytics/overview` - Get analytics overview
- `GET /api/analytics/consumption` - Get consumption data
- `GET /api/analytics/costs` - Get cost analysis

### Terahive ESS (ESS Users Only)
- `GET /api/terahive/system` - Get system info
- `GET /api/terahive/status` - Get real-time status
- `GET /api/terahive/history` - Get historical data

## Implementation Details

### Registration Logic
```javascript
// In auth.js - registration endpoint
const { hasTerahiveEss } = req.body;

// Determine user type based on Terahive ESS installation
const userType = hasTerahiveEss ? 'terahive_ess' : 'regular';

// Create user with appropriate type
const user = new User({
  // ... other fields
  userType,
  terahiveEss: {
    isInstalled: hasTerahiveEss,
  },
});
```

### Terahive Status Update
```javascript
// In users.js - update Terahive status
user.terahiveEss.isInstalled = hasTerahiveEss;
user.userType = hasTerahiveEss ? 'terahive_ess' : 'regular';

// Clear system data if removing Terahive ESS
if (!hasTerahiveEss) {
  user.terahiveEss = { isInstalled: false };
}
```

### Conditional Features
```javascript
// Example: Analytics with ESS data
if (user.userType === 'terahive_ess' && user.terahiveEss.isInstalled) {
  // Include ESS data in analytics
  analytics.essData = await getEssData(user.terahiveEss.systemId);
}
```

## Security Considerations

### Input Validation
- Validate `hasTerahiveEss` as boolean
- Sanitize all user inputs
- Rate limiting on registration

### Access Control
- ESS endpoints only accessible to ESS users
- User can only access their own data
- JWT token validation on all protected routes

### Data Protection
- Passwords hashed with bcrypt
- Sensitive ESS data encrypted
- API credentials stored securely

## Testing

### Registration Tests
```javascript
describe('User Registration', () => {
  it('should create regular user when hasTerahiveEss is false', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'test@example.com',
        password: 'Password123!',
        firstName: 'Test',
        lastName: 'User',
        hasTerahiveEss: false
      });
    
    expect(response.body.data.user.userType).toBe('regular');
    expect(response.body.data.user.hasTerahiveEss).toBe(false);
  });

  it('should create ESS user when hasTerahiveEss is true', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: 'ess@example.com',
        password: 'Password123!',
        firstName: 'ESS',
        lastName: 'User',
        hasTerahiveEss: true
      });
    
    expect(response.body.data.user.userType).toBe('terahive_ess');
    expect(response.body.data.user.hasTerahiveEss).toBe(true);
  });
});
```

## Deployment

### Environment Variables
```bash
# Required
MONGODB_URI=mongodb://localhost:27017/electricity_bill_app
JWT_SECRET=your-jwt-secret
AZURE_OPENAI_ENDPOINT=your-azure-openai-endpoint
AZURE_OPENAI_API_KEY=your-azure-openai-key

# Optional
EMAIL_SERVICE=gmail
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-email-password
FRONTEND_URL=http://localhost:3000
```

### Docker Deployment
```bash
# Build and run with Docker Compose
docker-compose up -d

# Or build manually
docker build -t electricity-bill-backend .
docker run -p 3000:3000 electricity-bill-backend
```

## Future Enhancements

### Planned Features
1. **Advanced ESS Analytics**
   - Battery health monitoring
   - Efficiency optimization recommendations
   - Predictive maintenance alerts

2. **Integration Features**
   - Multiple ESS system support
   - Third-party energy provider APIs
   - Smart home device integration

3. **User Experience**
   - Onboarding flow for ESS users
   - Guided setup process
   - Interactive tutorials

### Scalability Considerations
- Database indexing for large datasets
- Caching for frequently accessed data
- Microservices architecture for ESS features
- Real-time updates with WebSocket support

## Troubleshooting

### Common Issues

1. **Registration Fails**
   - Check MongoDB connection
   - Verify email format validation
   - Ensure password meets requirements

2. **ESS Features Not Available**
   - Verify user has `userType: 'terahive_ess'`
   - Check if `terahiveEss.isInstalled` is true
   - Ensure proper authentication

3. **API Integration Issues**
   - Verify Azure OpenAI credentials
   - Check rate limiting
   - Validate request format

### Debug Mode
```bash
# Enable debug logging
DEBUG=app:* npm start

# Check logs
docker logs electricity-bill-backend
```

## Support

For issues or questions:
1. Check the API documentation
2. Review error logs
3. Test with provided examples
4. Contact development team 