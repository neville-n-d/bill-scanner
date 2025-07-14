# Electricity Bill App Backend API Documentation

## Overview

This API provides endpoints for the Electricity Bill Analyzer app, supporting both regular users and Terahive ESS users.

## Base URL
```
http://localhost:3000/api
```

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Endpoints

### Authentication

#### POST `/auth/register`
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
  "message": "User registered successfully. Please check your email to verify your account.",
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

#### POST `/auth/login`
Authenticate user and get token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "regular",
      "hasTerahiveEss": false,
      "isEmailVerified": true,
      "preferences": {},
      "statistics": {}
    },
    "token": "jwt_token"
  }
}
```

#### GET `/auth/me`
Get current user profile.

**Response:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "user_id",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "userType": "regular",
      "hasTerahiveEss": false,
      "isEmailVerified": true,
      "preferences": {},
      "statistics": {},
      "subscription": {},
      "terahiveEss": {}
    }
  }
}
```

### User Management

#### PUT `/users/terahive-status`
Update Terahive ESS installation status.

**Request Body:**
```json
{
  "hasTerahiveEss": true
}
```

**Response:**
```json
{
  "success": true,
  "message": "Terahive ESS status updated successfully",
  "data": {
    "hasTerahiveEss": true,
    "userType": "terahive_ess"
  }
}
```

#### POST `/users/terahive-setup`
Setup Terahive ESS system details (only for users with Terahive ESS installed).

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
  },
  "apiCredentials": {
    "accessToken": "your-access-token",
    "refreshToken": "your-refresh-token"
  }
}
```

### Bill Management

#### POST `/bills/upload`
Upload and process a new bill image.

**Headers:**
```
Authorization: Bearer <jwt_token>
Content-Type: multipart/form-data
```

**Form Data:**
- `billImage`: Image file (JPEG, PNG, WebP)

**Response:**
```json
{
  "success": true,
  "message": "Bill uploaded successfully. Processing with AI...",
  "data": {
    "billId": "bill_id",
    "processingStatus": "processing"
  }
}
```

#### GET `/bills`
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

**Response:**
```json
{
  "success": true,
  "data": {
    "bills": [
      {
        "id": "bill_id",
        "billNumber": "BILL-2024-001",
        "utilityProvider": {
          "name": "Pacific Gas & Electric"
        },
        "billDate": "2024-01-15T00:00:00.000Z",
        "consumption": {
          "total": 850.5,
          "unit": "kWh"
        },
        "costs": {
          "total": 125.75,
          "currency": "USD"
        },
        "status": "processed",
        "aiAnalysis": {
          "summary": "Your bill shows normal consumption patterns...",
          "insights": [],
          "recommendations": []
        }
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalBills": 50,
      "hasNextPage": true,
      "hasPrevPage": false
    }
  }
}
```

### Analytics

#### GET `/analytics/overview`
Get analytics overview.

**Query Parameters:**
- `period`: Analysis period (3months, 6months, 12months, 24months)

**Response:**
```json
{
  "success": true,
  "data": {
    "analytics": {
      "totalConsumption": 850.5,
      "totalCost": 125.75,
      "averageConsumption": 425.25,
      "averageCost": 62.88,
      "consumptionTrend": "stable",
      "costTrend": "increasing",
      "peakConsumption": 950.0,
      "peakCost": 150.00,
      "efficiency": 0.15
    },
    "period": "12months",
    "totalBills": 2
  }
}
```

### Terahive ESS (ESS Users Only)

#### GET `/terahive/system`
Get user's Terahive system information.

**Response:**
```json
{
  "success": true,
  "data": {
    "system": {
      "systemId": "TH-ESS-001",
      "systemName": "Home Energy Storage",
      "specifications": {
        "batteryCapacity": 13.5,
        "inverterPower": 5.0
      },
      "status": {
        "isOnline": true,
        "batteryLevel": 85,
        "operatingMode": "discharging"
      }
    }
  }
}
```

#### GET `/terahive/status`
Get real-time system status.

**Response:**
```json
{
  "success": true,
  "data": {
    "status": {
      "isOnline": true,
      "operatingMode": "discharging",
      "batteryLevel": 85,
      "temperature": {
        "battery": 25,
        "inverter": 30
      },
      "power": {
        "battery": -2.5,
        "grid": 1.0,
        "load": 3.5
      }
    },
    "lastUpdated": "2024-01-15T10:30:00.000Z"
  }
}
```

## Error Responses

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Please provide a valid email address"
    }
  ]
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `429` - Too Many Requests
- `500` - Internal Server Error

## User Types

### Regular Users
- Can upload and analyze electricity bills
- Access basic analytics and insights
- Receive email notifications

### Terahive ESS Users
- All regular user features
- Real-time system monitoring
- Advanced analytics with ESS data
- System alerts and maintenance notifications

## Registration Flow

1. **User Registration**: User provides basic info and indicates if they have Terahive ESS installed
2. **Email Verification**: User verifies their email address
3. **ESS Setup** (if applicable): Users with Terahive ESS can optionally set up their system details
4. **Bill Upload**: Users can start uploading and analyzing bills

## Security

- JWT-based authentication
- Password hashing with bcrypt
- Rate limiting on all endpoints
- Input validation and sanitization
- CORS protection 