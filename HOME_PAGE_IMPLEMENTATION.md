# 🏠 Home Page Implementation Guide

## Overview
The GOALSIGHT Home Page is a comprehensive football analytics dashboard that displays:
- Featured/Hero Match with live scores
- Today's upcoming matches
- Recent match results
- Latest football news
- Video highlights from recent games

All data is fetched dynamically from **SerpAPI** for real-time sports information.

---

## 🔐 Authentication & Routing

### Login Flow
1. User enters credentials on `/` (Login Page)
2. On successful login:
   - User data and token stored in Zustand store (persisted in localStorage)
   - Automatically redirects to `/home`
3. All protected routes check authentication via `ProtectedRoute` component

### Protected Routes
```jsx
/home      - Home page (featured matches, news, highlights)
/dashboard - Analytics dashboard (coming soon)
/analysis  - Match analysis tools (coming soon)
/profile   - User profile settings
```

### Logout
- Click "Logout" button in sidebar
- Clears auth state and redirects to login page

---

## 🎨 UI Components

### Sidebar Navigation
Located in `MainLayout.jsx`:
- **Top**: GOALSIGHT logo
- **Middle**: Navigation links (Home, Dashboard, Analysis)
- **Bottom**: Profile section and Logout button
- Active state shows purple-blue gradient background

### Home Page Sections

#### 1. **Featured Match Card**
- Large gradient card at the top
- Shows team logos, names, score, and match status
- Displays league name and match date
- Falls back to demo data if API fails

#### 2. **Today's Matches**
- Grid of upcoming matches
- Shows kickoff time and league name
- Scrollable and responsive
- Updates based on current date

#### 3. **Recent Results**
- List of completed matches
- Team names, scores, and competition
- Click to view match details (coming soon)

#### 4. **Video Highlights**
- Grid of highlight videos
- Thumbnail images with play button overlay
- Opens video in new tab on click
- Source attribution included

#### 5. **Latest News**
- Football news articles
- Image, title, snippet, and source
- External links to full articles
- Responsive grid layout

---

## 🔌 SerpAPI Integration

