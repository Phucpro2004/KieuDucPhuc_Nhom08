-- ===============================================================
-- DỰ ÁN MÔN HỌC: APP CHẤM CÔNG NHÂN VIÊN (NHÓM 8)
-- SINH VIÊN thực hiện: KIỀU ĐỨC PHÚC
-- CƠ SỞ DỮ LIỆU: SQL SERVER (KieuDucPhuc_Db_Nhom8)
-- ===============================================================

CREATE DATABASE KieuDucPhuc_Db_Nhom8;
GO

USE KieuDucPhuc_Db_Nhom8;
GO

-- 1. BẢNG TÀI KHOẢN NGƯỜI DÙNG & MÃ OTP EMAIL
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(150) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    FullName NVARCHAR(150) NOT NULL,
    Role NVARCHAR(50) NOT NULL DEFAULT 'employee', -- 'admin' hoặc 'employee'
    Department NVARCHAR(100) NOT NULL DEFAULT 'Phòng Công Nghệ',
    OtpCode NVARCHAR(10) NULL,
    OtpExpiry DATETIME2 NULL,
    IsOtpVerified BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

-- 2. BẢNG HỒ SƠ NHÂN VIÊN (PHỤC VỤ CHỨC NĂNG CRUD)
CREATE TABLE Employees (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeCode NVARCHAR(50) NOT NULL UNIQUE,
    FullName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(20) NULL,
    Department NVARCHAR(100) NOT NULL,
    Position NVARCHAR(100) NOT NULL,
    BaseSalary DECIMAL(18,2) NOT NULL DEFAULT 15000000,
    AvatarUrl NVARCHAR(500) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    JoinDate DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
GO

-- 3. BẢNG BẢN GHI CHẤM CÔNG (LƯU TỌA ĐỘ GPS & CẢM BIẾN MÔI TRƯỜNG)
CREATE TABLE Attendances (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    EmployeeName NVARCHAR(150) NOT NULL,
    CheckInTime DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CheckOutTime DATETIME2 NULL,
    Latitude FLOAT NOT NULL,
    Longitude FLOAT NOT NULL,
    LocationAddress NVARCHAR(500) NULL,
    NoiseDb FLOAT NOT NULL DEFAULT 42.0,      -- Mức tiếng ồn (dB)
    MotionScore FLOAT NOT NULL DEFAULT 0.8,   -- Chỉ số gia tốc chuyển động (m/s²)
    PressureHpa FLOAT NOT NULL DEFAULT 1013.25, -- Áp suất khí quyển (hPa)
    Status NVARCHAR(50) NOT NULL DEFAULT 'Thành công',
    IsAiVerified BIT NOT NULL DEFAULT 1
);
GO

-- CHÈN DỮ LIỆU MẪU BAN ĐẦU
INSERT INTO Users (Email, PasswordHash, FullName, Role, Department, IsOtpVerified)
VALUES
(N'kieuducphuc.admin@company.com', N'Phuc123456@', N'Kiều Đức Phúc', 'admin', N'Ban Giám Đốc', 1),
(N'nguyenvananh@company.com', N'User123456@', N'Nguyễn Văn Anh', 'employee', N'Phòng Công Nghệ', 1);

INSERT INTO Employees (EmployeeCode, FullName, Email, Phone, Department, Position, BaseSalary)
VALUES
(N'NV-202401', N'Kiều Đức Phúc', N'kieuducphuc.admin@company.com', N'0988123456', N'Ban Giám Đốc', N'Tổng Giám Đốc (CEO)', 45000000),
(N'NV-202402', N'Nguyễn Văn Anh', N'nguyenvananh@company.com', N'0912345678', N'Phòng Công Nghệ', N'Trưởng Phòng IT', 28000000),
(N'NV-202403', N'Trần Thị Mai', N'tranthimai@company.com', N'0909876543', N'Phòng Nhân Sự', N'Chuyên Viên HR', 18000000);
GO
