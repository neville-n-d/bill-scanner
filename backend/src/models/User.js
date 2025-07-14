const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const userSchema = new mongoose.Schema({
  // Basic user information
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email'],
  },
  password: {
    type: String,
    required: true,
    minlength: [8, 'Password must be at least 8 characters long'],
  },
  firstName: {
    type: String,
    required: true,
    trim: true,
    maxlength: [50, 'First name cannot exceed 50 characters'],
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
    maxlength: [50, 'Last name cannot exceed 50 characters'],
  },
  phone: {
    type: String,
    trim: true,
    match: [/^\+?[\d\s-()]+$/, 'Please enter a valid phone number'],
  },
  
  // User type and preferences
  userType: {
    type: String,
    enum: ['regular', 'terahive_ess'],
    default: 'regular',
    required: true,
  },
  
  // Account status
  isActive: {
    type: Boolean,
    default: true,
  },
  isEmailVerified: {
    type: Boolean,
    default: false,
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  
  // Password reset
  passwordResetToken: String,
  passwordResetExpires: Date,
  
  // Terahive ESS specific fields
  terahiveEss: {
    isInstalled: {
      type: Boolean,
      default: false,
    },
    installationDate: Date,
    systemId: {
      type: String,
      unique: true,
      sparse: true, // Allows multiple null values
    },
    capacity: {
      type: Number, // in kWh
      min: 0,
    },
    batteryType: {
      type: String,
      enum: ['lithium-ion', 'lithium-iron-phosphate', 'lead-acid', 'other'],
    },
    inverterPower: {
      type: Number, // in kW
      min: 0,
    },
    location: {
      address: String,
      city: String,
      state: String,
      zipCode: String,
      country: String,
      coordinates: {
        latitude: Number,
        longitude: Number,
      },
    },
    apiCredentials: {
      accessToken: String,
      refreshToken: String,
      tokenExpiresAt: Date,
      deviceId: String,
    },
    lastSync: Date,
    syncStatus: {
      type: String,
      enum: ['active', 'inactive', 'error'],
      default: 'inactive',
    },
  },
  
  // App preferences
  preferences: {
    currency: {
      type: String,
      default: 'USD',
      enum: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
    },
    energyUnit: {
      type: String,
      default: 'kWh',
      enum: ['kWh', 'MWh', 'GJ'],
    },
    timezone: {
      type: String,
      default: 'UTC',
    },
    language: {
      type: String,
      default: 'en',
      enum: ['en', 'es', 'fr', 'de'],
    },
    notifications: {
      email: {
        type: Boolean,
        default: true,
      },
      push: {
        type: Boolean,
        default: true,
      },
      sms: {
        type: Boolean,
        default: false,
      },
      billReminders: {
        type: Boolean,
        default: true,
      },
      energyAlerts: {
        type: Boolean,
        default: true,
      },
      systemAlerts: {
        type: Boolean,
        default: true,
      },
    },
  },
  
  // Usage statistics
  statistics: {
    totalBills: {
      type: Number,
      default: 0,
    },
    totalConsumption: {
      type: Number,
      default: 0, // in kWh
    },
    totalAmount: {
      type: Number,
      default: 0, // in user's currency
    },
    averageMonthlyConsumption: {
      type: Number,
      default: 0,
    },
    averageMonthlyCost: {
      type: Number,
      default: 0,
    },
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
  },
  
  // Subscription and billing
  subscription: {
    plan: {
      type: String,
      enum: ['free', 'basic', 'premium', 'enterprise'],
      default: 'free',
    },
    startDate: Date,
    endDate: Date,
    isActive: {
      type: Boolean,
      default: true,
    },
    features: [{
      name: String,
      isEnabled: {
        type: Boolean,
        default: false,
      },
    }],
  },
  
  // Timestamps
  lastLogin: Date,
  lastActivity: Date,
}, {
  timestamps: true,
});

// Indexes for better query performance
userSchema.index({ userType: 1 });
userSchema.index({ 'terahiveEss.isInstalled': 1 });
userSchema.index({ createdAt: -1 });

// Virtual for full name
userSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName}`;
});

// Virtual for Terahive ESS status
userSchema.virtual('hasTerahiveEss').get(function() {
  return this.userType === 'terahive_ess' && this.terahiveEss.isInstalled;
});

// Pre-save middleware to hash password
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(parseInt(process.env.BCRYPT_ROUNDS) || 12);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Instance method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Instance method to generate JWT token
userSchema.methods.generateAuthToken = function() {
  const payload = {
    userId: this._id,
    email: this.email,
    userType: this.userType,
    hasTerahiveEss: this.hasTerahiveEss,
  };
  
  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
};

// Instance method to update last activity
userSchema.methods.updateLastActivity = function() {
  this.lastActivity = new Date();
  return this.save();
};

// Instance method to update statistics
userSchema.methods.updateStatistics = function(billData) {
  this.statistics.totalBills += 1;
  this.statistics.totalConsumption += billData.consumptionKwh || 0;
  this.statistics.totalAmount += billData.totalAmount || 0;
  this.statistics.lastUpdated = new Date();
  
  // Calculate averages (simplified - in production, you'd want more sophisticated calculations)
  if (this.statistics.totalBills > 0) {
    this.statistics.averageMonthlyConsumption = this.statistics.totalConsumption / this.statistics.totalBills;
    this.statistics.averageMonthlyCost = this.statistics.totalAmount / this.statistics.totalBills;
  }
  
  return this.save();
};

// Static method to find users by type
userSchema.statics.findByUserType = function(userType) {
  return this.find({ userType, isActive: true });
};

// Static method to find Terahive ESS users
userSchema.statics.findTerahiveUsers = function() {
  return this.find({
    userType: 'terahive_ess',
    'terahiveEss.isInstalled': true,
    isActive: true,
  });
};

// JSON serialization (exclude sensitive fields)
userSchema.methods.toJSON = function() {
  const userObject = this.toObject();
  delete userObject.password;
  delete userObject.emailVerificationToken;
  delete userObject.passwordResetToken;
  delete userObject.terahiveEss.apiCredentials;
  return userObject;
};

module.exports = mongoose.model('User', userSchema); 