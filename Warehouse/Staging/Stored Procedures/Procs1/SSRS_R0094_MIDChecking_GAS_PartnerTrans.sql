
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 04/08/2015
-- Description: Finds baseline stats for MIDS looking in GAS and PartnerTrans
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0094_MIDChecking_GAS_PartnerTrans] (
			@MID VARCHAR(200)
			)

AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#MID') IS NOT NULL DROP TABLE #MID
CREATE TABLE #MID (MID VARCHAR(20))

WHILE @MID LIKE '%,%'
BEGIN
      INSERT INTO #MID
      SELECT  SUBSTRING(@MID,1,CHARINDEX(',',@MID)-1)
      SET @MID = (SELECT  SUBSTRING(@MID,CHARINDEX(',',@MID)+1,LEN(@MID)))
END
      INSERT INTO #MID
      SELECT @MID


SELECT  p.PartnerID,
	p.PartnerName,
	o.OutletID,
        o.MerchantID,
        COUNT(pt.MatchID) as Trans,
        SUM(TransactionAmount) as TotalSpend,
        SUM(CashbackEarned) as TotalCashbackEarned,
        MIN(TransactionDate) as FirstTran,
        MAX(TransactionDate) as LastTran
FROM Warehouse.Relational.Outlet o
Left Outer JOIN Warehouse.Relational.PartnerTrans pt
      ON o.OutletID = pt.OutletID
INNER JOIN #MID as m
      ON Right(replace(o.MerchantID,' ',''),Len(m.MID)) = m.MID
	  --o.MerchantID = m.MID
INNER JOIN Warehouse.Relational.Partner p
	ON o.PartnerID = p.PartnerID
GROUP BY p.PartnerID,p.PartnerName,o.OutletID, o.MerchantID
ORDER BY o.MerchantID


END