

/****************************************************************************
-- Author: Suraj Chahal
-- Create date: 07/07/2015
-- Description: Identifies outlets which don't have a tran in the last 90days

Change History
----------------------
#1		Zoe Taylor		24/01/2017			Modified to include MID from GAS to construct correct URL in the display query
*****************************************************************************/

CREATE PROCEDURE [Staging].[SSRS_R0086_Outlets_NoTransLast90Days]
									
AS
BEGIN
	SET NOCOUNT ON;


/*******************************************************************************
******Checking PartnerTrans for Outlets not received trans in last 90 days******
*******************************************************************************/
IF OBJECT_ID ('tempdb..#MIDs') IS NOT NULL DROP TABLE #MIDs
SELECT	p.PartnerID,
        p.PartnerName,
        pt.OutletID,
        o.MerchantID,
        MAX(TransactionDate) as LastTrans
INTO #MIDs
FROM Warehouse.Relational.PartnerTrans pt
INNER JOIN SLC_Report.dbo.RetailOutlet o
      ON pt.OutletID = o.ID
INNER JOIN Warehouse.Relational.Partner p
      ON o.PartnerID = p.PartnerID
WHERE	p.CurrentlyActive = 1
	AND o.SuppressFromSearch = 0
	AND o.GeolocationUpdateFailed = 0 
	AND o.Coordinates IS NOT NULL
GROUP BY p.PartnerID, p.PartnerName, pt.OutletID, o.MerchantID
HAVING MAX(TransactionDate) < = DATEADD(DAY,-90,CAST(GETDATE() AS DATE))



/*************************************************************
******Transforming MIDs removing or adding leading zeros******
*************************************************************/
IF OBJECT_ID ('tempdb..#CCMIDs') IS NOT NULL DROP TABLE #CCMIDs
SELECT	*, MerchantID [OriginalMID] 
INTO #CCMIDs
FROM #MIDs
UNION ALL
SELECT	PartnerID,
	PartnerName,
	OutletID,
	CASE 
            WHEN LEFT(MerchantID,1) = '0' THEN RIGHT(MerchantID,LEN(MerchantID)-1) 
            ELSE '0'+MerchantID 
	END  MerchantID,
	LastTrans,
	MerchantID [OriginalMID]
FROM #MIDs



/*************************************************************
****************Finding CCIDs for these MIDs******************
*************************************************************/
IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
SELECT	cc.ConsumerCombinationID,
	cc.MID,
	cc.Narrative,
	cc.LocationCountry,
	c.OriginalMID 
INTO #CCIDs
FROM Warehouse.relational.ConsumerCombination cc
INNER JOIN #CCMIDs c
      ON cc.MID = c.MerchantID



/**************************************************************
***********Finding Last Transaction for MIDS in BPD************
**************************************************************/
IF OBJECT_ID ('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	cc.*,
	MAX(Trandate) as LastTran
INTO #Trans
FROM #CCIDs as cc
INNER JOIN Warehouse.Relational.ConsumerTransaction ct (NOLOCK)
      ON cc.ConsumerCombinationID = ct.ConsumerCombinationID
GROUP BY  cc.ConsumerCombinationID, cc.MID, cc.Narrative, cc.LocationCountry, cc.OriginalMID 



/********************************************
***********Final Select for Report***********
********************************************/
SELECT	m.PartnerID,
	m.PartnerName,
	m.OutletID,
	t.OriginalMID [MerchantID],
	o.Address1,
	o.Address2,
	o.City,
	o.Postcode,
	m.LastTrans as LastTransInGas,
	MAX(t.LastTran) as LastTransInBPD,
	cast('https://admin.reward.tv/PartnerSection/OfflinePartnerManagerEditor.aspx?action=edit&mid=' + convert(varchar(20), t.OriginalMID) as varchar(500)) as GAS_URL
FROM #Trans t
INNER JOIN #CCMIDs m
      ON t.MID = m.MerchantID
INNER JOIN Warehouse.Relational.Outlet o
      ON m.OutletID = o.OutletID
GROUP BY m.PartnerID, m.PartnerName, m.OutletID, m.MerchantID, m.LastTrans, o.Address1, o.Address2, o.City, o.Postcode, t.OriginalMID
HAVING MAX(t.LastTran) < DATEADD(DAY,-90,CAST(GETDATE() AS DATE))
ORDER BY PartnerName


END