ALTER ROLE [db_owner] ADD MEMBER [SLCReplication];


GO
ALTER ROLE [db_ddladmin] ADD MEMBER [conord];


GO
ALTER ROLE [db_datareader] ADD MEMBER [datarecon];


GO
ALTER ROLE [db_datareader] ADD MEMBER [conord];


GO
ALTER ROLE [db_datareader] ADD MEMBER [SamW];


GO
ALTER ROLE [db_datareader] ADD MEMBER [ProcessOp];


GO
ALTER ROLE [db_datawriter] ADD MEMBER [conord];

