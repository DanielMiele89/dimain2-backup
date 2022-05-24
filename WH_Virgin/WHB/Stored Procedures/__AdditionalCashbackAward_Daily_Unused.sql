/*
-- Replaces this bunch of stored procedures:

EXEC WHB.AdditionalCashbackAward_V1_11_Append
EXEC WHB.AdditionalCashbackAward_CC_MonthlyAwards
EXEC WHB.AdditionalCashbackAward_ApplePay_V1_2
EXEC WHB.AdditionalCashbackAward_ItemAlterations_V1_0
EXEC WHB.AdditionalCashbackAward_Adjustments_V1_1
EXEC WHB.AdditionalCashbackAward_Adjustment_AmazonRedemptions
*/
CREATE PROCEDURE [WHB].[__AdditionalCashbackAward_Daily_Unused] 
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_V1_11_Append ###############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_V1_11_Append', 'Starting'

Declare 
	@AddedDate date, --********Date of last transaction********--
	@AddedDateTime datetime, --********Datetime of last transaction********--
	@ACA_ID int
		

--Find Last record Imported (Find the last processed date so that we only import rows after this day)
SELECT 
	@AddedDate = Max([Derived].[AdditionalCashbackAward].[AddedDate]), 
	@ACA_ID = Max([Derived].[AdditionalCashbackAward].[AdditionalCashbackAwardID])
FROM Derived.AdditionalCashbackAward as aca				

Set @AddedDate = Dateadd(day,1,@AddedDate)
Set @AddedDateTime = @AddedDate


--Get Additional Cashback Awards with a PanID---------------------
INSERT INTO Derived.AdditionalCashbackAward	
SELECT t.Matchid as MatchID,
		t.VectorMajorID as FileID,
		t.VectorMinorID as RowNum,
		t.FanID,
		t.[Date] as TranDate,
		t.ProcessDate as AddedDate,
		t.Price as Amount,
		t.ClubCash*tt.Multiplier as CashbackEarned,
		t.ActivationDays,
		tt.AdditionalCashbackAwardTypeID,
		Case
			When CardTypeID = 1 then 1 -- Credit Card
			When CardTypeID = 2 then 0 -- Debit Card
			When t.DirectDebitOriginatorID IS not null then 2 -- Direct Debit
			When tt.AdditionalCashbackAwardTypeID = 11 then 1 -- ApplyPay and Credit Card
			Else 0
		End as PaymentMethodID,
		t.DirectDebitOriginatorID

FROM (
	SELECT aca.*,tt.Multiplier
	From Warehouse.Relational.AdditionalCashbackAwardType as aca
	INNER JOIN SLC_Report.dbo.TransactionType as tt 
		on	aca.TransactionTypeID = tt.ID	
) as tt
	
INNER HASH JOIN SLC_Report.dbo.Trans as t 
	on tt.ItemID = t.ItemID 
	and tt.TransactionTypeID = t.TypeID

INNER JOIN Warehouse.Relational.Customer as c
	on t.FanID = c.fanid

LEFT JOIN SLC_Report.dbo.Pan as p
	on t.PanID = p.ID

LEFT JOIN SLC_Report..PaymentCard as pc
	on p.PaymentCardID = pc.ID

WHERE t.VectorMajorID is not null 
	and t.VectorMinorID is not null
	and t.ProcessDate >= @AddedDateTime
	

-- Remove those records with a MatchID and no TRANS record ---------------------
UPDATE aca
	Set [Derived].[AdditionalCashbackAward].[MatchID] = m.ID
FROM Derived.AdditionalCashbackAward as aca
INNER JOIN SLC_Report..match as m with (nolock)
	on	aca.FileID = m.VectorMajorID and
		aca.RowNum = m.VectorMinorID
INNER JOIN Warehouse.Relational.PartnerTrans as pt
	on	m.ID = pt.MatchID
WHERE aca.AdditionalCashbackAwardID >= @ACA_ID

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_V1_11_Append', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_CC_MonthlyAwards ###########################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_CC_MonthlyAwards', 'Starting'
--Find out number of last entry
Declare @MaxRow int
Select @MaxRow = Max([Staging].[RBSGFundedCreditCardMonthlyOffers].[RowNum]) From Staging.RBSGFundedCreditCardMonthlyOffers
Set @MaxRow = coalesce(@MaxRow,0)


--Insert missing Transactions into listing table
INSERT INTO Staging.RBSGFundedCreditCardMonthlyOffers 
SELECT	
	ID as TranID,
	-1 as FileID,
	ROW_NUMBER() OVER(ORDER BY t.TranID ASC) + @MaxRow AS RowNum,
	a.ACATypeID	as AdditionalCashbackAwardTypeID
FROM SLC_Report.dbo.Trans as t
INNER JOIN Staging.AdditionalCashbackAwards_MonthlyCCOffers as a
	ON t.ItemID = a.ItemID
WHERE t.TypeID = 1
	AND NOT EXISTS (SELECT 1 FROM Staging.RBSGFundedCreditCardMonthlyOffers as b WHERE t.ID = b.TranID)


