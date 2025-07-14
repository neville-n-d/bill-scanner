const axios = require('axios');
const logger = require('../utils/logger');
const User = require('../models/User');
const TerahiveSystem = require('../models/TerahiveSystem');

class TerahiveService {
  constructor() {
    this.baseURL = process.env.TERAHIVE_API_BASE_URL;
    this.apiKey = process.env.TERAHIVE_API_KEY;
    this.clientId = process.env.TERAHIVE_CLIENT_ID;
    this.clientSecret = process.env.TERAHIVE_CLIENT_SECRET;
  }

  // Create authenticated API client
  createApiClient(accessToken = null) {
    const client = axios.create({
      baseURL: this.baseURL,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'ElectricityBillApp/1.0',
      },
    });

    // Add authentication headers
    if (accessToken) {
      client.defaults.headers.common['Authorization'] = `Bearer ${accessToken}`;
    } else if (this.apiKey) {
      client.defaults.headers.common['X-API-Key'] = this.apiKey;
    }

    // Add request interceptor for logging
    client.interceptors.request.use(
      (config) => {
        logger.debug('Terahive API Request:', {
          method: config.method,
          url: config.url,
          data: config.data,
        });
        return config;
      },
      (error) => {
        logger.error('Terahive API Request Error:', error);
        return Promise.reject(error);
      }
    );

    // Add response interceptor for logging
    client.interceptors.response.use(
      (response) => {
        logger.debug('Terahive API Response:', {
          status: response.status,
          url: response.config.url,
        });
        return response;
      },
      (error) => {
        logger.error('Terahive API Response Error:', {
          status: error.response?.status,
          message: error.response?.data?.message || error.message,
          url: error.config?.url,
        });
        return Promise.reject(error);
      }
    );

