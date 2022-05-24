CREATE PROC [Report].[AWSUPload_FileCounts]
AS
	DECLARE @CalendarDate AS DATE = CAST(GETDATE() AS DATE)

	IF OBJECT_ID('Tempdb..#CalDates') IS NOT NULL
				DROP TABLE #CalDates
	SELECT CAST(@CalendarDate AS DATE) [CalendarDate] 
	INTO #CalDates
	INSERT INTO [Inbound].[FileCounts]
		(CalendarDate, Customers, Trans, Balances, Login, Redemptions, Goodwill)
	SELECT cd.CalendarDate, c.Customers, t.Trans --, mt.MatchedTrans
			, b.Balances, l.Login, r.Redemptions, cr.Goodwill
	FROM #CalDates cd
	LEFT JOIN
	(
		select cast(loaddate as date) [LoadDate], count(*) [Customers]
		from [Inbound].[customers]
		group by cast(loaddate as date)
	) c
	on c.LoadDate = cd.CalendarDate
	LEFT JOIN (
		select  cast(loaddate as date) [LoadDate], count(*) [Trans]
		from [Inbound].[Transactions]
		group by cast(loaddate as date)
		) t
	ON t.LoadDate =  cd.CalendarDate
	-- LEFT JOIN (
	--	select cast(loaddate as date) [LoadDate], count(*) [MatchedTrans]
	--	from WH_Virgin.inbound.MatchedTransactions
	--	group by cast(loaddate as date)
	--	) mt 
	--on MT.LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast(loaddate as date) [LoadDate], count(*) [Balances]
		from [Inbound].[Balances]
		group by cast(loaddate as date)
		) b 
		ON b.LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast(loaddate as date) [LoadDate], count(*) [Login]
		from [Inbound].[Login]
		group by cast(loaddate as date)
		) l 
	ON l.LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast(loaddate as date) [LoadDate], count(*) [Redemptions]
		from [Inbound].[Redemptions]
		group by cast(loaddate as date)
		) r 
	ON r.LoadDate =  cd.CalendarDate
		LEFT JOIN (
		select cast(loaddate as date) [LoadDate], count(*) [Goodwill]
		from [Inbound].[Goodwill]
		group by cast(loaddate as date)
		) cr
	ON cr.LoadDate =  cd.CalendarDate


