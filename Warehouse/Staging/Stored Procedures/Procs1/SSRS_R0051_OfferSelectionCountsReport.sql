﻿
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 16/10/2014
-- Description: Report to pull top level stats for offers going live that week
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0051_OfferSelectionCountsReport]
			
AS
BEGIN
	SET NOCOUNT ON;


/**************************************************************************
**********************Creating the OfferMerged Table***********************
**************************************************************************/
--IF OBJECT_ID ('tempdb..##Offers') IS NOT NULL DROP TABLE ##Offers
--CREATE TABLE ##Offers (
--	ClientServicesRef VARCHAR(10),
--	HTMID INT,
--	HTM_Description VARCHAR(50),
--	OfferID INT,
--	CashbackRate NUMERIC(32,2),
--	MailedCustomers INT,
--	ControlCustomers INT,
--	CommissionRate NUMERIC(32,2)
--	)
----

Truncate table Staging.SSRS_R0051_OfferSelectionCounts

/**************************************************************************
**************Looping mailable audience from selection tables**************
**************************************************************************/
DECLARE @StartRow INT,
	@Qry NVARCHAR(MAX),
	@TableName VARCHAR(100)

SET @StartRow = 1

WHILE @StartRow <= (SELECT MAX(TableID) FROM Relational.NominatedOfferMember_TableNames)
BEGIN

SET @TableName = (SELECT TableName FROM Relational.NominatedOfferMember_TableNames WHERE TableID = @StartRow)

SET @Qry = '
INSERT INTO Staging.SSRS_R0051_OfferSelectionCounts
SELECT	ClientServicesRef,
	CASE 
		WHEN HTMID IS NULL THEN ''''
		ELSE HTMID
	END as HTMID,
	CASE
		WHEN HTM_Description IS NULL THEN ''SoW Not Applicable''
		ELSE HTM_Description
	END as HTM_Description,
	OfferID,
	CashbackRate,
	SUM(CASE WHEN s.Grp = ''Mail'' THEN 1 ELSE 0 END) as MailedCustomers,
	SUM(CASE WHEN s.Grp = ''Control'' THEN 1 ELSE 0 END) as ControlCustomers,
	CommissionRate
FROM '+ @TableName +' s
LEFT OUTER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END)/100 as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
	ON s.OfferID = pcr.RequiredIronOfferID
GROUP BY ClientServicesRef, CASE WHEN HTMID IS NULL THEN ''''	ELSE HTMID END,
	CASE
		WHEN HTM_Description IS NULL THEN ''SoW Not Applicable''
		ELSE HTM_Description
	END, OfferID, CashbackRate, CommissionRate
ORDER BY HTMID

'
EXEC sp_ExecuteSQL @Qry

SET @StartRow = @StartRow+1

END

SELECT	*
FROM Staging.SSRS_R0051_OfferSelectionCounts
ORDER BY ClientServicesRef,HTMID

/*************************

*************************/

END

