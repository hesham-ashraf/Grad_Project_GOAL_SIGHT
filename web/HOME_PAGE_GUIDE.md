# Home Page Implementation Guide

## Overview

A comprehensive Home Page for the football analytics website that displays after successful login. Features live sports data, match results, news, and video highlights.

---

## ✅ Features Implemented

### 1. **Routing & Authentication**
- ✅ Redirects to `/home` after login
- ✅ Protected route (requires authentication)
- ✅ `/dashboard` route for analytics dashboard
- ✅ Admin and Manager roles redirect appropriately

### 2. **Home Page Sections**

#### Featured Match (Hero Section)
- Large gradient card showcasing the main match
- Team logos, names, scores
- Match status, time, venue, competition
- "View Analytics" button

#### Today's Matches
- Horizontal scrollable list
- Upcoming matches for today
- Team names, logos, kickoff times
- Competition badges

#### Recent Results
- Grid layout of recent match results
- Team scores and match dates
- Competition names
- Click to view match details

#### Latest Football News
- News articles grid
- Thumbnails, titles, descriptions
- Source and publish time
- External links to full articles

#### Video Highlights
- Video cards with thumbnails
- Play button overlay
- Video duration
- Links to watch videos

### 3. **UI/UX Features**
- ✅ Mobile-first responsive design
- ✅ Glass morphism effects
- ✅ Gradient accents (purple → pink)
- ✅ Skeleton loading states
- ✅ Error handling with retry
- ✅ Empty states
- ✅ Theme toggle support (Dark/Light)
- ✅ Smooth animations and transitions

---

## 📁 Files Created

```
web/src/
├── pages/
│   └── Home.jsx              # Home page component
├── styles/
│   └── Home.css              # Home page styling
└── services/
    └── serpapi.js            # SerpAPI integration
```

---

## 🔧 SerpAPI Integration

### Setup

1. **Get API Key**
   ```bash
   # Sign up at https://serpapi.com/
   # Get your API key from dashboard
   ```

2. **Configure Environment**
   ```bash
   # Copy .env.example to .env
   cp .env.example .env
   
   # Add your API key
   VITE_SERPAPI_KEY=your_actual_api_key_here
   ```

3. **Available Functions**

```javascript
import {
  fetchTeamResults,
  fetchRecentResults,
  fetchTodayMatches,
  fetchVideoHighlights,
  fetchFootballNews,
  fetchFeaturedMatch,
  fetchAllHomeData
} from '../services/serpapi';
```

### API Functions

#### 1. Fetch Team Results
```javascript
const result = await fetchTeamResults('Manchester United F.C.', 'United States');

// Response:
{
  success: true,
  data: [
    {
      id: 1,
      homeTeam: { name: 'Man Utd', logo: '⚽', score: 2 },
      awayTeam: { name: 'Liverpool', logo: '⚽', score: 1 },
      date: '2026-02-15',
      status: 'Completed',
      venue: 'Old Trafford',
      competition: 'Premier League'
    }
  ]
}
```

#### 2. Fetch Recent Results
```javascript
const results = await fetchRecentResults('Premier League results');
```

#### 3. Fetch Today's Matches
```javascript
const matches = await fetchTodayMatches('Premier League');
```

#### 4. Fetch Video Highlights
```javascript
const videos = await fetchVideoHighlights('Manchester United highlights');

// Response:
{
  success: true,
  data: [
    {
      id: 1,
      title: 'Man Utd 2-1 Liverpool | Highlights',
      thumbnail: 'https://...',
      duration: '8:45',
      source: 'YouTube',
      url: 'https://...'
    }
  ]
}
```

#### 5. Fetch Football News
```javascript
const news = await fetchFootballNews('Premier League news');

// Response:
{
  success: true,
  data: [
    {
      id: 1,
      title: 'Manchester United win crucial match',
      description: 'Red Devils secure victory...',
      image: 'https://...',
      source: 'ESPN',
      time: '2h ago',
      url: 'https://...'
    }
  ]
}
```