--Get Additional Cashback Awards with a PanID
Insert Into Derived.AdditionalCashbackAward	
select t.Matchid as MatchID,
		a.FileID as FileID,
		a.RowNum as RowNum,
		t.FanID,
		t.[Date] as TranDate,
		t.ProcessDate as AddedDate,
		t.Price as Amount,
		t.ClubCash*tt.Multiplier as CashbackEarned,
		t.ActivationDays,
		tt.AdditionalCashbackAwardTypeID,
		1 as PaymentMethodID,
		t.DirectDebitOriginatorID
from Derived.Customer c 
inner join SLC_Report.dbo.Trans t 
	on t.FanID = c.fanid
inner join (
	Select aca.*,tt.Multiplier
	From Warehouse.Relational.[AdditionalCashbackAwardType] aca
	inner join SLC_Report.dbo.TransactionType tt 
		on	aca.TransactionTypeID = tt.ID
) as tt
	on tt.ItemID = t.ItemID 
	and tt.TransactionTypeID = t.TypeID          
inner join Staging.RBSGFundedCreditCardMonthlyOffers as a
	on t.ID = a.TranID
Where RowNum > @MaxRow

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_CC_MonthlyAwards', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_ApplePay_V1_2 ##############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_ApplePay_V1_2', 'Starting'

DECLARE @MaxApplePayTran int, @HighestRowNo int

SELECT 
	@MaxApplePayTran = ISNULL(Max([Staging].[AdditionalCashbackAward_ApplePay].[TranID]),0),
	@HighestRowNo = ISNULL(Max([Staging].[AdditionalCashbackAward_ApplePay].[RowNum]),0)
FROM Staging.AdditionalCashbackAward_ApplePay


--Create Types Table---------------------------------------
if object_id('tempdb..#Types') is not null drop table #Types
SELECT aca.*,tt.Multiplier
INTO #Types
FROM Warehouse.Relational.[AdditionalCashbackAwardType] as aca
INNER JOIN SLC_Report.dbo.TransactionType as tt with (Nolock)
	ON	aca.TransactionTypeID = tt.ID
WHERE Title Like '%Apple Pay%'


