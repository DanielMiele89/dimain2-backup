CREATE ROLE [ssis_admin]
    AUTHORIZATION [dbo];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [AllSchemaOwner];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [Zoe];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [jason];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN\jasondimain];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN\rorydimain];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN\haydendimain];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [kevinc];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [Rory];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN2\haydendimain2];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN2\SQLAgentJobUser];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [SQLAgentJobUser];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN2\awsetluser];


GO
ALTER ROLE [ssis_admin] ADD MEMBER [DIMAIN2\williamdimain2];

