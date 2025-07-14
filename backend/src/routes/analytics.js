const express = require('express');
const Bill = require('../models/Bill');
const User = require('../models/User');
const TerahiveSystem = require('../models/TerahiveSystem');
const { auth, optionalAuth } = require('../middleware/auth');
const aiService = require('../services/aiService');
const logger = require('../utils/logger');

const router = express.Router();

// @route   GET /api/analytics/overview
// @desc    Get analytics overview for user
// @access  Private
router.get('/overview', auth, async (req, res) => {
  try {
    const { period = '12months' } = req.query;
    
    // Calculate date range
    const endDate = new Date();
    const startDate = new Date();
    
    switch (period) {
      case '3months':
        startDate.setMonth(endDate.getMonth() - 3);
        break;
      case '6months':
        startDate.setMonth(endDate.getMonth() - 6);
        break;
      case '12months':
        startDate.setFullYear(endDate.getFullYear() - 1);
        break;
      case '24months':
        startDate.setFullYear(endDate.getFullYear() - 2);
        break;
      default:
        startDate.setFullYear(endDate.getFullYear() - 1);
    }

    // Get bills for the period
    const bills = await Bill.find({
      userId: req.user.userId,
      billDate: { $gte: startDate, $lte: endDate },
      status: { $in: ['processed', 'verified'] },
    }).sort({ billDate: 1 });

    // Calculate analytics
    const analytics = calculateAnalytics(bills, period);

    res.json({
      success: true,
      data: {
        analytics,
        period,
        dateRange: {
          startDate,
          endDate,
        },
        totalBills: bills.length,
      },
    });
  } catch (error) {
    logger.error('Get analytics overview error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve analytics overview',
    });
  }
});

// @route   GET /api/analytics/consumption
// @desc    Get consumption analytics
// @access  Private
router.get('/consumption', auth, async (req, res) => {
  try {
    const { granularity = 'monthly', startDate, endDate } = req.query;

    const query = { userId: req.user.userId };
    
    if (startDate && endDate) {
      query.billDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const bills = await Bill.find(query)
      .sort({ billDate: 1 })
      .select('billDate consumption billingPeriod');

    // Group by granularity
    const consumptionData = groupConsumptionByGranularity(bills, granularity);

    res.json({
      success: true,
      data: {
        consumption: consumptionData,
        granularity,
        totalConsumption: bills.reduce((sum, bill) => sum + (bill.consumption.total || 0), 0),
        averageConsumption: bills.length > 0 
          ? bills.reduce((sum, bill) => sum + (bill.consumption.total || 0), 0) / bills.length 
          : 0,
      },
    });
  } catch (error) {
    logger.error('Get consumption analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve consumption analytics',
    });
  }
});

// @route   GET /api/analytics/costs
// @desc    Get cost analytics
// @access  Private
router.get('/costs', auth, async (req, res) => {
  try {
    const { granularity = 'monthly', startDate, endDate } = req.query;

    const query = { userId: req.user.userId };
    
    if (startDate && endDate) {
      query.billDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      };
    }

    const bills = await Bill.find(query)
      .sort({ billDate: 1 })
      .select('billDate costs billingPeriod');

    // Group by granularity
    const costData = groupCostsByGranularity(bills, granularity);

    res.json({
      success: true,
      data: {
        costs: costData,
        granularity,
        totalCost: bills.reduce((sum, bill) => sum + (bill.costs.total || 0), 0),
        averageCost: bills.length > 0 
          ? bills.reduce((sum, bill) => sum + (bill.costs.total || 0), 0) / bills.length 
          : 0,
      },
    });
  } catch (error) {
    logger.error('Get cost analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve cost analytics',
    });
  }
});

