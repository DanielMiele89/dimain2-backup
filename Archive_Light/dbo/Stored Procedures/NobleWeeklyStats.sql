CREATE proc [dbo].[NobleWeeklyStats]
as
set nocount on

declare @report table(
	Bank varchar(50),
	CustCount bigint,
	ActiveCardCount bigint,
	TotalCardCount bigint,
	TotalTranCount bigint
)

declare @msg varchar(max)


insert into @report(bank, CustCount)
select i.name, count_big(1)
from slc_report.dbo.issuer i
inner join slc_report.dbo.issuercustomer ic on i.id = ic.issuerid
group by i.name

update r
set r.TotalCardCount = p.TotalCardCount
from @report r
inner join
(
	select i.name, count_big(1) as TotalCardCount
	from slc_report.dbo.issuer i
	inner join slc_report.dbo.issuercustomer ic on i.id = ic.issuerid
	inner join slc_report.dbo.issuerpaymentcard ipc on ic.id = ipc.issuercustomerid
	group by i.name
) p on r.Bank = p.name

update r
set r.ActiveCardCount = p.ActiveCardCount
from @report r
inner join
(
	select i.name, count_big(1) as ActiveCardCount
	from slc_report.dbo.issuer i
	inner join slc_report.dbo.issuercustomer ic on i.id = ic.issuerid
	inner join slc_report.dbo.issuerpaymentcard ipc on ic.id = ipc.issuercustomerid
	where ipc.status = 1
	group by i.name
) p on r.Bank = p.name


select 
	bankid,
	count_big(1) as TotalTranCount
into #transtats
from nobletransactionhistory 
group by bankid

update r
set r.TotalTranCount = p.TotalTranCount
from @report r
inner join
(
	select 
		case bankid 
			when '0365' then 'RBS'
			else 'NatWest'
		end as name,
		TotalTranCount
	from #transtats
) p on r.Bank = p.name

drop table #transtats

select @msg =
	convert(varchar(max),
		(
			select 
				Bank 'td','',
				CustCount 'td','',
				ActiveCardCount 'td','',
				TotalCardCount 'td','',
				TotalTranCount 'td',''
			from @report
			for xml path ('tr')
		)
	)
	
	select @msg = 			'<table border="1">
								<tr>
									<th>Bank</th>
									<th>Total Customers</th>
									<th>Total Active Cards</th>
									<th>Total Cards</th>
									<th>Total Transactions</th>
								</tr>' +
							@msg +
							'</table>'
	
	exec msdb..sp_send_dbmail 
		@profile_name = 'Administrator', 
		@recipients='nirupam.biswas@rewardinsight.com;joe.simpson@rewardinsight.com;joanne.foster@rewardinsight.com',
		@subject = 'Noble Weekly Stats',
		@body=@msg,
		@body_format = 'HTML', 
		@importance = 'NORMAL', 
		@exclude_query_output = 1	