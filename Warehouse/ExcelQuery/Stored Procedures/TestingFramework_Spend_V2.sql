

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

Create PROCEDURE [ExcelQuery].[TestingFramework_Spend_V2]	
	(@PopTable varchar(max)
	,@Population varchar(max)
	,@BrandID varchar(max)
	,@StartDate varchar(10)
	,@EndDate varchar(10))
AS
BEGIN
	SET NOCOUNT ON;

	-- Select population into temp table
	IF OBJECT_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			id int
		)

	DECLARE @sql varchar(Max)
	SET @sql =	'SELECT	* FROM ' + @poptable +  ''

	INSERT INTO #Population execute (@sql)

	IF @Population = 'my_rewards'
		BEGIN
			Select		b.brandid
						,ConsumerCombinationID
			Into		#cc
			From		Relational.ConsumerCombination cc
			Inner Join	relational.brand b on b.brandid = cc.brandid
			Where		b.brandid = @BrandID

			CREATE CLUSTERED INDEX ix_BrandID on #cc(BrandID)

			Select		ct.CINID
						,sum(Amount) as spend
			Into		#spend
			From		Relational.ConsumerTransaction ct with (nolock)
			Inner Join	#Population p on p.ID=ct.cinid
			Inner Join	#cc cc on cc.ConsumerCombinationID=ct.ConsumerCombinationID
			Where		trandate between @StartDate and @EndDate
			and			ct.IsRefund = 0
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
							and part.ID = @BrandID
			GROUP BY		f.ID	
		END
END