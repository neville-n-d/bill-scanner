const mongoose = require('mongoose');

const terahiveSystemSchema = new mongoose.Schema({
  // User reference
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  
  // System identification
  systemId: {
    type: String,
    required: true,
    unique: true,
  },
  systemName: {
    type: String,
    required: true,
    trim: true,
  },
  model: {
    type: String,
    required: true,
  },
  serialNumber: {
    type: String,
    required: true,
    unique: true,
  },
  
  // System specifications
  specifications: {
    batteryCapacity: {
      type: Number, // in kWh
      required: true,
    },
    inverterPower: {
      type: Number, // in kW
      required: true,
    },
    batteryType: {
      type: String,
      enum: ['lithium-ion', 'lithium-iron-phosphate', 'lead-acid', 'other'],
      required: true,
    },
    voltage: {
      type: Number, // in V
      required: true,
    },
    maxChargeRate: {
      type: Number, // in kW
      required: true,
    },
    maxDischargeRate: {
      type: Number, // in kW
      required: true,
    },
    cycleLife: {
      type: Number, // number of cycles
      required: true,
    },
    warranty: {
      years: Number,
      cycles: Number,
    },
  },
  
  // Installation details
  installation: {
    date: {
      type: Date,
      required: true,
    },
    installer: {
      name: String,
      company: String,
      license: String,
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
    configuration: {
      gridTied: {
        type: Boolean,
        default: true,
      },
      backupEnabled: {
        type: Boolean,
        default: true,
      },
      solarIntegration: {
        type: Boolean,
        default: false,
      },
      solarCapacity: Number, // in kW
      loadShifting: {
        type: Boolean,
        default: true,
      },
      peakShaving: {
        type: Boolean,
        default: true,
      },
    },
  },
  
  // Real-time system status
  status: {
    isOnline: {
      type: Boolean,
      default: false,
    },
    lastSeen: Date,
    operatingMode: {
      type: String,
      enum: ['standby', 'charging', 'discharging', 'backup', 'maintenance', 'error'],
      default: 'standby',
    },
    batteryLevel: {
      type: Number, // percentage
      min: 0,
      max: 100,
      default: 0,
    },
    temperature: {
      battery: Number, // in Celsius
      inverter: Number, // in Celsius
      ambient: Number, // in Celsius
    },
    voltage: {
      battery: Number, // in V
      grid: Number, // in V
    },
    current: {
      battery: Number, // in A
      grid: Number, // in A
    },
    power: {
      battery: Number, // in kW (positive = charging, negative = discharging)
      grid: Number, // in kW (positive = importing, negative = exporting)
      load: Number, // in kW
    },
    frequency: {
      grid: Number, // in Hz
    },
  },
  
  // Performance metrics
  performance: {
    totalEnergyThroughput: {
      type: Number, // in kWh
      default: 0,
    },
    totalCycles: {
      type: Number,
      default: 0,
    },
    efficiency: {
      roundTrip: Number, // percentage
      charge: Number, // percentage
      discharge: Number, // percentage
    },
    availability: {
      type: Number, // percentage
      default: 100,
    },
    uptime: {
      type: Number, // in hours
      default: 0,
    },
    lastMaintenance: Date,
    nextMaintenance: Date,
  },
  
  // Financial metrics
  financial: {
    totalSavings: {
      type: Number, // in user's currency
      default: 0,
    },
    energyCostSavings: {
      type: Number,
      default: 0,
    },
    demandCostSavings: {
      type: Number,
      default: 0,
    },
    gridExportRevenue: {
      type: Number,
      default: 0,
    },
    installationCost: {
      type: Number,
      required: true,
    },
    paybackPeriod: {
      type: Number, // in months
    },
    roi: {
      type: Number, // percentage
    },
  },
  
  // Alerts and notifications
  alerts: [{
    id: String,
    type: {
      type: String,
      enum: ['system', 'performance', 'maintenance', 'financial', 'security'],
    },
    severity: {
      type: String,
      enum: ['low', 'medium', 'high', 'critical'],
    },
    title: String,
    message: String,
    timestamp: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    isAcknowledged: {
      type: Boolean,
      default: false,
    },
    acknowledgedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    acknowledgedAt: Date,
    resolution: String,
    resolvedAt: Date,
  }],
  
  // Historical data (aggregated daily)
  historicalData: [{
    date: {
      type: Date,
      required: true,
    },
    energyFlow: {
      gridImport: Number, // kWh
      gridExport: Number, // kWh
      batteryCharge: Number, // kWh
      batteryDischarge: Number, // kWh
      loadServed: Number, // kWh
    },
    financial: {
      energyCost: Number,
      energySavings: Number,
      demandSavings: Number,
      exportRevenue: Number,
      totalSavings: Number,
    },
    performance: {
      efficiency: Number, // percentage
      availability: Number, // percentage
      peakPower: Number, // kW
      averagePower: Number, // kW
    },
    environmental: {
      co2Saved: Number, // kg
      renewableEnergyUsed: Number, // kWh
    },
  }],
  
  // API integration
  apiIntegration: {
    accessToken: String,
    refreshToken: String,
    tokenExpiresAt: Date,
    lastSync: Date,
    syncStatus: {
      type: String,
      enum: ['active', 'inactive', 'error'],
      default: 'inactive',
    },
    syncError: String,
    webhookUrl: String,
    webhookSecret: String,
  },
  
  // Settings and preferences
  settings: {
    backupThreshold: {
      type: Number, // percentage
      default: 20,
    },
    chargeThreshold: {
      type: Number, // percentage
      default: 80,
    },
    peakShavingThreshold: {
      type: Number, // kW
      default: 5,
    },
    loadShiftingSchedule: [{
      day: {
        type: String,
        enum: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
      },
      startTime: String, // HH:MM format
      endTime: String, // HH:MM format
      mode: {
        type: String,
        enum: ['charge', 'discharge', 'standby'],
      },
    }],
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
      alertTypes: [{
        type: String,
        enum: ['system', 'performance', 'maintenance', 'financial'],
      }],
    },
  },
  
  // System health and maintenance
  health: {
    overallHealth: {
      type: String,
      enum: ['excellent', 'good', 'fair', 'poor', 'critical'],
      default: 'good',
    },
    batteryHealth: {
      type: Number, // percentage
      min: 0,
      max: 100,
      default: 100,
    },
    inverterHealth: {
      type: Number, // percentage
      min: 0,
      max: 100,
      default: 100,
    },
    lastHealthCheck: Date,
    nextHealthCheck: Date,
    maintenanceHistory: [{
      date: Date,
      type: String,
      description: String,
      performedBy: String,
      cost: Number,
      notes: String,
    }],
  },
  
  // Timestamps
  lastUpdated: {
    type: Date,
    default: Date.now,
  },
}, {
  timestamps: true,
});

