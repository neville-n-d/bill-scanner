const express = require('express');
const { body, validationResult } = require('express-validator');
const TerahiveSystem = require('../models/TerahiveSystem');
const { auth, requireTerahiveEss } = require('../middleware/auth');
const terahiveService = require('../services/terahiveService');
const logger = require('../utils/logger');

const router = express.Router();

// Validation middleware
const validateSystemSettings = [
  body('backupThreshold')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Backup threshold must be between 0 and 100'),
  body('chargeThreshold')
    .optional()
    .isFloat({ min: 0, max: 100 })
    .withMessage('Charge threshold must be between 0 and 100'),
  body('peakShavingThreshold')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Peak shaving threshold must be a positive number'),
];

// @route   GET /api/terahive/system
// @desc    Get user's Terahive system information
// @access  Private (Terahive ESS users only)
router.get('/system', auth, requireTerahiveEss, async (req, res) => {
  try {
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });
    
    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    res.json({
      success: true,
      data: {
        system,
      },
    });
  } catch (error) {
    logger.error('Get Terahive system error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve system information',
    });
  }
});

// @route   GET /api/terahive/status
// @desc    Get real-time system status
// @access  Private (Terahive ESS users only)
router.get('/status', auth, requireTerahiveEss, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get real-time status from Terahive API
    try {
      const realTimeStatus = await terahiveService.getSystemStatus(
        system.systemId,
        user.terahiveEss.apiCredentials.accessToken
      );

      // Update system status in database
      await system.updateStatus(realTimeStatus);

      res.json({
        success: true,
        data: {
          status: realTimeStatus,
          lastUpdated: system.lastUpdated,
        },
      });
    } catch (apiError) {
      logger.warn('Failed to get real-time status, using cached data:', apiError);
      
      res.json({
        success: true,
        data: {
          status: system.status,
          lastUpdated: system.lastUpdated,
          note: 'Using cached data due to API connection issue',
        },
      });
    }
  } catch (error) {
    logger.error('Get Terahive status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve system status',
    });
  }
});

// @route   GET /api/terahive/historical-data
// @desc    Get historical system data
// @access  Private (Terahive ESS users only)
router.get('/historical-data', auth, requireTerahiveEss, async (req, res) => {
  try {
    const { startDate, endDate, granularity = 'daily' } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date are required',
      });
    }

    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get historical data from Terahive API
    const historicalData = await terahiveService.getHistoricalData(
      system.systemId,
      user.terahiveEss.apiCredentials.accessToken,
      new Date(startDate),
      new Date(endDate),
      granularity
    );

    res.json({
      success: true,
      data: {
        historicalData,
        systemId: system.systemId,
        period: {
          startDate,
          endDate,
          granularity,
        },
      },
    });
  } catch (error) {
    logger.error('Get historical data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve historical data',
    });
  }
});

// @route   GET /api/terahive/alerts
// @desc    Get system alerts
// @access  Private (Terahive ESS users only)
router.get('/alerts', auth, requireTerahiveEss, async (req, res) => {
  try {
    const { activeOnly = 'true' } = req.query;
    
    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get alerts from Terahive API
    const alerts = await terahiveService.getSystemAlerts(
      system.systemId,
      user.terahiveEss.apiCredentials.accessToken,
      activeOnly === 'true'
    );

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

// @route   POST /api/terahive/alerts/:alertId/acknowledge
// @desc    Acknowledge an alert
// @access  Private (Terahive ESS users only)
router.post('/alerts/:alertId/acknowledge', auth, requireTerahiveEss, [
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

    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Acknowledge alert via API
    await terahiveService.acknowledgeAlert(
      system.systemId,
      alertId,
      user.terahiveEss.apiCredentials.accessToken,
      resolution
    );

    // Update local alert record
    await system.acknowledgeAlert(alertId, req.user.userId, resolution);

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

// @route   GET /api/terahive/performance
// @desc    Get system performance metrics
// @access  Private (Terahive ESS users only)
router.get('/performance', auth, requireTerahiveEss, async (req, res) => {
  try {
    const { period = 'monthly' } = req.query;

    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get performance metrics from Terahive API
    const performanceMetrics = await terahiveService.getPerformanceMetrics(
      system.systemId,
      user.terahiveEss.apiCredentials.accessToken,
      period
    );

    res.json({
      success: true,
      data: {
        performance: performanceMetrics,
        period,
        systemId: system.systemId,
      },
    });
  } catch (error) {
    logger.error('Get performance metrics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve performance metrics',
    });
  }
});

// @route   GET /api/terahive/financial
// @desc    Get financial metrics
// @access  Private (Terahive ESS users only)
router.get('/financial', auth, requireTerahiveEss, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return res.status(400).json({
        success: false,
        message: 'Start date and end date are required',
      });
    }

    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get financial metrics from Terahive API
    const financialMetrics = await terahiveService.getFinancialMetrics(
      system.systemId,
      user.terahiveEss.apiCredentials.accessToken,
      new Date(startDate),
      new Date(endDate)
    );

    res.json({
      success: true,
      data: {
        financial: financialMetrics,
        period: {
          startDate,
          endDate,
        },
        systemId: system.systemId,
      },
    });
  } catch (error) {
    logger.error('Get financial metrics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve financial metrics',
    });
  }
});

// @route   PUT /api/terahive/settings
// @desc    Update system settings
// @access  Private (Terahive ESS users only)
router.put('/settings', auth, requireTerahiveEss, validateSystemSettings, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const user = await User.findById(req.user.userId);
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Update settings via Terahive API
    await terahiveService.updateSystemSettings(
      system.systemId,
      user.terahiveEss.apiCredentials.accessToken,
      req.body
    );

    // Update local settings
    if (req.body.settings) {
      system.settings = {
        ...system.settings,
        ...req.body.settings,
      };
      await system.save();
    }

    res.json({
      success: true,
      message: 'System settings updated successfully',
      data: {
        settings: system.settings,
      },
    });
  } catch (error) {
    logger.error('Update settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update system settings',
    });
  }
});

// @route   POST /api/terahive/sync
// @desc    Manually sync system data
// @access  Private (Terahive ESS users only)
router.post('/sync', auth, requireTerahiveEss, async (req, res) => {
  try {
    // Sync system data
    const system = await terahiveService.syncUserSystem(req.user.userId);

    res.json({
      success: true,
      message: 'System data synced successfully',
      data: {
        system,
        lastSync: system.lastUpdated,
      },
    });
  } catch (error) {
    logger.error('Sync system error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync system data',
    });
  }
});

// @route   GET /api/terahive/health
// @desc    Get system health information
// @access  Private (Terahive ESS users only)
router.get('/health', auth, requireTerahiveEss, async (req, res) => {
  try {
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });

    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    res.json({
      success: true,
      data: {
        health: system.health,
        systemAge: system.systemAge,
        warrantyStatus: system.warrantyStatus,
        lastHealthCheck: system.health.lastHealthCheck,
        nextHealthCheck: system.health.nextHealthCheck,
      },
    });
  } catch (error) {
    logger.error('Get system health error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve system health',
    });
  }
});

module.exports = router; 