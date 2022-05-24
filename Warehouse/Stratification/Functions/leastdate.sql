CREATE function [Stratification].[leastdate] (@str1 date,@str2 date)
RETURNS nvarchar(max)
BEGIN

	DECLARE @retVal date;

	set @retVal = (select case when @str1<=@str2 then @str1 else coalesce(@str2,@str1)  end as retVal)

	RETURN @retVal;
END;
