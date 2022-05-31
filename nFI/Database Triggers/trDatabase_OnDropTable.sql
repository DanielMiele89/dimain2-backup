CREATE trigger trDatabase_OnDropTable
on database
for drop_table
as
begin
    set nocount on;

    --Get the table schema and table name from EVENTDATA()
    DECLARE @Schema SYSNAME = eventdata().value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname');

    IF @Schema IN ('Relational', 'Staging')
    BEGIN

        PRINT 'DROP permission denied'

        --Rollback transaction for the DROP TABLE statement that fired the DDL trigger
        ROLLBACK;
    END
   
end;

--ENABLE trigger trDatabse_OnDropTable ON DATABASE
