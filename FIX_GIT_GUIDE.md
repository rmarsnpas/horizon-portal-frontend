# Fix Git Repository Corruption

Your git repository is corrupted because it's stored in OneDrive, which causes conflicts with git's internal files.

## Quick Fix (Move repo out of OneDrive):

1. Clone fresh copy to local drive:
   ```cmd
   cd C:\
   mkdir Projects
   cd Projects
   git clone https://github.com/rmarsnpas/horizon-portal-frontend.git
   cd horizon-portal-frontend
   ```

2. Copy your updated drug-screen.html from OneDrive to the new location:
   ```cmd
   copy "C:\Users\rmars\OneDrive\Documents\Documents\marsliz\Horizon-House\website\index_files\drug-screen.html" .
   ```

3. Commit and push:
   ```cmd
   git add drug-screen.html
   git commit -m "Update drug screen form"
   git push
   ```

4. Work from C:\Projects\horizon-portal-frontend going forward to avoid OneDrive conflicts

## Alternative: Use GitHub Desktop

Download from: https://desktop.github.com/
- Handles git corruption better
- Visual interface
- Automatic authentication
