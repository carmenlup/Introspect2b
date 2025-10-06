using ClaimStatus.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Text.Json.Serialization;
using Azure;
using Azure.AI.OpenAI;
using ClaimStatus.Models.Response;
using OpenAI.Chat;

[ApiController]
[Route("api/[controller]")]
public class ClaimsController : ControllerBase
{
    private readonly ILogger<ClaimsController> _logger;
    private readonly string? _solPath;
    private readonly IConfiguration _configuration;


    public ClaimsController(ILogger<ClaimsController> logger, IConfiguration configuration)
    {
        _logger = logger;
        _configuration = configuration;
        var currentDirectory = Directory.GetCurrentDirectory(); // Gets the current working directory
        _solPath = Directory.GetParent(currentDirectory)?.FullName; // Navigate up to the solution folder
    }

    [HttpGet("{id}")]
    public IActionResult GetClaim(int id)
    {
        _logger.LogInformation("GetClaim method invoked with ID: {Id}", id);
        if (id <= 0)
        {
            _logger.LogWarning("Claim Id should have a valid value. Please provide an integer value grater than zero");
            return BadRequest("Invalid Id Claim provided.");
        }

        var claimsFilePath = Path.Combine(_solPath, "mocks", "claims.json");

        if (!System.IO.File.Exists(claimsFilePath))
        {
            _logger.LogWarning("Claims file not found at path: {FilePath}", claimsFilePath);
            return NotFound("Claims data set not found. Check if claim.json exist");
        }

        var claimsData = System.IO.File.ReadAllText(claimsFilePath);
        var claims = JsonSerializer.Deserialize<Claims>(claimsData);

        var claim = claims?.ClaimList.FirstOrDefault(c => c.Id == id);
        if (claim == null)
        {
            _logger.LogWarning("Claim with ID {Id} not found.", id);
            return NotFound($"Claim with ID {id} not found.");
        }

        var claimResponse = new ClaimResponse()
        {
            Amount = claim.Amount,
            ClaimantName = claim.ClaimantName,
            DateFiled = claim.DateFiled,
            PolicyNumber = claim.PolicyNumber,
            Status = claim.Status
        };

        _logger.LogInformation("Claim with ID {Id} successfully retrieved.", id);
        return Ok(claim);
    }

    [HttpPost("{id}/summarize")]
    public async Task<IActionResult> SummarizeClaimNotes(int id)
    {

        if (id <= 0)
        {
            _logger.LogWarning($"Invalid claim id provided: {id}");
            return BadRequest($"Invalid claim id provided: {id}");
        }

        var notesFilePath = Path.Combine(_solPath, "mocks", "notes.json");
        if (!System.IO.File.Exists(notesFilePath))
        {
            _logger.LogWarning("Notes file not found at path: {FilePath}", notesFilePath);
            return NotFound($"Notes data not found for Claim Id {id}. Check if notes.exist to path: {notesFilePath}");
        }

        var notesData = JsonSerializer.Deserialize<Notes>(System.IO.File.ReadAllText(notesFilePath));

        if (notesData.NoteList.Count == 0)
        {
            _logger.LogWarning($"No notes found for Claim ID: {id}");
            return NotFound($"Notes for Claim ID {id} not found.");
        }

        _logger.LogInformation($"Notes found for Claim ID: {id}. Generating summary...");

        var (originalNotes, summary, recommendation) = await GetSummaryFromOpenAi(notesData.NoteList.Where(n => n.ClaimId == id));

        _logger.LogInformation($"Summary and recommendation successfully generated for Claim ID: {id}");

        return Ok(new
        {
            ClaimId = id,
            OriginalNotes = originalNotes,
            Summary = summary,
            Recommendation = recommendation
        });
    }
    private Task<(string OriginalNotes, string Summary, string Recommendation)> GetSummaryFromOpenAi(IEnumerable<Note> notes)
    {
        var uriString = _configuration["OpenAiConfig:Endpoint"];
        var endpoint = new Uri(uriString);
        var deploymentName = _configuration["OpenAiConfig:DeploymentName"];
        var apiKey = _configuration["OpenAiConfig:ApiKey"];

        AzureOpenAIClient azureClient = new(
            endpoint,
            new AzureKeyCredential(apiKey));
        ChatClient chatClient = azureClient.GetChatClient(deploymentName);

        // Define the chat messages
        // send notes as a json string
        var notesJson = JsonSerializer.Serialize(notes);

        ChatCompletion chatCompletion = chatClient.CompleteChat(
        [
            // System messages represent instructions or other guidance about how the assistant should behave
            new SystemChatMessage( "You are an assistant that summarizes claim notes  and provides next-step recommendations."),
            // User messages represent user input, whether historical or the most recent input
            new UserChatMessage($"List original content of notes: {notesJson}. Summarize the following notes. Provide a next-step recommendation. Format the response on 3 sections named 'Original Notes','Summary:','Recommendation:"),
            // Assistant messages in a request represent conversation history for responses
        ]);


        //Console.WriteLine($"{chatCompletion.Role}: {chatCompletion.Content}");

        var responseContent = chatCompletion.Content[0].Text;

        // Split the response into summary and recommendation (assuming OpenAI returns them in a structured format)
        var parts = responseContent.Split("\n\n", StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);

        var originalNotes = parts.Length > 0 ? parts[0].Trim() : "No customer summary provided.";
        var summary = parts.Length > 1 ? parts[1].Trim() : "No summary provided.";
        var recommendation = parts.Length > 2 ? parts[2].Trim() : "No recommendation provided.";

        return Task.FromResult((originalNotes, summary, recommendation));
    }
}