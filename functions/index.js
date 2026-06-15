const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret, defineString } = require('firebase-functions/params');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

const smtpHost = defineSecret('SMTP_HOST');
const smtpUser = defineSecret('SMTP_USER');
const smtpPass = defineSecret('SMTP_PASS');
const smtpFrom = defineSecret('SMTP_FROM');
const smtpPort = defineString('SMTP_PORT', { default: '587' });

const smtpSecrets = [smtpHost, smtpUser, smtpPass, smtpFrom];

function crearTransport() {
  const host = smtpHost.value();
  const user = smtpUser.value();
  const pass = smtpPass.value();
  if (!host || !user || !pass) {
    return null;
  }
  const port = Number(smtpPort.value()) || 587;
  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
}

exports.enviarEmailUtilero = onDocumentCreated(
  {
    document: 'emails_utilero/{emailId}',
    secrets: smtpSecrets,
  },
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const data = snap.data();
    if (!data || data.estado !== 'pendiente') return;

    const ref = snap.ref;
    const para = (data.para || '').trim();
    const asunto = (data.asunto || 'DTFly Utilero').trim();
    const cuerpo = (data.cuerpo || '').trim();
    const html = data.html || null;

    if (!para || !para.includes('@')) {
      await ref.update({
        estado: 'error',
        error: 'Destinatario inválido',
        procesado_en: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const transport = crearTransport();
    if (!transport) {
      await ref.update({
        estado: 'error',
        error:
          'SMTP no configurado. Ejecuta firebase functions:secrets:set para SMTP_HOST, SMTP_USER, SMTP_PASS y SMTP_FROM.',
        procesado_en: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    const from =
      smtpFrom.value().trim() || smtpUser.value().trim() || 'dtfly@localhost';

    try {
      await transport.sendMail({
        from,
        to: para,
        subject: asunto,
        text: cuerpo || asunto,
        html: html || undefined,
      });
      await ref.update({
        estado: 'enviado',
        procesado_en: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      await ref.update({
        estado: 'error',
        error: String(err.message || err),
        procesado_en: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  },
);
