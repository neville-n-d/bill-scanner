const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const TerahiveSystem = require('../models/TerahiveSystem');
const { auth } = require('../middleware/auth');
const EmailService = require('../utils/email');
const logger = require('../utils/logger');

// Initialize email service
const emailService = new EmailService();

const router = express.Router();

// Validation middleware
const validateNotificationSettings = [
  body('notifications.email')
    .optional()
    .isBoolean()
    .withMessage('Email notifications must be a boolean'),
  body('notifications.push')
    .optional()
    .isBoolean()
    .withMessage('Push notifications must be a boolean'),
  body('notifications.sms')
    .optional()
    .isBoolean()
    .withMessage('SMS notifications must be a boolean'),
  body('notifications.billReminders')
    .optional()
    .isBoolean()
    .withMessage('Bill reminders must be a boolean'),
  body('notifications.energyAlerts')
    .optional()
    .isBoolean()
    .withMessage('Energy alerts must be a boolean'),
  body('notifications.systemAlerts')
    .optional()
    .isBoolean()
    .withMessage('System alerts must be a boolean'),
];

// @route   GET /api/notifications/settings
// @desc    Get user notification settings
// @access  Private
router.get('/settings', auth, async (req, res) => {
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
        notifications: user.preferences.notifications,
      },
    });
  } catch (error) {
    logger.error('Get notification settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve notification settings',
    });
  }
});

// @route   PUT /api/notifications/settings
// @desc    Update user notification settings
// @access  Private
router.put('/settings', auth, validateNotificationSettings, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const { notifications } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Update notification settings
    user.preferences.notifications = {
      ...user.preferences.notifications,
      ...notifications,
    };

    await user.save();

    res.json({
      success: true,
      message: 'Notification settings updated successfully',
      data: {
        notifications: user.preferences.notifications,
      },
    });
  } catch (error) {
    logger.error('Update notification settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update notification settings',
    });
  }
});

// @route   GET /api/notifications/alerts
// @desc    Get user alerts
// @access  Private
router.get('/alerts', auth, async (req, res) => {
  try {
    const { active = 'true', limit = 50 } = req.query;

    let alerts = [];

    // Get Terahive system alerts if user has Terahive ESS
    const user = await User.findById(req.user.userId);
    if (user.userType === 'terahive_ess' && user.hasTerahiveEss) {
      const system = await TerahiveSystem.findOne({ userId: req.user.userId });
      if (system) {
        const systemAlerts = system.alerts
          .filter(alert => active === 'true' ? alert.isActive : true)
          .map(alert => ({
            id: alert.id,
            type: 'system',
            category: alert.type,
            severity: alert.severity,
            title: alert.title,
            message: alert.message,
            timestamp: alert.timestamp,
            isActive: alert.isActive,
            isAcknowledged: alert.isAcknowledged,
            resolution: alert.resolution,
            source: 'terahive_system',
          }));
        
        alerts = alerts.concat(systemAlerts);
      }
    }

    // Sort by timestamp (newest first) and limit
    alerts.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    alerts = alerts.slice(0, parseInt(limit));

    res.json({
      success: true,
      data: {
        alerts,
        totalAlerts: alerts.length,
        activeAlerts: alerts.filter(alert => alert.isActive).length,
      },
    });
  } catch (error) {
    logger.error('Get alerts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve alerts',
    });
  }
});

// @route   POST /api/notifications/alerts/:alertId/acknowledge
// @desc    Acknowledge an alert
// @access  Private
router.post('/alerts/:alertId/acknowledge', auth, [
  body('resolution')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Resolution must be less than 500 characters'),
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

    const { alertId } = req.params;
    const { resolution = '' } = req.body;

    // Find and acknowledge the alert
    const user = await User.findById(req.user.userId);
    if (user.userType === 'terahive_ess' && user.hasTerahiveEss) {
      const system = await TerahiveSystem.findOne({ userId: req.user.userId });
      if (system) {
        await system.acknowledgeAlert(alertId, req.user.userId, resolution);
      }
    }

    res.json({
      success: true,
      message: 'Alert acknowledged successfully',
    });
  } catch (error) {
    logger.error('Acknowledge alert error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to acknowledge alert',
    });
  }
});

