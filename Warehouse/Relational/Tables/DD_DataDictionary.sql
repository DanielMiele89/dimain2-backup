CREATE TABLE [Relational].[DD_DataDictionary] (
    [DataDictionaryID] INT           IDENTITY (1, 1) NOT NULL,
    [OIN]              INT           NOT NULL,
    [Narrative]        VARCHAR (100) NOT NULL,
    [SupplierID]       INT           NOT NULL,
    CONSTRAINT [PK_DataDictionaryID] PRIMARY KEY CLUSTERED ([DataDictionaryID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_OIN]
    ON [Relational].[DD_DataDictionary]([OIN] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_Narr]
    ON [Relational].[DD_DataDictionary]([Narrative] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_SupplierID]
    ON [Relational].[DD_DataDictionary]([SupplierID] ASC);

