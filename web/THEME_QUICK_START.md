# 🎨 Theme System - Quick Start Guide

## ✅ Status: FULLY IMPLEMENTED

Your dashboard has a complete Dark/Light theme system ready to use!

---

## 🚀 How to Use

### 1. **Toggle Theme**
Click the **settings gear icon (⚙️)** in the dashboard header:
```
Dashboard Header
├── Welcome back, [User]!
└── [Settings ⚙️ Button] ← Click here!
```

### 2. **Select Theme**
In the dropdown menu:
- 🌞 **Light Mode** - Clean, bright interface
- 🌙 **Dark Mode** - Sophisticated, eye-friendly

### 3. **Theme Persists**
Your choice is automatically saved and restored on your next visit!

---

## 🎯 Quick Facts

- ✅ **Default**: Dark Mode
- ✅ **System Preference**: Detected on first visit
- ✅ **Persistence**: Saved in browser localStorage
- ✅ **Smooth Transitions**: Animated color changes
- ✅ **No Layout Shift**: UI stays stable during switch

---

## 🎨 What Changes Between Themes?

### Dark Mode (Default)
```
🎨 Backgrounds: Deep dark (#0B0F19)
💬 Text: High contrast white
🌟 Shadows: Dramatic depth
✨ Glows: Prominent accents
🔮 Glass: Frosted dark glass
```

### Light Mode
```
🎨 Backgrounds: Clean white (#FFFFFF)
💬 Text: Dark gray (not pure black)
🌟 Shadows: Soft, subtle
✨ Glows: Reduced opacity
🔮 Glass: Frosted white glass
```

### Always the Same
```
🎨 Purple → Pink gradient
🎯 Brand colors (primary, secondary, accent)
📐 Layout & spacing
🧩 Component structure
```

---

## 🔧 For Developers

### Use Theme in Components
```jsx
import { useTheme } from './hooks/useTheme';

function MyComponent() {
  const { theme, toggleTheme } = useTheme();
  
  return (
    <div>
      <p>Current theme: {theme}</p>
      <button onClick={toggleTheme}>Toggle</button>
    </div>
  );
}
```

### Use in CSS
```css
.my-element {
  background: var(--bg-primary);
  color: var(--text-primary);
  border: 1px solid var(--border-primary);
  box-shadow: var(--shadow-md);
}
```

---

## 📍 Where is the Theme Toggle?

### Dashboard Pages
```
┌─────────────────────────────────────────┐
│  ⚽ GOAL SIGHT        [User] [⚙️]       │ ← Settings button here
├─────────────────────────────────────────┤
│  Dashboard Content                      │
└─────────────────────────────────────────┘
```

### Settings Menu Dropdown
```
                          ┌──────────────────────┐
                          │  Preferences         │
                          │  Customize your...   │
                          ├──────────────────────┤
                          │  Appearance          │
                          │  [🌞] [🌙]          │ ← Click icon
                          └──────────────────────┘
```

---

## 🎓 CSS Variables Reference

### Backgrounds
- `--bg-primary` - Main background
- `--bg-secondary` - Secondary surfaces
- `--bg-tertiary` - Tertiary surfaces
- `--bg-elevated` - Elevated elements

### Text
- `--text-primary` - Main text
- `--text-secondary` - Secondary text
- `--text-tertiary` - Tertiary text
- `--text-muted` - Muted text

### Effects
- `--glass-bg` - Glass morphism background
- `--glass-border` - Glass border
- `--shadow-md` - Medium shadow
- `--shadow-lg` - Large shadow
- `--shadow-xl` - Extra large shadow

### Brand (Same in both themes)
- `--primary` - Primary brand color (#6366F1)
- `--gradient-primary` - Brand gradient
- `--success` - Success green
- `--warning` - Warning amber
- `--error` - Error red

---

## 🐛 Troubleshooting

### Theme not changing?
1. Check browser console for errors
2. Verify you're using CSS variables in styles
3. Clear localStorage and try again

### Colors look wrong?
1. Open DevTools → Elements → Computed
2. Check CSS variable values
3. Verify `data-theme` attribute on `<html>`

### Theme not saving?
1. Check if localStorage is enabled
2. Look for `goalSightTheme` key in localStorage
3. Try in incognito mode to test fresh

---

## 📚 Learn More

See [THEME_SYSTEM_DOCUMENTATION.md](./THEME_SYSTEM_DOCUMENTATION.md) for complete technical documentation.

---

**Ready to use!** Your theme system is production-ready. Just run the app and click the settings button! 🎉
