const nodemailer = require('nodemailer');
const fs = require('fs').promises;
const path = require('path');
const logger = require('./logger');

class EmailService {
  constructor() {
    this.transporter = null;
    this.templates = {};
    // Don't initialize immediately - let it be done lazily
  }

  // Initialize email transporter
  async initializeTransporter() {
    try {
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: process.env.SMTP_PORT === '465',
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASS,
        },
      });

      // Verify connection
      await this.transporter.verify();
      logger.info('Email service initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize email service:', error);
      this.transporter = null;
    }
  }

  // Load email templates
  async loadTemplates() {
    try {
      const templatesDir = path.join(__dirname, '../templates/emails');
      const templateFiles = await fs.readdir(templatesDir);

      for (const file of templateFiles) {
        if (file.endsWith('.html')) {
          const templateName = path.basename(file, '.html');
          const templatePath = path.join(templatesDir, file);
          const templateContent = await fs.readFile(templatePath, 'utf8');
          this.templates[templateName] = templateContent;
        }
      }

      logger.info(`Loaded ${Object.keys(this.templates).length} email templates`);
    } catch (error) {
      logger.error('Failed to load email templates:', error);
    }
  }

  // Render template with data
  renderTemplate(templateName, data) {
    let template = this.templates[templateName];
    
    if (!template) {
      logger.warn(`Email template not found: ${templateName}`);
      return this.getDefaultTemplate(data);
    }

    // Replace placeholders with data
    Object.keys(data).forEach(key => {
      const placeholder = `{{${key}}}`;
      const value = typeof data[key] === 'object' ? JSON.stringify(data[key]) : data[key];
      template = template.replace(new RegExp(placeholder, 'g'), value);
    });

    return template;
  }

  // Get default template
  getDefaultTemplate(data) {
    return `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <title>Electricity Bill App</title>
        </head>
        <body>
          <div style="max-width: 600px; margin: 0 auto; padding: 20px; font-family: Arial, sans-serif;">
            <h2>Electricity Bill App Notification</h2>
            <p>Hello ${data.name || 'User'},</p>
            <p>${data.message || 'You have a new notification from the Electricity Bill App.'}</p>
            <p>Best regards,<br>Electricity Bill App Team</p>
          </div>
        </body>
      </html>
    `;
  }

  // Send email
  async sendEmail(options) {
    try {
      // Initialize transporter if not already done
      if (!this.transporter) {
        await this.initializeTransporter();
        await this.loadTemplates();
      }
      
      if (!this.transporter) {
        logger.warn('Email service not available, skipping email send');
        return null;
      }

      const { to, subject, template, data, html, text } = options;

      if (!to || !subject) {
        throw new Error('Recipient and subject are required');
      }

      let emailHtml = html;
      let emailText = text;

      // Render template if provided
      if (template) {
        emailHtml = this.renderTemplate(template, data);
        emailText = this.htmlToText(emailHtml);
      }

      const mailOptions = {
        from: `"Electricity Bill App" <${process.env.SMTP_USER}>`,
        to,
        subject,
        html: emailHtml,
        text: emailText,
      };

      const result = await this.transporter.sendMail(mailOptions);
      
      logger.info('Email sent successfully:', {
        to,
        subject,
        messageId: result.messageId,
      });

      return result;
    } catch (error) {
      logger.error('Failed to send email:', error);
      throw error;
    }
  }

  // Convert HTML to plain text
  htmlToText(html) {
    return html
      .replace(/<[^>]*>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .trim();
  }

  // Send email verification
  async sendEmailVerification(email, name, verificationUrl) {
    return this.sendEmail({
      to: email,
      subject: 'Verify Your Email Address - Electricity Bill App',
      template: 'emailVerification',
      data: {
        name,
        verificationUrl,
        appName: 'Electricity Bill App',
        supportEmail: process.env.SMTP_USER,
      },
    });
  }

  // Send password reset
  async sendPasswordReset(email, name, resetUrl) {
    return this.sendEmail({
      to: email,
      subject: 'Reset Your Password - Electricity Bill App',
      template: 'passwordReset',
      data: {
        name,
        resetUrl,
        appName: 'Electricity Bill App',
        supportEmail: process.env.SMTP_USER,
      },
    });
  }

  // Send bill reminder
  async sendBillReminder(email, name, billData) {
    return this.sendEmail({
      to: email,
      subject: `Bill Reminder - ${billData.reminderType.replace('_', ' ').toUpperCase()}`,
      template: 'billReminder',
      data: {
        name,
        billNumber: billData.billNumber,
        dueDate: new Date(billData.dueDate).toLocaleDateString(),
        amount: `$${billData.amount.toFixed(2)}`,
        utilityProvider: billData.utilityProvider,
        reminderType: billData.reminderType,
        appName: 'Electricity Bill App',
      },
    });
  }

  // Send energy alert
  async sendEnergyAlert(email, name, alertData) {
    return this.sendEmail({
      to: email,
      subject: `Energy Alert - ${alertData.alertType.replace('_', ' ').toUpperCase()}`,
      template: 'energyAlert',
      data: {
        name,
        alertType: alertData.alertType,
        ...alertData,
        appName: 'Electricity Bill App',
      },
    });
  }

  // Send system alert
  async sendSystemAlert(email, name, alertData) {
    return this.sendEmail({
      to: email,
      subject: `System Alert - ${alertData.alertType.replace('_', ' ').toUpperCase()}`,
      template: 'systemAlert',
      data: {
        name,
        systemName: alertData.systemName,
        alertType: alertData.alertType,
        ...alertData,
        appName: 'Electricity Bill App',
      },
    });
  }

  // Send welcome email
  async sendWelcomeEmail(email, name, userType) {
    return this.sendEmail({
      to: email,
      subject: 'Welcome to Electricity Bill App',
      template: 'welcome',
      data: {
        name,
        userType,
        appName: 'Electricity Bill App',
        supportEmail: process.env.SMTP_USER,
      },
    });
  }

  // Send monthly report
  async sendMonthlyReport(email, name, reportData) {
    return this.sendEmail({
      to: email,
      subject: 'Your Monthly Energy Report - Electricity Bill App',
      template: 'monthlyReport',
      data: {
        name,
        month: reportData.month,
        totalConsumption: reportData.totalConsumption,
        totalCost: reportData.totalCost,
        averageConsumption: reportData.averageConsumption,
        averageCost: reportData.averageCost,
        savings: reportData.savings,
        insights: reportData.insights,
        recommendations: reportData.recommendations,
        appName: 'Electricity Bill App',
      },
    });
  }
}

// Export the class
module.exports = EmailService; 