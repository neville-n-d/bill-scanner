console.log('Starting simple test...');

// Test basic imports
try {
  console.log('Testing express...');
  const express = require('express');
  console.log('Express OK');
  
  console.log('Testing mongoose...');
  const mongoose = require('mongoose');
  console.log('Mongoose OK');
  
  console.log('Testing logger...');
  const logger = require('./src/utils/logger');
  console.log('Logger OK');
  
  console.log('Testing error handler...');
  const errorHandler = require('./src/middleware/errorHandler');
  console.log('ErrorHandler OK');
  
  console.log('Testing User model...');
  const User = require('./src/models/User');
  console.log('User model OK');
  
  console.log('Testing auth middleware...');
  const auth = require('./src/middleware/auth');
  console.log('Auth middleware OK');
  
  console.log('Testing auth routes...');
  const authRoutes = require('./src/routes/auth');
  console.log('Auth routes OK');
  
  console.log('All tests passed!');
} catch (error) {
  console.error('Error:', error.message);
  console.error('Stack:', error.stack);
} 