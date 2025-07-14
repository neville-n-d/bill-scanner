#!/usr/bin/env node

const fs = require('fs').promises;
const path = require('path');
const readline = require('readline');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

// Question helper
function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

// Create directories
async function createDirectories() {
  const dirs = ['logs', 'uploads', 'src/templates/emails'];
  
  for (const dir of dirs) {
    try {
      await fs.mkdir(dir, { recursive: true });
      console.log(`✓ Created directory: ${dir}`);
    } catch (error) {
      console.log(`- Directory already exists: ${dir}`);
    }
  }
}

// Create .env file
async function createEnvFile() {
  const envPath = path.join(process.cwd(), '.env');
  
  try {
    await fs.access(envPath);
    const overwrite = await question('.env file already exists. Overwrite? (y/N): ');
    if (overwrite.toLowerCase() !== 'y') {
      console.log('Skipping .env creation');
      return;
    }
  } catch (error) {
    // File doesn't exist, continue
  }

  console.log('\n=== Environment Configuration ===');
  
  const port = await question('Server port (default: 3000): ') || '3000';
  const nodeEnv = await question('Node environment (development/production) [development]: ') || 'development';
  
  console.log('\n=== MongoDB Configuration ===');
  const mongoUri = await question('MongoDB URI (default: mongodb://localhost:27017/electricity_bill_app): ') || 'mongodb://localhost:27017/electricity_bill_app';
  
  console.log('\n=== JWT Configuration ===');
  const jwtSecret = await question('JWT Secret (leave empty to generate): ') || require('crypto').randomBytes(64).toString('hex');
  const jwtExpires = await question('JWT Expires In (default: 7d): ') || '7d';
  
  console.log('\n=== Azure OpenAI Configuration ===');
  const azureEndpoint = await question('Azure OpenAI Endpoint: ');
  const azureDeployment = await question('Azure OpenAI Deployment: ');
  const azureApiKey = await question('Azure OpenAI API Key: ');
  const azureApiVersion = await question('Azure OpenAI API Version (default: 2024-02-15-preview): ') || '2024-02-15-preview';
  
  console.log('\n=== Terahive ESS Configuration ===');
  const terahiveBaseUrl = await question('Terahive API Base URL (default: https://api.terahive.com/v1): ') || 'https://api.terahive.com/v1';
  const terahiveApiKey = await question('Terahive API Key: ');
  const terahiveClientId = await question('Terahive Client ID: ');
  const terahiveClientSecret = await question('Terahive Client Secret: ');
  
  console.log('\n=== Email Configuration ===');
  const smtpHost = await question('SMTP Host (default: smtp.gmail.com): ') || 'smtp.gmail.com';
  const smtpPort = await question('SMTP Port (default: 587): ') || '587';
  const smtpUser = await question('SMTP User (email): ');
  const smtpPass = await question('SMTP Password: ');
  
  const envContent = `# Server Configuration
PORT=${port}
NODE_ENV=${nodeEnv}

# MongoDB Configuration
MONGODB_URI=${mongoUri}
MONGODB_URI_PROD=${mongoUri}

# JWT Configuration
JWT_SECRET=${jwtSecret}
JWT_EXPIRES_IN=${jwtExpires}

# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=${azureEndpoint}
AZURE_OPENAI_DEPLOYMENT=${azureDeployment}
AZURE_OPENAI_API_KEY=${azureApiKey}
AZURE_OPENAI_API_VERSION=${azureApiVersion}

# Terahive ESS API Configuration
TERAHIVE_API_BASE_URL=${terahiveBaseUrl}
TERAHIVE_API_KEY=${terahiveApiKey}
TERAHIVE_CLIENT_ID=${terahiveClientId}
TERAHIVE_CLIENT_SECRET=${terahiveClientSecret}

# File Upload Configuration
MAX_FILE_SIZE=10485760
UPLOAD_PATH=./uploads
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp

# Email Configuration
SMTP_HOST=${smtpHost}
SMTP_PORT=${smtpPort}
SMTP_USER=${smtpUser}
SMTP_PASS=${smtpPass}

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
LOG_FILE=./logs/app.log

# Security
BCRYPT_ROUNDS=12
SESSION_SECRET=${require('crypto').randomBytes(32).toString('hex')}
`;

  await fs.writeFile(envPath, envContent);
  console.log('✓ Created .env file');
}

// Test database connection
async function testDatabaseConnection() {
  console.log('\n=== Testing Database Connection ===');
  
  try {
    // Load environment variables
    require('dotenv').config();
    
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    console.log('✓ Database connection successful');
    
    // Test creating a collection
    const testCollection = mongoose.connection.collection('test');
    await testCollection.insertOne({ test: true, timestamp: new Date() });
    await testCollection.deleteOne({ test: true });
    
    console.log('✓ Database write/delete test successful');
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('✗ Database connection failed:', error.message);
    console.log('Please check your MongoDB configuration and try again.');
    process.exit(1);
  }
}

