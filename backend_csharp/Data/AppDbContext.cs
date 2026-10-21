using Microsoft.EntityFrameworkCore;
using KieuDucPhuc_API_Nhom8.Models;

namespace KieuDucPhuc_API_Nhom8.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }
        public DbSet<Employee> Employees { get; set; }
        public DbSet<Attendance> Attendances { get; set; }
    }
}
