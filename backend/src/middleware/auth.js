const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../utils/logger');

const auth = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.header('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token, authorization denied',
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Check if user still exists
    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Token is not valid - user not found',
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated',
      });
    }

    // Add user info to request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      userType: decoded.userType,
      hasTerahiveEss: decoded.hasTerahiveEss,
    };

    next();
  } catch (error) {
    logger.error('Auth middleware error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Token is not valid',
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired',
      });
    }

    res.status(500).json({
      success: false,
      message: 'Server error in authentication',
    });
  }
};

// Optional auth middleware - doesn't fail if no token
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const user = await User.findById(decoded.userId).select('-password');
    if (user && user.isActive) {
      req.user = {
        userId: decoded.userId,
        email: decoded.email,
        userType: decoded.userType,
        hasTerahiveEss: decoded.hasTerahiveEss,
      };
    }

    next();
  } catch (error) {
    // Don't fail the request for optional auth
    next();
  }
};

// Role-based authorization middleware
const requireUserType = (allowedTypes) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    if (!allowedTypes.includes(req.user.userType)) {
      return res.status(403).json({
        success: false,
        message: 'Access denied - insufficient permissions',
      });
    }

    next();
  };
};

// Terahive ESS specific middleware
const requireTerahiveEss = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    if (req.user.userType !== 'terahive_ess') {
      return res.status(403).json({
        success: false,
        message: 'Terahive ESS account required',
      });
    }

    // Check if user has Terahive ESS installed
    const user = await User.findById(req.user.userId);
    if (!user.terahiveEss.isInstalled) {
      return res.status(403).json({
        success: false,
        message: 'Terahive ESS system not installed',
      });
    }

    next();
  } catch (error) {
    logger.error('Terahive ESS middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Server error',
    });
  }
};

module.exports = {
  auth,
  optionalAuth,
  requireUserType,
  requireTerahiveEss,
}; 