CREATE TABLE [Derived].[EmailEventCode] (
    [EmailEventCodeID] INT            NOT NULL,
    [EmailEventDesc]   NVARCHAR (100) NOT NULL,
    CONSTRAINT [pk_EEC] PRIMARY KEY CLUSTERED ([EmailEventCodeID] ASC)
);




GO
GRANT SELECT
    ON OBJECT::[Derived].[EmailEventCode] TO [virgin_etl_user]
    AS [dbo];

