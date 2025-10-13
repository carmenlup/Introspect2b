# Use the official .NET SDK image to build the application
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Copy the project file and restore dependencies
COPY ["ClaimStatus/*.csproj", "./"]
RUN dotnet restore

# Remove libpam-modules if present
RUN apt-get remove -y libpam-modules || true

# Copy the rest of the application files and build the application
COPY ClaimStatus/. ./

# Copy the external folders into the container
COPY mocks/. ./mocks
COPY pipelines/. ./pipelines
COPY iac/. ./iac
# Publish the application
RUN dotnet publish -c Release /p:PublishDir="/app/publish"

# Use the official ASP.NET runtime image for the final container
FROM mcr.microsoft.com/dotnet/aspnet:8.0-distroless AS runtime
WORKDIR /app
COPY --from=build /app/publish ./publish

# Copy the external folders to the runtime container (if needed at runtime)
COPY --from=build /app/mocks ./mocks
COPY --from=build /app/pipelines ./pipelines
COPY --from=build /app/iac ./iac

# Expose ports (adjust if necessary)
EXPOSE 8030
EXPOSE 8031

# Set the entry point for the container
ENTRYPOINT ["dotnet", "/app/publish/ClaimStatus.dll"]