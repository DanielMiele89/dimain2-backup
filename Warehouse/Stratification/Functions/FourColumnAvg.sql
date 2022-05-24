CREATE FUNCTION Stratification.[FourColumnAvg]
(
    @a float=NULL,
    @b float=NULL,
    @c float=NULL,
	@d float=NULL
)
RETURNS float
AS
BEGIN
    DECLARE @result float
    DECLARE @divisor int
    SELECT @divisor = 4

    IF @a IS NULL BEGIN SELECT @divisor = @divisor - 1 END
    IF @b IS NULL BEGIN SELECT @divisor = @divisor - 1 END
    IF @c IS NULL BEGIN SELECT @divisor = @divisor - 1 END
	IF @d IS NULL BEGIN SELECT @divisor = @divisor - 1 END

    IF @divisor = 0     
        SELECT @result = 0
    ELSE
        SELECT @result = 1.0*(COALESCE(@a,0) + COALESCE(@b,0) + COALESCE(@c,0)+COALESCE(@d,0) ) / @divisor

    RETURN @Result

END