// Create admin user
async function createAdminUser() {
  console.log('\n=== Admin User Setup ===');
  
  const createAdmin = await question('Create an admin user? (y/N): ');
  if (createAdmin.toLowerCase() !== 'y') {
    console.log('Skipping admin user creation');
    return;
  }
  
  try {
    // Load environment variables
    require('dotenv').config();
    
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    
    const User = require('./src/models/User');
    
    const email = await question('Admin email: ');
    const password = await question('Admin password: ');
    const firstName = await question('Admin first name: ');
    const lastName = await question('Admin last name: ');
    const hasTerahiveEss = await question('Does admin have Terahive ESS installed? (y/N): ');
    const userType = hasTerahiveEss.toLowerCase() === 'y' ? 'terahive_ess' : 'regular';
    
    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      console.log('✗ User with this email already exists');
      await mongoose.connection.close();
      return;
    }
    
    // Create admin user
    const adminUser = new User({
      email,
      password,
      firstName,
      lastName,
      userType,
      terahiveEss: {
        isInstalled: hasTerahiveEss.toLowerCase() === 'y',
      },
      isEmailVerified: true,
      isActive: true,
    });
    
    await adminUser.save();
    
    console.log('✓ Admin user created successfully');
    console.log(`Email: ${email}`);
    console.log(`User Type: ${userType}`);
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('✗ Failed to create admin user:', error.message);
  }
}

// Create sample email templates
async function createEmailTemplates() {
  console.log('\n=== Email Templates Setup ===');
  
  const createTemplates = await question('Create sample email templates? (y/N): ');
  if (createTemplates.toLowerCase() !== 'y') {
    console.log('Skipping email templates creation');
    return;
  }
  
  const templatesDir = path.join(process.cwd(), 'src', 'templates', 'emails');
  
  const templates = {
    'emailVerification.html': `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Verify Your Email - {{appName}}</title>
</head>
<body>
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2>Verify Your Email Address</h2>
        <p>Hello {{name}},</p>
        <p>Thank you for registering with {{appName}}. Please click the link below to verify your email address:</p>
        <p><a href="{{verificationUrl}}" style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Verify Email</a></p>
        <p>If you didn't create an account, you can safely ignore this email.</p>
        <p>Best regards,<br>{{appName}} Team</p>
    </div>
</body>
</html>`,
    
    'welcome.html': `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to {{appName}}</title>
</head>
<body>
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2>Welcome to {{appName}}!</h2>
        <p>Hello {{name}},</p>
        <p>Welcome to {{appName}}! We're excited to help you manage and analyze your electricity bills.</p>
        <p>Your account type: <strong>{{userType}}</strong></p>
        <p>If you have any questions, please contact us at {{supportEmail}}.</p>
        <p>Best regards,<br>{{appName}} Team</p>
    </div>
</body>
</html>`,
    
    'billReminder.html': `<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Bill Reminder - {{appName}}</title>
</head>
<body>
    <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
        <h2>Bill Reminder</h2>
        <p>Hello {{name}},</p>
        <p>This is a reminder about your electricity bill:</p>
        <ul>
            <li><strong>Bill Number:</strong> {{billNumber}}</li>
            <li><strong>Utility Provider:</strong> {{utilityProvider}}</li>
            <li><strong>Due Date:</strong> {{dueDate}}</li>
            <li><strong>Amount:</strong> {{amount}}</li>
        </ul>
        <p>Please make sure to pay your bill on time to avoid late fees.</p>
        <p>Best regards,<br>{{appName}} Team</p>
    </div>
</body>
</html>`
  };
  
  for (const [filename, content] of Object.entries(templates)) {
    const filepath = path.join(templatesDir, filename);
    await fs.writeFile(filepath, content);
    console.log(`✓ Created template: ${filename}`);
  }
}

// Main setup function
async function main() {
  console.log('🚀 Electricity Bill App Backend Setup');
  console.log('=====================================\n');
  
  try {
    await createDirectories();
    await createEnvFile();
    await testDatabaseConnection();
    await createAdminUser();
    await createEmailTemplates();
    
    console.log('\n🎉 Setup completed successfully!');
    console.log('\nNext steps:');
    console.log('1. Install dependencies: npm install');
    console.log('2. Start the server: npm run dev');
    console.log('3. Test the API: curl http://localhost:3000/health');
    console.log('\nFor more information, see README.md');
    
  } catch (error) {
    console.error('\n✗ Setup failed:', error.message);
    process.exit(1);
  } finally {
    rl.close();
  }
}

// Run setup
if (require.main === module) {
  main();
}

module.exports = {
  createDirectories,
  createEnvFile,
  testDatabaseConnection,
  createAdminUser,
  createEmailTemplates,
}; 