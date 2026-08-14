import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK if not already initialized
if (admin.apps.length === 0) {
  try {
    admin.initializeApp();
  } catch (error) {
    console.log('[FCM Backend] Firebase Admin SDK initialization note: Ensure GOOGLE_APPLICATION_CREDENTIALS is set for production deployment.');
  }
}

export interface SavingGoalNotificationPayload {
  userId: string;
  goalId: string;
  goalTitle: string;
  currentAmount: number;
  targetAmount: number;
  fcmToken?: string;
}

export interface ReminderNotificationPayload {
  userId: string;
  title: string;
  body: string;
  reminderType: 'DAILY_REMINDER' | 'BILL_REMINDER';
  fcmToken?: string;
}

/**
 * Trigger notification when a Saving Goal progresses or reaches 100%
 */
export async function checkAndSendSavingGoalNotification(payload: SavingGoalNotificationPayload) {
  const percentage = Math.floor((payload.currentAmount / payload.targetAmount) * 100);

  let title = '';
  let body = '';

  if (percentage >= 100) {
    title = '🎉 Saving Goal Reached!';
    body = `Congratulations! You have reached 100% of your goal "${payload.goalTitle}"!`;
  } else if (percentage >= 75) {
    title = '🔥 Almost There!';
    body = `You are 75% of the way to achieving your goal "${payload.goalTitle}"!`;
  } else if (percentage >= 50) {
    title = '💪 Halfway There!';
    body = `Great job! You hit 50% of your savings goal "${payload.goalTitle}".`;
  } else if (percentage >= 25) {
    title = '🌱 Strong Start!';
    body = `You reached 25% of your savings goal "${payload.goalTitle}". Keep going!`;
  } else {
    return; // No milestone reached yet
  }

  const fcmMessage: admin.messaging.Message = {
    notification: {
      title,
      body,
    },
    data: {
      type: 'SAVING_GOAL',
      goalId: payload.goalId,
      percentage: percentage.toString(),
    },
    ...(payload.fcmToken ? { token: payload.fcmToken } : { topic: 'saving_goals' }),
  };

  try {
    const response = await admin.messaging().send(fcmMessage);
    console.log(`[FCM Backend] Saving Goal push notification sent: ${response}`);
    return response;
  } catch (error) {
    console.error('[FCM Backend] Error sending Saving Goal notification:', error);
  }
}

/**
 * Trigger daily expense or upcoming bill reminder notification
 */
export async function sendReminderNotification(payload: ReminderNotificationPayload) {
  const fcmMessage: admin.messaging.Message = {
    notification: {
      title: payload.title,
      body: payload.body,
    },
    data: {
      type: payload.reminderType,
      userId: payload.userId,
    },
    ...(payload.fcmToken ? { token: payload.fcmToken } : { topic: 'reminders' }),
  };

  try {
    const response = await admin.messaging().send(fcmMessage);
    console.log(`[FCM Backend] Reminder push notification sent: ${response}`);
    return response;
  } catch (error) {
    console.error('[FCM Backend] Error sending Reminder notification:', error);
  }
}
