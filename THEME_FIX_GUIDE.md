# Theme Color Fix Guide

## Quick Reference for Color Replacements

### Standard Replacements:

```dart
// BEFORE → AFTER

// Backgrounds
_kBg → Theme.of(context).scaffoldBackgroundColor
Color(0xFFF0F0F8) → Theme.of(context).scaffoldBackgroundColor

// Surfaces (cards, panels)
_kCard → Theme.of(context).colorScheme.surface  
Color(0xFFFFFFFF) → Theme.of(context).colorScheme.surface
Color(0xFFFDFDFF) → Theme.of(context).colorScheme.surface

// Borders & Dividers
_kBorder → Theme.of(context).colorScheme.outline
Color(0xFFE5E5F0) → Theme.of(context).colorScheme.outline
Color(0xFFE9E4F4) → Theme.of(context).dividerColor

// Primary/Accent colors
_kAccent → Theme.of(context).colorScheme.primary
Color(0xFF6C3CE1) → Theme.of(context).colorScheme.primary

// Text colors
_kTextPri → Theme.of(context).colorScheme.onBackground
Color(0xFF1A1A2E) → Theme.of(context).colorScheme.onBackground
Color(0xFF202547) → Theme.of(context).colorScheme.onBackground

_kTextSec → Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
Color(0xFF666680) → Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
Color(0xFF7B7892) → Theme.of(context).colorScheme.onSurface.withOpacity(0.6)

// Error/Danger
_kDanger → Theme.of(context).colorScheme.error
Color(0xFFEF4444) → Theme.of(context).colorScheme.error
```

### Brand Colors (KEEP AS IS):
```dart
// These should NOT be changed
const Color(0xFF22C55E) // Success green
const Color(0xFF00B84C) // Submit button green
const Color(0xFFFFA116) // Orange accent
const Color(0xFF00B8A3) // Easy green
const Color(0xFFFFC01E) // Medium yellow
const Color(0xFFFF375F) // Hard red
const Color(0xFF2563EB) // Blue
```

## Files That Need Theme Fixes:

### 1. Friends Screen
**File:** `lib/features/friends/screens/friends_screen.dart`

**Steps:**
1. Remove lines 13-20 (color constant declarations)
2. In each build method, add: `final colorScheme = Theme.of(context).colorScheme;`
3. Search and replace all color references using the table above
4. For nested widgets, pass `colorScheme` as parameter if needed

**Affected widgets:**
- `_FriendsScreenState.build()` 
- `_FriendsTopBar.build()`
- `_FriendsTab.build()`
- `_FriendCard.build()`
- `_RequestsTab.build()`
- `_RequestCard.build()`
- `_FindUsersTab.build()`
- `_card()` helper function
- `_statusChip()` helper function
- `_Avatar.build()`
- `_SearchBar.build()`
- `_EmptyState.build()`

### 2. Contests Screen  
**File:** `lib/features/contests/screens/contests_screen.dart`

Similar replacements needed.

### 3. Contest Detail Screen
**File:** `lib/features/contests/screens/contest_detail_screen.dart`

Similar replacements needed.

### 4. Contest Problem Screen
**File:** `lib/features/contests/screens/contest_problem_screen.dart`

Similar replacements needed.

## Example Widget Conversion:

### BEFORE:
```dart
class _FriendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Text(
        friend.username,
        style: const TextStyle(color: _kTextPri, fontWeight: FontWeight.w700),
      ),
    );
  }
}
```

### AFTER:
```dart
class _FriendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Text(
        friend.username,
        style: TextStyle(
          color: colorScheme.onBackground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

## Testing After Changes:

1. Run the app in **dark mode**:
   - All text should be light colored
   - Backgrounds should be dark
   - Cards should be visible but darker than background
   - No pure white or pure black elements

2. Run the app in **light mode**:
   - All text should be dark colored
   - Backgrounds should be light
   - Cards should be white or light gray
   - Good contrast everywhere

3. Toggle theme back and forth:
   - No element should look broken
   - All text should remain readable
   - Brand colors (green, orange, etc.) should stay the same

## Common Pitfalls:

❌ **DON'T:**
```dart
// Don't use hardcoded colors in TextStyle
const TextStyle(color: Color(0xFF1A1A2E))

// Don't keep _k constant references
backgroundColor: _kCard
```

✅ **DO:**
```dart
// Use theme-aware colors
TextStyle(color: Theme.of(context).colorScheme.onBackground)

// Use colorScheme variable
backgroundColor: colorScheme.surface
```

## Search & Replace Helper:

Run these searches in VSCode to find remaining issues:

1. Search: `_kBg` - Should find 0 results when done
2. Search: `_kCard` - Should find 0 results when done
3. Search: `_kBorder` - Should find 0 results when done  
4. Search: `_kAccent` - Should find 0 results when done
5. Search: `_kTextPri` - Should find 0 results when done
6. Search: `_kTextSec` - Should find 0 results when done
7. Search: `Color(0xFFF0F0F8)` - Should find 0 results (except in app_theme.dart)
8. Search: `Color(0xFF1A1A2E)` - Should find 0 in screens (ok in app_theme.dart)
