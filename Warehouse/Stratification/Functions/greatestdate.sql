CREATE function [Stratification].[greatestdate] (@str1 date,@str2 date)
RETURNS nvarchar(max)
BEGIN

	DECLARE @retVal date;

	set @retVal = (select case when @str1<=@str2 then @str2 else coalesce(@str1,@str2)  end as retVal)

	RETURN @retVal;
END;
