# Use the official .NET SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the project file and restore dependencies
COPY ["*.csproj", "./"]
RUN dotnet restore

# Copy the rest of the application files and build the application
COPY . .

# Copy the external Mocks folder into the container
COPY mocks/. ./mocks

# Publish the application
RUN dotnet publish -c Release /p:PublishDir="/app/publish"

# Use the official ASP.NET runtime image for the final container
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app/publish ./publish

# Copy the Mocks folder to the runtime container (if needed at runtime)
COPY --from=build /app/mocks ./mocks

# Expose ports (adjust if necessary)
EXPOSE 8030
EXPOSE 8031

# Set the entry point for the container
ENTRYPOINT ["dotnet", "/app/publish/ClaimStatus.dll"]