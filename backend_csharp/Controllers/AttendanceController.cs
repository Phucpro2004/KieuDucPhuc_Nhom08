using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KieuDucPhuc_API_Nhom8.Data;
using KieuDucPhuc_API_Nhom8.Models;

namespace KieuDucPhuc_API_Nhom8.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AttendanceController : ControllerBase
    {
        private readonly AppDbContext _db;

        public AttendanceController(AppDbContext db)
        {
            _db = db;
        }

        [HttpPost("check-in")]
        public async Task<IActionResult> CheckIn([FromBody] Attendance record)
        {
            record.CheckInTime = DateTime.UtcNow;
            record.Status = "Thành công";
            record.IsAiVerified = true;

            _db.Attendances.Add(record);
            await _db.SaveChangesAsync();

            return Ok(record);
        }

        [HttpGet("history")]
        public async Task<IActionResult> GetHistory()
        {
            var list = await _db.Attendances.OrderByDescending(a => a.CheckInTime).ToListAsync();
            return Ok(list);
        }
    }
}