#### 6. Fetch All Data (Batch)
```javascript
const allData = await fetchAllHomeData();

// Response:
{
  featuredMatch: { ... },
  todayMatches: [ ... ],
  recentResults: [ ... ],
  news: [ ... ],
  videoHighlights: [ ... ]
}
```

---

## 🎨 UI Components

### Featured Match Card
```jsx
<FeaturedMatchCard 
  match={featuredMatch} 
  onView={viewMatchDetails}
/>
```

### Today's Match Card
```jsx
<TodayMatchCard 
  match={match} 
  onView={viewMatchDetails}
/>
```

### Result Card
```jsx
<ResultCard 
  result={result} 
  onView={viewMatchDetails}
/>
```

### News Card
```jsx
<NewsCard article={article} />
```

### Video Card
```jsx
<VideoCard video={video} />
```

---

## 🚀 Usage

### In Production with Real API

1. **Update Home.jsx** to use SerpAPI:

```javascript
import { fetchAllHomeData } from '../services/serpapi';

const fetchHomeData = async () => {
  setLoading(true);
  setError(null);

  try {
    const data = await fetchAllHomeData();
    
    setFeaturedMatch(data.featuredMatch);
    setTodayMatches(data.todayMatches);
    setNews(data.news);
    setRecentResults(data.recentResults);
    setVideoHighlights(data.videoHighlights);
    
    setLoading(false);
  } catch (err) {
    console.error('Error fetching home data:', err);
    setError('Failed to load content. Please try again.');
    setLoading(false);
  }
};
```

2. **For Specific Teams**:

```javascript
import { fetchTeamResults, getPopularTeams } from '../services/serpapi';

// Fetch for specific team
const teamName = 'Manchester United F.C.';
const result = await fetchTeamResults(teamName);

// Or use popular teams helper
const teams = getPopularTeams();
teams.forEach(async (team) => {
  const result = await fetchTeamResults(team);
  // Process results...
});
```

3. **Dynamic League Selection**:

```javascript
import { fetchTodayMatches, getPopularLeagues } from '../services/serpapi';

const leagues = getPopularLeagues();
// ['Premier League', 'La Liga', 'Bundesliga', ...]

const matches = await fetchTodayMatches(leagues[0]);
```

---

## 📊 Data Models

### Match Model
```typescript
{
  id: number;
  homeTeam: {
    name: string;
    logo: string;
    score?: number;
  };
  awayTeam: {
    name: string;
    logo: string;
    score?: number;
  };
  date: string;
  time?: string;
  status: 'Completed' | 'Live' | 'Scheduled';
  venue: string;
  competition: string;
}
```

### News Article Model
```typescript
{
  id: number;
  title: string;
  description: string;
  image: string | null;
  source: string;
  time: string;
  url: string;
}
```

### Video Model
```typescript
{
  id: number;
  title: string;
  thumbnail: string;
  duration: string;
  source: string;
  url: string;
}
```

---

## 🎯 Extending for More Teams

### Method 1: Multi-Team Dashboard

```javascript
// In Home.jsx or separate component
const [selectedTeam, setSelectedTeam] = useState('Manchester United F.C.');

const fetchTeamData = async (teamName) => {
  const result = await fetchTeamResults(teamName);
  setRecentResults(result.data);
};

useEffect(() => {
  fetchTeamData(selectedTeam);
}, [selectedTeam]);

// UI: Team selector dropdown
<select onChange={(e) => setSelectedTeam(e.target.value)}>
  {getPopularTeams().map(team => (
    <option key={team} value={team}>{team}</option>
  ))}
</select>
```

### Method 2: Multiple Team Cards

```javascript
const [allTeamsData, setAllTeamsData] = useState({});

const fetchMultipleTeams = async () => {
  const teams = getPopularTeams().slice(0, 5);
  
  const results = await Promise.all(
    teams.map(team => fetchTeamResults(team))
  );
  
  const dataMap = {};
  teams.forEach((team, index) => {
    dataMap[team] = results[index].data;
  });
  
  setAllTeamsData(dataMap);
};

// Render multiple team sections
{Object.entries(allTeamsData).map(([team, results]) => (
  <TeamSection key={team} team={team} results={results} />
))}
```

