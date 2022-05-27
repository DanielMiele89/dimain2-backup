/*

	Author:		Stuart Barnley

	Date:		11th October 2016

	Purpose:	To find the Median value in any list whether with an odd or 
				even number of rows

*/

CREATE Procedure [Prototype].[MedianValueCalculator] (
					@TableName varchar(500),
					@FieldName varchar(50)	)
With Execute as Owner
As

Declare @Qry nvarchar(max)

Set @qry = '
Select  '+@FieldName+' as Value,
		ROW_NUMBER() OVER(ORDER BY '+@FieldName+' ASC) AS RowNo
Into	#t1
From	'+@TableName+'

Declare @Rows int
Set @Rows = (Select Count(*) From #t1)

If @Rows % 2 = 0
Begin
	Select Value 
	into #Values 
	From #t1 where RowNo = @Rows/2
	Union All
	Select Value 
	From #t1 where RowNo = (@Rows/2)+1

	Select Sum(Cast(Value as real))/2 From #Values
End

If @Rows % 2 = 1
Begin
	Select Value 
	From #t1 where RowNo = (Cast(@Rows as real)/2)+0.5
End

'
--Select @Qry

Exec SP_ExecuteSQL @Qry