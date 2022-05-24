

/*=================================================================================================
Sales Visualisation Refresh
Version 1: A. Devereux 25/02/2016
=================================================================================================*/
--Define Date (Transactional Universe to be considered)
--Approximate Time: 1 Hour

CREATE PROCEDURE [ExcelQuery].[alan_customer_lifetime_value_loop]
AS
BEGIN
	SET NOCOUNT ON;


IF OBJECT_ID('sandbox.alan.customer_lifetime_value') IS NOT NULL DROP TABLE sandbox.alan.customer_lifetime_value

create table sandbox.alan.customer_lifetime_value(
		[brandid] int
		,[brandname] varchar(max)
		,[Previous_Segment] varchar(3)
		,[SDate] date
		,[month_1] money
		,[month_2] money
		,[month_3] money
		,[month_6] money
		,[month_9] money
		,[month_12] money
)

select ROW_NUMBER() over (order by brandid) as RowNo
		,s.*
into #temp
from sandbox.Alan.Customer_value_Brand_List s

Declare @max int = (select max(RowNo) from #temp)
Declare @count int = 1
Declare @brandid int
while @count <= @max
begin
	set @brandid = (select brandid from #temp where RowNo = @count)
	insert into sandbox.alan.customer_lifetime_value
	EXEC	[ExcelQuery].[alan_customer_lifetime_value]
			@brandid = @brandid,
			@Edate = '2015-04-01'
	set @count = @count +1
end
end

