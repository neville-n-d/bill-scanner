const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const sharp = require('sharp');
const { body, validationResult } = require('express-validator');
const Bill = require('../models/Bill');
const User = require('../models/User');
const { auth, requireUserType } = require('../middleware/auth');
const aiService = require('../services/aiService');
const terahiveService = require('../services/terahiveService');
const logger = require('../utils/logger');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadPath = process.env.UPLOAD_PATH || './uploads';
    try {
      await fs.mkdir(uploadPath, { recursive: true });
      cb(null, uploadPath);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, `bill-${req.user.userId}-${uniqueSuffix}${path.extname(file.originalname)}`);
  },
});

const fileFilter = (req, file, cb) => {
  console.log(`[DEBUG] Multer fileFilter: received file ${file.originalname}, mimetype: ${file.mimetype}`);
  if (
    file.mimetype === 'image/jpeg' ||
    file.mimetype === 'image/png' ||
    file.mimetype === 'image/webp'
  ) {
    cb(null, true);
  } else {
    cb(new Error('Invalid file type. Only JPEG, PNG, and WebP images are allowed.'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 10 * 1024 * 1024, // 10MB
  },
});

// Validation middleware
const validateBillData = [
  body('billNumber')
    .trim()
    .notEmpty()
    .withMessage('Bill number is required'),
  body('utilityProvider.name')
    .trim()
    .notEmpty()
    .withMessage('Utility provider name is required'),
  body('billDate')
    .isISO8601()
    .withMessage('Valid bill date is required'),
  body('dueDate')
    .isISO8601()
    .withMessage('Valid due date is required'),
  body('billingPeriod.startDate')
    .isISO8601()
    .withMessage('Valid billing period start date is required'),
  body('billingPeriod.endDate')
    .isISO8601()
    .withMessage('Valid billing period end date is required'),
  body('consumption.total')
    .isFloat({ min: 0 })
    .withMessage('Total consumption must be a positive number'),
  body('costs.total')
    .isFloat({ min: 0 })
    .withMessage('Total cost must be a positive number'),
];

// Always set userId on bill upload!
// @route   POST /api/bills/upload
// @desc    Upload and process new bills (multiple images)
// @access  Private
router.post('/upload', auth, upload.array('billImages', 10), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one bill image is required',
      });
    }

    // Debug: print number of files and their mimetypes
    console.log(`[DEBUG] Received ${req.files.length} files:`);
    req.files.forEach((file, idx) => {
      console.log(`[DEBUG] File #${idx + 1}: ${file.originalname}, mimetype: ${file.mimetype}`);
    });

    const billIds = [];
    for (const file of req.files) {
      // Get image dimensions
      const imageInfo = await sharp(file.path).metadata();
      // Create thumbnail
      const thumbnailPath = file.path.replace(path.extname(file.path), '_thumb.jpg');
      await sharp(file.path)
        .resize(300, 300, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 80 })
        .toFile(thumbnailPath);

      // Create bill record
      const bill = new Bill({
        userId: req.user.userId,
        billNumber: `TEMP-${Date.now()}`, // Temporary, will be updated after AI analysis
        utilityProvider: { name: 'Unknown' },
        billDate: new Date(),
        dueDate: new Date(),
        billingPeriod: { startDate: new Date(), endDate: new Date() },
        consumption: { total: 0 },
        costs: { total: 0, currency: 'USD' },
        aiAnalysis: { summary: 'Processing...' },
        image: {
          originalPath: file.path,
          thumbnailPath,
          fileSize: file.size,
          mimeType: file.mimetype,
          dimensions: { width: imageInfo.width, height: imageInfo.height },
          processingStatus: 'processing',
        },
        source: 'camera_scan',
      });
      await bill.save();
      billIds.push(bill._id);
      // Process with AI asynchronously
      processBillWithAI(bill._id, file.path).catch(error => {
        logger.error('AI processing failed for bill:', bill._id, error);
      });
    }

    res.status(201).json({
      success: true,
      message: 'Bills uploaded successfully. Processing with AI...',
      data: {
        billIds,
        processingStatus: 'processing',
      },
    });
  } catch (error) {
    logger.error('Bill upload error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload bills',
    });
  }
});

