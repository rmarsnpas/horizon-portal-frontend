// Simplified PBX Backend for Cloud Run
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pbxFlowroute = require('./pbx-flowroute');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'pbx-backend' });
});

// PBX API Routes
app.post('/api/pbx/make-call', async (req, res) => {
    try {
        const { from, to } = req.body;
        const result = await pbxFlowroute.makeOutboundCall(from, to);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/pbx/send-sms', async (req, res) => {
    try {
        const { to, message } = req.body;
        const result = await pbxFlowroute.sendSMS(to, message);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/pbx/call-log', async (req, res) => {
    try {
        const logs = await pbxFlowroute.getCallLog();
        res.json(logs);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/pbx/voicemails', async (req, res) => {
    try {
        const voicemails = await pbxFlowroute.getVoicemails();
        res.json(voicemails);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/pbx/stats', async (req, res) => {
    try {
        const stats = await pbxFlowroute.getCallStats();
        res.json(stats);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/pbx/incoming-sms', async (req, res) => {
    try {
        await pbxFlowroute.handleIncomingSMS(req.body);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/pbx/incoming-call', async (req, res) => {
    try {
        await pbxFlowroute.handleIncomingCall(req.body);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Start server - MUST bind to 0.0.0.0 for Cloud Run
app.listen(PORT, '0.0.0.0', () => {
    console.log(`PBX Backend running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`Flowroute DID: ${process.env.FLOWROUTE_DID}`);
});
