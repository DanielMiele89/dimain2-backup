CREATE procedure [AWSFile].[SpendEarn_004_Fetch]
as 
begin

select *
from awsfile.SpendEarn_004

end
GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SpendEarn_004_Fetch] TO [Process_AWS_SpendEarn]
    AS [dbo];

