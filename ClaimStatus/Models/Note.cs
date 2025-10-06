using System.Text.Json.Serialization;

namespace ClaimStatus.Models;


public class Note
{
    [JsonPropertyName("Id")]
    public int Id { get; set; }

    [JsonPropertyName("ClaimId")]
    public int ClaimId { get; set; }

    [JsonPropertyName("Content")]
    public string Content { get; set; }

    [JsonPropertyName("CreatedDate")]
    public DateTime CreatedDate { get; set; }
}
