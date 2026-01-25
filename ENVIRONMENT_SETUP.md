# Everywear - Production Environment Setup Guide

## Required Environment Variables

The Everywear app requires the following environment variables to be configured for production:

### Required Environment Variables

```bash
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Production Setup Instructions

### 1. Supabase Project Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Navigate to Project Settings > API
3. Copy the Project URL and Anon Key
4. Configure these in your build environment

### 2. Enable Authentication Providers

In your Supabase Dashboard:

1. **Enable Email Provider**:
   - Go to Authentication > Providers
   - Enable Email provider
   - Configure email templates for confirmation

2. **Enable Google OAuth**:
   - Go to Authentication > Providers > Google
   - Enable Google provider
   - Add your OAuth credentials from Google Cloud Console
   - Set the redirect URL: `io.supabase.everywear://login-callback/`

### 3. Database Setup

Run the following SQL in your Supabase SQL Editor:

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create wardrobe_items table
CREATE TABLE IF NOT EXISTS wardrobe_items (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  brand TEXT,
  image_url TEXT,
  semantic_label TEXT,
  purchase_price DECIMAL(10, 2),
  purchase_date DATE,
  notes TEXT,
  wear_count INTEGER DEFAULT 0,
  last_worn TIMESTAMP,
  cost_per_wear DECIMAL(10, 2),
  is_favorite BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create outfit_logs table
CREATE TABLE IF NOT EXISTS outfit_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  outfit_name TEXT,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  weather TEXT,
  occasion TEXT,
  notes TEXT,
  worn_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create outfit_items junction table
CREATE TABLE IF NOT EXISTS outfit_items (
  outfit_id UUID REFERENCES outfit_logs(id) ON DELETE CASCADE,
  item_id UUID REFERENCES wardrobe_items(id) ON DELETE CASCADE,
  PRIMARY KEY (outfit_id, item_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_user_id ON wardrobe_items(user_id);
CREATE INDEX IF NOT EXISTS idx_outfit_logs_user_id ON outfit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_wardrobe_items_category ON wardrobe_items(category);

-- Enable Row Level Security (RLS)
ALTER TABLE wardrobe_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE outfit_logs ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own wardrobe items"
  ON wardrobe_items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wardrobe items"
  ON wardrobe_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wardrobe items"
  ON wardrobe_items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own wardrobe items"
  ON wardrobe_items FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own outfit logs"
  ON outfit_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own outfit logs"
  ON outfit_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

### 4. Codemagic Configuration

Configure the environment variables in your Codemagic workflow:

```yaml
environment:
  vars:
    SUPABASE_URL: $SUPABASE_URL
    SUPABASE_ANON_KEY: $SUPABASE_ANON_KEY
```

Add these environment variables in Codemagic:
1. Go to Codemagic > Your App > Environment variables
2. Add `SUPABASE_URL` with your Supabase project URL
3. Add `SUPABASE_ANON_KEY` with your Supabase anon key
4. Mark them as sensitive

### 5. Android Configuration

Update `android/app/build.gradle` with your app signature:

```gradle
android {
    defaultConfig {
        // Add your app's deep link scheme
        manifestPlaceholders = [
            'deepLinkScheme': 'io.supabase.everywear'
        ]
    }
}
```

### 6. Testing Authentication Flow

Before deploying to production:

1. **Test Email Sign-up**:
   - Create a new account with email/password
   - Verify confirmation email is received
   - Test sign-in with the same credentials

2. **Test Google Sign-in**:
   - Ensure Google OAuth is enabled in Supabase
   - Test the OAuth flow on a physical device
   - Verify user is properly authenticated

3. **Test Wardrobe Features**:
   - Add wardrobe items
   - Verify data persists across app restarts
   - Test real-time synchronization

## Common Issues

### Authentication Failures

**Problem**: "Authentication service unavailable"
- **Solution**: Verify SUPABASE_URL and SUPABASE_ANON_KEY are set correctly in Codemagic environment variables

**Problem**: "Google sign-in failed"
- **Solution**: 
  - Ensure Google OAuth is enabled in Supabase Dashboard
  - Verify redirect URL matches: `io.supabase.everywear://login-callback/`
  - Check Google Cloud Console has correct OAuth credentials

### Build Issues

**Problem**: Build fails with missing environment variables
- **Solution**: Ensure both SUPABASE_URL and SUPABASE_ANON_KEY are set in Codemagic before building

**Problem**: White screen on launch
- **Solution**: Check app logs for Supabase initialization errors, verify environment variables are properly injected

### Database Issues

**Problem**: "relation does not exist" errors
- **Solution**: Run the database setup SQL script in Supabase SQL Editor

**Problem**: Permission denied errors
- **Solution**: Ensure Row Level Security policies are properly configured

## Production Checklist

Before deploying to production:

- [ ] Supabase project created and configured
- [ ] Email provider enabled in Supabase
- [ ] Google OAuth enabled with correct redirect URL
- [ ] Database tables created with proper RLS policies
- [ ] Environment variables set in Codemagic
- [ ] Email sign-up and sign-in tested
- [ ] Google sign-in tested on physical device
- [ ] Wardrobe features tested with real data
- [ ] Real-time synchronization tested
- [ ] Error handling verified

## Support

For production issues:
1. Check Codemagic build logs for environment variable errors
2. Verify Supabase Dashboard configuration
3. Review app logs for authentication errors
4. Check network connectivity and API status
