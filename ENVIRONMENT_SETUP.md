# Everywear - Environment Setup Guide

## Environment Variables

The Everywear app requires the following environment variables to be configured:

### Required Environment Variables

```bash
# Supabase Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### Setup Instructions

#### 1. Supabase Setup
1. Create a new project at [supabase.com](https://supabase.com)
2. Navigate to Project Settings > API
3. Copy the Project URL and Anon Key
4. Configure these in your build environment

#### 2. Development Environment

For local development, create an `env.json` file in the root directory:

```json
{
  "SUPABASE_URL": "your_supabase_url",
  "SUPABASE_ANON_KEY": "your_supabase_anon_key"
}
```

**Note**: `env.json` is gitignored and should never be committed to version control.

#### 3. Production Build (Codemagic)

Configure the environment variables in your Codemagic workflow:

```yaml
environment:
  vars:
    SUPABASE_URL: $SUPABASE_URL
    SUPABASE_ANON_KEY: $SUPABASE_ANON_KEY
```

## Demo Mode

If no Supabase credentials are provided, the app will run in demo mode with limited functionality:
- No real data persistence
- No real-time synchronization
- Mock data for demonstration purposes

## Troubleshooting

### Common Issues

1. **White Screen Issues**
   - Check that Supabase credentials are properly configured
   - Verify network connectivity
   - Check app logs for authentication errors

2. **Authentication Failures**
   - Ensure SUPABASE_URL and SUPABASE_ANON_KEY are correct
   - Check if Supabase project is active
   - Verify API key permissions

3. **Build Issues**
   - Make sure environment variables are set before building
   - Check Codemagic environment variable configuration
   - Verify `env.json` format (if used locally)

### Debug Mode

Enable debug logging by building in debug mode to see detailed error messages and network requests.

## Support

For setup issues, please check:
1. Environment variable configuration
2. Supabase project status
3. Network connectivity
4. Application logs
