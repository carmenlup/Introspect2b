using System.Runtime.InteropServices.JavaScript;
using System.Text.Json.Serialization;

namespace ClaimStatus.Models
{
    public class ClaimDetail
    {
        [JsonPropertyName("Id")]
        public int Id { get; set; }

        [JsonPropertyName("PolicyNumber")]
        public string PolicyNumber { get; set; }

        [JsonPropertyName("ClaimantName")]
        public string ClaimantName { get; set; }

        [JsonPropertyName("Status")]
        public string Status { get; set; }

        [JsonPropertyName("DateFiled")]
        public DateTime DateFiled { get; set; }

        [JsonPropertyName("Amount")]
        public decimal Amount { get; set; }
    }
}
