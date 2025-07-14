const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// User Schema (simplified version for this script)
const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
  },
  firstName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50,
  },
  lastName: {
    type: String,
    required: true,
    trim: true,
    maxlength: 50,
  },
  phone: {
    type: String,
    trim: true,
  },
  userType: {
    type: String,
    enum: ['regular', 'terahive_ess'],
    default: 'regular',
    required: true,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  isEmailVerified: {
    type: Boolean,
    default: true,
  },
  hasTerahiveEss: {
    type: Boolean,
    default: false,
  },
  terahiveEss: {
    isInstalled: {
      type: Boolean,
      default: false,
    },
  },
  preferences: {
    currency: {
      type: String,
      default: 'USD',
    },
    energyUnit: {
      type: String,
      default: 'kWh',
    },
    timezone: {
      type: String,
      default: 'UTC',
    },
    language: {
      type: String,
      default: 'en',
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
  statistics: {
    totalBills: {
      type: Number,
      default: 0,
    },
    totalConsumption: {
      type: Number,
      default: 0,
    },
    totalAmount: {
      type: Number,
      default: 0,
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
  createdAt: {
    type: Date,
    default: Date.now,
  },
  updatedAt: {
    type: Date,
    default: Date.now,
  },
});

const User = mongoose.model('User', userSchema);

async function createTestUser() {
  try {
    // Connect to MongoDB
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/electricity_bill_app';
    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log('Connected to MongoDB');

    // Check if test user already exists
    const existingUser = await User.findOne({ email: 'test@example.com' });
    if (existingUser) {
      console.log('Test user already exists!');
      console.log('Email: test@example.com');
      console.log('Password: Test@1234');
      await mongoose.connection.close();
      return;
    }

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash('Test@1234', saltRounds);

    // Create test user
    const testUser = new User({
      email: 'test@example.com',
      password: hashedPassword,
      firstName: 'Test',
      lastName: 'User',
      phone: '+1234567890',
      userType: 'regular',
      isActive: true,
      isEmailVerified: true,
      hasTerahiveEss: false,
      terahiveEss: {
        isInstalled: false,
      },
      preferences: {
        currency: 'USD',
        energyUnit: 'kWh',
        timezone: 'UTC',
        language: 'en',
        notifications: {
          email: true,
          push: true,
          sms: false,
          billReminders: true,
          energyAlerts: true,
          systemAlerts: true,
        },
      },
      statistics: {
        totalBills: 0,
        totalConsumption: 0,
        totalAmount: 0,
        averageMonthlyConsumption: 0,
        averageMonthlyCost: 0,
        lastUpdated: new Date(),
      },
    });

    await testUser.save();
    
    console.log('✅ Test user created successfully!');
    console.log('📧 Email: test@example.com');
    console.log('🔑 Password: Test@1234');
    console.log('👤 Name: Test User');
    console.log('📱 Phone: +1234567890');
    console.log('🔋 Terahive ESS: Not Installed');

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  } finally {
    await mongoose.connection.close();
    console.log('Disconnected from MongoDB');
  }
}

// Run the script
createTestUser(); 