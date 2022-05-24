CREATE TABLE [Relational].[DD_DataDictionary_SupplierSuggestedMatch] (
    [MatchID]    INT           IDENTITY (1, 1) NOT NULL,
    [OIN]        INT           NOT NULL,
    [Narrative]  VARCHAR (100) NOT NULL,
    [SupplierID] INT           NOT NULL,
    CONSTRAINT [PK_MatchID] PRIMARY KEY CLUSTERED ([MatchID] ASC)
);

