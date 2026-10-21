namespace KieuDucPhuc_API_Nhom8.Services
{
    public interface IEmailService
    {
        Task<bool> SendOtpEmailAsync(string toEmail, string otpCode, string recipientName);
    }
}
