using System.Reflection;

var builder = WebApplication.CreateBuilder(args);
// Add CORS policy
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyMethod()
            .AllowAnyHeader();
    });
});

// Add services to the container.
builder.Services.AddControllers();
builder.Configuration.AddUserSecrets(Assembly.GetExecutingAssembly(), true);

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Claim Status API",
        Version = "v1",
        Description = "API for managing claim statuses"
    });

    // Force Swagger 2.0 compatibility
    c.UseInlineDefinitionsForEnums(); // Optional: Helps with Swagger 2.0 compatibility
});

var app = builder.Build();
// Use CORS
app.UseCors("AllowAll");

app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "Claim Status API v1");
});

// Configure the HTTP request pipeline.

// Comment UseHttpsRedirection for testing with HTTP
app.UseHttpsRedirection();

app.UseAuthorization();
app.MapControllers();

app.Run();
