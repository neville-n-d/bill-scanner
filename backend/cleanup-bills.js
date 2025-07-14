const mongoose = require('mongoose');
require('dotenv').config();

const Bill = require('./src/models/Bill');
const User = require('./src/models/User');

async function cleanupBills() {
  try {
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/electricity_bill_app';
    await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('Connected to MongoDB');

    // Delete bills with no userId
    const result = await Bill.deleteMany({ $or: [ { userId: { $exists: false } }, { userId: null } ] });
    console.log(`Deleted ${result.deletedCount} bills with no userId.`);

    // Print summary of remaining bills by user
    const bills = await Bill.find({}).populate('userId', 'email firstName lastName');
    const userBillMap = {};
    bills.forEach(bill => {
      const user = bill.userId;
      const userKey = user ? `${user.email} (${user.firstName} ${user.lastName})` : 'Unknown User';
      if (!userBillMap[userKey]) userBillMap[userKey] = [];
      userBillMap[userKey].push(bill._id.toString());
    });

    console.log('\nRemaining bills by user:');
    Object.entries(userBillMap).forEach(([user, billIds]) => {
      console.log(`- ${user}: ${billIds.length} bill(s)`);
    });

    await mongoose.connection.close();
    console.log('Disconnected from MongoDB');
  } catch (error) {
    console.error('Error during cleanup:', error);
    process.exit(1);
  }
}

cleanupBills(); 