// @route   GET /api/analytics/trends
// @desc    Get trend analysis
// @access  Private
router.get('/trends', auth, async (req, res) => {
  try {
    const { months = 12 } = req.query;

    const endDate = new Date();
    const startDate = new Date();
    startDate.setMonth(endDate.getMonth() - parseInt(months));

    const bills = await Bill.find({
      userId: req.user.userId,
      billDate: { $gte: startDate, $lte: endDate },
      status: { $in: ['processed', 'verified'] },
    }).sort({ billDate: 1 });

    // Analyze trends using AI
    const trendAnalysis = await aiService.analyzeTrends(bills);

    res.json({
      success: true,
      data: {
        trends: trendAnalysis,
        period: {
          months: parseInt(months),
          startDate,
          endDate,
        },
        totalBills: bills.length,
      },
    });
  } catch (error) {
    logger.error('Get trends analysis error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve trend analysis',
    });
  }
});

// @route   GET /api/analytics/comparison
// @desc    Compare periods
// @access  Private
router.get('/comparison', auth, async (req, res) => {
  try {
    const { period1, period2 } = req.query;

    if (!period1 || !period2) {
      return res.status(400).json({
        success: false,
        message: 'Both period1 and period2 are required',
      });
    }

    // Parse periods (format: YYYY-MM to YYYY-MM)
    const [start1, end1] = period1.split(' to ');
    const [start2, end2] = period2.split(' to ');

    const bills1 = await Bill.find({
      userId: req.user.userId,
      billDate: {
        $gte: new Date(start1),
        $lte: new Date(end1),
      },
      status: { $in: ['processed', 'verified'] },
    });

    const bills2 = await Bill.find({
      userId: req.user.userId,
      billDate: {
        $gte: new Date(start2),
        $lte: new Date(end2),
      },
      status: { $in: ['processed', 'verified'] },
    });

    const comparison = comparePeriods(bills1, bills2, period1, period2);

    res.json({
      success: true,
      data: {
        comparison,
        periods: {
          period1: { start: start1, end: end1, bills: bills1.length },
          period2: { start: start2, end: end2, bills: bills2.length },
        },
      },
    });
  } catch (error) {
    logger.error('Get comparison analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve comparison analytics',
    });
  }
});

// @route   GET /api/analytics/terahive
// @desc    Get Terahive ESS specific analytics
// @access  Private (Terahive ESS users only)
router.get('/terahive', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    
    if (user.userType !== 'terahive_ess' || !user.hasTerahiveEss) {
      return res.status(403).json({
        success: false,
        message: 'Terahive ESS access required',
      });
    }

    const { period = '12months' } = req.query;

    // Get Terahive system
    const system = await TerahiveSystem.findOne({ userId: req.user.userId });
    if (!system) {
      return res.status(404).json({
        success: false,
        message: 'Terahive system not found',
      });
    }

    // Get bills with Terahive integration
    const endDate = new Date();
    const startDate = new Date();
    startDate.setFullYear(endDate.getFullYear() - 1);

    const bills = await Bill.find({
      userId: req.user.userId,
      'terahiveEss.isIntegrated': true,
      billDate: { $gte: startDate, $lte: endDate },
    }).sort({ billDate: 1 });

    // Calculate Terahive-specific analytics
    const terahiveAnalytics = calculateTerahiveAnalytics(bills, system);

    res.json({
      success: true,
      data: {
        terahiveAnalytics,
        system: {
          systemId: system.systemId,
          systemName: system.systemName,
          capacity: system.specifications.batteryCapacity,
          installationDate: system.installation.date,
        },
        period,
        totalBills: bills.length,
      },
    });
  } catch (error) {
    logger.error('Get Terahive analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve Terahive analytics',
    });
  }
});

