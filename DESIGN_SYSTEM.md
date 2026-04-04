# 🎨 GOALSIGHT - Design System & Architecture Documentation

## 📐 Project Architecture

### Overview
GOALSIGHT is a modern football statistics platform built with a scalable, component-based architecture following industry best practices.

### Technology Stack

#### Frontend
- **React 18** - Modern UI library with hooks
- **Vite** - Lightning-fast build tool
- **TailwindCSS** - Utility-first CSS framework
- **React Router v6** - Client-side routing
- **Framer Motion** - Smooth animations
- **Zustand** - Lightweight state management
- **Axios** - HTTP client
- **Socket.IO Client** - Real-time updates

#### Backend
- **Node.js + Express** - RESTful API server
- **MongoDB + Mongoose** - NoSQL database
- **JWT** - Authentication
- **Socket.IO** - WebSocket server
- **Bcrypt** - Password hashing

---

## 🎨 Design System

### Color Palette

#### Primary Colors (Purple)
```css
purple-500: #8b5cf6  /* Main purple */
purple-600: #7c3aed  /* Hover states */
purple-100: #ede9fe  /* Backgrounds */
```

#### Secondary Colors (Blue)
```css
blue-500: #3b82f6    /* Main blue */
blue-600: #2563eb    /* Hover states */
blue-100: #dbeafe    /* Backgrounds */
```

#### Gradients
```css
bg-gradient-primary: linear-gradient(135deg, #8b5cf6 0%, #3b82f6 100%)
```

### Typography
- **Display Font**: Poppins (headings, logos)
- **Body Font**: Inter (paragraphs, UI text)
- **Weights**: 300, 400, 500, 600, 700, 800

### Border Radius
- **Cards**: 16px (`rounded-card`)
- **Buttons**: 12px (`rounded-button`)
- **Badges**: 9999px (`rounded-full`)

### Shadows
- **Soft**: Light purple/blue tinted shadows
- **Card**: Elevated card shadow
- **Card Hover**: Enhanced shadow on hover

### Spacing System
Following Tailwind's 4px base unit:
- Small: 4px, 8px, 12px
- Medium: 16px, 20px, 24px
- Large: 32px, 48px, 64px

---

## 🧩 Component Library

### UI Components

#### 1. **Button**
Location: `src/components/ui/Button.jsx`

Variants:
- `primary` - Gradient purple-blue button
- `secondary` - Outlined button
- `ghost` - No background
- `danger` - Red button

Sizes: `sm`, `md`, `lg`

Usage:
```jsx
<Button variant="primary" size="md" icon={FaPlus}>
  Add Match
</Button>
```

#### 2. **Input**
Location: `src/components/ui/Input.jsx`

Features:
- Label support
- Icon support
- Error state
- Full validation

Usage:
```jsx
<Input
  label="Email"
  type="email"
  icon={FaEnvelope}
  error="Invalid email"
/>
```

#### 3. **StatCard**
Location: `src/components/ui/StatCard.jsx`

Perfect for displaying metrics with:
- Icon
- Value
- Label
- Trend indicator

Colors: `primary`, `secondary`, `success`, `warning`, `danger`

#### 4. **Loader**
Location: `src/components/ui/Loader.jsx`

Sizes: `sm`, `md`, `lg`
Modes: Normal, Full Screen

### Match Components

#### 5. **MatchCard**
Location: `src/components/match/MatchCard.jsx`

Displays:
- Team logos and names
- Live score
- Match status (Live, Finished, Scheduled)
- League info
- Animated hover effect

#### 6. **Timeline**
Location: `src/components/match/Timeline.jsx`

Shows match events:
- Goals ⚽
- Yellow/Red cards 🟨🟥
- Substitutions 🔄
- VAR decisions

### League Components

#### 7. **LeagueTable**
Location: `src/components/league/LeagueTable.jsx`

Features:
- Position indicators (Champions League, Europa, Relegation)
- Team logos
- Form (W/D/L)
- Goal difference
- Points

### Player Components

#### 8. **PlayerCard**
Location: `src/components/player/PlayerCard.jsx`

