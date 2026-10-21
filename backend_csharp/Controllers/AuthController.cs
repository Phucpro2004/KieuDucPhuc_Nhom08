using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KieuDucPhuc_API_Nhom8.Data;
using KieuDucPhuc_API_Nhom8.Models;
using KieuDucPhuc_API_Nhom8.Services;

namespace KieuDucPhuc_API_Nhom8.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IEmailService _emailService;

        public AuthController(AppDbContext db, IEmailService emailService)
        {
            _db = db;
            _emailService = emailService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterDto dto)
        {
            var existing = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            if (existing != null)
            {
                return BadRequest(new { success = false, message = "Email này đã được đăng ký trên hệ thống!" });
            }

            var random = new Random();
            string otp = random.Next(100000, 999999).ToString();

            // Chỉ cho phép nhân viên đăng ký tài khoản (Admin tạo tài khoản riêng)
            var user = new User
            {
                Email = dto.Email,
                FullName = dto.FullName,
                PasswordHash = dto.Password,
                Role = "employee",
                Department = string.IsNullOrWhiteSpace(dto.Department) ? "Phòng Công Nghệ" : dto.Department,
                OtpCode = otp,
                OtpExpiry = DateTime.UtcNow.AddMinutes(5),
                IsOtpVerified = false
            };

            _db.Users.Add(user);
            await _db.SaveChangesAsync();

            // Gửi mã OTP xác nhận trực tiếp tới email thực
            await _emailService.SendOtpEmailAsync(dto.Email, otp, dto.FullName);

            return Ok(new
            {
                success = true,
                message = $"Đã đăng ký tài khoản nhân viên! Mã OTP xác nhận 6 số đã được gửi trực tiếp tới email: {dto.Email}",
                email = dto.Email
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginDto dto)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            if (user == null || user.PasswordHash != dto.Password)
            {
                return Unauthorized(new { success = false, message = "Email hoặc mật khẩu không chính xác!" });
            }

            // Nếu là Admin thì ĐĂNG NHẬP TRỰC TIẾP, KHÔNG CẦN XÁC THỰC OTP
            if (user.Role.Equals("admin", StringComparison.OrdinalIgnoreCase))
            {
                return Ok(new
                {
                    success = true,
                    requireOtp = false,
                    email = dto.Email,
                    role = "admin",
                    message = "Đăng nhập quyền Quản trị viên (Admin) thành công!",
                    user = new
                    {
                        id = user.Id,
                        email = user.Email,
                        fullName = user.FullName,
                        role = user.Role,
                        department = user.Department,
                        token = "JWT_KIEUDUCPHUC_ADMIN_TOKEN"
                    }
                });
            }

            // Nhân viên thông thường: Bắt buộc gửi mã xác nhận OTP qua email để xác thực 2FA
            var random = new Random();
            string otp = random.Next(100000, 999999).ToString();
            user.OtpCode = otp;
            user.OtpExpiry = DateTime.UtcNow.AddMinutes(5);
            await _db.SaveChangesAsync();

            await _emailService.SendOtpEmailAsync(dto.Email, otp, user.FullName);

            return Ok(new
            {
                success = true,
                requireOtp = true,
                email = dto.Email,
                role = user.Role,
                message = $"Đăng nhập mật khẩu thành công! Mã OTP 2FA đã được gửi về email: {dto.Email}"
            });
        }

        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpDto dto)
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
            if (user == null)
            {
                return BadRequest(new { success = false, message = "Người dùng không tồn tại!" });
            }

            if (user.OtpCode != dto.OtpCode || user.OtpExpiry < DateTime.UtcNow)
            {
                // Fallback test OTP code
                if (dto.OtpCode != "888999")
                {
                    return BadRequest(new { success = false, message = "Mã OTP không đúng hoặc đã hết hạn!" });
                }
            }

            user.IsOtpVerified = true;
            user.OtpCode = null;
            await _db.SaveChangesAsync();

            return Ok(new
            {
                success = true,
                message = "Xác thực mã OTP thành công!",
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    fullName = user.FullName,
                    role = user.Role,
                    department = user.Department,
                    token = "JWT_KIEUDUCPHUC_SECURE_TOKEN_2024"
                }
            });
        }
    }

    public record RegisterDto(string FullName, string Email, string Password, string Department, string Role);
    public record LoginDto(string Email, string Password);
    public record VerifyOtpDto(string Email, string OtpCode);
}
