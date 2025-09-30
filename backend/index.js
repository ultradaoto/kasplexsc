/**
 * Kasplex Agricultural IP Backend
 * Main entry point for the Node.js backend service
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');

const eventMonitor = require('./services/eventMonitor');
const apiRoutes = require('./api/routes');
const logger = require('./utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors({
    origin: process.env.CORS_ORIGIN || 'http://localhost:3001'
}));
app.use(express.json());
app.use(morgan('combined', { stream: logger.stream }));

// Routes
app.use('/api', apiRoutes);

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        timestamp: new Date().toISOString(),
        network: 'Kasplex Testnet',
        chainId: process.env.CHAIN_ID || '167012'
    });
});

// Error handling
app.use((err, req, res, next) => {
    logger.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
});

// Database connection
const connectDB = async () => {
    try {
        if (process.env.MONGODB_URI) {
            await mongoose.connect(process.env.MONGODB_URI);
            logger.info('MongoDB connected successfully');
        } else {
            logger.warn('MongoDB URI not configured, running without database');
        }
    } catch (error) {
        logger.error('MongoDB connection error:', error);
        process.exit(1);
    }
};

// Start server
const startServer = async () => {
    try {
        await connectDB();
        
        app.listen(PORT, () => {
            logger.info(`Kasplex Agricultural IP Backend running on port ${PORT}`);
            logger.info(`Network: Kasplex Testnet (Chain ID: ${process.env.CHAIN_ID || '167012'})`);
            logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
        });

        // Start event monitoring
        if (process.env.IPNFT_ADDRESS) {
            eventMonitor.start();
        } else {
            logger.warn('Contract addresses not configured, event monitoring disabled');
        }
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
};

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM received, shutting down gracefully');
    eventMonitor.stop();
    await mongoose.connection.close();
    process.exit(0);
});

process.on('SIGINT', async () => {
    logger.info('SIGINT received, shutting down gracefully');
    eventMonitor.stop();
    await mongoose.connection.close();
    process.exit(0);
});

startServer();
