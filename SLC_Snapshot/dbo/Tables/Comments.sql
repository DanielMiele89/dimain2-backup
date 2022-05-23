CREATE TABLE [dbo].[Comments] (
    [ID]                    INT             IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FanID]                 INT             NOT NULL,
    [StaffID]               INT             NOT NULL,
    [Comment]               NVARCHAR (4000) NOT NULL,
    [Date]                  DATETIME        NOT NULL,
    [StaffUsername]         NVARCHAR (50)   NULL,
    [CustomerContactCodeID] INT             NULL,
    [ObjectID]              INT             NULL,
    [ObjectTypeID]          INT             NULL,
    [Status]                INT             NOT NULL,
    [GasUserID]             INT             NULL,
    CONSTRAINT [PK_Comments] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 95)
);


GO
CREATE NONCLUSTERED INDEX [ix_ObjectTypeID_ObjectID]
    ON [dbo].[Comments]([ObjectTypeID] ASC, [ObjectID] ASC)
    INCLUDE([Comment], [CustomerContactCodeID], [Date]) WITH (FILLFACTOR = 70)
    ON [SLC_REPL_Indexes];


GO
GRANT SELECT
    ON OBJECT::[dbo].[Comments] TO [Analyst]
    AS [dbo];