### Setup
1. Get API key from [https://serpapi.com/](https://serpapi.com/)
2. Add to `.env` file:
```env
VITE_SERPAPI_KEY=your_actual_key_here
```

### Service Methods

#### `getTeamResults(teamName, location)`
Fetches recent match results for a team.

**Example:**
```javascript
const results = await serpApiService.getTeamResults('Manchester United F.C.')
// Returns: sports_results.games array with match data
```

**Response Structure:**
```javascript
{
  games: [
    {
      teams: [
        { name: 'Manchester United', logo: '🔴' },
        { name: 'Liverpool', logo: '🔴' }
      ],
      score: '2 - 1',
      status: 'FT',
      date: '2 days ago',
      league: 'Premier League'
    }
  ]
}
```

#### `getTodayMatches(league)`
Fetches today's scheduled matches.

**Example:**
```javascript
const matches = await serpApiService.getTodayMatches('Premier League')
```

#### `getMatchHighlights(teamName, matchQuery)`
Fetches video highlights from recent matches.

**Example:**
```javascript
const highlights = await serpApiService.getMatchHighlights(
  'Manchester United',
  'last match highlights'
)
```

**Response:**
```javascript
[
  {
    title: 'Man United vs Liverpool | Full Match Highlights',
    thumbnail: 'https://...',
    link: 'https://youtube.com/...',
    source: 'YouTube'
  }
]
```

#### `getFootballNews(query, country)`
Fetches latest football news articles.

**Example:**
```javascript
const news = await serpApiService.getFootballNews('Premier League news')
```

---

## 🔄 Extending for More Teams

### Method 1: Dynamic Team Selection
Add a team selector dropdown in the UI:

```jsx
// HomePage.jsx
const [selectedTeam, setSelectedTeam] = useState('Manchester United')

const teams = [
  'Manchester United',
  'Liverpool',
  'Arsenal',
  'Chelsea',
  'Manchester City'
]

// Then fetch data based on selection
useEffect(() => {
  fetchTeamData(selectedTeam)
}, [selectedTeam])
```

### Method 2: Multi-Team Dashboard
Fetch data for multiple teams simultaneously:

```jsx
const teams = ['Manchester United', 'Arsenal', 'Liverpool']

const fetchMultipleTeams = async () => {
  const results = await Promise.all(
    teams.map(team => serpApiService.getTeamResults(team))
  )
  
  setTeamData(results)
}
```

### Method 3: Favorite Teams
Store user's favorite teams in the auth store:

```javascript
// authStore.js
favoriteTeams: [],
addFavoriteTeam: (team) => set((state) => ({
  favoriteTeams: [...state.favoriteTeams, team]
}))

// HomePage.jsx
const favoriteTeams = useAuthStore((state) => state.favoriteTeams)

favoriteTeams.forEach(async (team) => {
  const data = await serpApiService.getTeamResults(team)
  // Display data
})
```

---

## 🎯 Customization Examples

### Change Featured League
```javascript
// HomePage.jsx - Line 24
const [todayMatches] = await Promise.all([
  serpApiService.getTodayMatches('La Liga'), // Changed from Premier League
])
```

### Add More News Sources
```javascript
const [news1, news2] = await Promise.all([
  serpApiService.getFootballNews('Premier League'),
  serpApiService.getFootballNews('Champions League'),
])

setData({
  news: [...news1, ...news2].slice(0, 6)
})
```

### Custom Highlight Queries
```javascript
// Get specific match highlights
const highlights = await serpApiService.getMatchHighlights(
  'Manchester United',
  'vs Liverpool 2024 goals'
)
```

---

## 🛠️ Error Handling

### Fallback Data
If API calls fail, the app shows demo data:

```javascript
const getFallbackMatch = () => ({
  teams: [
    { name: 'Manchester United', logo: '🔴' },
    { name: 'Liverpool', logo: '🔴' }
  ],
  score: '2 - 1',
  status: 'FT'
})
```

### Loading States
Skeleton loaders display while fetching:
```jsx
{loading && (
  <div className="animate-pulse">
    <div className="h-6 bg-dark-200 rounded"></div>
  </div>
)}
```

### Empty States
Graceful messages when no data available:
```jsx
{data.news.length === 0 && (
  <p className="text-dark-500">No news available</p>
)}
```

---

## 📱 Responsive Design

- **Mobile**: Single column layout, stacked cards
- **Tablet**: 2-column grid for news and highlights
- **Desktop**: 3-column grid, full sidebar visible

Tailwind breakpoints used:
- `md:` - 768px and up
- `lg:` - 1024px and up

---

## 🚀 Performance Optimization

### Parallel Data Fetching
All API calls run simultaneously:
```javascript
const [teamResults, news, highlights] = await Promise.all([
  serpApiService.getTeamResults('...'),
  serpApiService.getFootballNews('...'),
  serpApiService.getMatchHighlights('...')
])
```

### Data Caching (Future Enhancement)
```javascript
// Add to serpApiService.js
const cache = new Map()

getTeamResults: async (teamName) => {
  const cacheKey = `team-${teamName}`
  if (cache.has(cacheKey)) {
    return cache.get(cacheKey)
  }
  
  const data = await fetchFromAPI(...)
  cache.set(cacheKey, data)
  return data
}
```

---

## 🔧 Tech Stack Summary

| Layer | Technology |
|-------|-----------|
| UI Framework | React 18 |
| Routing | React Router v6 |
| State Management | Zustand |
| Styling | TailwindCSS |
| HTTP Client | Axios |
| Notifications | React Hot Toast |
| Icons | React Icons |
| Sports Data API | SerpAPI |

---

## 📝 Next Steps

1. **Add Real Backend API**
   - Replace demo login with actual API calls
   - Implement proper JWT token refresh
   - Store user preferences in database

2. **Implement Match Details Page**
   - Click on any match to see detailed stats
   - Live match commentary
   - Player statistics and lineups

3. **User Preferences**
   - Save favorite teams
   - Customize home page sections
   - Set notification preferences

4. **Real-time Updates**
   - WebSocket integration for live scores
   - Push notifications for goals
   - Live match commentary updates

5. **Analytics Dashboard**
   - Build `/dashboard` page with charts
   - Team performance analytics
   - Player statistics comparison

---

## 🐛 Troubleshooting

### White Screen Issue
- Check browser console for errors
- Ensure all dependencies installed: `npm install`
- Verify dev server is running: `npm run dev`
- Clear browser cache and hard refresh (Ctrl+Shift+R)

### SerpAPI Not Working
- Verify API key is set in `.env` file
- Check API quota/rate limits
- Ensure `.env` file is in `frontend/` directory
- Restart dev server after adding `.env`

### Login Not Redirecting
- Check `useNavigate` import from 'react-router-dom'
- Verify `ProtectedRoute` component is wrapping routes
- Check Zustand store state in browser DevTools

---

**Built with ❤️ for football fans worldwide ⚽**
