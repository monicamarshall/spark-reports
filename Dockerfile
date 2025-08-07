# Step 1: Use official OpenJDK base image
FROM openjdk:17-jdk-slim

# Step 2: Set working directory inside container
WORKDIR /app

# Step 3: Copy the fat JAR into the container
COPY target/spark-reports-1.0.0.jar app.jar
            

# Step 4: Expose Spring Boot port
EXPOSE 8080

# Step 5: Run the application
# opens the sun.nio.ch module to all unnamed modules
ENTRYPOINT ["java", "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED", "-jar", "app.jar"]
