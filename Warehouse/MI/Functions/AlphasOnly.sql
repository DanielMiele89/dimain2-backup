
CREATE Function [MI].[AlphasOnly](@Temp as varchar(50)) Returns varchar(50) As
Begin
  Declare @NumRange as varchar(50) = '%[0-9]%'
    While PatIndex(@NumRange, @Temp) > 0
        Set @Temp = Stuff(@Temp, PatIndex(@NumRange, @Temp), 1, '')

    Return @Temp
End
