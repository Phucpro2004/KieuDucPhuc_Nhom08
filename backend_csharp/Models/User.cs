using System.ComponentModel.DataAnnotations;

namespace KieuDucPhuc_API_Nhom8.Models
{
    public class User
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string PasswordHash { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        public string Role { get; set; } = "employee"; // admin / employee

        public string Department { get; set; } = "Phòng Công Nghệ";

        public string? OtpCode { get; set; }

        public DateTime? OtpExpiry { get; set; }

        public bool IsOtpVerified { get; set; } = false;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
