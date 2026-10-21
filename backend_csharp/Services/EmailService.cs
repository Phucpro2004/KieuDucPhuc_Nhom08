using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace KieuDucPhuc_API_Nhom8.Services
{
    public class EmailService : IEmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task<bool> SendOtpEmailAsync(string toEmail, string otpCode, string recipientName)
        {
            try {
                var message = new MimeMessage();
                string senderEmail = _config["SmtpSettings:SenderEmail"] ?? "no-reply@company.com";
                string senderName = _config["SmtpSettings:SenderName"] ?? "KieuDucPhuc Group";

                message.From.Add(new MailboxAddress(senderName, senderEmail));
                message.To.Add(new MailboxAddress(recipientName, toEmail));
                message.Subject = $"[KieuDucPhuc Group] Mã Xác Thực OTP Đăng Nhập: {otpCode}";

                var bodyBuilder = new BodyBuilder
                {
                    HtmlBody = $@"
                        <div style='font-family: Arial, sans-serif; background-color: #0b0f19; color: #ffffff; padding: 30px; borderRadius: 12px;'>
                            <h2 style='color: #6366f1;'>TẬP ĐOÀN KIEU DUC PHUC GROUP</h2>
                            <p>Xin chào <b>{recipientName}</b>,</p>
                            <p>Mã OTP xác thực tài khoản ứng dụng Chấm công nhân viên của bạn là:</p>
                            <div style='font-size: 32px; font-weight: bold; color: #06b6d4; background-color: #1e293b; padding: 15px; text-align: center; letter-spacing: 5px; border-radius: 8px;'>
                                {otpCode}
                            </div>
                            <p style='margin-top: 20px; color: #94a3b8;'>Mã OTP có hiệu lực trong 2 phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.</p>
                            <hr style='border: 0.5px solid #334155;'/>
                            <p style='font-size: 11px; color: #64748b;'>Hệ Thống Quản Trị Nhân Sự & Chấm Công - KieuDucPhuc Group</p>
                        </div>"
                };

                message.Body = bodyBuilder.ToMessageBody();

                using var client = new SmtpClient();
                string host = _config["SmtpSettings:Host"] ?? "smtp.gmail.com";
                int port = int.Parse(_config["SmtpSettings:Port"] ?? "587");
                string username = _config["SmtpSettings:Username"] ?? "";
                string password = (_config["SmtpSettings:Password"] ?? "").Replace(" ", "").Trim();

                if (!string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password))
                {
                    await client.ConnectAsync(host, port, SecureSocketOptions.StartTls);
                    await client.AuthenticateAsync(username, password);
                    await client.SendAsync(message);
                    await client.DisconnectAsync(true);
                }
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[EmailService Error]: {ex.Message}");
                return false;
            }
        }
    }
}
