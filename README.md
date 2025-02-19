# Introduction au multi-staging Docker

## Création d'une application React.js pour la démonstration

On va créer une application React.js avec Vite.js pour la démonstration.

```bash
npm create vite@latest react-app
```

Après avoir sélectionné les différentes options, on peut se rendre dans le dossier de l'application, installer les dépendances et démarrer l'application.

```bash
cd react-app
# Installation des dépendances
npm install
# Démarrage de l'application
npm run dev
```

## Création d'une image Docker pour l'application

### Création d'une image dédiée au développement

On va créer une image Docker pour l'application React.js en mode développement. Pour cela, on crée un fichier `Dockerfile.development` à la racine du projet.

```Dockerfile
FROM node:latest

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
```

On peut maintenant construire l'image Docker.

```bash
docker build --tag react-app:development --file ./react-app/Dockerfile.development ./react-app
```

On peut maintenant démarrer un conteneur Docker avec l'image créée.

```bash
docker run --publish 5173:5173 react-app:development
```

On pourrait ajouter un volume pour synchroniser les modifications du code source avec le conteneur Docker, mais on préfèrera utiliser un Docker Compose pour cela, avec éventuellement Docker Compose Watch.

### Docker Compose Watch

On va utiliser Docker Compose Watch pour synchroniser les modifications du code source avec le conteneur Docker. Pour cela, on va créer un fichier `compose.development.yml` à la racine du projet.

```yaml
services:
  react-app:
    image: react-app:development
    build:
      context: ./react-app
      dockerfile: Dockerfile.development
    ports:
      - "5173:5173"
    develop:
      watch:
        - action: sync
          path: ./react-app/src
          target: /app/src
        - action: sync+restart
          path: ./react-app
          target: /app
        - action: rebuild
          path: ./react-app/package.json
```

Contrairement aux volumes, Docker Compose Watch permet de synchroniser les modifications avec le conteneur Docker de manière unidirectionnelle. 

On peut maintenant démarrer le conteneur Docker avec Docker Compose Watch.

```bash
docker-compose --file compose.development.yml up --build --watch
```

En ignorant (via le `.dockerignore`) le dossier `node_modules`, on peut éviter de synchroniser les dépendances du conteneur Docker avec le code source (évitant les potentiels conflits).

### Action: `sync`

En synchronisant le dossier `src` du code source avec le dossier `src` du conteneur Docker, on peut voir les modifications en temps réel dans le navigateur.

### Action: `sync+restart`

En synchronisant le dossier `react-app` du code source avec le dossier `app` du conteneur Docker, on peut redémarrer le conteneur Docker en cas de modification. Cela permet notamment un redémarrage lors des modifications des fichiers de configuration.

#### Action: `rebuild`

En surveillant le `package.json`, on peut reconstruire le conteneur Docker en cas de modification des dépendances. Cela permet d'avoir les dépendances automatiquement installées au sein d'une nouvelle image (construite automatiquement) lors d'une installation en local.

### Commit des modifications pour sauvegarde

Tout cela est bien pour le développement, et on peut éventuellement commit les modifications pour les sauvegarder.

```bash
docker commit <container_id> react-app:development
```

---

Lorsque l'on souhaitera déployer, on favorisera une image dédiée à la production, plus légère, contenant uniquement le résultat de la construction de l'application et le serveur web. On n'a pas besoin d'avoir les dépendances de développement dans l'image de production, ainsi que l'ensemble des outils de développement.

> 💡 Le multi-staging est utilisé pour créer des images Docker plus légères en séparant les étapes de développement et de production. Cela permet de réduire la taille des images finales en n’incluant que ce qui est nécessaire pour exécuter l’application.

### Création d'une image dédiée à la production

On va créer une image Docker pour l'application React.js en mode production. Pour cela, on crée un fichier `Dockerfile à la racine du projet.

```bash

```Dockerfile
FROM node:latest AS builder

WORKDIR /app

COPY ./package.json ./

RUN npm install

COPY ./ ./

RUN npm run build


FROM nginx:alpine AS server

COPY --from=builder /app/dist /usr/share/nginx/html
```

Le premier stage correspond à l'étape de construction de l'application, et le second stage correspond à l'étape de déploiement de l'application via un serveur web Nginx.

> 💡 Pour tirer le meilleur parti du multi-staging, minimisez les couches dans chaque étape et utilisez des images de base légères. Assurez-vous également de nettoyer les fichiers temporaires et inutiles pour optimiser la taille de l’image.

On peut maintenant construire l'image Docker.

```bash
docker build --tag react-app:production ./react-app
```

On peut maintenant démarrer un conteneur Docker avec l'image créée.

```bash
docker run --publish 80:80 react-app:production
```

## Comparaisons

En faisant un `docker images`, on peut comparer les images Docker créées.

```bash
docker images
```

```
REPOSITORY      TAG           IMAGE ID       CREATED              SIZE
react-app   production    ...            ...                  75.7MB
react-app   development   ...            ...                  2.03GB
```

On peut voir que l'image de production est beaucoup plus légère que l'image de développement. Seul le serveur web Nginx (avec l'application pré-construite) est présent dans l'image de production, alors que l'image de développement contient l'ensemble des dépendances de développement. Uniquement l'image de base pour la seconde étape (`server`) est présente dans l'image de production.

> 💡 Dans un Dockerfile traditionnel, toutes les opérations sont effectuées dans un seul conteneur, ce qui peut entraîner des images volumineuses et complexes. Le multi-staging, en revanche, permet de diviser le processus de construction en étapes distinctes, optimisant ainsi l’image finale.

## Conclusion

Le multi-staging permet de créer des images Docker plus légères et sécurisées.

En séparant les étapes de développement et de production, on optimise les performances et réduit les risques en production.

C'est une pratique essentielle pour tout développeur cherchant à améliorer ses workflows Docker.