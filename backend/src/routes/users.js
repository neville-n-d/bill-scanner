const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth, requireUserType } = require('../middleware/auth');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateProfileUpdate = [
  body('firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('First name must be between 2 and 50 characters'),
  body('lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Last name must be between 2 and 50 characters'),
  body('phone')
    .optional()
    .matches(/^\+?[\d\s-()]+$/)
    .withMessage('Please provide a valid phone number'),
];

const validatePreferences = [
  body('preferences.currency')
    .optional()
    .isIn(['USD', 'EUR', 'GBP', 'CAD', 'AUD'])
    .withMessage('Invalid currency'),
  body('preferences.energyUnit')
    .optional()
    .isIn(['kWh', 'MWh', 'GJ'])
    .withMessage('Invalid energy unit'),
  body('preferences.language')
    .optional()
    .isIn(['en', 'es', 'fr', 'de'])
    .withMessage('Invalid language'),
];

// @route   GET /api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          userType: user.userType,
          hasTerahiveEss: user.hasTerahiveEss,
          isEmailVerified: user.isEmailVerified,
          preferences: user.preferences,
          statistics: user.statistics,
          subscription: user.subscription,
          terahiveEss: user.terahiveEss,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin,
        },
      },
    });
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve profile',
    });
  }
});

// @route   PUT /api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', auth, validateProfileUpdate, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { firstName, lastName, phone } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Update fields
    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (phone !== undefined) user.phone = phone;

    await user.save();

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: {
          id: user._id,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          phone: user.phone,
          userType: user.userType,
          hasTerahiveEss: user.hasTerahiveEss,
        },
      },
    });
  } catch (error) {
    logger.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile',
    });
  }
});

// @route   PUT /api/users/preferences
// @desc    Update user preferences
// @access  Private
router.put('/preferences', auth, validatePreferences, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { preferences } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Update preferences
    if (preferences) {
      user.preferences = {
        ...user.preferences,
        ...preferences,
      };
    }

    await user.save();

    res.json({
      success: true,
      message: 'Preferences updated successfully',
      data: {
        preferences: user.preferences,
      },
    });
  } catch (error) {
    logger.error('Update preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update preferences',
    });
  }
});

// @route   PUT /api/users/password
// @desc    Change user password
// @access  Private
router.put('/password', auth, [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('New password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'),
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await user.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect',
      });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error) {
    logger.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password',
    });
  }
});

// @route   PUT /api/users/terahive-status
// @desc    Update Terahive ESS installation status
// @access  Private
router.put('/terahive-status', auth, [
  body('hasTerahiveEss')
    .isBoolean()
    .withMessage('hasTerahiveEss must be a boolean value'),
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { hasTerahiveEss } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Update Terahive ESS installation status
    user.terahiveEss.isInstalled = hasTerahiveEss;
    user.userType = hasTerahiveEss ? 'terahive_ess' : 'regular';

    // If user is removing Terahive ESS, clear system data
    if (!hasTerahiveEss) {
      user.terahiveEss = {
        isInstalled: false,
        // Keep basic structure but clear system-specific data
      };
    }

    await user.save();

    res.json({
      success: true,
      message: `Terahive ESS status updated successfully`,
      data: {
        hasTerahiveEss: user.terahiveEss.isInstalled,
        userType: user.userType,
      },
    });
  } catch (error) {
    logger.error('Update Terahive status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update Terahive ESS status',
    });
  }
});

// @route   POST /api/users/terahive-setup
// @desc    Setup Terahive ESS integration
// @access  Private
router.post('/terahive-setup', auth, async (req, res) => {
  try {
    const {
      systemId,
      systemName,
      capacity,
      batteryType,
      inverterPower,
      installationDate,
      location,
      apiCredentials,
    } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if user has Terahive ESS installed
    if (!user.terahiveEss.isInstalled) {
      return res.status(400).json({
        success: false,
        message: 'Terahive ESS is not installed for this user',
      });
    }

    // Check if system ID is already in use
    const existingSystem = await User.findOne({
      'terahiveEss.systemId': systemId,
      _id: { $ne: user._id },
    });

    if (existingSystem) {
      return res.status(400).json({
        success: false,
        message: 'System ID is already registered with another user',
      });
    }

    // Update user's Terahive ESS information
    user.terahiveEss = {
      ...user.terahiveEss,
      installationDate: installationDate ? new Date(installationDate) : new Date(),
      systemId: systemId || user.terahiveEss.systemId,
      systemName: systemName || user.terahiveEss.systemName,
      capacity: capacity || user.terahiveEss.capacity,
      batteryType: batteryType || user.terahiveEss.batteryType,
      inverterPower: inverterPower || user.terahiveEss.inverterPower,
      location: location || user.terahiveEss.location || {},
      apiCredentials: apiCredentials || user.terahiveEss.apiCredentials || {},
      lastSync: new Date(),
      syncStatus: 'active',
    };

    await user.save();

    res.json({
      success: true,
      message: 'Terahive ESS setup completed successfully',
      data: {
        terahiveEss: user.terahiveEss,
      },
    });
  } catch (error) {
    logger.error('Terahive setup error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to setup Terahive ESS',
    });
  }
});

// @route   GET /api/users/statistics
// @desc    Get user statistics
// @access  Private
router.get('/statistics', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.json({
      success: true,
      data: {
        statistics: user.statistics,
        hasTerahiveEss: user.hasTerahiveEss,
        userType: user.userType,
      },
    });
  } catch (error) {
    logger.error('Get statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve statistics',
    });
  }
});

// @route   DELETE /api/users/account
// @desc    Delete user account
// @access  Private
router.delete('/account', auth, [
  body('password')
    .notEmpty()
    .withMessage('Password is required for account deletion'),
], async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { password } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Password is incorrect',
      });
    }

    // Deactivate user instead of deleting (for data retention)
    user.isActive = false;
    await user.save();

    res.json({
      success: true,
      message: 'Account deactivated successfully',
    });
  } catch (error) {
    logger.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete account',
    });
  }
});

module.exports = router; 