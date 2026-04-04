# ⚽ GOALSIGHT - Football Statistics Platform

A modern football statistics website inspired by 365Scores, featuring live match tracking, player stats, and league information with a beautiful purple-blue gradient theme.

## 🎨 Design Philosophy

- **Purple → Blue gradient** primary colors
- **Soft rounded cards** (border-radius: 16px+)
- **Modern sports-tech UI** aesthetic
- **Soft shadows** and clean spacing
- **Smooth hover animations**
- **Modern typography** (Inter font family)

## 🚀 Tech Stack

### Frontend
- **React 18** with Vite
- **TailwindCSS** for styling
- **React Router v6** for navigation
- **Axios** for API calls
- **Socket.IO Client** for real-time updates
- **Recharts** for data visualization

### Backend
- **Node.js** with Express
- **MongoDB** with Mongoose
- **JWT** authentication
- **Socket.IO** for real-time features
- **Bcrypt** for password hashing

## 📁 Project Structure

```
GOALSIGHT/
├── frontend/              # React application
│   ├── src/
│   │   ├── components/    # Reusable components
│   │   ├── layouts/       # Page layouts
│   │   ├── pages/         # Page components
│   │   ├── services/      # API services
│   │   ├── hooks/         # Custom hooks
│   │   ├── context/       # Context providers
│   │   └── utils/         # Utility functions
│   └── public/
└── backend/               # Express API
    └── src/
        ├── controllers/   # Route controllers
        ├── models/        # Database models
        ├── routes/        # API routes
        ├── middleware/    # Custom middleware
        ├── services/      # Business logic
        ├── socket/        # Socket.IO handlers
        └── config/        # Configuration files
```

## 🛠️ Installation

### Prerequisites
- Node.js 18+ 
- MongoDB 6+
- npm or yarn

### Backend Setup

```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your configuration
npm run dev
```

### Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

## 🌐 Features

### Fan Portal
- **Home Page**: Live matches, today's fixtures, trending leagues
- **Match Page**: Live scores, timeline, match statistics
- **League Page**: Standings table, top scorers, fixtures
- **Team Page**: Squad list, team statistics
- **Player Page**: Player information, season stats with charts

### Admin Panel
- Match management
- Data updates
- User management

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user

### Matches
- `GET /api/matches` - Get all matches
- `GET /api/matches/:id` - Get match details
- `GET /api/matches/live` - Get live matches

### Leagues
- `GET /api/leagues` - Get all leagues
- `GET /api/leagues/:id` - Get league details
- `GET /api/leagues/:id/standings` - Get league standings

### Teams
- `GET /api/teams/:id` - Get team details
- `GET /api/teams/:id/squad` - Get team squad

### Players
- `GET /api/players/:id` - Get player details
- `GET /api/players/:id/stats` - Get player statistics

## 🎨 Tailwind Theme

The project uses a custom Tailwind configuration with:
- Purple to blue gradients
- Custom color palette
- Smooth animations
- Modern spacing system

## 📱 Responsive Design

Fully responsive design optimized for:
- Desktop (1920px+)
- Laptop (1024px+)
- Tablet (768px+)
- Mobile (375px+)

## 🔐 Environment Variables

### Backend (.env)
```
PORT=5000
MONGODB_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
NODE_ENV=development
```

### Frontend (.env)
```
VITE_API_URL=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5000
```

## 📄 License

MIT License

## 👥 Team

Graduation Project - GOALSIGHT Team

---

Made with ⚽ and 💜 by GOALSIGHT Team
