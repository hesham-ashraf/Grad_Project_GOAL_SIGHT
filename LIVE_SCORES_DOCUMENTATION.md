# ⚽ Live Scores Feature - Implementation Guide

## 🎯 Overview

This feature integrates **SportMonks API** to display real-time football match scores in the GOALSIGHT platform. It includes both backend (Node.js/Express) and frontend (React) implementations with auto-refresh capabilities.

---

## 📁 Architecture

```
Backend (MVC + Services Pattern)
├── services/
│   └── sportmonksService.js    # API integration layer
├── controllers/
│   └── liveController.js       # Request handling + caching
├── routes/
│   └── liveRoutes.js          # Route definitions
└── server.js                   # Main application entry

Frontend (Component-Based)
├── utils/
│   └── axios.js               # HTTP client configuration
├── components/
│   ├── LiveMatches.jsx        # Main live scores component
│   └── match/
│       └── MatchCard.jsx      # Individual match card UI
└── pages/
    └── HomePage.jsx           # Integrates LiveMatches
```

---

## 🔧 Backend Implementation

### 1. **SportMonks Service** (`services/sportmonksService.js`)

**Purpose:** Handle all API calls to SportMonks

**Key Features:**
- Fetches live/in-play matches
- Fetches today's fixtures
- Normalizes API responses
- Error handling with fallback

**Main Methods:**
```javascript
getLiveMatches()      // Returns live matches
getTodayFixtures()    // Returns today's scheduled matches
```

**Normalized Response Structure:**
```javascript
{
  id: 12345,
  league: {
    name: "Premier League",
    country: "England",
    logo: "https://..."
  },
  round: "Round 15",
  home: {
    id: 1,
    name: "Manchester United",
    logo: "https://...",
    score: 2
  },
  away: {
    id: 2,
    name: "Liverpool",
    logo: "https://...",
    score: 1
  },
  status: "LIVE",
  minute: 67,
  startTime: "2024-02-16T15:00:00Z",
  events: [
    {
      minute: 23,
      type: "Goal",
      player: "Marcus Rashford",
      team: "home",
      injuryTime: null
    }
  ]
}
```

### 2. **Live Controller** (`controllers/liveController.js`)

**Purpose:** Handle HTTP requests and implement caching

**Key Features:**
- **30-second in-memory cache** to reduce API calls
- Returns cache age in response
- Error handling with proper status codes

**Endpoints:**
```javascript
GET  /api/live-matches              // Get live matches (cached)
GET  /api/today-fixtures             // Get today's fixtures
POST /api/live-matches/clear-cache  // Clear cache (testing)
```

**Response Format:**
```javascript
{
  success: true,
  data: [...matches],
  cached: false,
  count: 5,
  cacheAge: 0  // seconds since last fetch
}
```

### 3. **Routes** (`routes/liveRoutes.js`)

Simple Express router connecting endpoints to controller methods.

### 4. **Server Setup** (`server.js`)

**Middleware Stack:**
- `helmet` - Security headers
- `cors` - Cross-origin requests
- `express.json()` - Parse JSON bodies
- `morgan` - Request logging

**Environment Check:**
The server validates that `SPORTMONKS_API_KEY` is configured on startup.

---

## 🎨 Frontend Implementation

### 1. **Axios Setup** (`utils/axios.js`)

**Purpose:** Centralized HTTP client configuration

**Features:**
- Base URL from environment variable
- Request interceptor (adds auth token)
- Response interceptor (handles 401 errors)
- 10-second timeout

**Usage:**
```javascript
import axios from '../utils/axios'
const response = await axios.get('/live-matches')
```

### 2. **MatchCard Component** (`components/match/MatchCard.jsx`)

**Purpose:** Display individual match information

**Design:**
- **Header:** Purple-blue gradient with league info and status badge
- **Body:** Team logos, names, and scores
- **Events:** Recent goals with player names and minutes
- **Footer:** "View Details" button (navigates to match details page)

**Status Badges:**
- `LIVE` - Red with pulse animation
- `HT` - Yellow (Half Time)
- `FT` - Gray (Full Time)
- Default - Light gray

**Responsive:**
- Desktop: 3 columns
- Tablet: 2 columns
- Mobile: 1 column

### 3. **LiveMatches Component** (`components/LiveMatches.jsx`)

**Purpose:** Fetch and display all live matches

