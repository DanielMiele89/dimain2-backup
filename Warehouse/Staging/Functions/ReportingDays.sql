
CREATE Function Staging.ReportingDays (@intvalue int) returns varchar(100)
As
--declare @intvalue int
--set @intvalue=60
Begin
declare @vsresult varchar(7)
declare @inti int
select @inti = 7, @vsresult = ''
while @inti>0
  begin
    select @vsresult=convert(char(1), @intvalue % 2)+@vsresult
    select @intvalue = convert(int, (@intvalue / 2)), @inti=@inti-1
  end
--select @vsresult


Declare @Days varchar(100)
Set @Days = ( Case
                     When Right(@vsresult,1) = 1 then 'Sunday,'
                     Else ''
              End +
			  Case
                     When Left(Right(@vsresult,2),1) = 1 then 'Monday,'
                     Else ''
              End+
			  Case
                     When Left(Right(@vsresult,3),1) = 1 then 'Tuesday,'
                     Else ''
              End+
			  Case
                     When Left(Right(@vsresult,4),1) = 1 then 'Wednesday,'
                     Else ''
              End+
			  Case
                     When Left(Right(@vsresult,5),1) = 1 then 'Thursday,'
                     Else ''
              End+
			  Case
                     When Left(Right(@vsresult,6),1) = 1 then 'Friday,'
                     Else ''
              End+
			  Case
                     When Left(@vsresult,1) = 1 then 'Saturday,'
                     Else ''
              End
			  )
			Set @days = (Select Case when Len(@Days) > 0 then Left(@Days,Len(@Days)-1) Else @Days End)
			Return @Days

End