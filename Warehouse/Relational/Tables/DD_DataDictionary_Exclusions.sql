CREATE TABLE [Relational].[DD_DataDictionary_Exclusions] (
    [ExclusionID] INT           IDENTITY (1, 1) NOT NULL,
    [OIN]         INT           NOT NULL,
    [Narrative]   VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ExclusionID] PRIMARY KEY CLUSTERED ([ExclusionID] ASC)
);

