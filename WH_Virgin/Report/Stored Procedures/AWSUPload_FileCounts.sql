CREATE PROC [Report].[AWSUPload_FileCounts]
AS
	DECLARE @CalendarDate AS DATE = CAST(GETDATE() AS DATE)

	IF OBJECT_ID('Tempdb..#CalDates') IS NOT NULL
				DROP TABLE #CalDates
	SELECT CAST(@CalendarDate AS DATE) [CalendarDate] 
	INTO #CalDates
	INSERT INTO [Inbound].[FileCounts]
		([Inbound].[FileCounts].[CalendarDate], [Inbound].[FileCounts].[Customers], [Inbound].[FileCounts].[Trans], [Inbound].[FileCounts].[Balances], [Inbound].[FileCounts].[Login], [Inbound].[FileCounts].[Redemptions], [Inbound].[FileCounts].[Goodwill])
	SELECT cd.CalendarDate, #CalDates.[c].Customers, #CalDates.[t].Trans --, mt.MatchedTrans
			, #CalDates.[b].Balances, #CalDates.[l].Login, #CalDates.[r].Redemptions, #CalDates.[cr].Goodwill
	FROM #CalDates cd
	LEFT JOIN
	(
		select cast([Inbound].[customers].[LoadDate] as date) [LoadDate], count(*) [Customers]
		from [Inbound].[customers]
		group by cast([Inbound].[customers].[LoadDate] as date)
	) c
	on #CalDates.[c].LoadDate = cd.CalendarDate
	LEFT JOIN (
		select  cast([Inbound].[Transactions].[LoadDate] as date) [LoadDate], count(*) [Trans]
		from [Inbound].[Transactions]
		group by cast([Inbound].[Transactions].[LoadDate] as date)
		) t
	ON #CalDates.[t].LoadDate =  cd.CalendarDate
	-- LEFT JOIN (
	--	select cast(loaddate as date) [LoadDate], count(*) [MatchedTrans]
	--	from WH_Virgin.inbound.MatchedTransactions
	--	group by cast(loaddate as date)
	--	) mt 
	--on MT.LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast([Inbound].[Balances].[LoadDate] as date) [LoadDate], count(*) [Balances]
		from [Inbound].[Balances]
		group by cast([Inbound].[Balances].[LoadDate] as date)
		) b 
		ON #CalDates.[b].LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast([Inbound].[Login].[LoadDate] as date) [LoadDate], count(*) [Login]
		from [Inbound].[Login]
		group by cast([Inbound].[Login].[LoadDate] as date)
		) l 
	ON #CalDates.[l].LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast([Inbound].[Redemptions].[LoadDate] as date) [LoadDate], count(*) [Redemptions]
		from [Inbound].[Redemptions]
		group by cast([Inbound].[Redemptions].[LoadDate] as date)
		) r 
	ON #CalDates.[r].LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast([Inbound].[Goodwill].[LoadDate] as date) [LoadDate], count(*) [Goodwill]
		from [Inbound].[Goodwill]
		group by cast([Inbound].[Goodwill].[LoadDate] as date)
		) cr
	ON #CalDates.[cr].LoadDate =  cd.CalendarDate


