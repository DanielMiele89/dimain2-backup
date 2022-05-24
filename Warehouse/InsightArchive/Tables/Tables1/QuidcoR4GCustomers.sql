CREATE TABLE [InsightArchive].[QuidcoR4GCustomers] (
    [PanID]       INT          NULL,
    [CompositeID] BIGINT       NULL,
    [SourceUID]   VARCHAR (20) NULL
);


GO
CREATE CLUSTERED INDEX [IXC_QuidcoR4GCustomers_PanID]
    ON [InsightArchive].[QuidcoR4GCustomers]([PanID] ASC) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [InsightArchive].[QuidcoR4GCustomers]([SourceUID] ASC) WITH (FILLFACTOR = 90);

