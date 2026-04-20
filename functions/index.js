const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const sgMail = require("@sendgrid/mail");

admin.initializeApp();

// 🔐 Secure SendGrid API key (stored in Firebase Secrets)
const SENDGRID_API_KEY = defineSecret("SENDGRID_API_KEY");

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

    try {
      // Set SendGrid key securely
      sgMail.setApiKey(SENDGRID_API_KEY.value());

      // Get all users
      const usersSnapshot = await admin.firestore().collection("users").get();

      const managers = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();
        if (user.role === "manager") {
          managers.push(user.email);
        }
      });

      if (managers.length === 0) {
        console.log("No managers found");
        return;
      }

      // Email message
      const msg = {
        to: managers,
        from: "mkasigiven09@gmail.com", // MUST be verified in SendGrid
        subject: `New Patrol Report - ${report.status.toUpperCase()}`,
        text: `
SECURITY PATROL REPORT

Location: ${report.locationName}
Status: ${report.status}
User: ${report.userName || "Unknown"}
Notes: ${report.notes || "None"}
        `,
      };

      await sgMail.sendMultiple(msg);

      console.log("Emails sent successfully to managers");
    } catch (error) {
      console.error("Email error:", error);
    }
  }
);