    return client;
  }

  // Authenticate with Terahive API
  async authenticate(clientId, clientSecret) {
    try {
      const client = this.createApiClient();
      
      const response = await client.post('/auth/token', {
        grant_type: 'client_credentials',
        client_id: clientId,
        client_secret: clientSecret,
      });

      return {
        accessToken: response.data.access_token,
        refreshToken: response.data.refresh_token,
        expiresIn: response.data.expires_in,
        tokenType: response.data.token_type,
      };
    } catch (error) {
      logger.error('Terahive authentication failed:', error);
      throw new Error('Failed to authenticate with Terahive API');
    }
  }

  // Get system information
  async getSystemInfo(systemId, accessToken) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}`);
      
      return {
        systemId: response.data.system_id,
        systemName: response.data.name,
        model: response.data.model,
        serialNumber: response.data.serial_number,
        status: response.data.status,
        specifications: response.data.specifications,
        location: response.data.location,
        installation: response.data.installation,
      };
    } catch (error) {
      logger.error('Failed to get system info:', error);
      throw new Error('Failed to retrieve system information');
    }
  }

  // Get real-time system status
  async getSystemStatus(systemId, accessToken) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/status`);
      
      return {
        isOnline: response.data.is_online,
        operatingMode: response.data.operating_mode,
        batteryLevel: response.data.battery_level,
        temperature: response.data.temperature,
        voltage: response.data.voltage,
        current: response.data.current,
        power: response.data.power,
        frequency: response.data.frequency,
        lastUpdate: response.data.last_update,
      };
    } catch (error) {
      logger.error('Failed to get system status:', error);
      throw new Error('Failed to retrieve system status');
    }
  }

  // Get historical data
  async getHistoricalData(systemId, accessToken, startDate, endDate, granularity = 'hourly') {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/data`, {
        params: {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
          granularity,
        },
      });
      
      return response.data.map(record => ({
        timestamp: new Date(record.timestamp),
        energyFlow: {
          gridImport: record.grid_import,
          gridExport: record.grid_export,
          batteryCharge: record.battery_charge,
          batteryDischarge: record.battery_discharge,
          loadServed: record.load_served,
        },
        financial: {
          energyCost: record.energy_cost,
          energySavings: record.energy_savings,
          demandSavings: record.demand_savings,
          exportRevenue: record.export_revenue,
          totalSavings: record.total_savings,
        },
        performance: {
          efficiency: record.efficiency,
          availability: record.availability,
          peakPower: record.peak_power,
          averagePower: record.average_power,
        },
        environmental: {
          co2Saved: record.co2_saved,
          renewableEnergyUsed: record.renewable_energy_used,
        },
      }));
    } catch (error) {
      logger.error('Failed to get historical data:', error);
      throw new Error('Failed to retrieve historical data');
    }
  }

  // Get system alerts
  async getSystemAlerts(systemId, accessToken, activeOnly = true) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/alerts`, {
        params: {
          active_only: activeOnly,
        },
      });
      
      return response.data.map(alert => ({
        id: alert.id,
        type: alert.type,
        severity: alert.severity,
        title: alert.title,
        message: alert.message,
        timestamp: new Date(alert.timestamp),
        isActive: alert.is_active,
        isAcknowledged: alert.is_acknowledged,
        resolution: alert.resolution,
      }));
    } catch (error) {
      logger.error('Failed to get system alerts:', error);
      throw new Error('Failed to retrieve system alerts');
    }
  }

  // Acknowledge alert
  async acknowledgeAlert(systemId, alertId, accessToken, resolution = '') {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.post(`/systems/${systemId}/alerts/${alertId}/acknowledge`, {
        resolution,
      });
      
      return response.data;
    } catch (error) {
      logger.error('Failed to acknowledge alert:', error);
      throw new Error('Failed to acknowledge alert');
    }
  }

  // Get system performance metrics
  async getPerformanceMetrics(systemId, accessToken, period = 'monthly') {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/performance`, {
        params: {
          period,
        },
      });
      
      return {
        totalEnergyThroughput: response.data.total_energy_throughput,
        totalCycles: response.data.total_cycles,
        efficiency: response.data.efficiency,
        availability: response.data.availability,
        uptime: response.data.uptime,
        lastMaintenance: response.data.last_maintenance ? new Date(response.data.last_maintenance) : null,
        nextMaintenance: response.data.next_maintenance ? new Date(response.data.next_maintenance) : null,
      };
    } catch (error) {
      logger.error('Failed to get performance metrics:', error);
      throw new Error('Failed to retrieve performance metrics');
    }
  }

  // Get financial metrics
  async getFinancialMetrics(systemId, accessToken, startDate, endDate) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/financial`, {
        params: {
          start_date: startDate.toISOString(),
          end_date: endDate.toISOString(),
        },
      });
      
      return {
        totalSavings: response.data.total_savings,
        energyCostSavings: response.data.energy_cost_savings,
        demandCostSavings: response.data.demand_cost_savings,
        gridExportRevenue: response.data.grid_export_revenue,
        installationCost: response.data.installation_cost,
        paybackPeriod: response.data.payback_period,
        roi: response.data.roi,
      };
    } catch (error) {
      logger.error('Failed to get financial metrics:', error);
      throw new Error('Failed to retrieve financial metrics');
    }
  }

  // Update system settings
  async updateSystemSettings(systemId, accessToken, settings) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.put(`/systems/${systemId}/settings`, settings);
      
      return response.data;
    } catch (error) {
      logger.error('Failed to update system settings:', error);
      throw new Error('Failed to update system settings');
    }
  }

  // Sync user's Terahive system data
  async syncUserSystem(userId) {
    try {
      const user = await User.findById(userId);
      if (!user || user.userType !== 'terahive_ess' || !user.terahiveEss.isInstalled) {
        throw new Error('User does not have Terahive ESS installed');
      }

      const { apiCredentials, systemId } = user.terahiveEss;
      
      if (!apiCredentials.accessToken) {
        throw new Error('No access token available');
      }

      // Check if token is expired
      if (apiCredentials.tokenExpiresAt && new Date() > apiCredentials.tokenExpiresAt) {
        await this.refreshUserToken(user);
      }

      // Get or create TerahiveSystem record
      let system = await TerahiveSystem.findOne({ systemId });
      if (!system) {
        system = new TerahiveSystem({
          userId: user._id,
          systemId,
        });
      }

      // Get system information
      const systemInfo = await this.getSystemInfo(systemId, apiCredentials.accessToken);
      const systemStatus = await this.getSystemStatus(systemId, apiCredentials.accessToken);
      const performanceMetrics = await this.getPerformanceMetrics(systemId, apiCredentials.accessToken);

      // Update system data
      Object.assign(system, {
        systemName: systemInfo.systemName,
        model: systemInfo.model,
        serialNumber: systemInfo.serialNumber,
        specifications: systemInfo.specifications,
        installation: systemInfo.installation,
        status: systemStatus,
        performance: performanceMetrics,
        lastUpdated: new Date(),
      });

      await system.save();

      // Update user's last sync
      user.terahiveEss.lastSync = new Date();
      user.terahiveEss.syncStatus = 'active';
      await user.save();

      logger.info(`Synced Terahive system for user ${userId}`);
      
      return system;
    } catch (error) {
      logger.error(`Failed to sync Terahive system for user ${userId}:`, error);
      
      // Update sync status to error
      const user = await User.findById(userId);
      if (user) {
        user.terahiveEss.syncStatus = 'error';
        await user.save();
      }
      
      throw error;
    }
  }

  // Refresh user's access token
  async refreshUserToken(user) {
    try {
      const { refreshToken } = user.terahiveEss.apiCredentials;
      
      if (!refreshToken) {
        throw new Error('No refresh token available');
      }

      const client = this.createApiClient();
      
      const response = await client.post('/auth/refresh', {
        grant_type: 'refresh_token',
        refresh_token: refreshToken,
        client_id: this.clientId,
        client_secret: this.clientSecret,
      });

      // Update user's API credentials
      user.terahiveEss.apiCredentials.accessToken = response.data.access_token;
      user.terahiveEss.apiCredentials.refreshToken = response.data.refresh_token;
      user.terahiveEss.apiCredentials.tokenExpiresAt = new Date(Date.now() + response.data.expires_in * 1000);
      
      await user.save();
      
      logger.info(`Refreshed token for user ${user._id}`);
    } catch (error) {
      logger.error(`Failed to refresh token for user ${user._id}:`, error);
      throw new Error('Failed to refresh access token');
    }
  }

  // Get billing period data for integration with bills
  async getBillingPeriodData(systemId, accessToken, billingPeriod) {
    try {
      const client = this.createApiClient(accessToken);
      
      const response = await client.get(`/systems/${systemId}/billing-period`, {
        params: {
          start_date: billingPeriod.startDate.toISOString(),
          end_date: billingPeriod.endDate.toISOString(),
        },
      });
      
      return {
        batteryData: {
          totalDischarge: response.data.battery.total_discharge,
          totalCharge: response.data.battery.total_charge,
          peakDischarge: response.data.battery.peak_discharge,
          peakCharge: response.data.battery.peak_charge,
          efficiency: response.data.battery.efficiency,
          cycles: response.data.battery.cycles,
        },
        gridInteraction: {
          gridImport: response.data.grid.import,
          gridExport: response.data.grid.export,
          netGridUsage: response.data.grid.net_usage,
          peakGridImport: response.data.grid.peak_import,
          peakGridExport: response.data.grid.peak_export,
        },
        savings: {
          energyCostSavings: response.data.savings.energy_cost,
          demandCostSavings: response.data.savings.demand_cost,
          totalSavings: response.data.savings.total,
          roi: response.data.savings.roi,
        },
        performance: {
          availability: response.data.performance.availability,
          uptime: response.data.performance.uptime,
        },
      };
    } catch (error) {
      logger.error('Failed to get billing period data:', error);
      throw new Error('Failed to retrieve billing period data');
    }
  }
}

module.exports = new TerahiveService(); 