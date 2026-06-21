# ⚽ Live Scores Feature - Quick Setup

## 🚀 Quick Start (5 minutes)

### 1. Get SportMonks API Key
1. Visit [https://www.sportmonks.com/](https://www.sportmonks.com/)
2. Sign up (free tier available)
3. Copy your API key

### 2. Backend Setup

```bash
cd backend
npm install
```

Create `.env` file:
```env
PORT=5000
NODE_ENV=development
SPORTMONKS_API_KEY=your_sportmonks_api_key_here
```

Start server:
```bash
npm run dev
```

Server runs on: **http://localhost:5000**

### 3. Frontend Setup

```bash
cd frontend
npm install
```

Create `.env` file (if not exists):
```env
VITE_API_BASE_URL=http://localhost:5000/api
```

Start dev server:
```bash
npm run dev
```

App runs on: **http://localhost:5173**

### 4. Test It!

1. Login to the app
2. Navigate to **Home** page
3. See **Live Matches** section at the top
4. Matches auto-refresh every 10 seconds

---

## 📡 API Endpoints

### Get Live Matches
```bash
GET http://localhost:5000/api/live-matches
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 12345,
      "league": {
        "name": "Premier League",
        "country": "England"
      },
      "home": {
        "name": "Manchester United",
        "score": 2
      },
      "away": {
        "name": "Liverpool",
        "score": 1
      },
      "status": "LIVE",
      "minute": 67
    }
  ],
  "cached": false,
  "count": 1
}
```

### Get Today's Fixtures
```bash
GET http://localhost:5000/api/today-fixtures
```

### Clear Cache (Testing)
```bash
POST http://localhost:5000/api/live-matches/clear-cache
```

---

## 🎨 Features

✅ **Real-time Updates** - Auto-refresh every 10 seconds
✅ **Smart Caching** - 30-second backend cache
✅ **Beautiful UI** - Purple-blue gradient cards
✅ **Live Status** - Animated LIVE badge
✅ **Match Events** - Display recent goals
✅ **Loading States** - Skeleton animations
✅ **Error Handling** - Graceful fallbacks
✅ **Responsive** - Mobile, tablet, desktop

---

## 📱 UI Components

### MatchCard Features
- Team logos and names
- Current score (large, bold)
- Match status (LIVE, HT, FT)
- Current minute
- League name and country
- Recent goal events
- "View Details" button

### LiveMatches Features
- Grid layout (1-3 columns)
- Auto-refresh indicator
- Manual refresh button
- Last update timestamp
- Match count badge
- Empty state message
- Error state with retry

---

## 🔧 Troubleshooting

### "No live matches"
- ✅ Check if there are actual live matches (try at weekend/evening)
- ✅ Verify API key in `backend/.env`
- ✅ Check backend console for errors
- ✅ Test API directly: `curl http://localhost:5000/api/live-matches`

### CORS errors
- ✅ Ensure backend is running
- ✅ Check `VITE_API_BASE_URL` in frontend `.env`
- ✅ Verify ports match (backend: 5000, frontend: 5173)

### Cache not working
- ✅ Check backend logs for "Cache" messages
- ✅ Clear cache: `curl -X POST http://localhost:5000/api/live-matches/clear-cache`

---

## 📚 Full Documentation

See [LIVE_SCORES_DOCUMENTATION.md](LIVE_SCORES_DOCUMENTATION.md) for:
- Architecture details
- Code explanations
- Data flow diagrams
- Production deployment
- Future enhancements

---

## 🎯 Tech Stack

| Component | Technology |
|-----------|------------|
| Backend API | Node.js + Express |
| Database | MongoDB (Mongoose) |
| Frontend | React 18 + Vite |
| Styling | TailwindCSS |
| HTTP Client | Axios |
| Sports Data | SportMonks API |
| Icons | React Icons |

---

**That's it! You're ready to go! 🚀⚽**