// @route   GET /api/analytics/insights
// @desc    Get AI-generated insights
// @access  Private
router.get('/insights', auth, async (req, res) => {
  try {
    const { limit = 10 } = req.query;

    // Get recent bills
    const bills = await Bill.find({
      userId: req.user.userId,
      status: { $in: ['processed', 'verified'] },
    })
      .sort({ billDate: -1 })
      .limit(parseInt(limit));

    if (bills.length === 0) {
      return res.json({
        success: true,
        data: {
          insights: [],
          message: 'No bills available for analysis',
        },
      });
    }

    // Aggregate insights from all bills
    const allInsights = bills.flatMap(bill => bill.aiAnalysis.insights || []);
    const allRecommendations = bills.flatMap(bill => bill.aiAnalysis.recommendations || []);

    // Group and prioritize insights
    const insights = groupAndPrioritizeInsights(allInsights);
    const recommendations = groupAndPrioritizeRecommendations(allRecommendations);

    res.json({
      success: true,
      data: {
        insights,
        recommendations,
        totalInsights: allInsights.length,
        totalRecommendations: allRecommendations.length,
        analyzedBills: bills.length,
      },
    });
  } catch (error) {
    logger.error('Get insights error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve insights',
    });
  }
});

// Helper functions

function calculateAnalytics(bills, period) {
  if (bills.length === 0) {
    return {
      totalConsumption: 0,
      totalCost: 0,
      averageConsumption: 0,
      averageCost: 0,
      consumptionTrend: 'stable',
      costTrend: 'stable',
      peakConsumption: 0,
      peakCost: 0,
      efficiency: 0,
    };
  }

  const totalConsumption = bills.reduce((sum, bill) => sum + (bill.consumption.total || 0), 0);
  const totalCost = bills.reduce((sum, bill) => sum + (bill.costs.total || 0), 0);
  const averageConsumption = totalConsumption / bills.length;
  const averageCost = totalCost / bills.length;

  // Calculate trends
  const consumptionTrend = calculateTrend(bills.map(bill => bill.consumption.total));
  const costTrend = calculateTrend(bills.map(bill => bill.costs.total));

  // Find peaks
  const peakConsumption = Math.max(...bills.map(bill => bill.consumption.total || 0));
  const peakCost = Math.max(...bills.map(bill => bill.costs.total || 0));

  // Calculate efficiency (cost per kWh)
  const efficiency = totalCost / totalConsumption;

  return {
    totalConsumption,
    totalCost,
    averageConsumption,
    averageCost,
    consumptionTrend,
    costTrend,
    peakConsumption,
    peakCost,
    efficiency,
  };
}

function calculateTrend(values) {
  if (values.length < 2) return 'stable';
  
  const firstHalf = values.slice(0, Math.floor(values.length / 2));
  const secondHalf = values.slice(Math.floor(values.length / 2));
  
  const firstAvg = firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length;
  const secondAvg = secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length;
  
  const change = ((secondAvg - firstAvg) / firstAvg) * 100;
  
  if (change > 5) return 'increasing';
  if (change < -5) return 'decreasing';
  return 'stable';
}

function groupConsumptionByGranularity(bills, granularity) {
  const grouped = {};
  
  bills.forEach(bill => {
    let key;
    const date = new Date(bill.billDate);
    
    switch (granularity) {
      case 'daily':
        key = date.toISOString().split('T')[0];
        break;
      case 'weekly':
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = weekStart.toISOString().split('T')[0];
        break;
      case 'monthly':
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        break;
      case 'quarterly':
        const quarter = Math.floor(date.getMonth() / 3) + 1;
        key = `${date.getFullYear()}-Q${quarter}`;
        break;
      case 'yearly':
        key = date.getFullYear().toString();
        break;
      default:
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    }
    
    if (!grouped[key]) {
      grouped[key] = {
        period: key,
        consumption: 0,
        bills: 0,
      };
    }
    
    grouped[key].consumption += bill.consumption.total || 0;
    grouped[key].bills += 1;
  });
  
  return Object.values(grouped).sort((a, b) => a.period.localeCompare(b.period));
}