Displays:
- Player photo
- Jersey number
- Position badge
- Key stats (Goals, Assists, Appearances)

---

## 📱 Page Structure

### Public Pages

#### HomePage (`/`)
Sections:
1. Hero with gradient heading
2. Live Matches (if any)
3. Today's Matches
4. Popular Leagues
5. CTA section

#### MatchDetailsPage (`/match/:id`)
Features:
- Real-time updates via Socket.IO
- Tabs: Timeline, Statistics, Lineups
- Team comparison
- Venue information

#### LeaguePage (`/league/:id`)
- League header with logo
- Standings table
- Future: Top scorers, fixtures

#### TeamPage (`/team/:id`)
- Team header with stadium info
- Squad grouped by position
- Team statistics

#### PlayerPage (`/player/:id`)
- Player profile with photo
- Physical stats
- Season statistics
- Performance charts

### Auth Pages

#### LoginPage (`/login`)
- Email + Password
- Link to register
- Gradient background

#### RegisterPage (`/register`)
- Name, Email, Password
- Validation
- Link to login

### Admin Pages

#### AdminDashboard (`/admin`)
- Overview statistics
- Recent activity
- Quick actions

#### AdminMatches (`/admin/matches`)
- Match management table
- CRUD operations
- Filters and search

---

## 🎯 Animation Strategy

### Framer Motion Usage

1. **Page Transitions**
```jsx
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
>
```

2. **Staggered Lists**
```jsx
transition={{ delay: index * 0.1 }}
```

3. **Hover Effects**
```jsx
<motion.div whileHover={{ scale: 1.05 }}>
```

4. **Button Press**
```jsx
<motion.button whileTap={{ scale: 0.95 }}>
```

### Tailwind Animations
- `animate-pulse` - Live badges
- `animate-spin` - Loading spinners
- `animate-fade-in` - Custom fade in
- `animate-slide-up` - Custom slide up

---

## 🔄 State Management

### Zustand Store
Location: `src/context/authStore.js`

Global state for:
- User authentication
- User profile
- Auth token management

Usage:
```jsx
const { user, isAuthenticated, logout } = useAuthStore();
```

---

## 🌐 API Architecture

### Services Layer
All API calls are abstracted into service files:

- `authService.js` - Authentication
- `matchService.js` - Matches
- `leagueService.js` - Leagues
- `teamService.js` - Teams
- `playerService.js` - Players
- `socketService.js` - Real-time connections

### API Client
Base configuration in `services/api.js`:
- Base URL configuration
- JWT token injection
- Error handling

---

## 🎭 Layouts

### MainLayout
Features:
- Responsive navbar
- Mobile menu
- User authentication status
- Footer
- Route outlet

### AdminLayout
Features:
- Protected routes
- Sidebar navigation
- Admin header
- Back to site button

---

## 📐 Responsive Design

### Breakpoints (Tailwind)
- `sm`: 640px
- `md`: 768px
- `lg`: 1024px
- `xl`: 1280px
- `2xl`: 1536px

### Grid System
```css
.grid-layout {
  grid-cols-1 md:grid-cols-2 lg:grid-cols-3
}
```

### Mobile-First Approach
All components are designed mobile-first, then enhanced for larger screens.

---

## 🚀 Performance Optimizations

1. **Code Splitting** - Routes are lazy loaded
2. **Image Optimization** - Lazy loading for images
3. **API Batching** - Parallel requests with Promise.all
4. **Memoization** - React hooks for expensive calculations
5. **Socket.IO** - Only connect when needed

---

## 🎨 UI Design Decisions

### Why Purple → Blue Gradient?

1. **Modern & Tech-Forward**: Purple-blue gradients are associated with modern tech brands and innovation
2. **Energy & Trust**: Purple = creativity/passion, Blue = trust/reliability
3. **Differentiation**: Most sports apps use red/green - this stands out
4. **Accessibility**: Good contrast ratios

### Why Soft Rounded Cards?

1. **Modern Aesthetic**: Sharp corners feel dated
2. **User-Friendly**: Softer shapes are more approachable
3. **Focus**: Rounded cards naturally guide the eye
4. **Consistency**: Matches mobile app design trends

