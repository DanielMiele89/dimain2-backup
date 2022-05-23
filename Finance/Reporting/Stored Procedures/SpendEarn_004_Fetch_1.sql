CREATE procedure [Reporting].[SpendEarn_004_Fetch]
as 
begin

select *
from reporting.SpendEarn_004

end
GO
GRANT EXECUTE
    ON OBJECT::[Reporting].[SpendEarn_004_Fetch] TO [Process_AWS_SpendEarn]
    AS [dbo];