function groupCostsByGranularity(bills, granularity) {
  const grouped = {};
  
  bills.forEach(bill => {
    let key;
    const date = new Date(bill.billDate);
    
    switch (granularity) {
      case 'daily':
        key = date.toISOString().split('T')[0];
        break;
      case 'weekly':
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = weekStart.toISOString().split('T')[0];
        break;
      case 'monthly':
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
        break;
      case 'quarterly':
        const quarter = Math.floor(date.getMonth() / 3) + 1;
        key = `${date.getFullYear()}-Q${quarter}`;
        break;
      case 'yearly':
        key = date.getFullYear().toString();
        break;
      default:
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
    }
    
    if (!grouped[key]) {
      grouped[key] = {
        period: key,
        cost: 0,
        bills: 0,
      };
    }
    
    grouped[key].cost += bill.costs.total || 0;
    grouped[key].bills += 1;
  });
  
  return Object.values(grouped).sort((a, b) => a.period.localeCompare(b.period));
}

function comparePeriods(bills1, bills2, period1Label, period2Label) {
  const period1Stats = calculateAnalytics(bills1);
  const period2Stats = calculateAnalytics(bills2);
  
  const consumptionChange = ((period2Stats.totalConsumption - period1Stats.totalConsumption) / period1Stats.totalConsumption) * 100;
  const costChange = ((period2Stats.totalCost - period1Stats.totalCost) / period1Stats.totalCost) * 100;
  
  return {
    period1: {
      label: period1Label,
      ...period1Stats,
    },
    period2: {
      label: period2Label,
      ...period2Stats,
    },
    changes: {
      consumptionChange,
      costChange,
      efficiencyChange: period2Stats.efficiency - period1Stats.efficiency,
    },
  };
}

function calculateTerahiveAnalytics(bills, system) {
  const totalSavings = bills.reduce((sum, bill) => sum + (bill.terahiveEss.savings.totalSavings || 0), 0);
  const totalBatteryDischarge = bills.reduce((sum, bill) => sum + (bill.terahiveEss.batteryData.totalDischarge || 0), 0);
  const totalGridExport = bills.reduce((sum, bill) => sum + (bill.terahiveEss.gridInteraction.gridExport || 0), 0);
  
  return {
    totalSavings,
    totalBatteryDischarge,
    totalGridExport,
    averageSavingsPerBill: bills.length > 0 ? totalSavings / bills.length : 0,
    systemEfficiency: system.performance.efficiency.roundTrip || 0,
    systemAvailability: system.performance.availability || 0,
    roi: system.financial.roi || 0,
    paybackPeriod: system.financial.paybackPeriod || 0,
  };
}

function groupAndPrioritizeInsights(insights) {
  const grouped = {};
  
  insights.forEach(insight => {
    if (!grouped[insight.category]) {
      grouped[insight.category] = [];
    }
    grouped[insight.category].push(insight);
  });
  
  // Sort by severity and return top insights
  return Object.entries(grouped)
    .map(([category, categoryInsights]) => ({
      category,
      insights: categoryInsights
        .sort((a, b) => {
          const severityOrder = { alert: 3, warning: 2, info: 1 };
          return severityOrder[b.severity] - severityOrder[a.severity];
        })
        .slice(0, 5), // Top 5 per category
    }))
    .filter(category => category.insights.length > 0);
}

function groupAndPrioritizeRecommendations(recommendations) {
  const grouped = {};
  
  recommendations.forEach(rec => {
    if (!grouped[rec.category]) {
      grouped[rec.category] = [];
    }
    grouped[rec.category].push(rec);
  });
  
  // Sort by priority and estimated savings
  return Object.entries(grouped)
    .map(([category, categoryRecs]) => ({
      category,
      recommendations: categoryRecs
        .sort((a, b) => {
          const priorityOrder = { high: 3, medium: 2, low: 1 };
          return priorityOrder[b.priority] - priorityOrder[a.priority] || 
                 (b.estimatedSavings || 0) - (a.estimatedSavings || 0);
        })
        .slice(0, 3), // Top 3 per category
    }))
    .filter(category => category.recommendations.length > 0);
}

module.exports = router; 