// Indexes for better query performance
terahiveSystemSchema.index({ userId: 1 });
terahiveSystemSchema.index({ systemId: 1 });
terahiveSystemSchema.index({ 'status.isOnline': 1 });
terahiveSystemSchema.index({ 'status.lastSeen': -1 });
terahiveSystemSchema.index({ 'alerts.isActive': 1 });
terahiveSystemSchema.index({ 'historicalData.date': -1 });

// Virtual for system age
terahiveSystemSchema.virtual('systemAge').get(function() {
  if (this.installation.date) {
    const ageInMs = Date.now() - this.installation.date;
    return Math.floor(ageInMs / (1000 * 60 * 60 * 24 * 365.25)); // years
  }
  return 0;
});

// Virtual for warranty status
terahiveSystemSchema.virtual('warrantyStatus').get(function() {
  if (!this.specifications.warranty || !this.installation.date) return 'unknown';
  
  const ageInYears = this.systemAge;
  const cycleAge = this.performance.totalCycles;
  
  if (ageInYears >= this.specifications.warranty.years || 
      cycleAge >= this.specifications.warranty.cycles) {
    return 'expired';
  }
  
  return 'active';
});

// Virtual for current power flow
terahiveSystemSchema.virtual('powerFlow').get(function() {
  const { power } = this.status;
  return {
    battery: power.battery || 0,
    grid: power.grid || 0,
    load: power.load || 0,
    net: (power.grid || 0) + (power.battery || 0) - (power.load || 0),
  };
});

