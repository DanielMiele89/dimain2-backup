/*
	=============================================
	Author: Suraj Chahal
	Create date: 28/08/2014
	Description: Script to analyse Incentivised MIDs to see if we have been incentivising Multiple
		MerchantID combinations against one outlet. Such as '000001234' and '1234'
	Update: SB 10-10-2014 - Amended to add Partner information and allow exclusion by the table 
							R_0046_MIDs_Already_Corrected
			SB 13-11-2014 - Amended to deal with the lack of Insight Archive
			SB 19-12-2014 - Amended to deal with time lag
-- =============================================
*/
CREATE PROCEDURE [Staging].[SSRS_R0046_OutletIDs_Incentivising_Multiple_MIDs_V3]

AS
BEGIN
	SET NOCOUNT ON;
/*------------------------------------------------------------------------------------------*/
-----------------------Find last transaction date in consumertrans---------------------------
/*------------------------------------------------------------------------------------------*/
Declare @Date date
Set @Date = dateadd(day,-5,(Select Max(TransactionDate) from Relational.PartnerTrans))
			

/*------------------------------------------------------------------------------------------*/
-------------Finding all the Outlets which have multiple MIDs attached to them----------------
/*------------------------------------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#Multiple_MID_Outlets') IS NOT NULL DROP TABLE #Multiple_MID_Outlets
SELECT	pt.OutletID,
		p.PartnerID,
		p.PartnerName		
INTO #Multiple_MID_Outlets
FROM Relational.PartnerTrans pt
INNER JOIN slc_report..match m
	ON pt.MatchID = m.ID
INNER JOIN Relational.[Outlet] AS o
	ON pt.OutletID = o.OutletID
INNER JOIN Relational.[Partner] AS p
	ON O.PartnerID = P.PartnerID
Left Outer Join Staging.R_0046_MIDs_Already_Corrected as a
	on pt.OutletID = a.OutletID
Where	a.OutletID is null and
		pt.TransactionDate <= @Date
GROUP BY pt.OutletID,
		 p.PartnerID,
		 p.PartnerName
HAVING COUNT(DISTINCT m.MerchantID) > 1

CREATE CLUSTERED INDEX IdxOID ON #Multiple_MID_Outlets (OutletID)


-------------------------------------------------------------------------------------------------------
-------------------------------Find out FileIDs and Row Numbers for trans------------------------------
-------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#FileRow') IS NOT NULL DROP TABLE #FileRow
SELECT	m.RetailOutletID,
		VectorMajorID,
		VectorMinorID,
		CashbackEarned,
		mmo.PartnerID,
		mmo.PartnerName
INTO #FileRow
FROM Relational.PartnerTrans as pt
INNER JOIN SLC_Report..Match as m
	ON pt.Matchid = m.id
INNER JOIN #Multiple_MID_Outlets mmo
	ON m.RetailOutletID = mmo.OutletID

CREATE CLUSTERED INDEX IdxOID ON #FileRow (RetailOutletID)
CREATE NONCLUSTERED INDEX IdxVMaI ON #FileRow (VectorMajorID)
CREATE NONCLUSTERED INDEX IdxVMiI ON #FileRow (VectorMinorID)

-------------------------------------------------------------------------------------------------------
-------------------------------------Pull key fields for multiple MIDs---------------------------------
-------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
SELECT	t.RetailOutletID,
		t.PartnerID,
		t.PartnerName,
		cc.MID as MerchantID,
		cc.Narrative,
		LocationCountry,
		MCC.MCC,
		MCC.MCCDesc,
		TranDate,
		ct.Amount,
		t.CashbackEarned,
		t.CashbackEarned/ct.Amount as CasabackPercentage
INTO #Transactions
FROM --Archive..NobleTransactionHistory nth
	  Relational.ConsumerTransaction as ct
inner join Relational.ConsumerCombination as cc
	on ct.ConsumerCombinationID = cc.ConsumerCombinationID
INNER JOIN #FileRow t
	ON ct.fileid = t.VectorMajorID 
	AND ct.RowNum = t.VectorMinorID
LEFT OUTER JOIN Relational.MCCList MCC
	ON cc.MCCID = MCC.MCCID

CREATE CLUSTERED INDEX IdxOID ON #Transactions (RetailOutletID)
-------------------------------------------------------------------------------------------------------
-------------------------------------------------Roll up data------------------------------------------
-------------------------------------------------------------------------------------------------------
SELECT	RetailOutletID,
		PartnerID,
		PartnerName,
		MerchantID,
		Narrative,
		LocationCountry,
		MCC,
		MCCDesc,
		MIN(TranDate) as First_Tran,
		MAX(TranDate) as Last_Tran,
		SUM(Amount) as TotalSpent,
		SUM(CashbackEarned) as CashbackEarned,
		COUNT(1) as Transations
FROM #Transactions
GROUP BY RetailOutletID,PartnerID,PartnerName,MerchantID,Narrative,LocationCountry,MCC,MCCDesc
ORDER BY RetailOutletID,MerchantID


END