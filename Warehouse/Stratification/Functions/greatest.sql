CREATE function [Stratification].[greatest] (@str1 float,@str2 float)
RETURNS float
BEGIN

	DECLARE @retVal float;

	set @retVal = (select case when @str1>=@str2 then @str1 else coalesce(@str2,@str1)  end as retVal)

	RETURN @retVal;
END;
