--=====================================================================
--SP Name : [dbo].[CBP_Process_CustomerJourneyStages]
--Description: 
-- Update Log
--		Ed - Unknown - Created
--		Nitin - 02/09/2014 - Replaced ##cust table with dbo.FanSFDDailyUploadDataStaging
--		Nirupam - 06/08/2015 - Added Direct Debit Transaction Type on Line 57
--=====================================================================
CREATE PROCEDURE [dbo].[__CBP_Process_CustomerJourneyStages]
	@RowNo INT,
	@interval INT
	--@EndDate date,
	--@TableName nvarchar(150)
AS
BEGIN
	SET NOCOUNT ON

	Declare @Today datetime,
		@time DATETIME,
		@msg VARCHAR(2048),
		@SSMS BIT

	set @Today = getdate()
	
	--------------------------------------------------------------------------------------------------------------
	--------------------------------------------Pull the Transactions---------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	----Pull rolling totals for spend ever based on cashback earned on transactions or discretionary amounts awarded
	--SELECT @msg = 'Pull the Transactions'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT
	--select	--top 1000
	--		t.FanID as FanID,
	--		t.[Date],
	--		t.ClubCash*tt.Multiplier as CashBack, --Cashback Earned
	--		Dateadd(day,t.ActivationDays,t.[Date]) as DateAvailable,
	--		Case
	--			When Dateadd(day,t.ActivationDays,t.[Date]) <= @Today then t.ClubCash*tt.Multiplier
	--			else 0
	--		End as CashBackAvailable, --Cashback available for use
	--		Sum(Case
	--				When Dateadd(day,t.ActivationDays,t.[Date]) <= @Today then t.ClubCash*tt.Multiplier
	--				else 0
	--			End) 
	--			Over (Partition By t.FanID Order By Dateadd(day,t.ActivationDays,t.[Date])) as RT,  --Running total based on cashback available (not pending)
	--		ROW_NUMBER() OVER(PARTITION BY t.FanID ORDER BY Dateadd(day,t.ActivationDays,t.[Date])) AS RowNo
	--Into #Trans
	--from dbo.FanSFDDailyUploadDataStaging AS F
	--inner join dbo.trans as t with (nolock)
	--	on f.FanID = t.FanID
	--Inner join dbo.TransactionType as TT with (noLock)
	--	on t.TypeID = TT.ID
	--Where	t.TypeID in (1,9,10,17,23) -- Cashback earned/removed from Transaction or Cashback awarded/removed by call centre
		 
	--Create Clustered index ixc_Trans on #Trans(FanID)

	--------------------------------------------------------------------------------------------------------------
	----------------------------------------------------MOT1 and MOT2---------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	----Assign members to MOT1 (never earned cashback with partner) and MOT2 (not enough available cashback ever gained to redeem).
	

	--DECLARE @CJ1 TABLE (FanID INT PRIMARY KEY, CJ_Status VARCHAR(50))

	--INSERT INTO @CJ1 (FanID, CJ_Status)
	--Select	FanID,
	--		Case
	--			When Sum(CashBack) <= 0 then 'MOT1'  -- Once a customer has some pending they move to MOT2
	--			When Sum(CashBackAvailable) <  5 then 'MOT2' --not enough available cashback ever gained to redeem (will need to review for microburn)
	--			When Sum(CashBackAvailable) >= 5 then '?' --enough gained to redeem
	--		End as CJ_Status
	--From #Trans
	--GROUP BY FanID	
	--------------------------------------------------------------------------------------------------------------
	----------------------------------------------------MOT3 and Saver---------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	----if customer has gained over £5 available cashback ever we are checking how long they have had it.
	--SELECT @msg = 'MOT3 and Saver'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT

	--DECLARE @CJ2 TABLE (FanID INT, CJ_Status VARCHAR(50))

	--INSERT INTO @CJ2(FanID, CJ_Status)
	--Select	a.FANID,
	--		Case
	--			When t.DateAvailable < dateadd(day,-13,cast(getdate() as date)) then 'Saver'
	--			Else 'MOT3'
	--		End as CJ_Status
	--from 
	--(Select	cj1.FaniD,
	--		Max(Case
	--				When RT < 5 then RowNo
	--				Else 0
	--			End)+1 as [5Pounds]
	--from @CJ1  as cj1
	--inner join #Trans as t
	--	on cj1.FanID = t.FanID
	--Where CJ_Status = '?'
	--Group by cj1.FanID
	--) as a
	--inner join #Trans as t
	--	on	a.fanid = t.fanid and
	--		a.[5Pounds] = t.RowNo
	--------------------------------------------------------------------------------------------------------------
	-------------------------------------------Produce a list of Redemptions--------------------------------------
	--------------------------------------------------------------------------------------------------------------
	--SELECT @msg = 'Produce a list of Redemptions'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT

	----Pull a list of redemptions
	--select	t.FanID,
	--		t.id as TranID,
	--		t.Date as RedeemDate,
	--		r.Description as PrivateDescription,
	--		t.Price,            
	--		case when Cancelled.TransID is null then 0 else 1 end Cancelled
	--into	#Redemptions        
	--from  dbo.FanSFDDailyUploadDataStaging as c with (nolock)
	--inner join dbo.Trans as t with (nolock)
	--	on t.FanID = c.FanID
	--inner join dbo.Redeem r with (nolock)
	--	on r.id = t.ItemID
	--LEFT Outer JOIN (select ItemID as TransID from dbo.trans t2 with (nolock) where t2.typeid=4) as Cancelled ON Cancelled.TransID=T.ID
	--inner join dbo.RedeemAction as ra with (nolock) on t.ID = ra.transid and ra.Status = 1
	--where	t.TypeID=3 and
	--		T.Points > 0
	--order by TranID

	--Create clustered index ixc_Redemptions on #Redemptions(FanID)
	--------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------Combine------------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	--SELECT @msg = 'Combine'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT

	--DECLARE @CJ3 TABLE (FanID INT PRIMARY KEY, CJ_Status VARCHAR(50))

	----Combine the currently attended statuses together
	--INSERT INTO @CJ3 (FanID, CJ_Status)
	--Select	a.FanID,
	--		Cast(Case
	--				When c.CJ_Status is not null then c.CJ_Status
	--				When b.CJ_Status is not null then b.CJ_Status
	--				Else 'MOT1'
	--			 End as varchar(30)) as cj_Status
	--from dbo.FanSFDDailyUploadDataStaging as a
	--left outer join @CJ1 as b
	--	on a.fanid = b.fanid
	--Left outer join @CJ2 as c
	--	on a.fanid = c.fanid
	--Order by FanID

	--------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------CJ Statuses--------------------------------------------
	--------------------------------------------------------------------------------------------------------------
	--SELECT @msg = 'CJ Statuses'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT
	----Update statues if they have redeemed
	--Update C
	--Set cj_Status = a.NewStatus
	--from @CJ3 as c
	--inner join 
	--(Select  cj.FanID,
	--		Min(Case
	--				When r.fanid is null then cj.cj_Status
	--				When r.cancelled = 0 and r.redeemdate > dateadd(year,-1,cast(getdate() as date)) then 'Redeemer'
	--				When r.cancelled = 0 and r.redeemdate < dateadd(year,-1,cast(getdate() as date)) then 'Saver'
	--				Else cj.cj_Status
	--			End) as NewStatus
	--from @CJ3 as cj
	--inner join #Redemptions as r
	--	on cj.fanid = r.fanid
	--Group by cj.FanID
	--) as a
	--	on c.fanid = a.fanid

	--------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------High Lower Spender-------------------------------------
	--------------------------------------------------------------------------------------------------------------
	--SELECT @msg = 'High Lower Spender'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT

	--DECLARE @CJ_HL TABLE (FanID INT, CJ_Status VARCHAR(50))

	--INSERT INTO @CJ_HL (FanID, CJ_Status)
	--Select FanID,
	--		Case 
	--			When AnnualCashback >= 15 then CJ_Status + ' - High Value'
	--			when Datediff(month,ActivatedDate,@Today) >= 12 then CJ_Status + ' - Low Value'
	--			When Datediff(month,ActivatedDate,@Today) <= 11 and AnnualCashback >= Datediff(month,ActivatedDate,@Today)*1.25 then CJ_Status + ' - High Value'
	--			Else CJ_Status + ' - Low Value'
	--		End as CJ_Status
	--From
	--(Select	cj.FanID,
	--		f.ActivatedDate,
	--		cj.cj_Status,
	--		Sum(Case
	--				When DateAvailable  between dateadd(day,1,dateadd(year,-1,@Today)) and @Today and
	--					DateAvailable >= f.ActivatedDate then Cashback
	--				Else 0
	--			End) AnnualCashback
	--from @CJ3 as cj
	--inner join #Trans as T
	--	on cj.FanID = t.FanID
	--inner join dbo.FanSFDDailyUploadDataStaging as f with (Nolock)
	--	on cj.FanID = f.FanID
	--Where cj.cj_Status in ('Redeemer','Saver')
	--Group by cj.FanID,
	--		f.ActivatedDate,
	--		cj.cj_Status
	--) as a
	----Order by cj_Status
	

	--------------------------------------------------------------------------------------------------------------
	--------------------------------------------------Update Customer Journey Table-------------------------------
	--------------------------------------------------------------------------------------------------------------
	--SELECT @msg = 'Update Customer Journey Table'
	--EXEC dbo.oo_TimerMessage @msg, @time OUTPUT

	--Update C
	--	Set cj_Status = hl.cj_Status
	--from @CJ3 as C
	--inner join @CJ_HL as hl
	--	on c.fanid = hl.FanID
	--Where c.cj_Status in ('Redeemer','Saver')


	------------------------------------------------------------------------------------------------------------
	--------------------------------------Populate CustomerJourneyStaging table---------------------------------
	------------------------------------------------------------------------------------------------------------
	EXEC dbo.oo_TimerMessageV2 'Populate CustomerJourneyStaging table', @time OUTPUT, @SSMS OUTPUT

	insert Into dbo.CustomerJourneyStaging (FanID, CustomerJourneyStatus, Date)
	Select	FanID,
			'Saver' as CustomerJourneyStatus,
			@Today as [Date]
	From dbo.FanSFDDailyUploadDataStaging AS F

	EXEC dbo.oo_TimerMessageV2 'End', @time OUTPUT, @SSMS OUTPUT
END
