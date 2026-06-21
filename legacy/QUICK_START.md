# 🚀 GOALSIGHT - Quick Start Guide

## ⚡ Get Up and Running in 5 Minutes

### Prerequisites
- Node.js 18+ installed
- MongoDB installed and running (or MongoDB Atlas account)
- Terminal/Command Prompt

---

## 📦 Step 1: Install Dependencies

### Backend
```bash
cd backend
npm install
```

### Frontend
```bash
cd frontend
npm install
```

---

## 🔧 Step 2: Configure Environment

### Backend Configuration
Create `.env` file in `backend/` folder:
```env
PORT=5000
NODE_ENV=development
MONGODB_URI=mongodb://localhost:27017/goalsight
JWT_SECRET=your_super_secret_key_change_in_production
JWT_EXPIRE=7d
CLIENT_URL=http://localhost:5173
```

**Using MongoDB Atlas?**
Replace `MONGODB_URI` with your Atlas connection string:
```
mongodb+srv://username:password@cluster.mongodb.net/goalsight
```

### Frontend Configuration
Create `.env` file in `frontend/` folder:
```env
VITE_API_URL=http://localhost:5000
VITE_SOCKET_URL=http://localhost:5000
```

---

## 🚀 Step 3: Start the Servers

### Terminal 1 - Backend
```bash
cd backend
npm run dev
```

You should see:
```
🚀 GOALSIGHT Server running on port 5000
📊 Environment: development
✅ MongoDB Connected: localhost
```

### Terminal 2 - Frontend
```bash
cd frontend
npm run dev
```

You should see:
```
  VITE v5.0.11  ready in XXX ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

---

## 🎉 Step 4: Access the Application

Open your browser and navigate to:
**http://localhost:5173**

You should see the GOALSIGHT homepage with:
- Purple → Blue gradient branding
- Modern navigation bar
- Hero section

---

## 👤 Step 5: Create an Admin Account

### Option 1: Using the UI
1. Click "Sign Up" in the navbar
2. Fill in the form
3. Register

### Option 2: Manually in MongoDB
Update the user's role to `admin`:
```javascript
// In MongoDB shell or Compass
db.users.updateOne(
  { email: "your@email.com" },
  { $set: { role: "admin" } }
)
```

### Option 3: Register via API (Postman/Thunder Client)
```bash
POST http://localhost:5000/api/auth/register
Content-Type: application/json

{
  "name": "Admin User",
  "email": "admin@goalsight.com",
  "password": "admin123"
}
```

Then update the role in MongoDB.

---

## 📊 Step 6: Add Sample Data (Optional)

To test the UI with data, you can add sample records via MongoDB or API:

### Sample League
```javascript
{
  "name": "Premier League",
  "country": "England",
  "season": "2025/26",
  "type": "league",
  "isPopular": true
}
```

### Sample Team
```javascript
{
  "name": "Manchester United",
  "shortName": "Man Utd",
  "country": "England",
  "founded": 1878,
  "venue": {
    "name": "Old Trafford",
    "capacity": 74879,
    "city": "Manchester"
  }
}
```

### Sample Match
```javascript
{
  "homeTeam": "TEAM_ID_1",
  "awayTeam": "TEAM_ID_2",
  "league": "LEAGUE_ID",
  "date": new Date(),
  "status": "scheduled",
  "score": { "home": 0, "away": 0 }
}
```

---

## 🎨 Verify the Theme

Check that you see:
- ✅ Purple (#8b5cf6) to Blue (#3b82f6) gradients
- ✅ Rounded cards (16px border radius)
- ✅ Soft shadows with purple/blue tint
- ✅ "GOALSIGHT" branding in gradient text
- ✅ Inter font for body text
- ✅ Smooth hover animations

---

## 🔍 Troubleshooting

### Backend won't start
**Problem:** MongoDB connection error
**Solution:** 
- Ensure MongoDB is running: `mongod` or check Atlas connection
- Verify `MONGODB_URI` in `.env`

### Frontend shows blank page
**Problem:** Backend not connected
**Solution:**
- Check backend is running on port 5000
- Verify `VITE_API_URL` in frontend `.env`
- Check browser console for errors

### "CORS Error" in console
**Problem:** Backend rejecting requests
**Solution:**
- Verify `CLIENT_URL` in backend `.env` matches frontend URL
- Restart backend after changing `.env`

### Theme colors not showing
**Problem:** Tailwind not building
**Solution:**
```bash
cd frontend
rm -rf node_modules
npm install
npm run dev
```

---

## 📱 Testing Features

### Test Public Features
1. ✅ View homepage
2. ✅ Click on match cards (even if no data)
3. ✅ Navigate using navbar
4. ✅ Register a new account
5. ✅ Login

### Test Admin Features (after setting role to admin)
1. ✅ Login as admin
2. ✅ Click "Admin" in navbar
3. ✅ View admin dashboard
4. ✅ Navigate to "Matches" section
5. ✅ See management interface

### Test Real-Time (when you have live matches)
1. ✅ Create a match with `status: "live"`
2. ✅ Open match details page
3. ✅ Update match via API
4. ✅ See auto-update on frontend

---

## 🎯 Next Steps

1. **Add Real Data**: Connect to a football data API or add manually
2. **Customize**: Update colors, logos, content in the code
3. **Deploy**: Follow deployment guide for production
4. **Enhance**: Add features from DESIGN_SYSTEM.md future enhancements

---

## 📚 Key Files to Know

### Configuration
- `frontend/tailwind.config.js` - Theme colors, spacing, animations
- `backend/src/server.js` - Backend entry point
- `frontend/src/App.jsx` - Routes and app structure

### Main Components
- `frontend/src/components/match/MatchCard.jsx` - Match display
- `frontend/src/components/ui/*` - Reusable UI components
- `frontend/src/layouts/MainLayout.jsx` - Main app layout

### Services
- `frontend/src/services/api.js` - API client
- `frontend/src/services/*Service.js` - API endpoints

### Pages
- `frontend/src/pages/HomePage.jsx` - Landing page
- `frontend/src/pages/MatchDetailsPage.jsx` - Match details

---

## 💡 Tips

1. **Check the Console**: Both browser and terminal show helpful errors
2. **Use React DevTools**: Install the browser extension for debugging
3. **MongoDB Compass**: Great GUI for viewing/editing database
4. **Postman/Thunder Client**: Test API endpoints easily
5. **Hot Reload**: Both frontend and backend auto-reload on changes

---

## 🆘 Need Help?

- Read `README.md` for detailed information
- Check `DESIGN_SYSTEM.md` for architecture details
- Review component code for usage examples
- Check browser console for frontend errors
- Check terminal for backend errors

---

## 🎊 You're Ready!

Your GOALSIGHT platform is now running with:
- ✅ Modern purple-blue gradient theme
- ✅ Responsive design
- ✅ Authentication system
- ✅ Admin panel
- ✅ Real-time capabilities
- ✅ Scalable architecture

**Happy coding! ⚽💜**
