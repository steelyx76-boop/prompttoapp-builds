# Prompt To App - Build Automation

Ce repo contient le workflow GitHub Actions pour builder automatiquement les projets créés sur Prompt To App.

## Configuration

1. Ajouter les secrets dans Settings > Secrets and variables > Actions :
   - `SUPABASE_URL` : URL de votre projet Supabase
   - `SUPABASE_SERVICE_KEY` : Service role key de Supabase

2. Le workflow se déclenche via `repository_dispatch` avec l'event type `build-project`

## Utilisation

Le workflow est déclenché automatiquement par l'application Prompt To App lors de la publication d'un projet.