// Always set userId on bill creation!
// @route   POST /api/bills
// @desc    Create a new bill manually
// @access  Private
router.post('/', auth, validateBillData, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const billData = req.body;
    billData.userId = req.user.userId;

    // Check if user has Terahive ESS and integrate data
    if (req.user.userType === 'terahive_ess' && req.user.hasTerahiveEss) {
      try {
        const user = await User.findById(req.user.userId);
        const billingPeriod = {
          startDate: new Date(billData.billingPeriod.startDate),
          endDate: new Date(billData.billingPeriod.endDate),
        };

        const terahiveData = await terahiveService.getBillingPeriodData(
          user.terahiveEss.systemId,
          user.terahiveEss.apiCredentials.accessToken,
          billingPeriod
        );

        billData.terahiveEss = {
          isIntegrated: true,
          systemId: user.terahiveEss.systemId,
          ...terahiveData,
        };
      } catch (terahiveError) {
        logger.warn('Failed to integrate Terahive data:', terahiveError);
        // Continue without Terahive data
      }
    }

    const bill = new Bill(billData);
    await bill.save();

    // Update user statistics
    const user = await User.findById(req.user.userId);
    await user.updateStatistics(billData);

    res.status(201).json({
      success: true,
      message: 'Bill created successfully',
      data: {
        bill: await bill.populate('userId', 'firstName lastName email'),
      },
    });
  } catch (error) {
    logger.error('Bill creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create bill',
    });
  }
});

// Always filter by userId for security and privacy!
// @route   GET /api/bills
// @desc    Get all bills for the authenticated user
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const {
      page = 1,
      limit = 10,
      status,
      startDate,
      endDate,
      utilityProvider,
      sortBy = 'billDate',
      sortOrder = 'desc',
    } = req.query;

    // Build query
    const query = { userId: req.user.userId };
    
    if (status) query.status = status;
    if (utilityProvider) query['utilityProvider.name'] = new RegExp(utilityProvider, 'i');
    
    if (startDate || endDate) {
      query.billDate = {};
      if (startDate) query.billDate.$gte = new Date(startDate);
      if (endDate) query.billDate.$lte = new Date(endDate);
    }

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query with pagination
    const bills = await Bill.find(query)
      .sort(sort)
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit))
      .populate('userId', 'firstName lastName email');

    const total = await Bill.countDocuments(query);

    res.json({
      success: true,
      data: {
        bills,
        pagination: {
          currentPage: parseInt(page),
          totalPages: Math.ceil(total / parseInt(limit)),
          totalBills: total,
          hasNextPage: parseInt(page) * parseInt(limit) < total,
          hasPrevPage: parseInt(page) > 1,
        },
      },
    });
  } catch (error) {
    logger.error('Get bills error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve bills',
    });
  }
});

// @route   GET /api/bills/:id
// @desc    Get a specific bill by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    }).populate('userId', 'firstName lastName email');

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found',
      });
    }

    res.json({
      success: true,
      data: {
        bill,
      },
    });
  } catch (error) {
    logger.error('Get bill error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve bill',
    });
  }
});

// @route   PUT /api/bills/:id
// @desc    Update a bill
// @access  Private
router.put('/:id', auth, validateBillData, async (req, res) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array(),
      });
    }

    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    });

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found',
      });
    }

    // Update bill data
    Object.assign(bill, req.body);
    await bill.save();

    res.json({
      success: true,
      message: 'Bill updated successfully',
      data: {
        bill: await bill.populate('userId', 'firstName lastName email'),
      },
    });
  } catch (error) {
    logger.error('Update bill error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update bill',
    });
  }
});

