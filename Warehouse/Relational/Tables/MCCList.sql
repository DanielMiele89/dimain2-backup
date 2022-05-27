CREATE TABLE [Relational].[MCCList] (
    [MCCID]       SMALLINT      IDENTITY (1, 1) NOT NULL,
    [MCC]         VARCHAR (4)   NOT NULL,
    [MCCGroup]    VARCHAR (50)  NOT NULL,
    [MCCCategory] VARCHAR (50)  NOT NULL,
    [MCCDesc]     VARCHAR (200) NOT NULL,
    [SectorID]    TINYINT       NOT NULL,
    CONSTRAINT [PK_Relational_MCCList] PRIMARY KEY CLUSTERED ([MCCID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [IX_MCCList_MCCDesc]
    ON [Relational].[MCCList]([MCC] ASC)
    INCLUDE([MCCDesc], [MCCID]) WITH (FILLFACTOR = 80);


GO
GRANT SELECT
    ON OBJECT::[Relational].[MCCList] TO [visa_etl_user]
    AS [dbo];

