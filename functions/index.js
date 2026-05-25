const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

// 🔐 Secure SendGrid API key (stored in Firebase Secrets)
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

const MAX_FCM_TOKENS_PER_BATCH = 500;

function getUserTokens(user) {
  const tokens = [];

  if (Array.isArray(user.fcmTokens)) {
    tokens.push(...user.fcmTokens);
  }

  if (typeof user.fcmToken === "string" && user.fcmToken.trim()) {
    tokens.push(user.fcmToken);
  }

  return [...new Set(tokens.filter(Boolean))];
}

function alertTargetsUser(alert, user, userId) {
  const targets = Array.isArray(alert.targetUsers) ? alert.targetUsers : [];
  const role = String(user.role || "").toLowerCase();

  if (targets.includes("all_users")) return true;
  if (targets.includes(userId) || targets.includes(user.id)) return true;
  if (user.email && targets.includes(user.email)) return true;
  if ((targets.includes("all_managers") || targets.includes("managers")) && role === "manager") return true;
  if ((targets.includes("all_guards") || targets.includes("guards")) && role === "guard") return true;

  return targets.length === 0 || alert.isMassAlert === true
    ? role === "manager"
    : false;
}

function chunkArray(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

async function removeInvalidTokens(tokenOwners, invalidTokens) {
  if (invalidTokens.length === 0) return;

  const db = admin.firestore();
  const batch = db.batch();

  invalidTokens.forEach((token) => {
    const userId = tokenOwners[token];
    if (!userId) return;

    batch.update(db.collection("users").doc(userId), {
      fcmTokens: admin.firestore.FieldValue.arrayRemove(token),
    });
  });

  await batch.commit();
}

/**
 * Trigger: when a new report is created in Firestore
 */
exports.sendReportEmail = onDocumentCreated(
  {
    document: "reports/{reportId}",
    secrets: [SENDGRID_API_KEY],
  },
  async (event) => {
    const report = event.data.data();
    let managerEmails = [];

    try {
      console.log("🚨 SECURITY ALERT: New report detected");
      console.log("📊 Report ID:", event.params.reportId);
      console.log("📍 Location:", report.locationName);
      console.log("📊 Status:", report.status.toUpperCase());
      console.log("👤 Submitted by:", report.userName);

      // Set SendGrid key securely
      sgMail.setApiKey(SENDGRID_API_KEY.value());

      // Get all users
      const usersSnapshot = await admin.firestore().collection("users").get();

      managerEmails = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.role === "manager") {
          managerEmails.push(user.email);
        }
      });

      console.log("👥 Found", managerEmails.length, "managers to notify:", managerEmails);

      if (managerEmails.length === 0) {
        console.log("⚠️ No managers found - no emails will be sent");
        return;
      }

      // Enhanced email message with HTML formatting
      const msg = {
        to: managerEmails,
        from: "mkasigiven09@gmail.com", // MUST be verified in SendGrid
        subject: `🚨 SECURITY ALERT: ${report.status.toUpperCase()} - ${report.locationName}`,
        text: `
SECURITY PATROL REPORT NOTIFICATION
=====================================

📍 Location: ${report.locationName}
📊 Status: ${report.status.toUpperCase()}
👤 Submitted by: ${report.userName || "Unknown"}
⏰ Date & Time: ${new Date(report.timestamp).toLocaleString()}
🆔 Report ID: ${event.params.reportId}

📝 Notes:
${report.notes || "No notes provided"}

📍 GPS Coordinates:
${report.latitude ? `${report.latitude}, ${report.longitude}` : "Not available"}

📸 Photo: ${report.imageUrl ? "Available" : "Not available"}

=====================================
This is an automated notification from the Security Patrol Monitoring System.
Please log in to view detailed information and take necessary action.
        `,
        html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Patrol Report</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 20px; border-radius: 0 0 10px 10px; }
        .alert-${report.status} { 
            background: ${report.status === 'emergency' ? '#dc3545' : report.status === 'suspicious' ? '#ffc107' : '#28a745'}; 
            color: white; padding: 10px; border-radius: 5px; text-align: center; font-weight: bold;
        }
        .details { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #007bff; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚨 SECURITY PATROL REPORT</h1>
            <p>Automated Alert Notification</p>
        </div>
        
        <div class="content">
            <div class="alert-${report.status}">
                STATUS: ${report.status.toUpperCase()}
            </div>
            
            <div class="details">
                <h3>📍 Location</h3>
                <p><strong>${report.locationName}</strong></p>
            </div>
            
            <div class="details">
                <h3>👤 Submitted By</h3>
                <p>${report.userName || "Unknown User"}</p>
            </div>
            
            <div class="details">
                <h3>⏰ Date & Time</h3>
                <p>${new Date(report.timestamp).toLocaleString()}</p>
            </div>
            
            <div class="details">
                <h3>📝 Notes</h3>
                <p>${report.notes || "No notes provided"}</p>
            </div>
            
            ${report.latitude ? `
            <div class="details">
                <h3>📍 GPS Coordinates</h3>
                <p>${report.latitude}, ${report.longitude}</p>
            </div>
            ` : ''}
            
            <div class="details">
                <h3>📸 Photo Evidence</h3>
                <p>${report.imageUrl ? "✅ Photo Available" : "❌ No Photo"}</p>
            </div>
            
            <div class="details">
                <h3>🆔 Report ID</h3>
                <p><code>${event.params.reportId}</code></p>
            </div>
        </div>
        
        <div class="footer">
            <p>This is an automated notification from the Security Patrol Monitoring System.</p>
            <p>Please log in to your dashboard to view detailed information and take necessary action.</p>
        </div>
    </div>
</body>
</html>
        `,
      };

      await sgMail.sendMultiple(msg);

      console.log("✅ Emails sent successfully to", managerEmails.length, "managers");
      console.log("📧 Subject:", msg.subject);
      
      // Log email delivery for tracking
      await admin.firestore().collection("email_logs").add({
        type: "manager_notification",
        reportId: event.params.reportId,
        reportStatus: report.status,
        locationName: report.locationName,
        managerEmails: managerEmails,
        sentAt: new Date().toISOString(),
        success: true
      });
      
    } catch (error) {
      console.error("❌ Email sending failed:", error);
      
      // Log failure for debugging
      await admin.firestore().collection("email_logs").add({
        type: "manager_notification",
        reportId: event.params.reportId,
        reportStatus: report.status,
        locationName: report.locationName,
        managerEmails: managerEmails,
        sentAt: new Date().toISOString(),
        success: false,
        error: error.message
      });
    }
  }
);

/**
 * Trigger: when any alert is created in Firestore, notify the right mobile users.
 */
exports.sendAlertPushNotification = onDocumentCreated(
  {
    document: "alerts/{alertId}",
  },
  async (event) => {
    const alert = event.data.data();
    const alertId = event.params.alertId;
    const db = admin.firestore();

    try {
      const usersSnapshot = await db.collection("users").get();
      const tokenOwners = {};
      const tokens = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (!alertTargetsUser(alert, user, doc.id)) return;

        getUserTokens(user).forEach((token) => {
          tokenOwners[token] = doc.id;
          tokens.push(token);
        });
      });

      const uniqueTokens = [...new Set(tokens)];

      if (uniqueTokens.length === 0) {
        console.log("No FCM tokens found for alert", alertId);
        await db.collection("notification_logs").add({
          type: "alert_push",
          alertId,
          sentAt: new Date().toISOString(),
          success: true,
          recipientCount: 0,
          message: "No recipient tokens found",
        });
        return;
      }

      const priority = String(alert.priority || "medium").toUpperCase();
      const location = alert.locationName ? ` - ${alert.locationName}` : "";
      const notificationTitle = alert.title || `${priority} Alert${location}`;
      const notificationBody = alert.message || "Open the app to review this alert.";
      let successCount = 0;
      let failureCount = 0;
      const invalidTokens = [];

      for (const tokenBatch of chunkArray(uniqueTokens, MAX_FCM_TOKENS_PER_BATCH)) {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: tokenBatch,
          notification: {
            title: notificationTitle,
            body: notificationBody,
          },
          data: {
            type: "alert",
            alertId,
            priority: String(alert.priority || ""),
            alertType: String(alert.type || ""),
            status: String(alert.status || ""),
            route: "/alert_center",
          },
          android: {
            priority: "high",
            notification: {
              priority: "high",
              sound: "default",
            },
          },
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        response.responses.forEach((sendResult, index) => {
          const code = sendResult.error && sendResult.error.code;
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            invalidTokens.push(tokenBatch[index]);
          }
        });
      }

      await removeInvalidTokens(tokenOwners, invalidTokens);

      await db.collection("notification_logs").add({
        type: "alert_push",
        alertId,
        alertPriority: alert.priority || null,
        alertType: alert.type || null,
        sentAt: new Date().toISOString(),
        success: failureCount === 0,
        recipientCount: uniqueTokens.length,
        successCount,
        failureCount,
        invalidTokenCount: invalidTokens.length,
      });

      console.log(
        `Alert push sent for ${alertId}: ${successCount} success, ${failureCount} failed`
      );
    } catch (error) {
      console.error("Alert push notification failed:", error);
      await db.collection("notification_logs").add({
        type: "alert_push",
        alertId,
        sentAt: new Date().toISOString(),
        success: false,
        error: error.message,
      });
    }
  }
);
