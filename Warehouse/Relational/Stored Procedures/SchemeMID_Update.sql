-- =============================================
-- Author:		JEA
-- Create date: 21/06/2013
-- Description:	Makes sure that he 
-- =============================================
CREATE PROCEDURE [Relational].[SchemeMID_Update]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    CREATE TABLE #OutletIDsAdded(OutletID INT NOT NULL)
    CREATE TABLE #OutletIDsRemoved(OutletID INT NOT NULL)
    CREATE TABLE #OutletIDsReAdded(OutletID INT NOT NULL)
    
    INSERT INTO #OutletIDsAdded(OutletID)
    SELECT o.ID
	FROM SLC_Report.dbo.RetailOutlet o
	INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
	WHERE MerchantID != ''
	EXCEPT
	SELECT OutletID
	FROM Relational.SchemeMID
	
	INSERT INTO #OutletIDsRemoved(OutletID)
	SELECT OutletID
	FROM Relational.SchemeMID
	WHERE RemovedDate IS NULL
	EXCEPT
	SELECT o.ID
	FROM SLC_Report.dbo.RetailOutlet o
	INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
	WHERE MerchantID != ''
	
	INSERT INTO #OutletIDsReAdded(OutletID)
	SELECT OutletID
	FROM Relational.SchemeMID
	WHERE NOT RemovedDate IS NULL
	INTERSECT
	SELECT o.ID
	FROM SLC_Report.dbo.RetailOutlet o
	INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
	WHERE MerchantID != ''
	
	UPDATE Relational.SchemeMID
	SET RemovedDate = GETDATE()
	FROM Relational.SchemeMID s
	INNER JOIN #OutletIDsRemoved r ON S.OutletID = r.OutletID
	
	UPDATE Relational.SchemeMID
	SET RemovedDate = NULL
	FROM Relational.SchemeMID s
	INNER JOIN #OutletIDsReAdded r ON S.OutletID = r.OutletID
	
	INSERT INTO Relational.SchemeMID(OutletID, MID, PartnerID)
	SELECT o.ID, o.MerchantID, p.PartnerID
	FROM SLC_Report.dbo.RetailOutlet o
	INNER JOIN Relational.[Partner] p on o.PartnerID = p.PartnerID
	INNER JOIN #OutletIDsAdded A on o.ID = a.OutletID
	WHERE MerchantID != ''
	
	UPDATE Relational.SchemeMID SET IsOnline = 0
	
	UPDATE Relational.SchemeMID SET IsOnline = 1
	FROM Relational.SchemeMID s
	INNER JOIN SLC_Report.dbo.RetailOutlet r on s.OutletID = r.ID
	WHERE r.Channel = 1
	
	DROP TABLE #OutletIDsAdded
    DROP TABLE #OutletIDsRemoved
    DROP TABLE #OutletIDsReAdded
    
END