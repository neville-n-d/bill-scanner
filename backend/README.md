# Electricity Bill App Backend

A comprehensive Node.js/Express backend for the Electricity Bill Analyzer app with support for both regular users and Terahive ESS (Energy Storage System) users.

## Features

### Core Features
- **User Authentication & Authorization**: JWT-based authentication with role-based access control
- **Bill Management**: Upload, process, and analyze electricity bills using Azure OpenAI Vision
- **AI-Powered Analysis**: Intelligent bill parsing and energy efficiency insights
- **Analytics & Reporting**: Comprehensive energy consumption and cost analytics
- **Real-time Notifications**: Email, push, and SMS notifications

### Terahive ESS Integration
- **System Management**: Real-time monitoring of Terahive ESS systems
- **Performance Tracking**: Battery efficiency, grid interaction, and financial metrics
- **Alert Management**: System alerts and maintenance notifications
- **Data Synchronization**: Automatic sync with Terahive API
- **Savings Calculation**: ROI and payback period analysis

### User Types
1. **Regular Users**: Standard electricity bill analysis and insights
2. **Terahive ESS Users**: Advanced features with energy storage system integration

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT with bcryptjs
- **AI Integration**: Azure OpenAI Vision API
- **Email**: Nodemailer with template support
- **File Upload**: Multer with image processing
- **Logging**: Winston
- **Validation**: Joi and express-validator
- **Security**: Helmet, CORS, rate limiting

## Prerequisites

- Node.js 18+ and npm
- MongoDB (local or cloud)
- Azure OpenAI account
- Terahive ESS API credentials (for ESS users)
- SMTP server for email notifications

## Installation

1. **Clone the repository**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` with your configuration:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # MongoDB Configuration
   MONGODB_URI=mongodb://localhost:27017/electricity_bill_app
   
   # JWT Configuration
   JWT_SECRET=your-super-secret-jwt-key-here
   JWT_EXPIRES_IN=7d
   
   # Azure OpenAI Configuration
   AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
   AZURE_OPENAI_DEPLOYMENT=gpt-4-vision
   AZURE_OPENAI_API_KEY=your-azure-openai-api-key
   AZURE_OPENAI_API_VERSION=2024-02-15-preview
   
   # Terahive ESS API Configuration
   TERAHIVE_API_BASE_URL=https://api.terahive.com/v1
   TERAHIVE_API_KEY=your-terahive-api-key
   TERAHIVE_CLIENT_ID=your-terahive-client-id
   TERAHIVE_CLIENT_SECRET=your-terahive-client-secret
   
   # Email Configuration
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-email-password
   ```

4. **Create required directories**
   ```bash
   mkdir -p logs uploads
   ```

5. **Start the server**
   ```bash
   # Development
   npm run dev
   
   # Production
   npm start
   ```

## API Documentation

### Authentication Endpoints