### Why Inter + Poppins?

1. **Inter**: Excellent readability at small sizes
2. **Poppins**: Bold, distinctive for headings
3. **Web-Optimized**: Both perform well on all devices
4. **Modern**: Contemporary feel matching the brand

### Component Hierarchy

```
Page Level
  ↓
Layout (Navbar, Footer)
  ↓
Section Containers
  ↓
Cards
  ↓
Content Components (MatchCard, PlayerCard)
  ↓
UI Elements (Button, Input, Badge)
```

---

## 📦 Folder Structure Explained

### Frontend
```
src/
├── components/        # Reusable components
│   ├── ui/           # Generic UI components
│   ├── match/        # Match-specific components
│   ├── league/       # League-specific components
│   └── player/       # Player-specific components
├── layouts/          # Page layouts
├── pages/            # Route pages
│   └── admin/        # Admin pages
├── services/         # API services
├── context/          # Global state
├── hooks/            # Custom hooks (future)
├── utils/            # Helper functions
└── assets/           # Static assets
```

### Backend
```
src/
├── controllers/      # Route handlers
├── models/           # Database schemas
├── routes/           # API routes
├── middleware/       # Express middleware
├── services/         # Business logic
├── socket/           # Socket.IO handlers
├── config/           # Configuration
└── utils/            # Helper functions
```

---

## 🔐 Security Features

1. **JWT Authentication** - Secure token-based auth
2. **Password Hashing** - Bcrypt with salt rounds
3. **Protected Routes** - Client & server-side guards
4. **CORS Configuration** - Restricted origins
5. **Helmet.js** - Security headers
6. **Rate Limiting** - API abuse prevention
7. **Input Validation** - Express-validator

---

## 🎯 Best Practices Implemented

### Frontend
- ✅ Component composition
- ✅ Custom hooks for reusability
- ✅ Service layer abstraction
- ✅ Error boundary handling
- ✅ Loading states
- ✅ Optimistic UI updates
- ✅ Accessibility (ARIA, semantic HTML)

### Backend
- ✅ MVC architecture
- ✅ Separation of concerns
- ✅ Async/await error handling
- ✅ Database indexing
- ✅ API versioning ready
- ✅ Environment-based configuration
- ✅ Logging middleware

---

## 🚀 Getting Started

### Installation

1. **Install Backend Dependencies**
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your MongoDB URI
npm run dev
```

2. **Install Frontend Dependencies**
```bash
cd frontend
npm install
cp .env.example .env
npm run dev
```

3. **Access the Application**
- Frontend: http://localhost:5173
- Backend: http://localhost:5000

---

## 🎓 Learning Resources

### For Developers Using This Project

**Understanding the Architecture:**
1. Start with `frontend/src/App.jsx` - See routing structure
2. Review `frontend/src/services/*` - Understand API layer
3. Study `backend/src/server.js` - Backend entry point
4. Explore component library in `frontend/src/components/ui`

**Making Changes:**
1. Add new API endpoint: Create controller → Create route → Register in server
2. Add new page: Create page component → Add route in App.jsx
3. Add new component: Follow existing patterns in components folder
4. Update theme: Edit `tailwind.config.js`

---

## 📝 Future Enhancements

### Planned Features
- [ ] Player comparison tool
- [ ] Match predictions
- [ ] Fantasy league integration
- [ ] Push notifications
- [ ] Video highlights
- [ ] Social features (comments, likes)
- [ ] Multi-language support
- [ ] Dark mode
- [ ] PWA support
- [ ] Advanced analytics dashboard

### Technical Improvements
- [ ] Unit tests (Jest, React Testing Library)
- [ ] E2E tests (Cypress)
- [ ] Performance monitoring
- [ ] CDN for assets
- [ ] Redis caching
- [ ] Microservices architecture
- [ ] GraphQL API option

---

## 📞 Support & Contact

For questions or suggestions regarding the design system and architecture, please refer to the project documentation or create an issue in the repository.

---

**Built with ⚽ and 💜 by GOALSIGHT Team**
