CREATE proc [dbo].[ReportNCPMIDWeeklySales]
as

set nocount on
set datefirst 1 --monday

--select @@DATEFIRST --7 sunday

declare 
	@today datetime = convert(datetime,convert(varchar(10),getdate(),120)),
	@startday datetime,
	@endday datetime,
	@msg varchar(max)


select 
	@startday = @today - (6 + DATEPART(weekday, @today)),
	@endday = @startday + 6

--select @today, @startday, @endday

select @msg =
	convert(varchar(max),
		(
			select 
				CONVERT(varchar(20),convert(date,@startday),103) + ' till ' + CONVERT(varchar(20),convert(date,@endday),103) 'td','',
				SUM(Amount) 'td','',
				COUNT(1) 'td',''
			from SLC_Report.dbo.NobleFiles f 
			inner join NobleTransactionHistory h on f.ID = h.FileID
			where f.FileType = 'TRANS' and (f.InDate between @startday and @endday)
			and h.MerchantID = '55678792' and h.MatchStatus = 1 and h.RewardStatus in (0,1) and h.TranDate >= '2012-01-31' and h.MatchID is not null
			for xml path ('tr')
		)
	)
	
if @msg is not null
begin
	select @msg = 			'<table border="1">
								<tr>
									<th>Week</th>
									<th>Total Sales</th>
									<th>Number of Transactions</th>
								</tr>' +
							@msg +
							'</table>'


	exec msdb..sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients='nirupam.biswas@rewardinsight.com; valentina.lupi@rewardinsight.com',
		@subject = 'NCP MID 55678792 Sales Report',
		@body=@msg,
		@body_format = 'HTML', 
		@importance = 'HIGH', 
		@exclude_query_output = 1								

end
else
	exec msdb..sp_send_dbmail 
	@profile_name = 'Administrator', 
	@recipients='nirupam.biswas@rewardinsight.com; valentina.lupi@rewardinsight.com',
	@subject = 'NCP MID 55678792 Sales Report',
	@body='No sales this week.',
	@body_format = 'TEXT', 
	@importance = 'NORMAL', 
	@exclude_query_output = 1