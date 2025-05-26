# ---------- Build stage ----------
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /workspace

# Copier le wrapper + fichiers Gradle pour profiter du cache
COPY gradlew gradlew.bat ./
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Rendre le wrapper exécutable et pré-télécharger les dépendances
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Copier le reste du code et produire le JAR exécutable
COPY . .
RUN ./gradlew clean bootJar --no-daemon -x test  \
 && ls -R build/libs

# ---------- Runtime stage ----------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /workspace/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
