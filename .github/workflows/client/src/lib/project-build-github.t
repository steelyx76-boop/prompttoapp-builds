const GITHUB_TOKEN = import.meta.env.VITE_GITHUB_TOKEN;
const GITHUB_REPO = 'steelyx76-boop/prompttoapp-builds';

export async function triggerBuild(projectId: string, userId: string) {
  const callbackUrl = `${window.location.origin}/api/build-callback`;
  
  const response = await fetch(`https://api.github.com/repos/${GITHUB_REPO}/dispatches`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${GITHUB_TOKEN}`,
      'Content-Type': 'application/json',
      'Accept': 'application/vnd.github.v3+json'
    },
    body: JSON.stringify({
      event_type: 'build-project',
      client_payload: {
        project_id: projectId,
        user_id: userId,
        callback_url: callbackUrl
      }
    })
  });
  
  if (!response.ok) {
    throw new Error(`Failed to trigger build: ${response.statusText}`);
  }
  
  return { success: true };
}

export async function waitForBuild(projectId: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const eventSource = new EventSource(`/api/build-status/${projectId}`);
    
    const timeout = setTimeout(() => {
      eventSource.close();
      reject(new Error('Build timeout'));
    }, 5 * 60 * 1000); // 5 minutes timeout
    
    eventSource.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      if (data.status === 'success') {
        clearTimeout(timeout);
        eventSource.close();
        resolve();
      } else if (data.status === 'error') {
        clearTimeout(timeout);
        eventSource.close();
        reject(new Error(data.message || 'Build failed'));
      }
    };
    
    eventSource.onerror = () => {
      clearTimeout(timeout);
      eventSource.close();
      reject(new Error('Connection error'));
    };
  });
}
```

### 3.2 Modifier project-publish.ts

Modifier `client/src/lib/project-publish.ts` :

```typescript
import { triggerBuild, waitForBuild } from './project-build-github';

export async function publishProject(projectId: string, userId: string) {
  try {
    // 1. Sauvegarder tous les fichiers dans Supabase Storage
    console.log(' Saving project files...');
    await saveProjectFiles(projectId, userId);
    
    // 2. Déclencher le build sur GitHub Actions
    console.log(' Triggering build...');
    await triggerBuild(projectId, userId);
    
    // 3. Attendre que le build soit terminé
    console.log('⏳ Waiting for build to complete...');
    await waitForBuild(projectId);
    
    // 4. Marquer le projet comme publié
    console.log(' Marking project as published...');
    await markProjectAsPublished(projectId);
    
    return { success: true };
  } catch (error) {
    console.error(' Publish failed:', error);
    throw error;
  }
}
