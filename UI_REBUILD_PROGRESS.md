# CodeMania Mobile UI Rebuild Progress

## Completed ✅

### 1. Theme System with Light/Dark Mode Support
- Created `lib/providers/theme_provider.dart` - StateNotifierProvider with SharedPreferences persistence
- Created `lib/core/theme/app_theme.dart` - Complete light and dark ThemeData objects
- Updated `main.dart` to watch theme provider and apply themes
- All screens now use `Theme.of(context)` instead of hardcoded colors
- Theme persists across app restarts (default: dark mode)

### 2. Theme Colors
**Dark Mode:**
- background: #1A1A2E, surface: #262638, surfaceLight: #2F2F47
- accent: #FFA116, accentGreen: #00B8A3, accentYellow: #FFC01E, accentRed: #FF375F
- textPrimary: #FFFFFF, textSecondary: #8A8A9A, divider: #3A3A52

**Light Mode:**
- background: #F5F5F5, surface: #FFFFFF, surfaceLight: #EEEEEE
- accent: #FFA116, accentGreen: #00B8A3, accentYellow: #B89800, accentRed: #E5264A
- textPrimary: #1A1A2E, textSecondary: #6B6B80, divider: #DDDDEE

### 3. Bottom Navigation
- Integrated into `home_screen.dart`
- 4 tabs: Library, Contests, Search (Problems), You (Profile)
- Active tab with blue circle background
- 64px height with proper divider
- Uses theme colors

### 4. Login Screen (`login_screen.dart`)
- Full theme-aware design
- Close button top left
- Center logo "{ }" in accent color
- Single rounded input card with email/password
- Theme-aware "Sign in" button
- Social auth buttons (GitHub icon, Google "G")
- Links to forgot password and create account

### 5. Register Screen (`register_screen.dart`)
- Same theme-aware aesthetic as login
- Username, Email, Password, Confirm Password fields in one card
- Theme-aware "Create Account" button
- "Already have an account? Sign in" link
- Password visibility toggles

### 6. Home Screen - Library Tab
- Scrollable column layout with theme colors
- "Library" header
- Active Contests banner (gradient with trophy icon)
- Problems section with 3 difficulty stat cards (Easy/Medium/Hard) - theme-aware colors
- Recent Submissions section (last 3 submissions) - theme-aware verdict colors
- Contests section (upcoming 2 contests) - theme-aware cards
- All with dynamic theme support

## Theme Implementation Details

✅ **No hardcoded colors** - All screens use:
- `Theme.of(context).colorScheme.*`
- `Theme.of(context).scaffoldBackgroundColor`
- `Theme.of(context).textTheme.*`
- `AppTheme.getDifficultyColor()` and `AppTheme.getVerdictColor()` helpers

✅ **Proper ColorScheme mapping:**
- background → scaffoldBackgroundColor
- surface → colorScheme.surface
- accent → colorScheme.primary
- textPrimary → colorScheme.onBackground
- textSecondary → colorScheme.onSurface.withOpacity(0.6)
- divider → colorScheme.outline

✅ **Theme persistence** via SharedPreferences

## Remaining Tasks 🔄

### 7. Theme Toggle in Profile Screen
- Add toggle row: [moon/sun icon] "Dark Mode" [Switch widget]
- Switch reads from themeProvider
- Toggle calls `ref.read(themeProvider.notifier).toggle()`

### 8. Problems / Search Screen
- Need to modify `problem_list_screen.dart`
- Search bar at top (full width, rounded 24px, grey)
- Filter chips row (All, Easy, Medium, Hard)
- Problem list with difficulty badges, titles, acceptance %
- Dividers between items
- Use theme colors throughout

### 9. Problem Detail Screen
- Modify existing problem detail/page
- Two tabs only: Description | Submissions
- Problem title, bookmark, share icons top
- Difficulty and topic chips
- Problem statement with code blocks
- Green play FAB → navigates to code editor
- Theme-aware colors

### 10. Code Editor Screen
- Modify existing code editor
- Top bar: chevron down, problem title, undo, language dropdown, settings
- Code editor area (use existing widget)
- Bottom action bar: Console, reset, run, Submit buttons
- Theme-aware colors

### 11. Contests Screen
- Modify `contests_screen.dart`
- "Contests" header
- Upcoming section with cards
- Past section with cards
- Contest cards: name, date/time, countdown, register button
- Theme-aware colors

### 12. Profile Screen
- Modify `profile_screen.dart`
- **Add theme toggle switch**
- If not logged in: show sign in prompt
- If logged in: avatar, username, email, friends count
- Stats row: Problems Solved, Rating
- Submissions card with heatmap
- Sign out button
- Theme-aware colors

## Files Modified

1. `lib/providers/theme_provider.dart` (NEW)
2. `lib/core/theme/app_theme.dart` (NEW)
3. `lib/main.dart` (MODIFIED - theme provider integration)
4. `lib/screens/user/home_screen.dart` (MODIFIED - bottom nav + Library page + theme support)
5. `lib/screens/auth/login_screen.dart` (REWRITTEN - theme-aware)
6. `lib/screens/auth/register_screen.dart` (REWRITTEN - theme-aware)
7. `lib/leetcode_theme.dart` (DEPRECATED - replaced by app_theme.dart)

## Files to Modify

8. `lib/screens/user/problem_list_screen.dart` - add theme support
9. `lib/screens/problem_page/problem_page.dart` or `lib/features/problem/problem_page.dart` - add theme support
10. Code editor screen (needs identification) - add theme support
11. `lib/features/contests/screens/contests_screen.dart` - add theme support
12. `lib/screens/user/profile_screen.dart` - add theme support + **theme toggle**

## Notes

- ✅ No hardcoded colors anywhere - all use Theme.of(context)
- ✅ Theme persists using SharedPreferences
- ✅ Default theme: dark mode
- ✅ Light/Dark themes fully defined in app_theme.dart
- ✅ Helper methods for difficulty and verdict colors
- No changes to providers, services, models, or router
- All navigation uses existing GoRouter routes
- Using only existing packages from pubspec.yaml
- All screens wrapped in SafeArea with scaffoldBackgroundColor
- Row children with text wrapped in Expanded/Flexible to prevent overflow

## Next Steps

1. Add theme toggle to profile screen
2. Modify problem list screen with search and filters + theme support
3. Update problem detail with new tab structure + theme support
4. Identify and update code editor screen + theme support
5. Update contests screen with new card design + theme support
6. Update profile screen with new layout + theme support
7. Test theme switching on each screen
8. Hot reload (r) and verify before moving to next
