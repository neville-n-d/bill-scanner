const mongoose = require('mongoose');

const billSchema = new mongoose.Schema({
  // User reference
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  
  // Bill identification
  billNumber: {
    type: String,
    required: true,
    trim: true,
  },
  utilityProvider: {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    code: String,
    website: String,
    phone: String,
  },
  
  // Bill details
  billDate: {
    type: Date,
    required: true,
  },
  dueDate: {
    type: Date,
    required: true,
  },
  billingPeriod: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
  },
  
  // Consumption and costs
  consumption: {
    total: {
      type: Number,
      required: true,
      min: 0,
    },
    unit: {
      type: String,
      default: 'kWh',
      enum: ['kWh', 'MWh', 'GJ'],
    },
    previousReading: Number,
    currentReading: Number,
    peakDemand: Number, // in kW
    offPeakDemand: Number, // in kW
  },
  
  // Cost breakdown
  costs: {
    total: {
      type: Number,
      required: true,
      min: 0,
    },
    currency: {
      type: String,
      default: 'USD',
      enum: ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
    },
    energyCharge: {
      type: Number,
      default: 0,
    },
    deliveryCharge: {
      type: Number,
      default: 0,
    },
    taxes: {
      type: Number,
      default: 0,
    },
    fees: {
      type: Number,
      default: 0,
    },
    demandCharge: {
      type: Number,
      default: 0,
    },
    renewableEnergyCharge: {
      type: Number,
      default: 0,
    },
  },
  
  // Rate information
  rates: {
    energyRate: {
      type: Number,
      default: 0, // per kWh
    },
    demandRate: {
      type: Number,
      default: 0, // per kW
    },
    deliveryRate: {
      type: Number,
      default: 0, // per kWh
    },
    fixedCharge: {
      type: Number,
      default: 0,
    },
  },
  
  // Terahive ESS specific data
  terahiveEss: {
    isIntegrated: {
      type: Boolean,
      default: false,
    },
    systemId: {
      type: String,
      ref: 'User.terahiveEss.systemId',
    },
    batteryData: {
      totalDischarge: Number, // kWh discharged during billing period
      totalCharge: Number, // kWh charged during billing period
      peakDischarge: Number, // kW peak discharge
      peakCharge: Number, // kW peak charge
      efficiency: Number, // percentage
      cycles: Number, // number of charge/discharge cycles
    },
    gridInteraction: {
      gridImport: Number, // kWh imported from grid
      gridExport: Number, // kWh exported to grid
      netGridUsage: Number, // net grid usage (import - export)
      peakGridImport: Number, // kW peak grid import
      peakGridExport: Number, // kW peak grid export
    },
    savings: {
      energyCostSavings: Number, // money saved through ESS
      demandCostSavings: Number, // demand charge savings
      totalSavings: Number, // total savings
      roi: Number, // return on investment percentage
    },
    performance: {
      availability: Number, // system availability percentage
      uptime: Number, // hours of operation
      alerts: [{
        type: String,
        message: String,
        severity: {
          type: String,
          enum: ['low', 'medium', 'high', 'critical'],
        },
        timestamp: Date,
        resolved: {
          type: Boolean,
          default: false,
        },
      }],
    },
  },
  
  // AI analysis results
  aiAnalysis: {
    summary: {
      type: String,
      required: true,
    },
    insights: [{
      type: String,
      category: {
        type: String,
        enum: ['consumption', 'cost', 'efficiency', 'trend', 'anomaly'],
      },
      severity: {
        type: String,
        enum: ['info', 'warning', 'alert'],
      },
      actionable: {
        type: Boolean,
        default: false,
      },
    }],
    recommendations: [{
      title: String,
      description: String,
      category: {
        type: String,
        enum: ['energy_saving', 'cost_reduction', 'efficiency', 'maintenance'],
      },
      priority: {
        type: String,
        enum: ['low', 'medium', 'high'],
      },
      estimatedSavings: Number,
      implementationCost: Number,
      paybackPeriod: Number, // in months
    }],
    trends: {
      consumptionTrend: {
        type: String,
        enum: ['increasing', 'decreasing', 'stable'],
      },
      costTrend: {
        type: String,
        enum: ['increasing', 'decreasing', 'stable'],
      },
      efficiencyTrend: {
        type: String,
        enum: ['improving', 'declining', 'stable'],
      },
    },
    anomalies: [{
      type: String,
      description: String,
      severity: {
        type: String,
        enum: ['low', 'medium', 'high'],
      },
      detectedAt: Date,
    }],
  },
  
  // Bill image and processing
  image: {
    originalPath: String,
    processedPath: String,
    thumbnailPath: String,
    fileSize: Number,
    mimeType: String,
    dimensions: {
      width: Number,
      height: Number,
    },
    processingStatus: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: 'pending',
    },
    processingError: String,
  },
  
  // Extracted text from OCR/AI
  extractedText: {
    raw: String,
    structured: {
      accountNumber: String,
      serviceAddress: String,
      meterNumber: String,
      rateSchedule: String,
    },
    confidence: Number, // OCR confidence score
  },
  
  // Tags and categorization
  tags: [{
    type: String,
    enum: ['residential', 'commercial', 'industrial', 'monthly', 'quarterly', 'annual', 'estimated', 'actual'],
  }],
  
  // Status and workflow
  status: {
    type: String,
    enum: ['draft', 'processed', 'verified', 'archived'],
    default: 'draft',
  },
  isPaid: {
    type: Boolean,
    default: false,
  },
  paymentDate: Date,
  paymentMethod: {
    type: String,
    enum: ['online', 'check', 'autopay', 'credit_card', 'other'],
  },
  
  // Metadata
  source: {
    type: String,
    enum: ['manual_upload', 'camera_scan', 'email_import', 'api_import', 'terahive_sync'],
    default: 'manual_upload',
  },
  processingTime: Number, // milliseconds
  version: {
    type: String,
    default: '1.0',
  },
  
  // Timestamps
  processedAt: Date,
  verifiedAt: Date,
  archivedAt: Date,
}, {
  timestamps: true,
});