**Key Features:**
- ✅ Initial fetch on mount
- ✅ Auto-refresh every 10 seconds
- ✅ Manual refresh button
- ✅ Loading skeleton
- ✅ Error state with retry
- ✅ Empty state ("No live matches")
- ✅ Shows last update time
- ✅ Match count badge

**States:**
```javascript
Loading:  Skeleton cards animation
Error:    Red alert box with retry button
Empty:    Centered message with football icon
Success:  Grid of MatchCard components
```

### 4. **HomePage Integration**

The `LiveMatches` component is placed at the top of the home page, right after the header and before other sections.

---

## 🔑 Environment Variables

### Backend (`.env`)
```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/goalsight
JWT_SECRET=your_secret
SPORTMONKS_API_KEY=your_sportmonks_api_key_here
```

### Frontend (`.env`)
```env
VITE_API_BASE_URL=http://localhost:5000/api
VITE_API_URL=http://localhost:5000
```

---

## 🚀 Getting Started

### 1. **Get SportMonks API Key**
- Visit [https://www.sportmonks.com/](https://www.sportmonks.com/)
- Sign up for a free account
- Get your API key from the dashboard
- Add to `backend/.env`:
  ```
  SPORTMONKS_API_KEY=your_actual_key_here
  ```

### 2. **Install Dependencies**

**Backend:**
```bash
cd backend
npm install
```

**Frontend:**
```bash
cd frontend
npm install
```

### 3. **Start Development Servers**

**Backend:**
```bash
cd backend
npm run dev
# Server runs on http://localhost:5000
```

**Frontend:**
```bash
cd frontend
npm run dev
# App runs on http://localhost:5173
```

### 4. **Test the API**

**Direct API Test:**
```bash
curl http://localhost:5000/api/live-matches
```

**Expected Response:**
```json
{
  "success": true,
  "data": [...],
  "cached": false,
  "count": 3
}
```

---

## 🧪 Testing

### Backend Tests

**Test live matches endpoint:**
```bash
curl http://localhost:5000/api/live-matches
```

**Test cache:**
```bash
# First call - fresh data
curl http://localhost:5000/api/live-matches

# Second call within 30 seconds - cached
curl http://localhost:5000/api/live-matches
# Response includes: "cached": true, "cacheAge": 5
```

**Clear cache:**
```bash
curl -X POST http://localhost:5000/api/live-matches/clear-cache
```

### Frontend Tests

1. **Login** to the app
2. Navigate to **Home** page
3. Check if **Live Matches** section appears
4. Verify auto-refresh (watch console for API calls every 10s)
5. Click **Refresh** button manually

---

## 📊 Data Flow

```
┌─────────────────┐
│  SportMonks API │
└────────┬────────┘
         │
         ↓ HTTP Request (with API key)
┌─────────────────────────┐
│  sportmonksService.js   │  ← Normalize data
└────────┬────────────────┘
         │
         ↓ Return normalized matches
┌─────────────────────────┐
│   liveController.js     │  ← Cache for 30s
└────────┬────────────────┘
         │
         ↓ JSON Response
┌─────────────────────────┐
│      Express Route      │  /api/live-matches
└────────┬────────────────┘
         │
         ↓ HTTP Response
┌─────────────────────────┐
│      Frontend Axios     │  ← Auto-refresh 10s
└────────┬────────────────┘
         │
         ↓ Update state
┌─────────────────────────┐
│   LiveMatches.jsx       │  ← Display
└────────┬────────────────┘
         │
         ↓ Render cards
┌─────────────────────────┐
│     MatchCard.jsx       │  ← UI Component
└─────────────────────────┘
```

---

## 🎨 UI Design Features

### Color Scheme
- **Purple-Blue Gradient:** `#8b5cf6` → `#3b82f6`
- **Live Badge:** Red with pulse animation
- **Card Hover:** Shadow elevation
- **Status Colors:**
  - Live: Red
  - Half Time: Yellow
  - Full Time: Gray

### Responsive Breakpoints
```css
Mobile:   1 column (default)
Tablet:   2 columns (md:)
Desktop:  3 columns (lg:)
```

### Animations
- Pulse effect on LIVE status
- Spin on refresh button while loading
- Skeleton loading animation
- Card hover elevation

---

## 🔄 Auto-Refresh Strategy

**Why 10 seconds?**
- Balance between real-time updates and API rate limits
- Less aggressive than 5s, more responsive than 30s
- SportMonks rate limits typically allow this frequency

**Backend Cache (30s):**
- Reduces API calls by 67% (10s refresh / 30s cache = 3 calls reuse cached data)
- Protects against rate limits
- Improves response time

**Calculation:**
```
- Frontend requests every 10s
- Backend caches for 30s
- Result: Only 1 API call per 30s (instead of 3)
```

---

## 🐛 Troubleshooting

### Issue: "No live matches" always shows

**Causes:**
1. No actual live matches at the moment
2. API key not configured
3. API rate limit exceeded
4. Network error

**Solutions:**
1. Check SportMonks dashboard for account status
2. Verify `SPORTMONKS_API_KEY` in `.env`
3. Check backend console for errors
4. Test API directly: `curl "https://api.sportmonks.com/v3/football/livescores/inplay?api_token=YOUR_KEY"`

### Issue: CORS errors

**Solution:**
```javascript
// backend/server.js
app.use(cors({
  origin: 'http://localhost:5173',  // Your frontend URL
  credentials: true
}))
```

### Issue: Cache not working

**Check:**
1. Backend logs show "Cache cleared" on first request
2. Second request within 30s shows `"cached": true`
3. Use clear cache endpoint: `POST /api/live-matches/clear-cache`

---

## 🚀 Production Deployment

### Backend

**Environment:**
```env
NODE_ENV=production
PORT=5000
SPORTMONKS_API_KEY=your_production_key
```

**Considerations:**
- Use environment-specific API keys
- Implement rate limiting
- Add request logging
- Monitor cache hit rate
- Set up alerts for API failures

### Frontend

**Build:**
```bash
npm run build
```

**Environment:**
```env
VITE_API_BASE_URL=https://api.goalsight.com/api
```

---

## 📈 Future Enhancements

1. **WebSocket Integration**
   - Real-time score updates without polling
   - Push notifications for goals

2. **Match Details Page**
   - Click on match card → full match details
   - Live commentary
   - Player statistics
   - Match timeline

3. **Filters**
   - Filter by league
   - Filter by team
   - Sort by kick-off time

4. **Favorites**
   - Save favorite teams
   - Highlight favorite matches
   - Push notifications

5. **Statistics**
   - Historical data
   - Head-to-head records
   - Form guide

---

## 📝 Example API Response

### SportMonks Live Matches Response

```json
{
  "data": [
    {
      "id": 19216139,
      "sport_id": 1,
      "league_id": 8,
      "season_id": 19735,
      "stage_id": 77457705,
      "starting_at": "2024-02-16 20:00:00",
      "state": {
        "state": "LIVE",
        "short": "LIVE"
      },
      "time": {
        "minute": 67,
        "second": 23
      },
      "participants": [
        {
          "id": 14,
          "name": "Manchester United",
          "image_path": "https://...",
          "meta": {
            "location": "home"
          }
        },
        {
          "id": 8,
          "name": "Liverpool",
          "image_path": "https://...",
          "meta": {
            "location": "away"
          }
        }
      ],
      "scores": [
        {
          "participant_id": 14,
          "score": {
            "goals": 2
          },
          "description": "CURRENT"
        },
        {
          "participant_id": 8,
          "score": {
            "goals": 1
          },
          "description": "CURRENT"
        }
      ],
      "league": {
        "name": "Premier League",
        "country": {
          "name": "England"
        }
      }
    }
  ]
}
```

---

## 🎓 Code Best Practices Used

✅ **Separation of Concerns:** Service → Controller → Route
✅ **Error Handling:** Try-catch blocks everywhere
✅ **Caching:** In-memory cache to reduce API calls
✅ **Environment Variables:** No hardcoded secrets
✅ **PropTypes:** Type checking in React components
✅ **Clean Code:** Comments on important sections
✅ **Responsive Design:** Mobile-first approach
✅ **Loading States:** Skeleton loaders for better UX
✅ **Auto-refresh:** Background updates without user action

---

## 📚 Resources

- **SportMonks Docs:** [https://docs.sportmonks.com/](https://docs.sportmonks.com/)
- **Express.js:** [https://expressjs.com/](https://expressjs.com/)
- **React:** [https://react.dev/](https://react.dev/)
- **TailwindCSS:** [https://tailwindcss.com/](https://tailwindcss.com/)
- **Axios:** [https://axios-http.com/](https://axios-http.com/)

---

**Built with ❤️ for football fans worldwide ⚽**
