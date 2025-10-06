using System.Text.Json.Serialization;

namespace ClaimStatus.Models
{
    public class Notes
    {
        [JsonPropertyName("Notes")]
        public List<Note> NoteList { get; set; } = new List<Note>();
    }
}