// Indexes for better query performance
billSchema.index({ userId: 1, billDate: -1 });
billSchema.index({ userId: 1, status: 1 });
billSchema.index({ 'terahiveEss.isIntegrated': 1 });
billSchema.index({ 'terahiveEss.systemId': 1 });
billSchema.index({ utilityProvider: 1 });
billSchema.index({ billingPeriod: 1 });
billSchema.index({ createdAt: -1 });

// Virtual for billing period duration
billSchema.virtual('billingPeriodDays').get(function() {
  if (this.billingPeriod.startDate && this.billingPeriod.endDate) {
    const diffTime = Math.abs(this.billingPeriod.endDate - this.billingPeriod.startDate);
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }
  return null;
});

// Virtual for daily average consumption
billSchema.virtual('dailyAverageConsumption').get(function() {
  if (this.consumption.total && this.billingPeriodDays) {
    return this.consumption.total / this.billingPeriodDays;
  }
  return null;
});

// Virtual for cost per unit
billSchema.virtual('costPerUnit').get(function() {
  if (this.consumption.total > 0) {
    return this.costs.total / this.consumption.total;
  }
  return null;
});

// Virtual for Terahive ESS savings percentage
billSchema.virtual('savingsPercentage').get(function() {
  if (this.terahiveEss.savings.totalSavings && this.costs.total > 0) {
    return (this.terahiveEss.savings.totalSavings / this.costs.total) * 100;
  }
  return 0;
});

// Pre-save middleware to update processing time
billSchema.pre('save', function(next) {
  if (this.isNew) {
    this.processingTime = Date.now() - this.createdAt;
  }
  next();
});

// Instance method to calculate savings
billSchema.methods.calculateSavings = function() {
  if (!this.terahiveEss.isIntegrated) return null;
  
  const savings = {
    energyCostSavings: 0,
    demandCostSavings: 0,
    totalSavings: 0,
  };
  
  // Calculate energy cost savings based on battery discharge
  if (this.terahiveEss.batteryData.totalDischarge) {
    savings.energyCostSavings = this.terahiveEss.batteryData.totalDischarge * this.rates.energyRate;
  }
  
  // Calculate demand cost savings based on peak demand reduction
  if (this.terahiveEss.batteryData.peakDischarge) {
    savings.demandCostSavings = this.terahiveEss.batteryData.peakDischarge * this.rates.demandRate;
  }
  
  savings.totalSavings = savings.energyCostSavings + savings.demandCostSavings;
  
  return savings;
};

// Instance method to update AI analysis
billSchema.methods.updateAIAnalysis = function(analysisData) {
  this.aiAnalysis = {
    ...this.aiAnalysis,
    ...analysisData,
  };
  this.processedAt = new Date();
  this.status = 'processed';
  return this.save();
};

// Instance method to mark as verified
billSchema.methods.markAsVerified = function() {
  this.status = 'verified';
  this.verifiedAt = new Date();
  return this.save();
};

// Static method to find bills by user and date range
billSchema.statics.findByUserAndDateRange = function(userId, startDate, endDate) {
  return this.find({
    userId,
    billDate: {
      $gte: startDate,
      $lte: endDate,
    },
  }).sort({ billDate: -1 });
};

// Static method to find Terahive ESS bills
billSchema.statics.findTerahiveBills = function(userId) {
  return this.find({
    userId,
    'terahiveEss.isIntegrated': true,
  }).sort({ billDate: -1 });
};

// Static method to get user statistics
billSchema.statics.getUserStatistics = async function(userId) {
  const stats = await this.aggregate([
    { $match: { userId: mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: null,
        totalBills: { $sum: 1 },
        totalConsumption: { $sum: '$consumption.total' },
        totalCost: { $sum: '$costs.total' },
        averageConsumption: { $avg: '$consumption.total' },
        averageCost: { $avg: '$costs.total' },
        totalSavings: { $sum: '$terahiveEss.savings.totalSavings' },
      },
    },
  ]);
  
  return stats[0] || {
    totalBills: 0,
    totalConsumption: 0,
    totalCost: 0,
    averageConsumption: 0,
    averageCost: 0,
    totalSavings: 0,
  };
};

module.exports = mongoose.model('Bill', billSchema); 