INSERT INTO Staging.AdditionalCashbackAward_ApplePay
SELECT 
	#Types.[t].ID as TranID,
	0 as FileID,
	ROW_NUMBER() OVER (ORDER BY #Types.[t].ID) + @HighestRowNo AS RowNum
FROM SLC_Report.DBO.Trans t	
INNER JOIN #Types tt 
	ON tt.ItemID = #Types.[t].ItemID 
	AND tt.TransactionTypeID = #Types.[t].TypeID
INNER JOIN Derived.Customer c 
	ON #Types.[t].FanID = c.FanID
WHERE NOT EXISTS (SELECT 1 FROM Staging.AdditionalCashbackAward_ApplePay a WHERE #Types.[t].ID = #Types.[a].TranID)

 
--Find final customers
INSERT INTO Derived.AdditionalCashbackAward
SELECT	   
	NULL as MatchID,
	#Types.[a].FileID as FileID,
	#Types.[a].RowNum as RowNum,
	#Types.[t].FanID,
	Cast(#Types.[t].[Date] as date) as TranDate,
	Cast(#Types.[t].ProcessDate as date) as AddedDate,
	#Types.[t].Price as Amount,
	#Types.[t].ClubCash*tt.Multiplier as CashbackEarned,
	#Types.[t].ActivationDays,
	tt.AdditionalCashbackAwardTypeID,
	1 as PaymentMethodID,
	NULL as DirectDebitOriginatorID
FROM Staging.AdditionalCashbackAward_ApplePay as a
INNER LOOP JOIN SLC_Report..Trans t 
	on a.TranID = t.ID
INNER JOIN #Types as tt
	on tt.ItemID = #Types.[t].ItemID 
	and tt.TransactionTypeID = #Types.[t].TypeID
WHERE #Types.[TranID] > @MaxApplePayTran ---******INCREMENTAL LOAD ONLY

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_ApplePay_V1_2', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_ItemAlterations_V1_0 #######################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_ItemAlterations_V1_0', 'Starting'

UPDATE b
SET [Derived].[AdditionalCashbackAward].[AdditionalCashbackAwardTypeID] = a.AdditionalCashbackAwardTypeID_New
FROM Warehouse.[Relational].[AdditionalCashbackAwardTypeAdjustments] as a
INNER JOIN Derived.AdditionalCashbackAward as b
	on a.AdditionalCashbackAwardTypeID_Original = b.AdditionalCashbackAwardTypeID
WHERE b.Trandate BETWEEN a.StartDate and a.EndDate

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_ItemAlterations_V1_0', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_Adjustments_V1_1 ###########################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_Adjustments_V1_1', 'Starting'

TRUNCATE TABLE Relational.AdditionalCashbackAdjustment
INSERT INTO Derived.AdditionalCashbackAdjustment
SELECT	t.FanID						as FanID,
		t.ProcessDate				as AddedDate,
		t.ClubCash* aca.Multiplier	as CashbackEarned,
		t.ActivationDays,
		aca.AdditionalCashbackAdjustmentTypeID
FROM SLC_Report.dbo.Trans t 
INNER JOIN ( -- Insert excludes Burn As You Earn, as these have an ItemID of 0 in the Warehouse.Relational.AdditionalCashbackAdjustmentType table
	SELECT aca.*,tt.Multiplier
	FROM Warehouse.Relational.AdditionalCashbackAdjustmentType aca
	INNER JOIN SLC_Report.dbo.TransactionType tt 
		on aca.TypeID = tt.ID
) aca 
	on t.ItemID = aca.ItemID 
	and t.TypeID = aca.TypeID
	--and t.fanid = 1960606
INNER JOIN Derived.Customer as c
	on t.FanID = c.FanID

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_Adjustments_V1_1', 'Finished'




-------------------------------------------------------------------------------
--EXEC WHB.AdditionalCashbackAward_Adjustment_AmazonRedemptions ###############
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_Adjustment_AmazonRedemptions', 'Starting'

--Find Transactions for Earn while you burn bonus-----------------------------
IF object_id('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
SELECT	t.TypeiD,
		t.FanID,
		t.ProcessDate,
		t.ClubCash* tt.Multiplier	as CashbackEarned,
		t.ActivationDays,
		t.ItemID
INTO #Trans
FROM SLC_Report.dbo.Trans t 
INNER JOIN SLC_Report.dbo.TransactionType tt 
	on t.TypeID = tt.ID		
INNER JOIN Derived.Customer c 
	on t.FanID = c.FanID
WHERE TypeID in (26,27)
-- (104991 rows affected) / 00:00:20

CREATE CLUSTERED INDEX i_Trans_ItemID on #Trans (ItemID)



INSERT INTO [Derived].[AdditionalCashbackAdjustment]
SELECT	
	a.FanID,
	a.ProcessDate,
	a.CashbackEarned,
	a.ActivationDays,
	Case
		-- Amazon
		When #Trans.[b].ItemID = 7236 and a.TypeID = 26 then 77 
		When #Trans.[b].ItemID = 7238 and a.TypeID = 26 then 78
		When #Trans.[b].ItemID = 7240 and a.TypeID = 26 then 79
		When #Trans.[b].ItemID = 7236 and a.TypeID = 27 then 80
		When #Trans.[b].ItemID = 7238 and a.TypeID = 27 then 81
		When #Trans.[b].ItemID = 7240 and a.TypeID = 27 then 82
		-- M&S
		When #Trans.[b].ItemID = 7242 and a.TypeID = 26 then 83
		When #Trans.[b].ItemID = 7243 and a.TypeID = 26 then 84
		When #Trans.[b].ItemID = 7244 and a.TypeID = 26 then 85
		When #Trans.[b].ItemID = 7242 and a.TypeID = 27 then 86
		When #Trans.[b].ItemID = 7243 and a.TypeID = 27 then 87
		When #Trans.[b].ItemID = 7244 and a.TypeID = 27 then 88
		-- B&Q
		When #Trans.[b].ItemID = 7248 and a.TypeID = 26 then 95
		When #Trans.[b].ItemID = 7249 and a.TypeID = 26 then 96
		When #Trans.[b].ItemID = 7250 and a.TypeID = 26 then 97
		When #Trans.[b].ItemID = 7248 and a.TypeID = 27 then 98
		When #Trans.[b].ItemID = 7249 and a.TypeID = 27 then 99
		When #Trans.[b].ItemID = 7250 and a.TypeID = 27 then 100
		-- Argos
		When #Trans.[b].ItemID = 7256 and a.TypeID = 26 then 101
		When #Trans.[b].ItemID = 7257 and a.TypeID = 26 then 102
		When #Trans.[b].ItemID = 7258 and a.TypeID = 26 then 103
		When #Trans.[b].ItemID = 7256 and a.TypeID = 27 then 104
		When #Trans.[b].ItemID = 7257 and a.TypeID = 27 then 105
		When #Trans.[b].ItemID = 7258 and a.TypeID = 27 then 106
		-- John Lewis
		When #Trans.[b].ItemID = 7260 and a.TypeID = 26 then 107
		When #Trans.[b].ItemID = 7261 and a.TypeID = 26 then 108
		When #Trans.[b].ItemID = 7262 and a.TypeID = 26 then 109
		When #Trans.[b].ItemID = 7260 and a.TypeID = 27 then 110
		When #Trans.[b].ItemID = 7261 and a.TypeID = 27 then 111
		When #Trans.[b].ItemID = 7262 and a.TypeID = 27 then 112

		Else 0
	End as [AdditionalCashbackAdjustmentTypeID]
FROM #Trans as a
INNER JOIN SLC_report.dbo.Trans as b 
	on a.ItemID = #Trans.[b].ID
-- (104991 rows affected) / 00:00:01

EXEC Monitor.ProcessLog_Insert 'WHB', 'AdditionalCashbackAward_Adjustment_AmazonRedemptions', 'Finished'




RETURN 0