// Instance method to update real-time status
terahiveSystemSchema.methods.updateStatus = function(statusData) {
  this.status = {
    ...this.status,
    ...statusData,
    lastSeen: new Date(),
  };
  this.lastUpdated = new Date();
  return this.save();
};

// Instance method to add alert
terahiveSystemSchema.methods.addAlert = function(alertData) {
  const alert = {
    id: require('uuid').v4(),
    timestamp: new Date(),
    isActive: true,
    isAcknowledged: false,
    ...alertData,
  };
  
  this.alerts.unshift(alert);
  
  // Keep only last 100 alerts
  if (this.alerts.length > 100) {
    this.alerts = this.alerts.slice(0, 100);
  }
  
  return this.save();
};

// Instance method to acknowledge alert
terahiveSystemSchema.methods.acknowledgeAlert = function(alertId, userId, resolution = '') {
  const alert = this.alerts.find(a => a.id === alertId);
  if (alert) {
    alert.isAcknowledged = true;
    alert.acknowledgedBy = userId;
    alert.acknowledgedAt = new Date();
    alert.resolution = resolution;
  }
  return this.save();
};

// Instance method to add historical data
terahiveSystemSchema.methods.addHistoricalData = function(data) {
  const historicalEntry = {
    date: new Date(),
    ...data,
  };
  
  this.historicalData.push(historicalEntry);
  
  // Keep only last 2 years of data
  const twoYearsAgo = new Date();
  twoYearsAgo.setFullYear(twoYearsAgo.getFullYear() - 2);
  
  this.historicalData = this.historicalData.filter(
    entry => entry.date >= twoYearsAgo
  );
  
  return this.save();
};

// Instance method to calculate financial metrics
terahiveSystemSchema.methods.calculateFinancialMetrics = function() {
  const totalSavings = this.financial.energyCostSavings + 
                      this.financial.demandCostSavings + 
                      this.financial.gridExportRevenue;
  
  this.financial.totalSavings = totalSavings;
  
  if (this.financial.installationCost > 0) {
    this.financial.paybackPeriod = (this.financial.installationCost / totalSavings) * 12; // months
    this.financial.roi = (totalSavings / this.financial.installationCost) * 100; // percentage
  }
  
  return this.save();
};

// Static method to find online systems
terahiveSystemSchema.statics.findOnlineSystems = function() {
  return this.find({ 'status.isOnline': true });
};

// Static method to find systems with active alerts
terahiveSystemSchema.statics.findSystemsWithAlerts = function() {
  return this.find({ 'alerts.isActive': true });
};

// Static method to get system statistics
terahiveSystemSchema.statics.getSystemStatistics = async function() {
  const stats = await this.aggregate([
    {
      $group: {
        _id: null,
        totalSystems: { $sum: 1 },
        onlineSystems: {
          $sum: { $cond: ['$status.isOnline', 1, 0] }
        },
        totalCapacity: { $sum: '$specifications.batteryCapacity' },
        totalSavings: { $sum: '$financial.totalSavings' },
        averageEfficiency: { $avg: '$performance.efficiency.roundTrip' },
      },
    },
  ]);
  
  return stats[0] || {
    totalSystems: 0,
    onlineSystems: 0,
    totalCapacity: 0,
    totalSavings: 0,
    averageEfficiency: 0,
  };
};

module.exports = mongoose.model('TerahiveSystem', terahiveSystemSchema); 