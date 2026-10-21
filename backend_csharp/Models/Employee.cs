using System.ComponentModel.DataAnnotations;

namespace KieuDucPhuc_API_Nhom8.Models
{
    public class Employee
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public string EmployeeCode { get; set; } = string.Empty;

        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        public string Phone { get; set; } = string.Empty;

        public string Department { get; set; } = "Phòng Công Nghệ";

        public string Position { get; set; } = "Chuyên Viên";

        public decimal BaseSalary { get; set; } = 15000000;

        public string AvatarUrl { get; set; } = "https://i.pravatar.cc/150";

        public bool IsActive { get; set; } = true;

        public DateTime JoinDate { get; set; } = DateTime.UtcNow;
    }
}