#### POST `/api/auth/register`
Register a new user.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "firstName": "John",
  "lastName": "Doe",
  "hasTerahiveEss": false,
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "regular",
      "hasTerahiveEss": false,
      "isEmailVerified": false
    },
    "token": "jwt_token"
  }
}
```

#### POST `/api/auth/login`
Authenticate user and get token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

### Bill Management Endpoints

#### POST `/api/bills/upload`
Upload and process a new bill image.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `billImage`: Image file (JPEG, PNG, WebP)

#### POST `/api/bills`
Create a new bill manually.

**Request Body:**
```json
{
  "billNumber": "BILL-2024-001",
  "utilityProvider": {
    "name": "Pacific Gas & Electric",
    "code": "PGE"
  },
  "billDate": "2024-01-15",
  "dueDate": "2024-02-15",
  "billingPeriod": {
    "startDate": "2023-12-15",
    "endDate": "2024-01-15"
  },
  "consumption": {
    "total": 850.5,
    "unit": "kWh"
  },
  "costs": {
    "total": 125.75,
    "currency": "USD"
  }
}
```

#### GET `/api/bills`
Get all bills for the authenticated user.

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `status`: Filter by status (draft, processed, verified, archived)
- `startDate`: Filter by start date
- `endDate`: Filter by end date
- `utilityProvider`: Filter by utility provider
- `sortBy`: Sort field (default: billDate)
- `sortOrder`: Sort order (asc, desc)

### Terahive ESS Endpoints

#### GET `/api/terahive/system`
Get user's Terahive system information.

#### GET `/api/terahive/status`
Get real-time system status.

#### GET `/api/terahive/historical-data`
Get historical system data.

**Query Parameters:**
- `startDate`: Start date (ISO format)
- `endDate`: End date (ISO format)
- `granularity`: Data granularity (hourly, daily, monthly)

#### GET `/api/terahive/alerts`
Get system alerts.

**Query Parameters:**
- `activeOnly`: Show only active alerts (true/false)

### Analytics Endpoints

#### GET `/api/analytics/overview`
Get analytics overview.

**Query Parameters:**
- `period`: Analysis period (3months, 6months, 12months, 24months)

#### GET `/api/analytics/consumption`
Get consumption analytics.

**Query Parameters:**
- `granularity`: Data granularity (daily, weekly, monthly, quarterly, yearly)
- `startDate`: Start date
- `endDate`: End date

#### GET `/api/analytics/trends`
Get trend analysis.

**Query Parameters:**
- `months`: Number of months to analyze (default: 12)

### User Management Endpoints

#### GET `/api/users/profile`
Get user profile.

#### PUT `/api/users/profile`
Update user profile.

#### PUT `/api/users/preferences`
Update user preferences.

#### POST `/api/users/terahive-setup`
Setup Terahive ESS integration.

**Request Body:**
```json
{
  "systemId": "TH-ESS-001",
  "systemName": "Home Energy Storage",
  "capacity": 13.5,
  "batteryType": "lithium-ion",
  "inverterPower": 5.0,
  "installationDate": "2024-01-01",
  "location": {
    "address": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zipCode": "94102"
  }
}
```

## Database Models

### User Model
- Basic user information (name, email, phone)
- User type (regular, terahive_ess)
- Terahive ESS configuration
- Preferences and settings
- Statistics and subscription

### Bill Model
- Bill identification and details
- Consumption and cost data
- Terahive ESS integration data
- AI analysis results
- Image and processing information

### TerahiveSystem Model
- System specifications and installation
- Real-time status and performance
- Historical data and financial metrics
- Alerts and maintenance history

## Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: bcryptjs with configurable rounds
- **Rate Limiting**: Request rate limiting and speed limiting
- **Input Validation**: Comprehensive request validation
- **CORS Protection**: Configurable CORS policies
- **Helmet Security**: Security headers
- **File Upload Security**: File type and size validation

## Error Handling

The backend includes comprehensive error handling:

- **Validation Errors**: Detailed validation error messages
- **Authentication Errors**: Proper JWT error handling
- **Database Errors**: Mongoose error handling
- **API Errors**: External API error handling
- **File Upload Errors**: Multer error handling

## Logging

Structured logging using Winston:

- **File Logging**: Separate log files for different levels
- **Console Logging**: Development console output
- **Error Tracking**: Detailed error logging with stack traces
- **Request Logging**: HTTP request/response logging

## Testing

Run tests:
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch
```

## Deployment

### Production Setup

1. **Environment Variables**
   - Set `NODE_ENV=production`
   - Configure production MongoDB URI
   - Set secure JWT secret
   - Configure production email settings

2. **Process Management**
   ```bash
   # Using PM2
   npm install -g pm2
   pm2 start src/server.js --name "electricity-bill-backend"
   ```

3. **Reverse Proxy**
   - Configure Nginx or Apache
   - Set up SSL certificates
   - Configure load balancing if needed

### Docker Deployment

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

## Monitoring

- **Health Check**: `/health` endpoint for monitoring
- **Logs**: Structured logging for monitoring
- **Metrics**: Performance metrics and statistics
- **Alerts**: System alerts and notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For support and questions:
- Email: support@electricitybillapp.com
- Documentation: [API Docs](https://docs.electricitybillapp.com)
- Issues: [GitHub Issues](https://github.com/your-repo/issues) 