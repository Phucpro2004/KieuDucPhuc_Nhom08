using System.ComponentModel.DataAnnotations;

namespace KieuDucPhuc_API_Nhom8.Models
{
    public class Attendance
    {
        [Key]
        public int Id { get; set; }

        public int UserId { get; set; }

        public string EmployeeName { get; set; } = string.Empty;

        public DateTime CheckInTime { get; set; } = DateTime.UtcNow;

        public DateTime? CheckOutTime { get; set; }

        public double Latitude { get; set; }

        public double Longitude { get; set; }

        public string LocationAddress { get; set; } = string.Empty;

        public double NoiseDb { get; set; }

        public double MotionScore { get; set; }

        public double PressureHpa { get; set; }

        public string Status { get; set; } = "Thành công";

        public bool IsAiVerified { get; set; } = true;
    }
}
