USE MarketingDB;

DROP TABLE IF EXISTS Campaigns;
CREATE TABLE Campaigns (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Channel VARCHAR(50),
    Team VARCHAR(50),
    DichVu VARCHAR(100),
    NgayBatDau DATE,
    NgayKetThuc DATE,
    TenChienDich VARCHAR(100),
    PhanPhoi VARCHAR(50),
    NganSachNhomQuangCao BIGINT,
    LoaiNganSach VARCHAR(50),
    SoTienDaChiTieu BIGINT,
    SoLuongMess INT,
    ChiBaoKetQua VARCHAR(100),
    ChiPhiTrenKetQua DECIMAL(18,2),
    BinhLuan INT,
    CTR FLOAT,
    CPM DECIMAL(18,2),
    TanSuat DECIMAL(10,2),
    LuotTiepCan BIGINT,
    LuotHienThi BIGINT,
    SoKHDen INT,
    DoanhThu BIGINT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SELECT 
    Channel,
    COUNT(*) AS SoChienDich,
    SUM(SoTienDaChiTieu) AS TongChiPhi,
    SUM(DoanhThu) AS TongDoanhThu,
    SUM(SoLuongMess) AS TongMess,
    AVG(ChiPhiTrenKetQua) AS CPA_TrungBinh,
    ROUND(SUM(DoanhThu) / NULLIF(SUM(SoTienDaChiTieu), 0), 2) AS ROI
FROM Campaigns
GROUP BY Channel
ORDER BY ROI DESC;

-- 2. Hiệu quả theo Team
SELECT 
    Team,
    SUM(SoLuongMess) AS TongMess,
    SUM(DoanhThu) AS TongDoanhThu,
    AVG(ChiPhiTrenKetQua) AS CPA_TrungBinh,
    ROUND(SUM(DoanhThu) / NULLIF(SUM(SoTienDaChiTieu), 0), 2) AS ROI
FROM Campaigns
GROUP BY Team;
-- 3. Top 5 chiến dịch tốt nhất
SELECT 
    TenChienDich, Channel, Team, SoTienDaChiTieu, DoanhThu, SoLuongMess,
    ROUND(DoanhThu / SoTienDaChiTieu, 2) AS ROI
FROM Campaigns
ORDER BY ROI DESC
LIMIT 5;
--CHI PHÍ & HIỆU QUẢ THEO KÊNH THEO TUẦN
SELECT 
    CONCAT('Tuần ', WEEK(NgayBatDau, 1), ' (', 
           DATE_FORMAT(DATE_SUB(NgayBatDau, INTERVAL WEEKDAY(NgayBatDau) DAY), '%d/%m'),
           ' - ',
           DATE_FORMAT(DATE_ADD(DATE_SUB(NgayBatDau, INTERVAL WEEKDAY(NgayBatDau) DAY), INTERVAL 6 DAY), '%d/%m'), ')') AS Thoi_Gian,
    Channel AS Kenh,
    COUNT(*) AS So_Chien_Dich,
    FORMAT(SUM(SoTienDaChiTieu), 0) AS Tong_Chi_Phi,
    FORMAT(SUM(SoLuongMess), 0) AS Tong_Mess,
    FORMAT(SUM(DoanhThu), 0) AS Tong_Doanh_Thu,
    FORMAT(AVG(ChiPhiTrenKetQua), 0) AS CPA_Trung_Binh,
    ROUND(SUM(DoanhThu) / NULLIF(SUM(SoTienDaChiTieu), 0), 2) AS ROI
FROM campaigns
GROUP BY WEEK(NgayBatDau, 1), Channel
ORDER BY WEEK(NgayBatDau, 1) DESC, ROI DESC;

–- TOP 10 CHIẾN DỊCH HIỆU QUẢ NHẤT (ROI > 5)
SELECT 
    TenChienDich,
    Channel,
    Team,
    NgayBatDau,
    SoTienDaChiTieu AS Chi_Phi,
    DoanhThu,
    SoLuongMess AS Mess,
    ROUND(DoanhThu / SoTienDaChiTieu, 2) AS ROI
FROM campaigns
WHERE DoanhThu / SoTienDaChiTieu >= 5
ORDER BY ROI DESC
LIMIT 10;
–- HIỆU SUẤT THEO TEAM (SO SÁNH ROI & DOANH THU)
SELECT 
    Team,
    COUNT(*) AS So_Chien_Dich,
    SUM(SoTienDaChiTieu) AS Tong_Chi,
    SUM(DoanhThu) AS Tong_Doanh_Thu,
    ROUND(SUM(DoanhThu) / NULLIF(SUM(SoTienDaChiTieu), 0), 2) AS ROI,
    ROUND(AVG(ChiPhiTrenKetQua), 0) AS CPA_TB
FROM campaigns
GROUP BY Team
ORDER BY ROI DESC;
--– PHÂN TÍCH KÊNH THEO CHI PHÍ / DOANH THU / MESS
SELECT 
    Channel,
    SUM(SoTienDaChiTieu) AS Chi_Phi,
    SUM(DoanhThu) AS Doanh_Thu,
    SUM(SoLuongMess) AS Tong_Mess,
    ROUND(SUM(SoTienDaChiTieu) / NULLIF(SUM(DoanhThu), 0), 2) AS ChiPhi_Tren_1_Trieu_Doanh_Thu,
    ROUND(SUM(SoLuongMess) / NULLIF(SUM(SoTienDaChiTieu)/1000000, 0), 0) AS Mess_Tren_1_Trieu_Chi
FROM campaigns
GROUP BY Channel;
--TOP 5 CAMPAIGN HIỆU QUẢ NHẤT (TỔNG HỢP 2 TRỌNG SỐ 70-30)
WITH RankedCampaigns AS (
    SELECT 
        TenChienDich,
        Channel,
        Team,
        (DoanhThu - SoTienDaChiTieu) AS Net_Profit,
        ROUND((SoKHDen / NULLIF(SoLuongMess, 0)) * 100, 2) AS Ty_Le_KH_Mess,
        
        -- Chuẩn hóa (rank) để tính trọng số
        RANK() OVER (ORDER BY (DoanhThu - SoTienDaChiTieu) DESC) AS Rank_Profit,
        RANK() OVER (ORDER BY (SoKHDen / NULLIF(SoLuongMess, 0)) DESC) AS Rank_Conversion,
        
        -- Tổng điểm (70% Profit + 30% Conversion)
        (0.7 / RANK() OVER (ORDER BY (DoanhThu - SoTienDaChiTieu) DESC)) + 
        (0.3 / RANK() OVER (ORDER BY (SoKHDen / NULLIF(SoLuongMess, 0)) DESC)) AS Composite_Score
    FROM campaigns
)
SELECT 
    TenChienDich,
    Channel,
    Team,
    FORMAT(Net_Profit, 0) AS Net_Profit,
    CONCAT(Ty_Le_KH_Mess, '%') AS Ty_Le_KH_Mess,
    ROUND(Composite_Score, 4) AS Diem_Tong_Hop
FROM RankedCampaigns
ORDER BY Composite_Score DESC
LIMIT 5;