

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[TestingFramework_Spend]	
	(@PopTable varchar(100)
	,@Population varchar(100)
	,@BrandName varchar(100)
	,@StartDate varchar(10)
	,@EndDate varchar(10))
AS
BEGIN
	SET NOCOUNT ON;

	--DECLARE @PopTable varchar(100) = 'Sandbox.Shaun.Z_Krowd_Tesco_20170228'
	--		,@Population varchar(100) ='my_rewards'
	--		,@BrandName varchar(100) = 425
	--		,@StartDate varchar(10) ='2016-03-01'
	--		,@EndDate varchar(10) = '2017-02-28'

	-- Select population into temp table
	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			id int
		)

	INSERT INTO #Population
		EXEC ('
				SELECT	*
				FROM	' + @poptable + '
			 ')
	
	CREATE CLUSTERED INDEX ix_ID ON #Population(ID)

	IF @Population = 'my_rewards'
		BEGIN
			If Object_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
			Select		distinct ConsumerCombinationID
			Into		#cc
			From		Relational.ConsumerCombination cc
			Where		BrandID = @BrandName
				and		IsUKSpend = 1

			CREATE CLUSTERED INDEX ix_ConsumerCombinationID on #cc(ConsumerCombinationID)

			If Object_ID('tempdb..#spend') IS NOT NULL DROP TABLE #spend
			Select		ct.CINID
						,sum(Amount) as spend
			Into		#spend
			From		Relational.ConsumerTransaction ct with (nolock)
			Join		#Population p on p.ID=ct.cinid
			Join		#cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		@StartDate <= ct.TranDate 
					and ct.TranDate <= @EndDate
					and	ct.IsRefund = 0
			Group By	ct.CINID

			Select		p.id as id
						,(case when s.spend is null then
							0
						else
							s.spend
						end) as spend
			From		#Population p
			Left Join	#spend s on s.CINID=p.ID
			Order By	p.ID asc
		END
	IF @Population = 'nfi'
		BEGIN					
			SELECT distinct f.ID 
							,sum(m.Amount) as spend
 			FROM			SLC_Report.dbo.Fan f
			inner join		SLC_Report.dbo.Pan p on f.CompositeID = p.CompositeID
			inner join		SLC_Report.dbo.Match m on p.ID = m.PanID
			inner join		SLC_Report.dbo.RetailOutlet ro on m.RetailOutletID = ro.ID
			inner join		SLC_Report.dbo.Partner part on ro.PartnerID = part.ID
			inner join		SLC_Report.dbo.Trans t on m.ID = t.MatchID
			inner join		SLC_Report.dbo.TransactionType tt on t.TypeID = tt.ID
			WHERE			cast(m.transactiondate as date) between @StartDate and @EndDate 
							and part.ID = @brandname
			GROUP BY		f.ID	
		END
END