### Method 3: User Preferences

```javascript
// Store user's favorite teams
const favoriteTeams = JSON.parse(
  localStorage.getItem('favoriteTeams') || '[]'
);

// Fetch only favorite teams' data
const fetchFavoriteTeamsData = async () => {
  const results = await Promise.all(
    favoriteTeams.map(team => fetchTeamResults(team))
  );
  
  // Display results
};
```

---

## 🔄 API Response Handling

### Success
```javascript
{
  success: true,
  data: [ ... ]
}
```

### Error
```javascript
{
  success: false,
  error: 'Error message'
}
```

### Usage Pattern
```javascript
const result = await fetchTeamResults('Team Name');

if (result.success) {
  setData(result.data);
} else {
  setError(result.error);
}
```

---

## 🎨 Theming

The Home Page supports the existing Dark/Light theme system:

- Uses CSS variables from `index.css`
- Theme toggle in header
- Smooth transitions
- Glass morphism in both themes
- Gradient accents consistent

---

## 📱 Responsive Design

### Breakpoints
- Desktop: 1200px+
- Tablet: 768px - 1199px
- Mobile: < 768px
- Small Mobile: < 480px

### Mobile Optimizations
- Stacked layouts
- Horizontal scrolling for matches
- Larger touch targets
- Simplified navigation
- Optimized font sizes

---

## ⚡ Performance

### Loading States
- Skeleton screens while fetching
- Progressive loading
- Lazy load images

### Error Handling
- Graceful degradation
- Retry mechanisms
- Fallback data
- User-friendly messages

### Caching (Optional)
```javascript
// Add caching to reduce API calls
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes
const cache = {};

const getCachedData = (key) => {
  const cached = cache[key];
  if (cached && Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data;
  }
  return null;
};

const setCachedData = (key, data) => {
  cache[key] = {
    data,
    timestamp: Date.now()
  };
};
```

---

## 🧪 Testing

### Manual Testing Checklist
- [ ] Login redirects to /home
- [ ] Theme toggle works
- [ ] Dashboard link navigates correctly
- [ ] Featured match displays properly
- [ ] Today's matches scroll horizontally
- [ ] Results grid responsive
- [ ] News cards link to articles
- [ ] Video cards link to videos
- [ ] Loading skeleton appears
- [ ] Error state shows with retry button
- [ ] Empty states display correctly
- [ ] Mobile responsive
- [ ] Theme persistence

---

## 🐛 Troubleshooting

### API Key Not Working
```javascript
import { isSerpApiConfigured } from '../services/serpapi';

if (!isSerpApiConfigured()) {
  console.warn('SerpAPI key not configured. Using mock data.');
}
```

### CORS Issues
If you encounter CORS errors:
1. Use a backend proxy
2. Or use SerpAPI's official client libraries
3. Or run in production (not localhost)

### Rate Limiting
- Free tier: 100 searches/month
- Implement caching
- Use mock data in development
- Upgrade plan if needed

---

## 📚 Resources

- **SerpAPI Docs**: https://serpapi.com/docs
- **Sports Results**: https://serpapi.com/sports-results
- **Video Search**: https://serpapi.com/video-results-api
- **News Search**: https://serpapi.com/news-results-api

---

## 🎯 Next Steps

1. **Add Real API Key**
   - Sign up for SerpAPI
   - Add key to `.env`
   - Test with real data

2. **Customize Teams**
   - Add your favorite teams
   - Implement team selection
   - Store user preferences

3. **Enhance Features**
   - Add live score updates
   - Implement push notifications
   - Add match reminders
   - Social sharing

4. **Backend Integration**
   - Create API endpoints
   - Implement caching
   - Add rate limiting
   - Store user data

---

**Your Home Page is ready! 🎉**

Run the app and see your new home page after login.
