import { checkAndSendSavingGoalNotification, sendReminderNotification } from './fcm_service';

/**
 * Test script for triggering Firebase Push Notifications for Saving Goals & Reminders
 * 
 * Usage:
 *   npx ts-node src/test_fcm.ts YOUR_FCM_DEVICE_TOKEN
 */

async function runTest() {
  // Get token from command line arguments or use topic broadcast
  const fcmToken = process.argv[2];

  if (!fcmToken) {
    console.log('\n-------------------------------------------------------------');
    console.log('💡 TIP: You can pass your device token as an argument:');
    console.log('   npx ts-node src/test_fcm.ts <YOUR_FCM_TOKEN>');
    console.log('   (Falling back to sending via topic "saving_goals" & "reminders")');
    console.log('-------------------------------------------------------------\n');
  } else {
    console.log(`\n🚀 Sending test notifications directly to token: ${fcmToken}\n`);
  }

  // Test 1: Saving Goal 50% Milestone
  console.log('1. Testing Saving Goal (50% Milestone)...');
  await checkAndSendSavingGoalNotification({
    userId: 'user_123',
    goalId: 'goal_001',
    goalTitle: 'Emergency Fund',
    currentAmount: 500,
    targetAmount: 1000,
    fcmToken: fcmToken,
  });

  // Test 2: Saving Goal 100% Completed
  console.log('2. Testing Saving Goal (100% Target Reached)...');
  await checkAndSendSavingGoalNotification({
    userId: 'user_123',
    goalId: 'goal_002',
    goalTitle: 'New Laptop',
    currentAmount: 1500,
    targetAmount: 1500,
    fcmToken: fcmToken,
  });

  // Test 3: Daily Reminder
  console.log('3. Testing Daily Reminder...');
  await sendReminderNotification({
    userId: 'user_123',
    title: '💰 Daily Expense Check-In',
    body: 'Don\'t forget to log your daily expenses! Stay on track with your budget.',
    reminderType: 'DAILY_REMINDER',
    fcmToken: fcmToken,
  });

  console.log('\n✅ Test execution completed!');
}

runTest();
