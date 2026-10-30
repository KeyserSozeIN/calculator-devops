# ---------- Stage 1: build the JAR ----------
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends maven && rm -rf /var/lib/apt/lists/*

# Copy only pom.xml first so dependencies are cached as their own layer
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Now copy the source and build (tests already run in Jenkins)
COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---------- Stage 2: slim runtime ----------
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Run as a non-root user
RUN addgroup -S app && adduser -S app -G app

# Copy only the JAR from the build stage
COPY --from=build /app/target/calculator.jar app.jar

USER app
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
