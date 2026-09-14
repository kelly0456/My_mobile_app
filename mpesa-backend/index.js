const express = require('express');
const axios = require('axios');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json());

const port = process.env.PORT || 5000;

app.get('/', (req, res) => {
    res.send('M-Pesa backend is running!');
});

// ============================================================
// GENERATE MPESA ACCESS TOKEN
// ============================================================
const generateToken = async (req, res, next) => {
    const consumerKey = process.env.MPESA_CONSUMER_KEY;
    const consumerSecret = process.env.MPESA_CONSUMER_SECRET;
    const auth = Buffer.from(`${consumerKey}:${consumerSecret}`).toString('base64');

    try {
        const response = await axios.get(
            'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
            {
                headers: {
                    Authorization: `Basic ${auth}`,
                },
            }
        );
        req.token = response.data.access_token;
        next();
    } catch (error) {
        console.error('Error generating token:', error.response ? error.response.data : error.message);
        res.status(400).json({ error: 'Failed to generate access token' });
    }
};

// ============================================================
// STK PUSH (LIPA NA MPESA ONLINE)
// ============================================================
app.post('/stkpush', generateToken, async (req, res) => {
    const phone = req.body.phone;
    const amount = req.body.amount;

    // Formatting phone number to 254XXXXXXXXX
    const formattedPhone = phone.startsWith('0') ? '254' + phone.slice(1) : phone;

    const shortCode = process.env.MPESA_SHORTCODE;
    const passkey = process.env.MPESA_PASSKEY;
    const timestamp = new Date().toISOString().replace(/[^0-9]/g, '').slice(0, 14);
    const password = Buffer.from(shortCode + passkey + timestamp).toString('base64');

    const stkPushData = {
        BusinessShortCode: shortCode,
        Password: password,
        Timestamp: timestamp,
        TransactionType: 'CustomerPayBillOnline',
        Amount: amount,
        PartyA: formattedPhone,
        PartyB: shortCode,
        PhoneNumber: formattedPhone,
        CallBackURL: process.env.MPESA_CALLBACK_URL,
        AccountReference: 'ShopifyApp',
        TransactionDesc: 'Payment for products',
    };

    try {
        const response = await axios.post(
            'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
            stkPushData,
            {
                headers: {
                    Authorization: `Bearer ${req.token}`,
                },
            }
        );
        res.status(200).json(response.data);
    } catch (error) {
        console.error('STK Push Error:', error.response ? error.response.data : error.message);
        res.status(400).json({ error: 'STK Push failed' });
    }
});

// =============
// CALLBACK
// =============
app.post('/callback', (req, res) => {
    console.log('--- MPESA CALLBACK RECEIVED ---');
    console.log(JSON.stringify(req.body, null, 2));
    res.status(200).send('OK');
});

app.listen(port, () => {
    console.log(`M-Pesa backend running on port ${port}`);
});