// @route   DELETE /api/bills/:id
// @desc    Delete a bill
// @access  Private
router.delete('/:id', auth, async (req, res) => {
  try {
    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    });

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found',
      });
    }

    // Delete associated image files
    if (bill.image.originalPath) {
      try {
        await fs.unlink(bill.image.originalPath);
      } catch (error) {
        logger.warn('Failed to delete original image:', error);
      }
    }

    if (bill.image.thumbnailPath) {
      try {
        await fs.unlink(bill.image.thumbnailPath);
      } catch (error) {
        logger.warn('Failed to delete thumbnail:', error);
      }
    }

    await bill.deleteOne();

    res.json({
      success: true,
      message: 'Bill deleted successfully',
    });
  } catch (error) {
    logger.error('Delete bill error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete bill',
    });
  }
});

// @route   POST /api/bills/:id/verify
// @desc    Mark a bill as verified
// @access  Private
router.post('/:id/verify', auth, async (req, res) => {
  try {
    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    });

    if (!bill) {
      return res.status(404).json({
        success: false,
        message: 'Bill not found',
      });
    }

    await bill.markAsVerified();

    res.json({
      success: true,
      message: 'Bill verified successfully',
    });
  } catch (error) {
    logger.error('Verify bill error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify bill',
    });
  }
});

// @route   GET /api/bills/:id/image
// @desc    Get bill image
// @access  Private
router.get('/:id/image', auth, async (req, res) => {
  try {
    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    });

    if (!bill || !bill.image.originalPath) {
      return res.status(404).json({
        success: false,
        message: 'Bill image not found',
      });
    }

    res.sendFile(path.resolve(bill.image.originalPath));
  } catch (error) {
    logger.error('Get bill image error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve bill image',
    });
  }
});

// @route   GET /api/bills/:id/thumbnail
// @desc    Get bill thumbnail
// @access  Private
router.get('/:id/thumbnail', auth, async (req, res) => {
  try {
    const bill = await Bill.findOne({
      _id: req.params.id,
      userId: req.user.userId,
    });

    if (!bill || !bill.image.thumbnailPath) {
      return res.status(404).json({
        success: false,
        message: 'Bill thumbnail not found',
      });
    }

    res.sendFile(path.resolve(bill.image.thumbnailPath));
  } catch (error) {
    logger.error('Get bill thumbnail error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to retrieve bill thumbnail',
    });
  }
});

// Helper function to process bill with AI
async function processBillWithAI(billId, imagePath) {
  try {
    const bill = await Bill.findById(billId);
    if (!bill) {
      throw new Error('Bill not found');
    }

    // Read image file
    const imageBuffer = await fs.readFile(imagePath);
    const base64Image = imageBuffer.toString('base64');

    // Process with AI
    const aiResult = await aiService.analyzeBillImage(base64Image);

    // Update bill with AI results
    bill.billNumber = aiResult.billNumber || bill.billNumber;
    bill.utilityProvider = aiResult.utilityProvider || bill.utilityProvider;
    bill.billDate = aiResult.billDate ? new Date(aiResult.billDate) : bill.billDate;
    bill.dueDate = aiResult.dueDate ? new Date(aiResult.dueDate) : bill.dueDate;
    bill.billingPeriod = aiResult.billingPeriod || bill.billingPeriod;
    bill.consumption = aiResult.consumption || bill.consumption;
    bill.costs = aiResult.costs || bill.costs;
    bill.rates = aiResult.rates || bill.rates;
    bill.extractedText = aiResult.extractedText || bill.extractedText;
    bill.aiAnalysis = aiResult.aiAnalysis || bill.aiAnalysis;
    bill.image.processingStatus = 'completed';

    await bill.save();

    // Update user statistics
    const user = await User.findById(bill.userId);
    await user.updateStatistics(bill);

    logger.info(`AI processing completed for bill ${billId}`);
  } catch (error) {
    logger.error(`AI processing failed for bill ${billId}:`, error);
    
    // Update bill status to failed
    const bill = await Bill.findById(billId);
    if (bill) {
      bill.image.processingStatus = 'failed';
      bill.image.processingError = error.message;
      await bill.save();
    }
  }
}

module.exports = router; 