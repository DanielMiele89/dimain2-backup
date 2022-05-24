

CREATE PROCEDURE [Staging].[SOW_MovingProspectsOutOfSOWMembers]
			(
			@AllProspects BIT,
			@PartnerID INT
			)
AS

BEGIN

/*
Title: SOW - Moving Prospects Out Of HTMMembers
Author: Suraj Chahal
Purpose: To automatically transition Prospects for Individual Partners or ALl prospect Partners
Date: 13/05/2014
*/



--SET @AllProspects = 1
--SET @PartnerID = 0


IF @AllProspects = 0
BEGIN
/*-------------------------------------------------------------------------*/
---------------------------Declare the variables-----------------------------
/*-------------------------------------------------------------------------*/
DECLARE @StartRow INT,
	@EndRow INT, 
	@ChunkSize INT

SET @ChunkSize = 500000
SET @StartRow = (SELECT	MIN(ID) FROM Warehouse.Relational.ShareOfWallet_Members
		WHERE PartnerID = @PartnerID)
SET @EndRow = (SELECT	MAX(ID) FROM Warehouse.Relational.ShareOfWallet_Members
		WHERE PartnerID = @PartnerID)

/*--------------------------------------------------------------------------------*/
--------Insert selected records from the Members into the Prospects table----------
/*--------------------------------------------------------------------------------*/
WHILE @StartRow <= @EndRow
BEGIN

INSERT INTO Warehouse.Relational.ShareOfWallet_Members_Prospects
SELECT	FanID, 
	HTMID, 
	PartnerID,
	StartDate,
	EndDate
FROM Warehouse.Relational.ShareOfWallet_Members
WHERE	PartnerID = @PartnerID
	AND ID BETWEEN @StartRow AND (@StartRow+@ChunkSize)-1

SET @StartRow = @StartRow+@Chunksize
END

/*---------------------------------------------------------------------------------------*/
-----Delete from SOW Members table where the ID has been input into the holding table-----
/*---------------------------------------------------------------------------------------*/
DELETE FROM Warehouse.Relational.ShareOfWallet_Members
WHERE PartnerID = @PartnerID

END
ELSE
BEGIN

/*-------------------------------------------------------------------------*/
---------------------------Declare the variables-----------------------------
/*-------------------------------------------------------------------------*/
DECLARE @StartRow2 INT,
	@EndRow2 INT, 
	@ChunkSize2 INT

SET @ChunkSize2 = 500000
SET @StartRow2 = (SELECT MIN(ID) FROM Warehouse.Relational.ShareOfWallet_Members
		WHERE PartnerID < 1000)
SET @EndRow2 = (SELECT	MAX(ID) FROM Warehouse.Relational.ShareOfWallet_Members
		WHERE PartnerID < 1000)


/*----------------------------------------------------------------------------------*/
-----------Find the SOW Members for all prospects in the HTM Members table-----------
/*----------------------------------------------------------------------------------*/
WHILE @StartRow2 <= @EndRow2
BEGIN

INSERT INTO Warehouse.Relational.ShareOfWallet_Members_Prospects
SELECT	FanID, 
	HTMID, 
	PartnerID,
	StartDate,
	EndDate
FROM Warehouse.Relational.ShareOfWallet_Members
WHERE	PartnerID < 1000
	AND ID BETWEEN @StartRow2 AND (@StartRow2+@ChunkSize2)-1

SET @StartRow2 = @StartRow2+@Chunksize2
END

/*---------------------------------------------------------------------------------------*/
-----Delete from HTM Members table where the ID has been input into the holding table-----
/*---------------------------------------------------------------------------------------*/
DELETE FROM Warehouse.Relational.ShareOfWallet_Members
WHERE PartnerID < 1000

END



END
