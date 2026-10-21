using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using KieuDucPhuc_API_Nhom8.Data;
using KieuDucPhuc_API_Nhom8.Models;

namespace KieuDucPhuc_API_Nhom8.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EmployeeController : ControllerBase
    {
        private readonly AppDbContext _db;

        public EmployeeController(AppDbContext db)
        {
            _db = db;
        }

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var list = await _db.Employees.OrderByDescending(e => e.Id).ToListAsync();
            return Ok(list);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(int id)
        {
            var emp = await _db.Employees.FindAsync(id);
            if (emp == null) return NotFound(new { message = "Không tìm thấy nhân viên!" });
            return Ok(emp);
        }

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] Employee model)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            _db.Employees.Add(model);
            await _db.SaveChangesAsync();
            return CreatedAtAction(nameof(GetById), new { id = model.Id }, model);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> Update(int id, [FromBody] Employee model)
        {
            var existing = await _db.Employees.FindAsync(id);
            if (existing == null) return NotFound(new { message = "Không tìm thấy nhân viên!" });

            existing.EmployeeCode = model.EmployeeCode;
            existing.FullName = model.FullName;
            existing.Email = model.Email;
            existing.Phone = model.Phone;
            existing.Department = model.Department;
            existing.Position = model.Position;
            existing.BaseSalary = model.BaseSalary;
            existing.IsActive = model.IsActive;

            await _db.SaveChangesAsync();
            return Ok(existing);
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(int id)
        {
            var emp = await _db.Employees.FindAsync(id);
            if (emp == null) return NotFound(new { message = "Không tìm thấy nhân viên!" });

            _db.Employees.Remove(emp);
            await _db.SaveChangesAsync();
            return Ok(new { success = true, message = "Đã xóa nhân viên thành công!" });
        }
    }
}