// @route   POST /api/notifications/test-email
// @desc    Send test email notification
// @access  Private
router.post('/test-email', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (!user.preferences.notifications.email) {
      return res.status(400).json({
        success: false,
        message: 'Email notifications are disabled',
      });
    }

    // Send test email
    await emailService.sendEmail({
      to: user.email,
      subject: 'Test Notification - Electricity Bill App',
      template: 'testNotification',
      data: {
        name: user.firstName,
        timestamp: new Date().toISOString(),
      },
    });

    res.json({
      success: true,
      message: 'Test email sent successfully',
    });
  } catch (error) {
    logger.error('Send test email error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send test email',
    });
  }
});

// @route   POST /api/notifications/bill-reminder
// @desc    Send bill reminder notification
// @access  Private
router.post('/bill-reminder', auth, [
  body('billId')
    .notEmpty()
    .withMessage('Bill ID is required'),
  body('reminderType')
    .isIn(['due_soon', 'overdue', 'payment_confirmed'])
    .withMessage('Invalid reminder type'),
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

    const { billId, reminderType } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if user has enabled bill reminders
    if (!user.preferences.notifications.billReminders) {
      return res.status(400).json({
        success: false,
        message: 'Bill reminders are disabled',
      });
    }

    // Get bill information
    const Bill = require('../models/Bill');
    const bill = await Bill.findOne({
      _id: billId,
      userId: req.user.userId,
    });

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found',
      });
    }

    // Send bill reminder email
    if (user.preferences.notifications.email) {
      await emailService.sendEmail({
        to: user.email,
        subject: `Bill Reminder - ${reminderType.replace('_', ' ').toUpperCase()}`,
        template: 'billReminder',
        data: {
          name: user.firstName,
          billNumber: bill.billNumber,
          dueDate: bill.dueDate,
          amount: bill.costs.total,
          reminderType,
          utilityProvider: bill.utilityProvider.name,
        },
      });
    }

    res.json({
      success: true,
      message: 'Bill reminder sent successfully',
    });
  } catch (error) {
    logger.error('Send bill reminder error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send bill reminder',
    });
  }
});

// @route   POST /api/notifications/energy-alert
// @desc    Send energy consumption alert
// @access  Private
router.post('/energy-alert', auth, [
  body('alertType')
    .isIn(['high_consumption', 'unusual_pattern', 'cost_spike', 'efficiency_tip'])
    .withMessage('Invalid alert type'),
  body('data')
    .isObject()
    .withMessage('Alert data is required'),
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

    const { alertType, data } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    // Check if user has enabled energy alerts
    if (!user.preferences.notifications.energyAlerts) {
      return res.status(400).json({
        success: false,
        message: 'Energy alerts are disabled',
      });
    }

    // Send energy alert email
    if (user.preferences.notifications.email) {
      await emailService.sendEmail({
        to: user.email,
        subject: `Energy Alert - ${alertType.replace('_', ' ').toUpperCase()}`,
        template: 'energyAlert',
        data: {
          name: user.firstName,
          alertType,
          ...data,
          timestamp: new Date().toISOString(),
        },
      });
    }

    res.json({
      success: true,
      message: 'Energy alert sent successfully',
    });
  } catch (error) {
    logger.error('Send energy alert error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send energy alert',
    });
  }
});

// @route   POST /api/notifications/system-alert
// @desc    Send Terahive system alert
// @access  Private (Terahive ESS users only)
router.post('/system-alert', auth, [
  body('alertType')
    .isIn(['system_offline', 'maintenance_required', 'performance_issue', 'battery_low'])
    .withMessage('Invalid alert type'),
  body('data')
    .isObject()
    .withMessage('Alert data is required'),
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

    const { alertType, data } = req.body;

    const user = await User.findById(req.user.userId);
    if (!user || user.userType !== 'terahive_ess' || !user.hasTerahiveEss) {
      return res.status(403).json({
        success: false,
        message: 'Terahive ESS access required',
      });
    }

    // Check if user has enabled system alerts
    if (!user.preferences.notifications.systemAlerts) {
      return res.status(400).json({
        success: false,
        message: 'System alerts are disabled',
      });
    }

    // Get system information
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });
    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Send system alert email
    if (user.preferences.notifications.email) {
      await emailService.sendEmail({
        to: user.email,
        subject: `System Alert - ${alertType.replace('_', ' ').toUpperCase()}`,
        data: {
          name: user.firstName,
          systemName: system.systemName,
          alertType,
          ...data,
          timestamp: new Date().toISOString(),
        },
      });
    }

    res.json({
      success: true,
      message: 'System alert sent successfully',
    });
  } catch (error) {
    logger.error('Send system alert error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send system alert',
    });
  }
});

module.exports = router; 