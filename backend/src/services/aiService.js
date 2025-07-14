const axios = require('axios');
const logger = require('../utils/logger');

class AIService {
  constructor() {
    this.endpoint = process.env.AZURE_OPENAI_ENDPOINT;
    this.deployment = process.env.AZURE_OPENAI_DEPLOYMENT;
    this.apiKey = process.env.AZURE_OPENAI_API_KEY;
    this.apiVersion = process.env.AZURE_OPENAI_API_VERSION;
  }

  // Analyze bill image using Azure OpenAI Vision
  async analyzeBillImage(base64Image) {
    try {
      const url = `${this.endpoint}/openai/deployments/${this.deployment}/chat/completions?api-version=${this.apiVersion}`;
      
      const prompt = `Analyze this electricity bill image and extract the following information in JSON format:

{
  "billNumber": "string",
  "utilityProvider": {
    "name": "string",
    "code": "string",
    "website": "string",
    "phone": "string"
  },
  "billDate": "YYYY-MM-DD",
  "dueDate": "YYYY-MM-DD",
  "billingPeriod": {
    "startDate": "YYYY-MM-DD",
    "endDate": "YYYY-MM-DD"
  },
  "consumption": {
    "total": number,
    "unit": "kWh",
    "previousReading": number,
    "currentReading": number,
    "peakDemand": number
  },
  "costs": {
    "total": number,
    "currency": "USD",
    "energyCharge": number,
    "deliveryCharge": number,
    "taxes": number,
    "fees": number,
    "demandCharge": number
  },
  "rates": {
    "energyRate": number,
    "demandRate": number,
    "deliveryRate": number,
    "fixedCharge": number
  },
  "extractedText": {
    "raw": "string",
    "structured": {
      "accountNumber": "string",
      "serviceAddress": "string",
      "meterNumber": "string",
      "rateSchedule": "string"
    },
    "confidence": number
  },
  "aiAnalysis": {
    "summary": "string",
    "insights": [
      {
        "type": "string",
        "category": "consumption|cost|efficiency|trend|anomaly",
        "severity": "info|warning|alert",
        "actionable": boolean
      }
    ],
    "recommendations": [
      {
        "title": "string",
        "description": "string",
        "category": "energy_saving|cost_reduction|efficiency|maintenance",
        "priority": "low|medium|high",
        "estimatedSavings": number,
        "implementationCost": number,
        "paybackPeriod": number
      }
    ],
    "trends": {
      "consumptionTrend": "increasing|decreasing|stable",
      "costTrend": "increasing|decreasing|stable",
      "efficiencyTrend": "improving|declining|stable"
    },
    "anomalies": [
      {
        "type": "string",
        "description": "string",
        "severity": "low|medium|high",
        "detectedAt": "YYYY-MM-DD"
      }
    ]
  }
}

Please be as accurate as possible. If any information is not clearly visible or cannot be determined, use null for that field. For monetary values, extract only the numeric amount without currency symbols. For dates, use YYYY-MM-DD format. For the AI analysis, provide insights based on the bill data and general energy efficiency best practices.`;

      const response = await axios.post(url, {
        messages: [
          {
            role: "system",
            content: "You are an expert in analyzing electricity bills and providing energy efficiency insights. Extract all relevant information accurately and provide actionable recommendations."
          },
          {
            role: "user",
            content: [
              {
                type: "text",
                text: prompt
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`
                }
              }
            ]
          }
        ],
        max_tokens: 4000,
        temperature: 0.1
      }, {
        headers: {
          'api-key': this.apiKey,
          'Content-Type': 'application/json'
        }
      });

      const content = response.data.choices[0].message.content;
      
      // Parse JSON response
      let parsedData;
      try {
        // Extract JSON from the response (in case there's additional text)
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          parsedData = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error('No JSON found in response');
        }
      } catch (parseError) {
        logger.error('Failed to parse AI response:', parseError);
        throw new Error('Failed to parse AI analysis results');
      }

      // Validate and clean the data
      const cleanedData = this.validateAndCleanData(parsedData);
      
      logger.info('AI analysis completed successfully');
      return cleanedData;

    } catch (error) {
      logger.error('AI analysis failed:', error);
      throw new Error('Failed to analyze bill image');
    }
  }

  // Validate and clean AI response data
  validateAndCleanData(data) {
    const cleaned = {};

    // Basic bill information
    cleaned.billNumber = data.billNumber || null;
    cleaned.utilityProvider = {
      name: data.utilityProvider?.name || 'Unknown',
      code: data.utilityProvider?.code || null,
      website: data.utilityProvider?.website || null,
      phone: data.utilityProvider?.phone || null,
    };

    // Dates
    cleaned.billDate = this.parseDate(data.billDate);
    cleaned.dueDate = this.parseDate(data.dueDate);
    cleaned.billingPeriod = {
      startDate: this.parseDate(data.billingPeriod?.startDate),
      endDate: this.parseDate(data.billingPeriod?.endDate),
    };

    // Consumption data
    cleaned.consumption = {
      total: this.parseNumber(data.consumption?.total),
      unit: data.consumption?.unit || 'kWh',
      previousReading: this.parseNumber(data.consumption?.previousReading),
      currentReading: this.parseNumber(data.consumption?.currentReading),
      peakDemand: this.parseNumber(data.consumption?.peakDemand),
    };

    // Cost data
    cleaned.costs = {
      total: this.parseNumber(data.costs?.total),
      currency: data.costs?.currency || 'USD',
      energyCharge: this.parseNumber(data.costs?.energyCharge),
      deliveryCharge: this.parseNumber(data.costs?.deliveryCharge),
      taxes: this.parseNumber(data.costs?.taxes),
      fees: this.parseNumber(data.costs?.fees),
      demandCharge: this.parseNumber(data.costs?.demandCharge),
    };

    // Rate information
    cleaned.rates = {
      energyRate: this.parseNumber(data.rates?.energyRate),
      demandRate: this.parseNumber(data.rates?.demandRate),
      deliveryRate: this.parseNumber(data.rates?.deliveryRate),
      fixedCharge: this.parseNumber(data.rates?.fixedCharge),
    };

    // Extracted text
    cleaned.extractedText = {
      raw: data.extractedText?.raw || '',
      structured: {
        accountNumber: data.extractedText?.structured?.accountNumber || null,
        serviceAddress: data.extractedText?.structured?.serviceAddress || null,
        meterNumber: data.extractedText?.structured?.meterNumber || null,
        rateSchedule: data.extractedText?.structured?.rateSchedule || null,
      },
      confidence: this.parseNumber(data.extractedText?.confidence) || 0.8,
    };

    // AI analysis
    cleaned.aiAnalysis = {
      summary: data.aiAnalysis?.summary || 'Bill analysis completed',
      insights: this.validateInsights(data.aiAnalysis?.insights || []),
      recommendations: this.validateRecommendations(data.aiAnalysis?.recommendations || []),
      trends: this.validateTrends(data.aiAnalysis?.trends || {}),
      anomalies: this.validateAnomalies(data.aiAnalysis?.anomalies || []),
    };

    return cleaned;
  }

  // Parse date string
  parseDate(dateString) {
    if (!dateString) return null;
    try {
      const date = new Date(dateString);
      return isNaN(date.getTime()) ? null : date;
    } catch (error) {
      return null;
    }
  }

  // Parse number
  parseNumber(value) {
    if (value === null || value === undefined || value === '') return null;
    const num = parseFloat(value);
    return isNaN(num) ? null : num;
  }

  // Validate insights array
  validateInsights(insights) {
    if (!Array.isArray(insights)) return [];
    
    return insights.filter(insight => 
      insight.type && 
      insight.category && 
      ['consumption', 'cost', 'efficiency', 'trend', 'anomaly'].includes(insight.category) &&
      ['info', 'warning', 'alert'].includes(insight.severity)
    ).map(insight => ({
      type: insight.type,
      category: insight.category,
      severity: insight.severity,
      actionable: Boolean(insight.actionable),
    }));
  }

  // Validate recommendations array
  validateRecommendations(recommendations) {
    if (!Array.isArray(recommendations)) return [];
    
    return recommendations.filter(rec => 
      rec.title && 
      rec.description && 
      rec.category && 
      ['energy_saving', 'cost_reduction', 'efficiency', 'maintenance'].includes(rec.category) &&
      ['low', 'medium', 'high'].includes(rec.priority)
    ).map(rec => ({
      title: rec.title,
      description: rec.description,
      category: rec.category,
      priority: rec.priority,
      estimatedSavings: this.parseNumber(rec.estimatedSavings),
      implementationCost: this.parseNumber(rec.implementationCost),
      paybackPeriod: this.parseNumber(rec.paybackPeriod),
    }));
  }

  // Validate trends object
  validateTrends(trends) {
    const validTrends = ['increasing', 'decreasing', 'stable'];
    
    return {
      consumptionTrend: validTrends.includes(trends.consumptionTrend) ? trends.consumptionTrend : 'stable',
      costTrend: validTrends.includes(trends.costTrend) ? trends.costTrend : 'stable',
      efficiencyTrend: validTrends.includes(trends.efficiencyTrend) ? trends.efficiencyTrend : 'stable',
    };
  }

  // Validate anomalies array
  validateAnomalies(anomalies) {
    if (!Array.isArray(anomalies)) return [];
    
    return anomalies.filter(anomaly => 
      anomaly.type && 
      anomaly.description && 
      ['low', 'medium', 'high'].includes(anomaly.severity)
    ).map(anomaly => ({
      type: anomaly.type,
      description: anomaly.description,
      severity: anomaly.severity,
      detectedAt: this.parseDate(anomaly.detectedAt) || new Date(),
    }));
  }

  // Generate energy efficiency insights
  async generateInsights(billData, userType = 'regular') {
    try {
      const prompt = `Based on the following electricity bill data, provide energy efficiency insights and recommendations:

Bill Data:
- Consumption: ${billData.consumption?.total || 0} kWh
- Total Cost: $${billData.costs?.total || 0}
- Billing Period: ${billData.billingPeriod?.startDate} to ${billData.billingPeriod?.endDate}
- User Type: ${userType}

Please provide:
1. A summary of the bill analysis
2. Key insights about consumption patterns
3. Cost-saving recommendations
4. Energy efficiency tips
5. Any anomalies or unusual patterns

Format the response as JSON with the following structure:
{
  "summary": "string",
  "insights": [...],
  "recommendations": [...],
  "trends": {...},
  "anomalies": [...]
}`;

      const response = await axios.post(`${this.endpoint}/openai/deployments/${this.deployment}/chat/completions?api-version=${this.apiVersion}`, {
        messages: [
          {
            role: "system",
            content: "You are an energy efficiency expert providing insights and recommendations for electricity bills."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 2000,
        temperature: 0.3
      }, {
        headers: {
          'api-key': this.apiKey,
          'Content-Type': 'application/json'
        }
      });

      const content = response.data.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('No JSON found in response');
      }

    } catch (error) {
      logger.error('Failed to generate insights:', error);
      return {
        summary: 'Unable to generate insights at this time',
        insights: [],
        recommendations: [],
        trends: {},
        anomalies: [],
      };
    }
  }

  // Compare bills and identify trends
  async analyzeTrends(bills) {
    try {
      if (!Array.isArray(bills) || bills.length < 2) {
        return {
          trend: 'insufficient_data',
          message: 'Need at least 2 bills to analyze trends',
        };
      }

      const billData = bills.map(bill => ({
        date: bill.billDate,
        consumption: bill.consumption.total,
        cost: bill.costs.total,
        period: bill.billingPeriod,
      }));

      const prompt = `Analyze the following electricity bill data for trends:

${JSON.stringify(billData, null, 2)}

Identify:
1. Consumption trends (increasing/decreasing/stable)
2. Cost trends
3. Seasonal patterns
4. Anomalies or unusual patterns
5. Recommendations for improvement

Format as JSON.`;

      const response = await axios.post(`${this.endpoint}/openai/deployments/${this.deployment}/chat/completions?api-version=${this.apiVersion}`, {
        messages: [
          {
            role: "system",
            content: "You are an energy analyst specializing in identifying patterns and trends in electricity consumption."
          },
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 1500,
        temperature: 0.2
      }, {
        headers: {
          'api-key': this.apiKey,
          'Content-Type': 'application/json'
        }
      });

      const content = response.data.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]);
      } else {
        throw new Error('No JSON found in response');
      }

    } catch (error) {
      logger.error('Failed to analyze trends:', error);
      return {
        trend: 'error',
        message: 'Failed to analyze trends',
      };
    }
  }
}

module.exports = new AIService(); 