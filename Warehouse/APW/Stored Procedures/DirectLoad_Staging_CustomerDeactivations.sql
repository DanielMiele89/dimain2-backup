﻿-- =============================================
-- Author:		JEA
-- Create date: 03/11/2016
-- Description:	Marks recently deactivated customers
-- =============================================
CREATE PROCEDURE [APW].[DirectLoad_Staging_CustomerDeactivations]
AS
BEGIN

	SET NOCOUNT ON;

	---------------------------------------------------------------------------------------
	-----------Find those customers who are deactivated with no DeactivatedDate------------
	---------------------------------------------------------------------------------------
	/*DeactivatedDate is populated off of a table end produces based on an assessment of the
	  changelog, therefore I am finding dates for those catered for by this*/

	SELECT FanID,ActivationDate as ActivatedDate
	INTO #DeactivatedCustomers 
	FROM APW.DirectLoad_Staging_Customer as c
	WHERE CustStatus = 0 AND 
			DeactivationDate IS NULL
	---------------------------------------------------------------------------------------
	-----------------Find comment that indicates the Fan was Deactivated-------------------
	---------------------------------------------------------------------------------------
	/*This comment is normally generated by an overnight process checking valid Pans and 
	  Fans etc*/
	SELECT c.FanID,Max([Date]) as Deact_Date
	INTO #Comm_Deact
	FROM slc_report.dbo.comments c
	INNER JOIN #DeactivatedCustomers dc
		ON	c.FanID = dc.FanID
	WHERE c.Comment LIKE  'Fan Deactivated%' AND
			c.[Date] >= DC.ActivatedDate
	GROUP BY c.FanID

	SELECT	Dc.FanID, 
			Min(DataDate) AS Deact_Date
	INTO #DeactTable
	FROM #DeactivatedCustomers DC
	INNER JOIN warehouse.staging.DeactivatedCustomers c
		ON dc.FanID = c.FanID
	LEFT OUTER JOIN #Comm_Deact as cd
		ON dc.FanID = cd.FanID
	WHERE cd.FanID IS NULL
	GROUP BY DC.FanID
		HAVING MIN(DataDate) > 'Jul 17, 2012' -- ignore those from first week.
	---------------------------------------------------------------------------------------
	----------------------Find List of those still without deactivateddate-----------------
	---------------------------------------------------------------------------------------
	SELECT dc.FanID,dc.ActivatedDate
	INTO #D
	FROM #DeactivatedCustomers as dc
	LEFT OUTER JOIN #Comm_Deact as cd
		ON dc.FanID = cd.FanID
	LEFT OUTER JOIN #DeactTable as d
		ON dc.FanID = d.FanID
	WHERE cd.fanid IS NULL AND d.fanid IS NULL

	---------------------------------------------------------------------------------------
	----------------------Find other Comment entries to use for date-----------------------
	---------------------------------------------------------------------------------------

	SELECT c.ObjectID,Max([Date]) AS Deact_Date
	INTO #Comm_Deact2
	FROM slc_report.dbo.comments  as c
	INNER JOIN #DeactivatedCustomers as dc
		ON	c.ObjectID = dc.FanID
	LEFT OUTER JOIN
		(SELECT * 
		 FROM #Comm_Deact
		 UNION ALL
		 SELECT * 
		 FROM #DeactTable
		 ) a
		ON dc.FanID = a.fanid
	WHERE	(c.Comment Like '%Opt_Out%' or
			 c.Comment Like '%Account_Close%' or
			 c.Comment Like '%Close_Account%' or
			 c.Comment like '%Disabled%' or
			 c.Comment like '%Deceased%' or
			 c.Comment like '%Died%' or
			 c.Comment like '%Removed_Scheme%' or
			 c.Comment like '%Pan Deactivated%'
			 ) and
			c.[Date] >= DC.ActivatedDate and
			a.FanID is null
	GROUP BY c.ObjectID

	---------------------------------------------------------------------------------------
	-------------------------Create a table of Deac dates----------------------------------
	---------------------------------------------------------------------------------------
	/*Where no other date could be found we put in the Activation Date*/
	SELECT Dc.* ,
			CASE
				WHEN a.Deact_Date IS NULL THEN dc.ActivatedDate
				ELSE a.Deact_Date
			END AS DDate
	INTO #Deactivations
	FROM #DeactivatedCustomers dc
	LEFT OUTER JOIN
		(SELECT * 
		 FROM #Comm_Deact
		 UNION ALL
		 SELECT * 
		 FROM #DeactTable
		 UNION ALL
		 SELECT * 
		 FROM #Comm_Deact2) a
		ON dc.FanID = a.fanid
	---------------------------------------------------------------------------------------
	--------------------------------Update Customer Table----------------------------------
	---------------------------------------------------------------------------------------
	UPDATE APW.DirectLoad_Staging_Customer
	SET DeactivationDate = DDate
	FROM APW.DirectLoad_Staging_Customer c
	INNER JOIN #Deactivations D
		ON C.FanID = D.FanID
	WHERE C.ActivationDate IS NOT NULL AND
		c.CustStatus = 0
    
END
