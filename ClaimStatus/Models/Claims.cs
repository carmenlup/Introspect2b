using System.Text.Json.Serialization;

namespace ClaimStatus.Models
{
    public class Claims
    {
        [JsonPropertyName("Claims")]
        public List<ClaimDetail> ClaimList { get; set; } = new List<ClaimDetail>();
    }
}

