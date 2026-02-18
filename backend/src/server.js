import dotenv from 'dotenv'
import express from 'express'
import cors from 'cors'
import helmet from 'helmet'
import morgan from 'morgan'
import { fileURLToPath } from 'url'
import { dirname, join } from 'path'

// Import routes
import liveRoutes from './routes/liveRoutes.js'

// Get current file's directory
const __filename = fileURLToPath(
    import.meta.url)
const __dirname = dirname(__filename)

// Load .env from backend root directory
dotenv.config({ path: join(__dirname, '..', '.env') })

const app = express()
const PORT = process.env.PORT || 5000

// Middleware
app.use(helmet()) // Security headers
app.use(cors()) // Enable CORS
app.use(express.json()) // Parse JSON bodies
app.use(express.urlencoded({ extended: true })) // Parse URL-encoded bodies
app.use(morgan('dev')) // Logging

// Health check route
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'GOALSIGHT API is running',
        version: '1.0.0',
    })
})

// API Routes
app.use('/api', liveRoutes)

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Route not found',
    })
})

// Error handler
app.use((err, req, res, next) => {
    console.error('Server error:', err)

    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal server error',
        error: process.env.NODE_ENV === 'development' ? err.stack : undefined,
    })
})

// Start server
app.listen(PORT, () => {
    console.log(`🚀 GOALSIGHT Server running on port ${PORT}`)
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`)
    console.log(`🔑 SportMonks API: ${process.env.SPORTMONKS_API_KEY ? 'Configured ✓' : 'Not configured ✗'}`)
})

export default app